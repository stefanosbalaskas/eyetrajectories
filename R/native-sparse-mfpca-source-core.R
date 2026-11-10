# Frozen Python 1.2 _sparse_multivariate.py: joint sparse planar covariance
# and full-covariance PACE algorithms. Python-free, no marginal fdapace or
# raw-trajectory interpolation. Uncertified source-model implementation.

.etr_spnm_validate_observations<-function(trajectories,dimensions,index){
  for(i in seq_along(trajectories$curve_ids)){
    values<-trajectories$values[[i]][,index,drop=FALSE]
    finite<-is.finite(values)
    mismatch<-which(xor(finite[,1L],finite[,2L]))
    details<-list(curve_id=trajectories$curve_ids[i],dimensions=dimensions)
    if(length(mismatch)){
      details$n_coordinate_specific_missing<-length(mismatch)
      details$sample_indices<-mismatch-1L
      .etr_spn_fail("coordinate_specific_missingness_unsupported",
        "x and y must be jointly observed at every retained sparse timestamp",details)
    }
    absent<-which(!finite[,1L]&!finite[,2L])
    if(length(absent)){
      details$n_nonfinite_joint_samples<-length(absent)
      details$sample_indices<-absent-1L
      .etr_spn_fail("nonfinite_sparse_planar_observation",
        "absent planar observations must be represented by absent samples",details)
    }
  }
}

.etr_spnm_analysis_support<-function(times,grid,action){
  .etr_assert(length(action)==1L&&action%in%c("error","restrict"),
    "analysis_support_action must be error or restrict")
  .etr_spn_check_grid_support(times,grid)
  masks<-lapply(times,function(t)t>=grid[1L]&t<=tail(grid,1L))
  counts<-as.integer(vapply(masks,sum,integer(1L)))
  outside<-as.integer(lengths(times)-counts)
  support<-list(analysis_support=range(grid),analysis_support_action=action,
    original_sample_counts=as.integer(lengths(times)),analysis_sample_counts=counts,
    outside_observation_count=sum(outside),outside_counts_by_curve=outside)
  if(action=="error"&&any(outside>0L))
    .etr_spn_fail("observations_outside_analysis_support",
      "observations lie outside the declared evaluation-grid support",
      support[c("analysis_support","outside_observation_count","outside_counts_by_curve")])
  if(sum(counts)<3L)
    .etr_spn_fail("insufficient_joint_support",
      "fewer than three planar observations remain on declared support",
      list(analysis_support=range(grid),in_support_observation_count=sum(counts),
        in_support_counts_by_curve=counts))
  list(masks=masks,summary=support)
}

.etr_spnm_pairs<-function(times,rx,ry){
  xx<-.etr_spn_pairs(times,rx)
  yy<-.etr_spn_pairs(times,ry)
  parts<-lapply(seq_along(times),function(i){
    t<-times[[i]];n<-length(t)
    if(n<2L)return(NULL)
    # Frozen _sparse_multivariate.raw_planar_covariance_pairs loops
    # left index outer, right index inner (Python row-major order).
    # which(...,arr.ind=TRUE) is column-major in R and permutes the
    # directional xy products even when the fitted operator is close.
    left<-rep(seq_len(n),each=n)
    right<-rep(seq_len(n),times=n)
    keep<-left!=right
    a<-left[keep];b<-right[keep]
    list(s=t[a],t=t[b],products=rx[[i]][a]*ry[[i]][b])
  })
  xy<-list(s=unlist(lapply(parts,function(z)z$s),use.names=FALSE),
    t=unlist(lapply(parts,function(z)z$t),use.names=FALSE),
    products=unlist(lapply(parts,function(z)z$products),use.names=FALSE))
  if(length(xy$products)<3L)
    .etr_spn_fail("insufficient_cross_covariance_pairs",
      "fewer than three offdiagonal cross-channel products")
  list(xx=xx,xy=xy,yy=yy,
    counts=c(xx=length(xx$products),xy=length(xy$products),
      yy=length(yy$products)))
}

.etr_spnm_surface<-function(pairs,grid,h,min_pairs=6L,
    cross=FALSE){
  n<-length(grid);C<-matrix(NA_real_,n,n)
  count<-matrix(0L,n,n)
  code<-if(cross)"insufficient_cross_covariance_local_support"
    else "insufficient_covariance_local_support"
  for(i in seq_len(n)){
    ds<-pairs$s-grid[i]
    ws<-.etr_spn_kernel(ds/h)
    for(j in seq_len(n)){
      dt<-pairs$t-grid[j]
      w<-ws*.etr_spn_kernel(dt/h)
      count[i,j]<-sum(w>0)
      if(count[i,j]<min_pairs)
        .etr_spn_fail(code,"too few offdiagonal local covariance pairs")
      C[i,j]<-.etr_spn_local_fit(cbind(1,ds,dt),
        pairs$products,w,3L,code)
    }
  }
  # Python smooth_planar_covariance_pairs retains the *raw* fitted
  # xx/xy/yy surfaces. Auditing and any explicit symmetry enforcement
  # happen later in audit_repair_planar_covariance. Pre-symmetrizing
  # xx/yy here conceals asymmetry and changes published smoothed_* data.
  list(values=C,support_counts=count)
}

.etr_spnm_operator<-function(blocks,grid,action="error",
    tolerance=1e-8,symmetry_tolerance=1e-10){
  .etr_assert(action%in%c("error","project"),
    "psd_action must be error or project")
  .etr_assert(is.finite(tolerance)&&tolerance>=0&&
    is.finite(symmetry_tolerance)&&symmetry_tolerance>=0,
    "joint PSD tolerances must be finite nonnegative")
  n<-length(grid)
  # Do NOT self-symmetrize xy: Cxy(s,t) and Cxy(t,s) have different meaning.
  xx<-blocks$xx;xy<-blocks$xy;yy<-blocks$yy
  yx<-t(xy)
  mismatch<-max(abs(xx-t(xx)),abs(yy-t(yy)),abs(yx-t(xy)))
  if(mismatch>symmetry_tolerance)
    .etr_spn_fail("joint_covariance_symmetry_failure",
      "planar covariance blocks violate joint symmetry tolerance",
      list(maximum_symmetry_error=mismatch,symmetry_tolerance=symmetry_tolerance))
  original<-rbind(cbind(xx,xy),cbind(yx,yy))
  original<-(original+t(original))/2
  w<-.etr_spn_weights(grid)
  sw<-sqrt(rep(w,2L))
  W<-outer(sw,sw)*original
  ev<-eigen(W,symmetric=TRUE)
  negative<-ev$values<0
  substantial<-ev$values < -tolerance
  if(action=="error"&&any(substantial))
    .etr_spn_fail("joint_covariance_psd_failure",
      "planar covariance operator has eigenvalues below the PSD tolerance",
      list(most_negative_eigenvalue=min(ev$values),
        negative_eigenvalue_count=sum(negative),
        substantial_negative_eigenvalue_count=sum(substantial),tolerance=tolerance))
  out<-original;applied<-"none"
  if(any(negative)){
    applied<-if(action=="project")"project"else
      "numerical_clip_within_tolerance"
    J<-ev$vectors%*%diag(pmax(ev$values,0),nrow=2L*n)%*%
      t(ev$vectors)
    out<-J/outer(sw,sw)
    out<-(out+t(out))/2
  }
  diff<-out-original
  a<-sqrt(sum(diff^2));b<-sqrt(sum(original^2))
  wd<-outer(sw,sw)*diff;wa<-sqrt(sum(wd^2));wb<-sqrt(sum(W^2))
  audit<-list(
    requested_action=action,applied_action=applied,
    tolerance=tolerance,symmetry_tolerance=symmetry_tolerance,
    pre_enforcement_symmetry_error=mismatch,
    pre_repair_operator_eigenvalues=sort(ev$values),
    negative_eigenvalue_count=sum(negative),
    substantial_negative_eigenvalue_count=sum(substantial),
    most_negative_eigenvalue=min(ev$values),
    correction_frobenius_norm=a,
    relative_correction_frobenius_norm=if(b==0)0 else a/b,
    operator_correction_frobenius_norm=wa,
    relative_operator_correction_frobenius_norm=if(wb==0)0 else wa/wb)
  list(
    smoothed=list(cxx=xx,cxy=xy,cyx=yx,cyy=yy),
    covariance=list(cxx=out[seq_len(n),seq_len(n)],
      cxy=out[seq_len(n),n+seq_len(n)],
      cyx=out[n+seq_len(n),seq_len(n)],
      cyy=out[n+seq_len(n),n+seq_len(n)]),
    matrix=out,audit=audit,quadrature_weights=w)
}

.etr_spnm_eigen<-function(matrix,grid,k,tolerance=1e-10){
  n<-length(grid)
  sw<-sqrt(rep(.etr_spn_weights(grid),2L))
  A<-outer(sw,sw)*((matrix+t(matrix))/2)
  e<-eigen(A,symmetric=TRUE)
  positive<-sum(e$values>tolerance)
  if(positive<k)
    .etr_spn_fail("insufficient_positive_joint_components",
      "joint covariance has fewer positive components than requested",
      list(requested_components=k,positive_components=positive,
        positive_tolerance=tolerance))
  lambda<-e$values[seq_len(k)]
  flat<-t(sweep(e$vectors[,seq_len(k),drop=FALSE],1L,sw,"/"))
  for(i in seq_len(k))if(flat[i,which.max(abs(flat[i,]))]<0)
    flat[i,]<- -flat[i,]
  # R output is (component, time, dimension), matching the public
  # Python fit's transposed score-eigenfunction schema.
  phi<-array(NA_real_,c(k,n,2L))
  for(j in seq_len(k)){
    phi[j,,1L]<-flat[j,seq_len(n)]
    phi[j,,2L]<-flat[j,n+seq_len(n)]
  }
  list(eigenvalues=lambda,eigenfunctions=phi,
    quadrature_weights=.etr_spn_weights(grid))
}

.etr_spnm_error<-function(mode,variances=NULL,covariance=NULL){
  .etr_assert(mode%in%c("diagonal","fixed_matrix"),
    "measurement_error must be diagonal or fixed_matrix")
  if(mode=="diagonal"){
    .etr_assert(is.null(covariance),
      "measurement_error_covariance is only valid for fixed_matrix")
    if(!(is.numeric(variances)&&length(variances)==2L&&
        all(is.finite(variances))&&all(variances>=0)))
      .etr_spn_fail("invalid_measurement_error_covariance",
        "diagonal requires two finite nonnegative noise variances")
    C<-diag(variances,nrow=2L)
  }else{
    .etr_assert(is.null(variances),
      "measurement_error_variance is only valid for diagonal")
    if(!(is.matrix(covariance)&&identical(dim(covariance),c(2L,2L))&&
        is.numeric(covariance)&&all(is.finite(covariance))))
      .etr_spn_fail("invalid_measurement_error_covariance",
        "fixed_matrix requires finite 2x2 covariance")
    C<-covariance
  }
  mismatch<-max(abs(C-t(C)))
  if(mismatch>1e-12)
    .etr_spn_fail("invalid_measurement_error_covariance",
      "noise covariance must be symmetric")
  C<-(C+t(C))/2
  e<-eigen(C,symmetric=TRUE,only.values=TRUE)$values
  if(min(e)<(-1e-12))
    .etr_spn_fail("invalid_measurement_error_covariance",
      "noise covariance must be positive semidefinite")
  list(mode=mode,covariance=C,eigenvalues=sort(e),
    symmetry_error=mismatch)
}

.etr_spnm_interp<-function(grid,C,time){
  n<-length(grid);m<-length(time)
  .etr_assert(all(time>=grid[1L])&&
    all(time<=grid[n]),
    "native_time_outside_fitted_support")
  ix<-pmin(findInterval(time,grid,all.inside=TRUE),n-1L)
  f<-(time-grid[ix])/(grid[ix+1L]-grid[ix])
  out<-matrix(0,m,m)
  for(i in seq_len(m))for(j in seq_len(m)){
    a<-ix[i];b<-ix[j];u<-f[i];v<-f[j]
    out[i,j]<-(1-u)*(1-v)*C[a,b]+u*(1-v)*C[a+1L,b]+
      (1-u)*v*C[a,b+1L]+u*v*C[a+1L,b+1L]
  }
  out
}

.etr_spnm_cov_eval <- function(grid,blocks,time){
  xx<-.etr_spnm_interp(grid,blocks$cxx,time)
  xy<-.etr_spnm_interp(grid,blocks$cxy,time)
  yy<-.etr_spnm_interp(grid,blocks$cyy,time)
  channel_major<-rbind(cbind(xx,xy),cbind(t(xy),yy))
  indices<-seq_along(time)
  time_major<-as.vector(rbind(indices,length(time)+indices))
  channel_major[time_major,time_major,drop=FALSE]
}

.etr_spnm_score<-function(ids,times,values,grid,mu,blocks,
    eig,measurement_noise,ridge=0,limit=1e12,
    min_time=2L,failure="error"){
  k<-length(eig$eigenvalues);n<-length(ids)
  scores<-matrix(NaN,n,k)
  diag_rows<-vector("list",n)
  E<-measurement_noise
  for(i in seq_len(n)){
    t<-times[[i]];v<-values[[i]]
    nt<-length(t);status<-"ok";solve_status<-"not_attempted"
    condition<-mine<-maxe<-NaN
    if(nt<min_time){
      status<-"curve_too_sparse_for_joint_score_system"
    }else{
      C<-.etr_spnm_cov_eval(grid,blocks,t)
      noise<-kronecker(diag(nt),E)
      Sigma<-C+noise+diag(ridge,2L*nt)
      Sigma<-(Sigma+t(Sigma))/2
      lambda<-eigen(Sigma,symmetric=TRUE,only.values=TRUE)$values
      mine<-min(lambda);maxe<-max(lambda)
      condition<-if(mine<=0)Inf else maxe/mine
      if(mine<=0)
        status<-"joint_score_covariance_not_positive_definite"
      else if(condition>limit)
        status<-"joint_score_covariance_ill_conditioned"
      else{
        raw<-as.vector(t(v))
        avg<-as.vector(rbind(
          .etr_spn_eval(grid,mu[,1L],t),
          .etr_spn_eval(grid,mu[,2L],t)))
        phi<-matrix(NA_real_,2L*nt,k)
        for(j in seq_len(k)){
          fj<-rbind(.etr_spn_eval(grid,eig$eigenfunctions[j,,1L],t),
            .etr_spn_eval(grid,eig$eigenfunctions[j,,2L],t))
          phi[,j]<-as.vector(fj)
        }
        beta<-solve(Sigma,raw-avg)
        scores[i,]<-eig$eigenvalues*as.numeric(crossprod(phi,beta))
        solve_status<-"solved"
      }
    }
    diag_rows[[i]]<-data.frame(curve_id=ids[i],n_time_points=nt,
      n_planar_observations=2L*nt,status_code=status,
      solve_status=solve_status,condition_number=condition,
      minimum_eigenvalue=mine,maximum_eigenvalue=maxe,
      score_ridge=ridge,condition_limit=limit,
      observation_order="time_major_interleaved_xy",
      stringsAsFactors=FALSE)
  }
  audit<-do.call(rbind,diag_rows)
  if(failure=="error"&&any(audit$status_code!="ok")){
    j<-which(audit$status_code!="ok")[1L]
    .etr_spn_score_fail(audit,j,
      paste0("joint PACE score system failed for curve ",ids[j]))
  }
  list(scores=scores,diagnostics=audit,
    provenance=list(
      operator_storage_order="channel_major",
      score_observation_order="time_major_interleaved_xy",
      ordering_permutation_applied=TRUE,
      score_covariance_source=
        "full_fitted_joint_covariance_plus_measurement_error",
      rank_k_covariance_used_for_scoring=FALSE))
}
