# Genuine native R mathematical reproduction of the FDApy 1.0.x UFPCA
# irregular covariance-operator fitting path. Pinned source:
# StevenGolovkine/FDApy snapshot 6626ebc6a70a6496f3058c4abb0bb97f5bdb20be
# FDApy/representation/functional_data.py::IrregularFunctionalData.mean,
# .center, .covariance; FDApy/preprocessing/smoothing/psplines.py and
# local_polynomial.py; FDApy/preprocessing/dim_reduction/ufpca.py.
#
# In particular, covariance is estimated on the pooled observed grid
# without raw-curve interpolation; source UFPCA PACE conditional scoring
# is performed separately and DOES internally interpolate (prior source).
# Native R may use different eigensystem signs/order than numpy.linalg.eig.
# Results expose that limitation explicitly; no Python backend object.

.etr_fdapy_fit_check_int <- function(x,name,min=0L) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x==floor(x)&&x>=min&&x<=.Machine$integer.max,
    paste0("FDApy ",name," must be a finite integer >= ",min))
  as.integer(x)
}

.etr_fdapy_ps_basis <- function(x,n_segments=10L,degree=3L,
    domain_min=min(x),domain_max=max(x)) {
  nseg<-.etr_fdapy_fit_check_int(n_segments,"n_segments",1L)
  deg<-.etr_fdapy_fit_check_int(degree,"degree",1L)
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)>=2L&&
    all(is.finite(x))&&
    is.numeric(domain_min)&&length(domain_min)==1L&&
    is.finite(domain_min)&&is.numeric(domain_max)&&
    length(domain_max)==1L&&is.finite(domain_max)&&
    domain_max>domain_min,
    "FDApy P-spline basis needs a nondegenerate physical time domain")
  dx<-(domain_max-domain_min)/nseg
  knots<-seq(domain_min-deg*dx,domain_max+deg*dx,
    length.out=nseg+2L*deg+1L)
  # FDApy computes precisely the uniform unclamped B-spline basis with
  # n_segments+degree functions via truncated powers and differences.
  # splines::splineDesign is the direct de Boor equivalent; domain
  # endpoints lie strictly inside the unclamped outer knot support.
  B<-splines::splineDesign(knots,x,ord=deg+1L,outer.ok=TRUE)
  .etr_assert(identical(dim(B),c(length(x),nseg+deg))&&
    all(is.finite(B)),
    "source FDApy uniform B-spline basis dimension or values invalid")
  B
}

.etr_fdapy_ps_penalty <- function(p,order_penalty=2L) {
  ord<-.etr_fdapy_fit_check_int(order_penalty,"order_penalty",0L)
  .etr_assert(ord<p,"FDApy difference penalty order exceeds spline basis")
  D<-diag(p)
  if(ord>0L)
    for(k in seq_len(ord))
      D<-D[-nrow(D),,drop=FALSE]-
        D[-1L,,drop=FALSE]
  crossprod(D)
}

.etr_fdapy_ps_1d <- function(x,y,points,
    penalty=1,n_segments=10L,degree=3L,
    order_penalty=2L,domain_min=min(points),
    domain_max=max(points)) {
  .etr_assert(is.numeric(x)&&is.numeric(y)&&
    length(x)==length(y)&&length(x)>=2L&&
    all(is.finite(x))&&all(is.finite(y))&&
    is.numeric(penalty)&&length(penalty)==1L&&
    is.finite(penalty)&&penalty>=0,
    "FDApy 1D P-spline requires finite paired data and nonnegative penalty")
  B<-.etr_fdapy_ps_basis(x,n_segments,degree,domain_min,domain_max)
  X<-.etr_fdapy_ps_basis(points,n_segments,degree,domain_min,domain_max)
  gram<-crossprod(B)+as.numeric(penalty)*
    .etr_fdapy_ps_penalty(ncol(B),order_penalty)
  beta<-.etr_fdapy_spectrum_pinv(gram)%*%crossprod(B,y)
  as.vector(X%*%beta)
}

# FDApy's IrregularFunctionalData.mean(..., method_smoothing="PS") first
# calls _format_data: it constructs a unique-time grid, keeps the LAST
# long-format observation at each repeated time, and gives a ZERO weight
# to any cell whose last value is zero. This is not ordinary pooled least
# squares across all irregular observations. Preserve the original pooled
# evaluation domain even when a boundary cell has zero weight.
.etr_fdapy_ps_irregular_mean <- function(x,y,points,
    penalty=1,n_segments=10L,degree=3L,order_penalty=2L) {
  .etr_assert(is.numeric(x)&&is.numeric(y)&&length(x)==length(y)&&
    all(is.finite(x))&&all(is.finite(y)),
    "FDApy PS irregular mean requires finite aligned source observations")
  if(length(x)>2000L) {
    # Source defaults to approx=TRUE. For >2000 original long-form
    # samples, pandas.groupby(time).mean() is applied BEFORE _format_data.
    # Preserve exact double-time grouping and source's zero-weight rule.
    ord<-order(x)
    sorted_x<-x[ord]
    sorted_y<-y[ord]
    starts<-which(c(TRUE,diff(sorted_x)!=0))
    ends<-c(starts[-1L]-1L,length(sorted_x))
    x<-sorted_x[starts]
    y<-vapply(seq_along(starts),function(i)
      mean(sorted_y[starts[i]:ends[i]]),numeric(1L))
  }
  retained<-!duplicated(x,fromLast=TRUE)
  weighted<-retained&(y!=0)
  .etr_assert(sum(weighted)>=2L,
    "FDApy PS irregular mean has insufficient nonzero unique-time cells")
  .etr_fdapy_ps_1d(x[weighted],y[weighted],points,
    penalty=penalty,n_segments=n_segments,degree=degree,
    order_penalty=order_penalty)
}

.etr_fdapy_lp_design <- function(x,degree) {
  deg<-.etr_fdapy_fit_check_int(degree,"local polynomial degree",0L)
  .etr_assert(deg<=2L,
    "FDApy source-scientific LP supports degrees 0, 1 or 2; higher polynomial interactions not reviewed")
  if(is.null(dim(x)))x<-matrix(x,ncol=1L)
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    ncol(x)%in%c(1L,2L)&&all(is.finite(x)),
    "FDApy local polynomial requires numeric one- or two-dimensional predictor matrix")
  z<-matrix(1,nrow(x),1L)
  if(deg>=1L)z<-cbind(z,x)
  if(deg>=2L)
    z<-if(ncol(x)==1L)
      cbind(z,x[,1L]^2)
    else cbind(z,x[,1L]^2,x[,1L]*x[,2L],x[,2L]^2)
  z
}

.etr_fdapy_lp_predict <- function(x,y,points,
    bandwidth,degree=1L,kernel_name="epanechnikov") {
  if(is.null(dim(x)))x<-matrix(x,ncol=1L)
  if(is.null(dim(points)))points<-matrix(points,ncol=ncol(x))
  .etr_assert(is.matrix(x)&&is.matrix(points)&&
    ncol(x)==ncol(points)&&
    is.numeric(y)&&length(y)==nrow(x)&&all(is.finite(y))&&
    is.numeric(bandwidth)&&length(bandwidth)==1L&&
    is.finite(bandwidth)&&bandwidth>0,
    "FDApy local polynomial needs finite paired values and positive bandwidth")
  .etr_assert(is.character(kernel_name)&&length(kernel_name)==1L&&
    kernel_name%in%c("epanechnikov","gaussian","tricube","bisquare"),
    "FDApy local polynomial kernel_name unsupported")
  X<-.etr_fdapy_lp_design(x,degree)
  Q<-.etr_fdapy_lp_design(points,degree)
  out<-numeric(nrow(points))
  for(j in seq_len(nrow(points))) {
    dx<-sweep(x,2L,points[j,],"-")
    dist<-sqrt(rowSums(dx^2))/bandwidth
    w<-switch(kernel_name,
      epanechnikov=.75*pmax(0,1-dist^2)*(dist<=1),
      gaussian=exp(-.5*dist^2)/sqrt(2*pi),
      tricube=pmax(0,1-abs(dist)^3)^3*(dist<1),
      bisquare=pmax(0,1-dist^2)^2*(dist<1))
    # Source _local_regression: np.linalg.lstsq(X'W X,
    # X'W y, rcond=1e-10), *not* locally recentered x-x0.
    gram<-crossprod(X,X*w)
    rhs<-crossprod(X,w*y)
    beta<-.etr_fdapy_spectrum_pinv(gram,rcond=1e-10)%*%rhs
    out[j]<-as.vector(Q[j,,drop=FALSE]%*%beta)
  }
  out
}

.etr_fdapy_ps_2d <- function(time,rawcov,
    n_segments=30L,degree=3L,order_penalty=2L,
    penalty=c(1,1)) {
  m<-length(time)
  pmat<-.etr_fdapy_ps_basis(time,n_segments,degree)
  p<-ncol(pmat)
  .etr_assert(is.numeric(penalty)&&length(penalty)==2L&&
    all(is.finite(penalty))&&all(penalty>=0),
    "FDApy PS 2D requires two finite nonnegative penalties")
  .etr_assert(is.matrix(rawcov)&&identical(dim(rawcov),c(m,m)),
    "FDApy raw covariance grid shape mismatch")
  .etr_assert(p*p<=1600L,
    "FDApy dense source PS covariance basis requires <=1600 tensor coefficients in native R")
  # FDApy computes covariance weights BEFORE setting its diagonal
  # pseudo-observations to 0, so the original nonzero-diagonal weights
  # persist. The zero rawcov slots have zero P-spline weights.
  W<-as.numeric(t(rawcov!=0))
  Y<-rawcov
  diag(Y)<-0
  y<-as.numeric(t(Y))
  # In Python the full grid is C-order: (time_i,time_j) with j
  # varying fastest. Tensor basis columns have first axis slow.
  Z<-matrix(0,m*m,p*p)
  for(i in seq_len(m))for(j in seq_len(m))
    Z[(i-1L)*m+j,]<-rep(pmat[i,],each=p)*
      rep(pmat[j,],times=p)
  P<-.etr_fdapy_ps_penalty(p,order_penalty)
  pen<-penalty[1L]*kronecker(P,diag(p))+
    penalty[2L]*kronecker(diag(p),P)
  # FDApy 2D uses np.linalg.lstsq(A,b,rcond=None). Numerical
  # eigenvalue signs/rounding of its general LAPACK SVD remain
  # bounded by tolerance, not asserted bitwise identical.
  gram<-crossprod(Z,Z*W)+pen
  rhs<-crossprod(Z,W*y)
  coeff<-.etr_fdapy_spectrum_pinv(gram,rcond=.Machine$double.eps*
    max(dim(gram)))%*%rhs
  matrix(as.vector(Z%*%coeff),nrow=m,ncol=m,byrow=TRUE)
}

.etr_fdapy_cov_raw <- function(times,values,pooled) {
  m<-length(pooled)
  total<-matrix(0,m,m)
  counts<-matrix(0,m,m)
  for(i in seq_along(times)) {
    idx<-match(times[[i]],pooled)
    .etr_assert(!anyNA(idx),
      "FDApy pooled covariance times could not be mapped exactly")
    z<-values[[i]]
    total[idx,idx]<-total[idx,idx]+tcrossprod(z)
    counts[idx,idx]<-counts[idx,idx]+1
  }
  covariance<-matrix(0,m,m)
  present<-counts>0
  covariance[present]<-total[present]/counts[present]
  list(raw=covariance,count=counts,zero_weight=(!present))
}

.etr_fdapy_diff_noise <- function(values) {
  # FDApy misc/utils.py DIFF_SEQUENCES[2] constants are deliberately
  # fixed to their published rounded source values (not normalized).
  coef<-c(.8090,-.5000,-.3090)
  vapply(values,function(y){
    if(length(y)<3L)return(0)
    mean(vapply(seq_len(length(y)-2L),function(j)
      sum(coef*y[j:(j+2L)])^2,numeric(1L)))
  },numeric(1L))
}

# DGEEV is used rather than base::eigen(): base::eigen() reorders even
# general eigenvalues by decreasing modulus, while NumPy keeps DGEEV order.
# This helper deliberately returns the unsorted real LAPACK right eigenpairs.
.etr_fdapy_unsorted_real_eig <- function(x) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&nrow(x)==ncol(x)&&
    all(is.finite(x)),"FDApy DGEEV needs a finite real square matrix")
  n<-as.integer(nrow(x))
  .etr_assert(n>=2L&&n<=.Machine$integer.max/8L,
    "FDApy DGEEV dimension is outside the supported range")
  work_n<-as.integer(max(1L,8L*n))
  result<-tryCatch(.Fortran("dgeev",
      jobvl="N",jobvr="V",n=n,a=as.double(x),lda=n,
      wr=double(n),wi=double(n),vl=double(1L),ldvl=1L,
      vr=double(n*n),ldvr=n,
      work=double(work_n),lwork=work_n,info=integer(1L)),
    error=function(e)stop("Native FDApy requires unsorted LAPACK DGEEV: ",
      conditionMessage(e),call.=FALSE))
  .etr_assert(identical(result$info,0L)&&
    all(is.finite(result$wr))&&all(is.finite(result$wi))&&
    all(abs(result$wi)<=1e-10),
    "FDApy real covariance DGEEV failed or returned complex eigenpairs")
  list(values=as.numeric(result$wr),
    vectors=matrix(as.numeric(result$vr),n,n))
}

.etr_fdapy_fit_native_ufpca <- function(trajectories,dimension,
    n_components,fit_smoothing,score_smoothing,tol,normalize,
    evaluation_grid,kwargs_mean,kwargs_covariance) {
  .etr_assert(identical(normalize,FALSE),
    "FDApy source native PS/LP full fit currently requires normalize=FALSE")
  n_components<-.etr_fdapy_fit_check_int(n_components,"n_components",1L)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "FDApy source fit dimension must be a known sampled channel")
  .etr_assert(is.character(fit_smoothing)&&length(fit_smoothing)==1L&&
    fit_smoothing%in%c("PS","LP"),
    "FDApy native full UFPCA source fit needs fit_smoothing PS or LP")
  # UFPCA.transform(data,method="PACE",tol=...) passes tol through
  # IrregularFunctionalData.center to DenseFunctionalData.smooth.
  # Source PSplines.__init__ does NOT accept 'tol', whereas source
  # LocalPolynomial.__init__ accepts and ignores **kwargs. Therefore
  # the frozen public wrapper's score_smoothing='PS' can fail with a
  # TypeError rather than supplying scores. Do not claim that mode.
  .etr_assert(identical(score_smoothing,"LP"),
    "FDApy frozen 1.0.x public PACE transform with tol requires score_smoothing='LP'; PS source passes unexpected tol to PSplines")
  .etr_assert(is.null(kwargs_mean)||is.list(kwargs_mean),
    "FDApy kwargs_mean must be a named source options list")
  .etr_assert(is.null(kwargs_covariance)||is.list(kwargs_covariance),
    "FDApy kwargs_covariance must be a named source options list")
  meanopts<-if(is.null(kwargs_mean))list() else kwargs_mean
  covopts<-if(is.null(kwargs_covariance))list() else kwargs_covariance
  allowed_mean<-if(identical(fit_smoothing,"PS"))
    c("penalty","n_segments","degree","order_penalty") else
    c("bandwidth","degree","kernel_name")
  allowed_cov<-if(identical(fit_smoothing,"PS"))
    c("penalty","n_segments","degree","order_penalty",
      "remove_diagonal") else
    c("bandwidth","degree","kernel_name","remove_diagonal")
  named_valid<-function(x,allowed) {
    length(x)==0L ||
      (!is.null(names(x))&&
        all(!is.na(names(x))&nzchar(names(x)))&&
        all(names(x)%in%allowed)&&
        !anyDuplicated(names(x)))
  }
  .etr_assert(named_valid(meanopts,allowed_mean)&&
    named_valid(covopts,allowed_cov),
    "FDApy full source fit kwargs_mean/kwargs_covariance include unnamed, unsupported or duplicate options")
  .etr_assert(is.null(covopts$remove_diagonal)||
    identical(covopts$remove_diagonal,TRUE),
    "FDApy source-scientific covariance currently requires remove_diagonal=TRUE")
  grid<-sort(unique(unlist(trajectories$time,use.names=FALSE)))
  if(!is.null(evaluation_grid))
    .etr_assert(identical(as.numeric(evaluation_grid),grid),
      "FDApy irregular source evaluation_grid must equal exact pooled observed times")
  idx<-match(dimension,trajectories$dimension_names)
  .etr_assert(!is.na(idx)&&is.character(dimension)&&length(dimension)==1L,
    "FDApy native source dimension must name a true irregular channel")
  n<-length(trajectories$curve_ids)
  .etr_assert(n_components<=n-1L&&n_components>=1L,
    "n_components cannot exceed n_curves-1")
  time<-trajectories$time
  values<-lapply(trajectories$values,function(z)
    as.numeric(z[,idx]))
  .etr_assert(all(vapply(values,function(x)all(is.finite(x)),
    logical(1L))),"FDApy native source channel requires finite observations")
  if(identical(fit_smoothing,"PS")){
    mean_segs<-if(is.null(meanopts$n_segments))10L else meanopts$n_segments
    mean_degree<-if(is.null(meanopts$degree))3L else meanopts$degree
    mean_order<-if(is.null(meanopts$order_penalty))2L else meanopts$order_penalty
    pen<-if(is.null(meanopts$penalty))1 else meanopts$penalty
    .etr_assert(is.numeric(pen)&&length(pen)==1L,
      "FDApy PS mean penalty must be a scalar")
    mu<-.etr_fdapy_ps_irregular_mean(
      unlist(time,use.names=FALSE),unlist(values,use.names=FALSE),grid,
      penalty=pen,n_segments=mean_segs,degree=mean_degree,
      order_penalty=mean_order)
    # Source data.center(mean=...,method_smoothing='PS',penalty=(0,))
    # independently re-fits the pre-estimated mean with zero penalty
    # on the pooled grid, using DEFAULT PS basis settings.
    mu_center<-.etr_fdapy_ps_1d(grid,mu,grid,penalty=0,
      n_segments=10L,degree=3L,order_penalty=2L)
  }else{
    bandwidth<-if(is.null(meanopts$bandwidth))
      mean(lengths(time))^(-1/5) else meanopts$bandwidth
    degree<-if(is.null(meanopts$degree))1L else meanopts$degree
    kernel<-if(is.null(meanopts$kernel_name))
      "epanechnikov" else meanopts$kernel_name
    mu<-.etr_fdapy_lp_predict(unlist(time),unlist(values),grid,
      bandwidth=bandwidth,degree=degree,kernel_name=kernel)
    mu_center<-.etr_fdapy_ps_1d(grid,mu,grid,penalty=0,
      n_segments=10L,degree=3L,order_penalty=2L)
  }
  centered<-lapply(seq_along(time),function(i)
    values[[i]]-mu_center[match(time[[i]],grid)])
  noise<-mean(.etr_fdapy_diff_noise(centered))
  raw<-.etr_fdapy_cov_raw(time,centered,grid)
  m<-length(grid)
  if(identical(fit_smoothing,"PS")){
    C<-.etr_fdapy_ps_2d(grid,raw$raw,
      n_segments=if(is.null(covopts$n_segments))30L else covopts$n_segments,
      degree=if(is.null(covopts$degree))3L else covopts$degree,
      order_penalty=if(is.null(covopts$order_penalty))2L else covopts$order_penalty,
      penalty=if(is.null(covopts$penalty))c(1,1) else covopts$penalty)
  }else{
    rawlp<-raw$raw
    diag(rawlp)<-NA_real_
    pairs<-which(!is.na(rawlp),arr.ind=TRUE)
    y<-rawlp[pairs]
    p<-cbind(grid[pairs[,1L]],grid[pairs[,2L]])
    qi<-rep(seq_len(m),each=m)
    qj<-rep(seq_len(m),times=m)
    q<-cbind(grid[qi],grid[qj])
    cov_band<-if(is.null(covopts$bandwidth))
      (m*m)^(-1/5) else covopts$bandwidth
    cov_degree<-if(is.null(covopts$degree))2L else covopts$degree
    kernel<-if(is.null(covopts$kernel_name))
      "epanechnikov" else covopts$kernel_name
    C<-matrix(.etr_fdapy_lp_predict(p,y,q,
      bandwidth=cov_band,degree=cov_degree,kernel_name=kernel),
      nrow=m,ncol=m,byrow=TRUE)
  }
  C<-(C+t(C))/2
  # FDApy UFPCA._fit_covariance: eig(W^1/2 C W^1/2) where
  # W denotes actual nonuniform-grid trapezoidal quadrature weights.
  delta<-diff(grid)
  w<-if(m==2L) rep(delta[1L]/2,2L) else
    c(delta[1L],grid[3:m]-grid[1:(m-2L)],delta[m-1L])/2
  .etr_assert(all(is.finite(w))&&all(w>0),
    "FDApy covariance fitting requires strictly positive trapezoidal source weights")
  weighted<-C*outer(sqrt(w),sqrt(w))
  # Frozen FDApy misc/utils.py::_compute_eigen calls numpy.linalg.eig,
  # NOT eigh, on this symmetric-in-values matrix. Crucially it selects
  # the FIRST n_components in LAPACK DGEEV's UNSORTED order and only
  # afterwards clips negative eigenvalues to zero. Calling R eigen with
  # symmetric=TRUE instead sorts descending, changes the second
  # eigenpair (often a negative one), then propagates false positive
  # minor components into Mercer covariance and PACE scores.
  # Base R eigen() *also sorts* its general eigenpairs by modulus.
  # FDApy uses NumPy's raw DGEEV order; do not sort before slicing.
  eig<-.etr_fdapy_unsorted_real_eig(weighted)
  lambda<-pmax(eig$values,0)
  .etr_assert(length(lambda)>=n_components&&all(is.finite(lambda)),
    "FDApy native covariance requires finite source eigenvalues")
  phi<-t(sweep(eig$vectors[,seq_len(n_components),drop=FALSE],
    1L,sqrt(w),"/"))
  # Only sign conventions and platform-level unsorted LAPACK tie
  # ordering may differ from NumPy. Do not re-sort eigenpairs or
  # replace zero-clipped source components with positive alternatives.
  # Frozen public source explicitly calls UFPCA.transform(data, ...)
  # rather than UFPCA.transform(NULL, ...). FDApy therefore calls
  # data.center(mean=self._mean,method_smoothing=score_smoothing).
  # This SECOND centering is distinct from FIT's required PS penalty=0
  # re-smoothing and must be used for public PACE scores.
  score_mean<-if(identical(score_smoothing,"LP"))
    .etr_fdapy_lp_predict(grid,mu,grid,
      bandwidth=m^(-1/5),degree=1L,
      kernel_name="epanechnikov")
  else if(identical(score_smoothing,"PS"))
    .etr_fdapy_ps_1d(grid,mu,grid,penalty=1,
      n_segments=10L,degree=3L,order_penalty=2L)
  else stop("FDApy score_smoothing must be PS or LP",call.=FALSE)
  score_centered<-lapply(seq_along(time),function(i)
    values[[i]]-score_mean[match(time[[i]],grid)])
  snapshot<-list(mean_grid=mu,
    eigenfunctions=phi,
    eigenvalues=lambda[seq_len(n_components)],
    noise_variance=noise,
    centered_observations=score_centered,
    backend_version=NULL)
  out<-.etr_fdapy_fixed_spectrum_pace(trajectories,dimension,
    n_components,fit_smoothing,score_smoothing,tol,normalize,
    evaluation_grid,kwargs_mean,kwargs_covariance,snapshot)
  out$source_mean_fit<-mu
  out$source_mean_center_resmoothed<-mu_center
  out$source_fit_centered_observations<-centered
  out$source_score_mean_resmoothed<-score_mean
  out$source_score_centered_observations<-score_centered
  out$source_raw_covariance<-raw$raw
  out$source_raw_covariance_counts<-raw$count
  out$source_smoothed_covariance<-C
  out$source_quadrature_weights<-w
  out$source_eigenfunctions<-phi
  out$source_eigenvalues_full<-lambda
  out$source_eigenvalue_orientation<-"FDApy_numpy_general_eig_unsorted_negative_clipped"
  out$source_noise_estimator<-"FDApy_DIFFERENCE_SEQUENCE_order_2"
  out$source_covariance_estimator<-
    paste0("FDApy_irregular_1.0.x_",fit_smoothing,"_smoothing")
  out$fitted_UFPCA_model_natively<-TRUE
  out$source_fit_full_parity<-FALSE
  out$source_scientific_scope<-
    "FDApy_UFPCA_irregular_PS_LP_mean_center_raw_covariance_smoothed_covariance_weighted_FPCA_PACE"
  out$source_backend<-"native_R_FDApy_1_0_x_UFPCA_PS_LP_PACE_scientific"
  out$provenance$sparse_fpca$spectral_state_supplied_instead_of_fitted<-FALSE
  out$provenance$sparse_fpca$scientific_native_UFPCA_fit<-TRUE
  out$provenance$sparse_fpca$fit_covariance_centering<-
    "data.center(mean=UFPCA.mean,method_smoothing=PS,penalty=0)"
  out$provenance$sparse_fpca$pace_score_centering<-
    paste0("data.center(mean=UFPCA.mean,method_smoothing=",
      score_smoothing,")")
  out$provenance$sparse_fpca$source_eigen_sign_and_order_uncertified<-TRUE
  class(out)<-c("etr_fdapy_native_ufpca_ps_lp_scientific_record",class(out))
  out
}
