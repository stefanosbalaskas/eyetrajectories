# Direct frozen Python 1.2 known-truth multi-component FPCA recovery.
# Source: recovery.py::_population_values, _align_components,
# evaluate_fpca_recovery at c1cd95ad718327550f7e55393ff38582872f7a94.
# Pure native R. Does not refit a model, interpolate, or infer significance.

.etr_fpca_recovery_rows <- function(modes,weights,name) {
  .etr_assert(is.array(modes)&&is.numeric(modes)&&
    length(dim(modes))==3L&&dim(modes)[1L]>=1L&&
    length(weights)==dim(modes)[2L]&&
    all(is.finite(modes)),
    paste(name,"must contain finite source component arrays"))
  k<-dim(modes)[1L];nt<-dim(modes)[2L];nd<-dim(modes)[3L]
  flat<-matrix(0,k,nt*nd)
  for(j in seq_len(k))
    flat[j,]<-as.vector(t(matrix(modes[j,,,drop=FALSE],nt,nd)))
  flat
}

.etr_fpca_recovery_multi_assignment <- function(similarity){
  .etr_assert(is.matrix(similarity)&&is.numeric(similarity)&&
    nrow(similarity)>=1L&&ncol(similarity)>=nrow(similarity)&&
    all(is.finite(similarity)),
    "truth contains fewer components than the fitted result or invalid similarity")
  k<-nrow(similarity);m<-ncol(similarity)
  # SciPy maximizes absolute weighted cosine in a rectangular k-by-m matrix.
  # Pad with equal-cost dummy rows; their assignment cannot change the
  # true k-row objective. Our exact O(m^3) Hungarian source solver then
  # returns the original k real-row assignments.
  top<-max(abs(similarity))-abs(similarity)
  cost<-matrix(max(abs(similarity)),m,m)
  cost[seq_len(k),]<-top
  .etr_exact_assignment_hungarian(cost)[seq_len(k)]
}

.etr_fpca_recovery_multi <- function(result,truth) {
  .etr_recovery_source_fields(result,c("time","provenance",
    "dimension_names","scale","mean","components","explained_variance",
    "scores","weights"),"FPCA fit")
  .etr_recovery_source_fields(truth,c("truth_grid","dimension_names",
    "mean","eigenfunctions","eigenvalues","scores",
    "latent_on_truth_grid"),"FPCA generating truth")
  tt<-truth$truth_grid
  .etr_assert(is.numeric(tt)&&is.null(dim(tt))&&length(tt)>=3L&&
    all(is.finite(tt))&&all(diff(tt)>0),
    "truth_grid must be finite and strictly increasing")
  .etr_assert(is.numeric(result$time)&&is.null(dim(result$time))&&
    identical(as.numeric(result$time),as.numeric(tt)),
    "known-truth FPCA recovery requires exact source grid")
  .etr_assert(is.list(result$provenance),
    "FPCA provenance must be a source-shaped record")
  fpca<-result$provenance[["fpca",exact=TRUE]]
  .etr_assert(is.null(fpca)||is.list(fpca),
    "FPCA fit provenance must be source-shaped")
  scaling<-if(is.null(fpca))NULL else fpca[["scaling",exact=TRUE]]
  .etr_assert(is.null(scaling)||identical(scaling,"none"),
    "known-truth FPCA recovery requires scaling='none'")
  names_truth<-truth$dimension_names;nd<-length(names_truth);nt<-length(tt)
  .etr_assert(is.character(names_truth)&&nd>=1L&&!anyNA(names_truth)&&
    !anyDuplicated(names_truth)&&
    identical(result$dimension_names,names_truth),
    "fitted dimension names/order do not match generating truth")
  .etr_assert(is.numeric(result$scale)&&is.null(dim(result$scale))&&
    length(result$scale)==nd&&all(is.finite(result$scale))&&
    all(abs(result$scale-1)<=1e-12),
    "known-truth FPCA recovery requires unit dimension scales")
  w<-result$weights
  .etr_assert(is.numeric(w)&&is.null(dim(w))&&
    length(w)==nt&&all(is.finite(w))&&all(w>0),
    "functional quadrature weights must be finite and positive")
  .etr_assert(is.matrix(result$mean)&&is.numeric(result$mean)&&
    identical(dim(result$mean),c(nt,nd))&&all(is.finite(result$mean))&&
    is.matrix(truth$mean)&&is.numeric(truth$mean)&&
    identical(dim(truth$mean),c(nt,nd))&&all(is.finite(truth$mean)),
    "source fitted and generating means must match finite time/dimension geometry")
  est<-result$components;target<-truth$eigenfunctions
  .etr_assert(is.array(est)&&length(dim(est))==3L&&
    identical(as.integer(dim(est)[2:3]),c(nt,nd)),
    "fitted components must match source time/dimension geometry")
  .etr_assert(is.array(target)&&length(dim(target))==3L&&
    identical(as.integer(dim(target)[2:3]),c(nt,nd)),
    "truth components must match source time/dimension geometry")
  ke<-dim(est)[1L];kt<-dim(target)[1L]
  .etr_assert(ke>=1L&&kt>=ke,"truth contains fewer components than the fitted result")
  lambda<-result$explained_variance;truth_lambda<-truth$eigenvalues
  .etr_assert(is.numeric(lambda)&&length(lambda)==ke&&
    all(is.finite(lambda))&&is.numeric(truth_lambda)&&
    length(truth_lambda)==kt&&all(is.finite(truth_lambda))&&
    all(truth_lambda>0),
    "fitted and truth eigenvalues must match finite component geometry")
  ss<-result$scores;ts<-truth$scores
  .etr_assert(is.matrix(ss)&&is.numeric(ss)&&ncol(ss)==ke&&
    nrow(ss)>=2L&&all(is.finite(ss)),
    "estimated source scores must have finite curves-by-components geometry")
  n<-nrow(ss)
  .etr_assert(is.matrix(ts)&&is.numeric(ts)&&
    identical(dim(ts),c(n,kt))&&all(is.finite(ts)),
    "truth source scores must match all curves/components")
  latent<-truth$latent_on_truth_grid
  .etr_assert(is.array(latent)&&is.numeric(latent)&&
    identical(dim(latent),c(n,nt,nd))&&all(is.finite(latent)),
    "latent source curves must match reconstruction geometry")
  # Full population covariance is a dense (time*dimension)^2 object.
  .etr_assert(as.double(nt)*nd<=2000,
    "dense covariance recovery above 2000 source coordinates is not supported")
  flat_w<-rep(w,each=nd)
  E<-.etr_fpca_recovery_rows(est,w,"estimated")
  T<-.etr_fpca_recovery_rows(target,w,"truth")
  en<-sqrt(rowSums(sweep(E^2,2L,flat_w,"*")))
  tn<-sqrt(rowSums(sweep(T^2,2L,flat_w,"*")))
  .etr_assert(all(is.finite(c(en,tn)))&&all(en>0)&&all(tn>0),
    "functional components contain an invalid norm")
  E_norm<-E/en;T_norm<-T/tn
  signed<-sweep(E_norm,2L,flat_w,"*")%*%t(T_norm)
  assignment<-.etr_fpca_recovery_multi_assignment(signed)
  sign_match<-ifelse(signed[cbind(seq_len(ke),assignment+1L)]>=0,1,-1)
  similarity<-abs(signed[cbind(seq_len(ke),assignment+1L)])
  # NumPy QR and R QR provide the same weighted subspaces; singular
  # values of the cross-basis Gram matrix are principal cosines.
  e_weighted<-sweep(t(E_norm),1L,sqrt(flat_w),"*")
  t_weighted<-sweep(t(T_norm[assignment+1L,,drop=FALSE]),
    1L,sqrt(flat_w),"*")
  qe<-qr.Q(qr(e_weighted),complete=FALSE)
  qt<-qr.Q(qr(t_weighted),complete=FALSE)
  cosines<-pmax(0,pmin(1,svd(crossprod(qe,qt),nu=0L,nv=0L)$d))
  values<-list()
  add<-function(name,value,component=NULL){
    values[[length(values)+1L]]<<-
      .etr_fpca_recovery_value(name,value,component)
  }
  add("mean_ise",sum(sweep((result$mean-truth$mean)^2,1L,w,"*")))
  # NumPy time-major C-order matches rows flattened from t(time*channel).
  cov_est<-crossprod(E,E*lambda)
  cov_truth<-crossprod(T,T*truth_lambda)
  add("covariance_ise",sum((cov_est-cov_truth)^2*
    outer(flat_w,flat_w)))
  for(j in seq_len(ke)) {
    original<-assignment[j]+1L
    add("eigenvalue_relative_error",
      abs(lambda[j]-truth_lambda[original])/abs(truth_lambda[original]),
      as.integer(j-1L))
    add("component_absolute_similarity",similarity[j],
      as.integer(j-1L))
    aligned<-sign_match[j]*ss[,j]
    if(length(aligned)>=2L){
      correlation<-stats::cor(aligned,ts[,original])
      # Python may emit NaN for a constant score column; the finite
      # native scientific subset deliberately fails closed instead.
      .etr_assert(is.finite(correlation),
        "source score correlation is undefined on constant scores")
      add("score_correlation",correlation,as.integer(j-1L))
      add("score_rmse",sqrt(mean((aligned-ts[,original])^2)),
        as.integer(j-1L))
    }
  }
  for(j in seq_len(ke)){
    add("subspace_principal_cosine",cosines[j],as.integer(j-1L))
    add("subspace_principal_angle_degrees",
      acos(cosines[j])*180/pi,as.integer(j-1L))
  }
  curve_ise<-numeric(n)
  for(i in seq_len(n)){
    prediction<-result$mean
    for(j in seq_len(ke))
      prediction<-prediction+ss[i,j]*matrix(est[j,,,drop=FALSE],
        nrow=nt,ncol=nd)
    original<-matrix(latent[i,,,drop=FALSE],nrow=nt,ncol=nd)
    curve_ise[i]<-sum(sweep((prediction-original)^2,1L,w,"*"))
  }
  add("reconstruction_ise",mean(curve_ise))
  structure(list(values=values,provenance=list(
    estimator="FPCA",multivariate=nd>1L,
    truth_grid_match="exact",scaling="none",
    matched_truth_components=as.integer(assignment),
    alignment_signs=as.numeric(sign_match))),
    class="etr_functional_recovery_assessment")
}
