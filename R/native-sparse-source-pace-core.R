# Source-structured native R PACE mathematics. Frozen Python 1.2
# src/eyetrajectoriespy/_sparse_native.py, c1cd95ad718327550f7e55393ff38582872f7a94.
# Scope: known measurement-error variance, local-linear Epanechnikov mean and
# off-diagonal covariance, weighted operator PSD, full-covariance PACE.
# No fdapace, reticulate, or R/Python full-contract certification.

.etr_spn_fail<-function(code,message,details=list()){
  stop(structure(list(message=paste0(code,": ",message),call=NULL,
    code=code,details=details),
    class=c("etr_sparse_native_error","simpleError","error","condition")))
}

.etr_spn_score_fail<-function(audit,index,message,include_curve_audit=TRUE){
  details<-as.list(audit[index,,drop=FALSE])
  if(include_curve_audit)
    details$all_curve_diagnostics<-lapply(seq_len(nrow(audit)),
      function(i)as.list(audit[i,,drop=FALSE]))
  .etr_spn_fail(audit$status_code[index],message,details)
}

.etr_spn_grid<-function(x){
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)>=3L&&
    all(is.finite(x))&&all(diff(x)>0),
    "evaluation_grid must be finite strictly increasing with >=3 points")
  x
}

.etr_spn_uncertainty_grid<-function(x){
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)>=2L&&
    all(is.finite(x))&&all(diff(x)>0),"fit evaluation grid is invalid")
  x
}

.etr_spn_score_correlations<-function(covariance,standard_errors){
  out<-array(NaN,dim(covariance))
  k<-ncol(standard_errors)
  for(i in seq_len(nrow(standard_errors))){
    P<-matrix(covariance[i,,],k,k)
    if(!all(is.finite(P)))next
    scale<-outer(standard_errors[i,],standard_errors[i,])
    correlation<-matrix(NaN,k,k)
    use<-scale>0
    correlation[use]<-P[use]/scale[use]
    diag(correlation)<-1
    out[i,,]<-correlation
  }
  out
}

.etr_spn_check_grid_support<-function(times,grid){
  start<-min(vapply(times,function(t)t[1L],numeric(1L)))
  end<-max(vapply(times,function(t)tail(t,1L),numeric(1L)))
  tolerance<-1e-12*max(1,abs(start),abs(end))
  if(grid[1L]<start-tolerance||tail(grid,1L)>end+tolerance)
    .etr_spn_fail("evaluation_grid_outside_pooled_support",
      "evaluation_grid must lie within pooled observation support",
      list(pooled_start=start,pooled_end=end,
        grid_start=grid[1L],grid_end=tail(grid,1L)))
}

.etr_spn_analysis_support<-function(times,values,grid,action){
  support<-range(grid)
  keep<-lapply(times,function(t)t>=support[1L]&t<=support[2L])
  counts<-vapply(keep,sum,integer(1L))
  outside<-lengths(times)-counts
  diagnostics<-list(analysis_support=support,analysis_support_action=action,
    outside_observation_count=sum(outside),
    curves_with_outside_observations=sum(outside>0L),
    curves_without_in_support_observations=sum(counts==0L),
    outside_counts_by_curve=as.integer(outside),
    original_sample_counts=as.integer(lengths(times)),
    analysis_sample_counts=as.integer(counts))
  if(action=="error"&&any(outside>0L))
    .etr_spn_fail("observations_outside_analysis_support",
      "raw sparse observations outside fitted population grid",
      diagnostics[c("analysis_support","outside_observation_count",
        "curves_with_outside_observations","outside_counts_by_curve")])
  if(sum(counts)<3L)
    .etr_spn_fail("insufficient_pooled_support",
      "fewer than three in-support observations",
      list(analysis_support=support,in_support_observation_count=sum(counts),
        in_support_counts_by_curve=as.integer(counts)))
  if(action=="restrict"){
    times<-Map(function(t,m)t[m],times,keep)
    values<-Map(function(y,m)y[m],values,keep)
  }
  list(times=times,values=values,diagnostics=diagnostics)
}

.etr_spn_kernel<-function(u){
  out<-numeric(length(u))
  ok<-abs(u)<=1&is.finite(u)
  out[ok]<-.75*(1-u[ok]^2)
  out
}

.etr_spn_local_fit<-function(design,y,w,required,code,details=list()){
  mask<-w>0
  if(sum(mask)<required)
    .etr_spn_fail(code,"insufficient positive-weight observations",details)
  sw<-sqrt(w[mask])
  A<-design[mask,,drop=FALSE]*sw
  # Frozen Python 1.2 uses NumPy matrix_rank and lstsq, not R's QR
  # rank tolerance. For tiny time units (e.g. 1e-13 seconds), QR with
  # tol=1e-12 can reject a full-rank local fit accepted by NumPy.
  # NumPy's default cutoff is max(m,n) * sigma_max * eps(binary64).
  decomposition<-svd(A,nu=ncol(A),nv=ncol(A))
  cutoff<-max(dim(A))*max(decomposition$d)*.Machine$double.eps
  if(sum(decomposition$d>cutoff)<ncol(A))
    .etr_spn_fail(code,"weighted local design is rank deficient",details)
  projected<-as.numeric(crossprod(decomposition$u,y[mask]*sw))
  coefficients<-decomposition$v%*%(projected/decomposition$d)
  as.numeric(coefficients[1L])
}

.etr_spn_mean<-function(t,y,points,h,min_points=3L){
  .etr_assert(is.numeric(h)&&length(h)==1L&&is.finite(h)&&h>0,
    "mean_bandwidth must be finite positive")
  .etr_assert(length(t)==length(y)&&all(is.finite(t))&&
    all(is.finite(y))&&all(is.finite(points)),
    "mean smoother needs finite matched observations")
  v<-numeric(length(points));support<-integer(length(points))
  for(i in seq_along(points)){
    delta<-t-points[i];w<-.etr_spn_kernel(delta/h)
    support[i]<-sum(w>0)
    if(support[i]<min_points)
      .etr_spn_fail("insufficient_mean_local_support",
        "local-linear mean support below declared minimum",
        list(evaluation_point=as.numeric(points[i]),
          support_count=as.integer(support[i]),
          required_count=as.integer(min_points),bandwidth=as.numeric(h)))
    v[i]<-.etr_spn_local_fit(cbind(1,delta),y,w,2L,
      "insufficient_mean_local_support",
      list(evaluation_point=as.numeric(points[i]),
        support_count=as.integer(support[i]),bandwidth=as.numeric(h)))
  }
  list(values=v,support_counts=support)
}

.etr_spn_pairs<-function(times,residuals){
  pieces<-lapply(seq_along(times),function(i){
    t<-times[[i]];r<-residuals[[i]]
    if(length(t)<2L)return(NULL)
    ix<-which(upper.tri(matrix(FALSE,length(t),length(t))),
      arr.ind=TRUE)
    a<-ix[,1L];b<-ix[,2L];v<-r[a]*r[b]
    list(s=c(t[a],t[b]),t=c(t[b],t[a]),
      products=c(v,v))
  })
  out<-lapply(c("s","t","products"),function(field)
    unlist(lapply(pieces,function(z)z[[field]]),use.names=FALSE))
  names(out)<-c("s","t","products")
  if(length(out$products)<3L)
    .etr_spn_fail("insufficient_within_curve_covariance_pairs",
      "fewer than three offdiagonal pairs")
  out
}

.etr_spn_surface<-function(pairs,grid,h,min_pairs=6L){
  .etr_assert(is.numeric(h)&&length(h)==1L&&is.finite(h)&&h>0,
    "covariance_bandwidth must be finite positive")
  n<-length(grid);C<-matrix(NA_real_,n,n)
  support<-matrix(0L,n,n)
  for(i in seq_len(n)){
    ds<-pairs$s-grid[i];wi<-.etr_spn_kernel(ds/h)
    for(j in seq_len(n)){
      dt<-pairs$t-grid[j]
      w<-wi*.etr_spn_kernel(dt/h)
      support[i,j]<-sum(w>0)
      if(support[i,j]<min_pairs)
        .etr_spn_fail("insufficient_covariance_local_support",
          "insufficient offdiagonal covariance local pairs",
          list(s=as.numeric(grid[i]),t=as.numeric(grid[j]),
            support_count=as.integer(support[i,j]),
            required_count=as.integer(min_pairs),bandwidth=as.numeric(h)))
      C[i,j]<-.etr_spn_local_fit(cbind(1,ds,dt),
        pairs$products,w,3L,"insufficient_covariance_local_support",
        list(s=as.numeric(grid[i]),t=as.numeric(grid[j]),
          support_count=as.integer(support[i,j]),bandwidth=as.numeric(h)))
    }
  }
  list(values=(C+t(C))/2,support_counts=support)
}

.etr_spn_rotated_diagonal<-function(pairs,grid,h,min_pairs=6L){
  .etr_assert(is.numeric(h)&&length(h)==1L&&is.finite(h)&&h>0,
    "covariance_bandwidth must be finite positive")
  along<-(pairs$s+pairs$t)/sqrt(2)
  perp<-(pairs$t-pairs$s)/sqrt(2)
  fitted<-numeric(length(grid));support<-integer(length(grid))
  for(i in seq_along(grid)){
    delta<-along-sqrt(2)*grid[i]
    w<-.etr_spn_kernel(delta/h)*.etr_spn_kernel(perp/h)
    support[i]<-sum(w>0)
    if(support[i]<min_pairs)
      .etr_spn_fail("insufficient_noise_diagonal_local_support",
        "rotated covariance-diagonal has too few offdiagonal pairs",
        list(evaluation_point=as.numeric(grid[i]),
          support_count=as.integer(support[i]),
          required_count=as.integer(min_pairs),bandwidth=as.numeric(h)))
    fitted[i]<-.etr_spn_local_fit(
      cbind(1,delta,perp^2),pairs$products,w,3L,
      "insufficient_noise_diagonal_local_support",
      list(evaluation_point=as.numeric(grid[i]),
        support_count=as.integer(support[i]),bandwidth=as.numeric(h)))
  }
  list(values=fitted,support_counts=support,
    rotation="45_degrees_linear_along_diagonal_quadratic_perpendicular")
}

.etr_spn_noise_diagonal_difference<-function(times,residuals,grid,
    latent_diagonal,noise_bandwidth,noise_support,min_local_points=3L){
  .etr_assert(is.numeric(noise_bandwidth)&&
    length(noise_bandwidth)==1L&&is.finite(noise_bandwidth)&&
    noise_bandwidth>0,
    "noise_bandwidth must be finite positive")
  .etr_assert(is.numeric(noise_support)&&
    length(noise_support)==2L&&all(is.finite(noise_support))&&
    noise_support[1L]<noise_support[2L]&&
    noise_support[1L]>=grid[1L]&&
    noise_support[2L]<=tail(grid,1L),
    "noise_support must be finite interval inside evaluation grid")
  t_pool<-unlist(times,use.names=FALSE)
  squared<-unlist(lapply(residuals,function(z)z^2),use.names=FALSE)
  raw<-.etr_spn_mean(t_pool,squared,grid,noise_bandwidth,
    min_local_points)$values
  delta<-raw-latent_diagonal
  mask<-grid>=noise_support[1L]&grid<=noise_support[2L]
  if(sum(mask)<2L)
    .etr_spn_fail("insufficient_noise_support",
      "fewer than two evaluation points on noise support")
  w<-.etr_spn_weights(grid[mask])
  variance<-sum(w*delta[mask])/sum(w)
  # Frozen primitive retains an invalid estimate and status; the public
  # fit rejects it only after collecting source measurement diagnostics.
  list(variance=variance,
    raw_diagonal=raw,
    latent_diagonal=latent_diagonal,
    diagonal_difference=delta,support_mask=mask,
    status_code=if(is.finite(variance)&&variance>0)
      "ok" else "noise_variance_invalid")
}

.etr_spn_weights<-function(grid){
  n<-length(grid);w<-numeric(n)
  w[1L]<-(grid[2L]-grid[1L])/2
  w[n]<-(grid[n]-grid[n-1L])/2
  if(n>2L)w[2L:(n-1L)]<-
    (grid[3L:n]-grid[1L:(n-2L)])/2
  w
}

.etr_spn_psd<-function(C,grid,action="error",tolerance=1e-8){
  .etr_assert(action%in%c("error","project"),
    "psd_action must be error or project")
  .etr_assert(is.numeric(tolerance)&&length(tolerance)==1L&&
    is.finite(tolerance)&&tolerance>=0,
    "psd_tolerance must be finite nonnegative")
  n<-length(grid);C<-(C+t(C))/2
  sw<-sqrt(.etr_spn_weights(grid))
  W<-outer(sw,sw)*C
  e<-eigen(W,symmetric=TRUE)
  neg<-e$values<0;substantial<-e$values < -tolerance
  if(action=="error"&&any(substantial))
    .etr_spn_fail("covariance_psd_failure",
      "fitted weighted covariance has substantial negative eigenvalues")
  applied<-"none";R<-C
  if(any(neg)){
    applied<-if(action=="project")"project"else
      "numerical_clip_within_tolerance"
    RW<-e$vectors%*%diag(pmax(e$values,0),nrow=n)%*%t(e$vectors)
    R<-RW/outer(sw,sw);R<-(R+t(R))/2
  }
  d<-R-C;norm<-sqrt(sum(C^2));delta<-sqrt(sum(d^2))
  wd<-outer(sw,sw)*d;wn<-sqrt(sum(W^2));dn<-sqrt(sum(wd^2))
  list(covariance=R,audit=list(
    requested_action=action,applied_action=applied,tolerance=tolerance,
    pre_repair_operator_eigenvalues=sort(e$values),
    negative_eigenvalue_count=sum(neg),
    substantial_negative_eigenvalue_count=sum(substantial),
    most_negative_eigenvalue=min(e$values),
    correction_frobenius_norm=delta,
    relative_correction_frobenius_norm=if(norm==0)0 else delta/norm,
    operator_correction_frobenius_norm=dn,
    relative_operator_correction_frobenius_norm=if(wn==0)0 else dn/wn))
}

.etr_spn_eigensystem<-function(C,grid,k,tolerance=1e-10){
  w<-.etr_spn_weights(grid);sw<-sqrt(w)
  D<-outer(sw,sw)*((C+t(C))/2)
  ev<-eigen(D,symmetric=TRUE)
  if(sum(ev$values>tolerance)<k)
    .etr_spn_fail("insufficient_positive_components",
      "operator has fewer positive components than requested")
  lambda<-ev$values[seq_len(k)]
  phi<-t(sweep(ev$vectors[,seq_len(k),drop=FALSE],1L,sw,"/"))
  for(j in seq_len(k))if(phi[j,which.max(abs(phi[j,]))]<0)
    phi[j,]<- -phi[j,]
  list(eigenvalues=lambda,eigenfunctions=phi,quadrature_weights=w)
}

.etr_spn_eval<-function(grid,v,t){
  .etr_assert(all(t>=grid[1L])&&all(t<=tail(grid,1L)),
    "native_time_outside_fitted_support")
  stats::approx(grid,v,xout=t,rule=1,ties="ordered")$y
}

.etr_spn_cov_eval<-function(grid,C,t){
  n<-length(grid);m<-length(t)
  .etr_assert(all(t>=grid[1L])&&all(t<=grid[n]),
    "native_time_outside_fitted_support")
  a<-pmin(findInterval(t,grid,all.inside=TRUE),n-1L)
  u<-(t-grid[a])/(grid[a+1L]-grid[a])
  V<-matrix(0,m,m)
  for(i in seq_len(m))for(j in seq_len(m)){
    x<-a[i];y<-a[j];p<-u[i];q<-u[j]
    V[i,j]<-(1-p)*(1-q)*C[x,y]+p*(1-q)*C[x+1L,y]+
      (1-p)*q*C[x,y+1L]+p*q*C[x+1L,y+1L]
  }
  (V+t(V))/2
}

.etr_spn_score_system<-function(ids,times,values,grid,mean,C,lambda,phi,
    noise,ridge=0,limit=1e12,min_samples=2L,
    failure_action="error",posterior=FALSE){
  k<-length(lambda);n<-length(ids)
  scores<-matrix(NaN,n,k);posterior_cov<-array(NaN,c(n,k,k))
  standard_errors<-matrix(NaN,n,k)
  diagnostics<-vector("list",n)
  prior<-diag(lambda,nrow=k)
  tol<-1e-10*max(1,max(abs(lambda)))
  for(i in seq_len(n)){
    t<-times[[i]];v<-values[[i]];nobs<-length(t)
    status<-"ok";solved<-"not_attempted"
    cond<-mine<-maxe<-post_min<-residual<-NaN;repaired<-FALSE
    if(nobs<min_samples)status<-"curve_too_sparse_for_score_system"
    else{
      Sigma<-.etr_spn_cov_eval(grid,C,t)+diag(noise+ridge,nobs)
      Sigma<-(Sigma+t(Sigma))/2
      e<-eigen(Sigma,symmetric=TRUE,only.values=TRUE)$values
      mine<-min(e);maxe<-max(e)
      cond<-if(mine<=0)Inf else maxe/mine
      if(mine<=0)status<-"score_covariance_not_positive_definite"
      else if(cond>limit)status<-"score_covariance_ill_conditioned"
      else{
        Phi<-matrix(NA_real_,nobs,k)
        for(j in seq_len(k))Phi[,j]<-.etr_spn_eval(grid,phi[j,],t)
        if(posterior){
          rhs<-Phi%*%prior
          M<-solve(Sigma,rhs,tol=0)
          residual<-sqrt(sum((Sigma%*%M-rhs)^2))/
            max(1,sqrt(sum(rhs^2)))
          P<-prior-crossprod(rhs,M);P<-(P+t(P))/2
          pe<-eigen(P,symmetric=TRUE)
          post_min<-min(pe$values)
          if(post_min< -tol)status<-"conditional_score_covariance_not_psd"
          else{
            if(post_min<0){
              P<-pe$vectors%*%diag(pmax(pe$values,0),nrow=k)%*%
                t(pe$vectors)
              P<-(P+t(P))/2;repaired<-TRUE
            }
            posterior_cov[i,,]<-P
            standard_errors[i,]<-sqrt(pmax(diag(P),0))
            solved<-"solved"
          }
        }else{
          b<-solve(Sigma,v-.etr_spn_eval(grid,mean,t))
          scores[i,]<-lambda*as.numeric(crossprod(Phi,b))
          solved<-"solved"
        }
      }
    }
    row<-data.frame(curve_id=ids[i],n_samples=nobs,
      status_code=status,solve_status=solved,
      condition_number=cond,minimum_eigenvalue=mine,
      maximum_eigenvalue=maxe,score_ridge=ridge,
      condition_limit=limit,stringsAsFactors=FALSE)
    if(posterior){
      row$posterior_minimum_eigenvalue<-post_min
      row$posterior_psd_repair_applied<-repaired
      row$solve_relative_residual<-residual
      row<-row[c("curve_id","n_samples","status_code","solve_status",
        "condition_number","minimum_eigenvalue","maximum_eigenvalue",
        "posterior_minimum_eigenvalue","posterior_psd_repair_applied",
        "solve_relative_residual","score_ridge","condition_limit")]
    }
    diagnostics[[i]]<-row
  }
  diagnostic<-do.call(rbind,diagnostics)
  if(failure_action=="error"&&any(diagnostic$status_code!="ok")){
    i<-which(diagnostic$status_code!="ok")[1L]
    message<-if(posterior)paste("conditional PACE uncertainty system failed for curve",
      .etr_python_workflow_identifier_repr(ids[i])) else
      paste("PACE system failed for curve",ids[i])
    .etr_spn_score_fail(diagnostic,i,message)
  }
  list(scores=scores,covariance=posterior_cov,
    standard_errors=standard_errors,diagnostics=diagnostic)
}
