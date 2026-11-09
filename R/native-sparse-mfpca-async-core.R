# Frozen Python 1.2 _sparse_multivariate_async.py, SHA:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Source-model raw asynchronous planar covariance and joint PACE primitives.
# No interpolation of raw coordinate observations or Python runtime.

.etr_spna_views<-function(trajectories,dimensions,grid,action){
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(length(trajectories$curve_ids)>=3L,
    "insufficient_joint_support")
  .etr_assert(is.character(dimensions)&&length(dimensions)==2L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must name two distinct source planar channels")
  .etr_assert(action%in%c("error","restrict"),
    "analysis_support_action must be error or restrict")
  ii<-match(dimensions,trajectories$dimension_names)
  n<-length(trajectories$curve_ids)
  tx<-ty<-xv<-yv<-vector("list",n)
  ux<-uy<-sim<-xonly<-yonly<-outx<-outy<-integer(n)
  for(i in seq_len(n)){
    t<-trajectories$time[[i]]
    v<-trajectories$values[[i]][,ii,drop=FALSE]
    if(any(is.infinite(v)))
      .etr_spn_fail("nonfinite_sparse_async_observation",
        "asynchronous values can be finite or NaN but not Inf")
    a<-is.finite(v[,1L]);b<-is.finite(v[,2L])
    if(any(!(a|b)))
      .etr_spn_fail("empty_async_timestamp_row",
        "each union timestamp needs at least one observed coordinate")
    ux[i]<-sum(a);uy[i]<-sum(b);sim[i]<-sum(a&b)
    xonly[i]<-sum(a&!b);yonly[i]<-sum(!a&b)
    mx<-t[a]>=grid[1L]&t[a]<=tail(grid,1L)
    my<-t[b]>=grid[1L]&t[b]<=tail(grid,1L)
    outx[i]<-sum(!mx);outy[i]<-sum(!my)
    tx[[i]]<-t[a];xv[[i]]<-v[a,1L]
    ty[[i]]<-t[b];yv[[i]]<-v[b,2L]
  }
  poolx<-unlist(tx,use.names=FALSE)
  pooly<-unlist(ty,use.names=FALSE)
  if(length(poolx)<3L)
    .etr_spn_fail("insufficient_async_x_support",
      "fewer than three x observations")
  if(length(pooly)<3L)
    .etr_spn_fail("insufficient_async_y_support",
      "fewer than three y observations")
  tol<-1e-12*max(1,abs(poolx),abs(pooly))
  if(grid[1L]<min(poolx)-tol||tail(grid,1L)>max(poolx)+tol||
      grid[1L]<min(pooly)-tol||tail(grid,1L)>max(pooly)+tol)
    .etr_spn_fail("evaluation_grid_outside_coordinate_support",
      "population grid must lie inside both coordinate supports")
  if(action=="error"&&sum(outx+outy)>0L)
    .etr_spn_fail("observations_outside_analysis_support",
      "coordinate values outside population grid")
  if(action=="restrict")for(i in seq_len(n)){
    a<-tx[[i]]>=grid[1L]&tx[[i]]<=tail(grid,1L)
    b<-ty[[i]]>=grid[1L]&ty[[i]]<=tail(grid,1L)
    tx[[i]]<-tx[[i]][a];xv[[i]]<-xv[[i]][a]
    ty[[i]]<-ty[[i]][b];yv[[i]]<-yv[[i]][b]
  }
  if(sum(lengths(tx))<3L)
    .etr_spn_fail("insufficient_async_x_support",
      "fewer than three x values on analysis support")
  if(sum(lengths(ty))<3L)
    .etr_spn_fail("insufficient_async_y_support",
      "fewer than three y values on analysis support")
  support<-list(
    analysis_support=range(grid),analysis_support_action=action,
    original_union_sample_counts=as.integer(lengths(trajectories$time)),
    original_x_sample_counts=as.integer(ux),
    original_y_sample_counts=as.integer(uy),
    analysis_x_sample_counts=as.integer(lengths(tx)),
    analysis_y_sample_counts=as.integer(lengths(ty)),
    x_outside_counts_by_curve=as.integer(outx),
    y_outside_counts_by_curve=as.integer(outy),
    simultaneous_sample_counts=as.integer(sim),
    x_only_sample_counts=as.integer(xonly),
    y_only_sample_counts=as.integer(yonly),
    outside_coordinate_observation_count=as.integer(sum(outx+outy)))
  list(tx=tx,xv=xv,ty=ty,yv=yv,support=support)
}

.etr_spna_cross_pairs<-function(tx,rx,ty,ry,tolerance){
  xx<-.etr_spn_pairs(tx,rx)
  yy<-.etr_spn_pairs(ty,ry)
  items<-vector("list",length(tx));candidate<-excluded<-0L
  for(i in seq_along(tx)){
    if(!length(tx[[i]])||!length(ty[[i]]))next
    ix<-rep(seq_along(tx[[i]]),each=length(ty[[i]]))
    iy<-rep(seq_along(ty[[i]]),times=length(tx[[i]]))
    candidate<-candidate+length(ix)
    keep<-abs(tx[[i]][ix]-ty[[i]][iy])>tolerance
    excluded<-excluded+sum(!keep)
    items[[i]]<-list(s=tx[[i]][ix[keep]],
      t=ty[[i]][iy[keep]],
      products=rx[[i]][ix[keep]]*ry[[i]][iy[keep]])
  }
  xy<-lapply(c("s","t","products"),function(name)
    unlist(lapply(items,function(x)x[[name]]),use.names=FALSE))
  names(xy)<-c("s","t","products")
  if(length(xy$products)<3L)
    .etr_spn_fail("insufficient_async_cross_covariance_pairs",
      "less than three cross-coordinate products after same-time exclusion")
  list(xx=xx,xy=xy,yy=yy,
    pair_counts=c(xx=length(xx$products),
      xy=length(xy$products),yy=length(yy$products)),
    audit=list(cross_candidate_pair_count=as.integer(candidate),
      cross_same_time_pair_count_excluded=as.integer(excluded),
      cross_retained_pair_count=as.integer(length(xy$products)),
      same_time_tolerance=tolerance))
}

.etr_spna_scalar_layout<-function(tx,x,ty,y,tolerance){
  n<-length(tx)+length(ty)
  times<-c(tx,ty);channels<-c(rep(1L,length(tx)),rep(2L,length(ty)))
  values<-c(x,y);original<-c(seq_along(tx),seq_along(ty))
  order<-order(times,channels,method="radix")
  list(time=times[order],channel=channels[order],
    value=values[order],original=original[order],
    n_x=length(tx),n_y=length(ty),
    simultaneous=sum(vapply(tx,function(t)
      sum(abs(ty-t)<=tolerance),integer(1L))))
}

.etr_spna_pace<-function(ids,views,grid,mu,blocks,eigen,noise,
    tolerance,ridge,limit,min_obs,failure){
  n<-length(ids);k<-length(eigen$eigenvalues)
  scores<-matrix(NaN,n,k);diagnostics<-vector("list",n)
  for(i in seq_len(n)){
    layout<-.etr_spna_scalar_layout(views$tx[[i]],views$xv[[i]],
      views$ty[[i]],views$yv[[i]],tolerance)
    t<-layout$time;ch<-layout$channel;m<-length(t)
    status<-"ok";solve_status<-"not_attempted"
    min_eig<-max_eig<-cond<-NaN;links<-0L
    if(m<min_obs)status<-"curve_too_sparse_for_async_joint_score_system"
    else{
      # Evaluate four fitted blocks on the full scalar native-time layout.
      # Cxy(s,t) is directional; Cyx(t,s) is its transpose.
      M<-matrix(0,m,m)
      for(a in seq_len(m))for(b in seq_len(m)){
        C<-switch(paste0(ch[a],ch[b]),
          "11"=blocks$cxx,"12"=blocks$cxy,
          "21"=blocks$cyx,"22"=blocks$cyy)
        ia<-min(findInterval(t[a],grid,all.inside=TRUE),
          length(grid)-1L)
        ib<-min(findInterval(t[b],grid,all.inside=TRUE),
          length(grid)-1L)
        fa<-(t[a]-grid[ia])/(grid[ia+1L]-grid[ia])
        fb<-(t[b]-grid[ib])/(grid[ib+1L]-grid[ib])
        M[a,b]<-(1-fa)*(1-fb)*C[ia,ib]+
          fa*(1-fb)*C[ia+1L,ib]+
          (1-fa)*fb*C[ia,ib+1L]+fa*fb*C[ia+1L,ib+1L]
      }
      M<-(M+t(M))/2
      for(a in seq_len(m))M[a,a]<-M[a,a]+noise[ch[a],ch[a]]+ridge
      for(a in seq_len(m))if(a<m)for(b in seq.int(a+1L,m)){
        if(ch[a]!=ch[b]&&abs(t[a]-t[b])<=tolerance){
          M[a,b]<-M[a,b]+noise[ch[a],ch[b]]
          M[b,a]<-M[b,a]+noise[ch[b],ch[a]]
          links<-links+1L
        }
      }
      spectrum<-base::eigen(M,symmetric=TRUE,only.values=TRUE)$values
      min_eig<-min(spectrum);max_eig<-max(spectrum)
      cond<-if(min_eig<=0)Inf else max_eig/min_eig
      if(min_eig<=0)status<-
        "async_joint_score_covariance_not_positive_definite"
      else if(cond>limit)status<-
        "async_joint_score_covariance_ill_conditioned"
      else{
        fitted_mu<-numeric(m);Phi<-matrix(NA_real_,m,k)
        for(a in seq_len(m)){
          fitted_mu[a]<-.etr_spn_eval(grid,mu[,ch[a]],t[a])
          for(j in seq_len(k))Phi[a,j]<-.etr_spn_eval(grid,
            eigen$eigenfunctions[j,,ch[a]],t[a])
        }
        solved<-tryCatch(solve(M,layout$value-fitted_mu),
          error=function(e).etr_spn_fail(
            "async_joint_score_covariance_solve_failed",
            conditionMessage(e)))
        scores[i,]<-eigen$eigenvalues*
          as.numeric(crossprod(Phi,solved))
        solve_status<-"solved"
      }
    }
    diagnostics[[i]]<-data.frame(curve_id=ids[i],
      n_x_observations=layout$n_x,
      n_y_observations=layout$n_y,
      n_scalar_observations=m,
      n_simultaneous_pairs=layout$simultaneous,
      measurement_error_cross_links=links,
      status_code=status,solve_status=solve_status,
      condition_number=cond,minimum_eigenvalue=min_eig,
      maximum_eigenvalue=max_eig,
      score_ridge=ridge,condition_limit=limit,
      observation_order="time_major_x_before_y_for_ties",
      stringsAsFactors=FALSE)
  }
  audit<-do.call(rbind,diagnostics)
  if(failure=="error"&&any(audit$status_code!="ok")){
    i<-which(audit$status_code!="ok")[1L]
    .etr_spn_fail(audit$status_code[i],
      paste("asynchronous PACE failed for",ids[i]))
  }
  list(scores=scores,diagnostics=audit,
    provenance=list(
      score_observation_order="time_major_x_before_y_for_ties",
      paired_reduction_order="time_major_interleaved_xy",
      score_covariance_source=
        "full_fitted_joint_covariance_plus_async_measurement_error",
      rank_k_covariance_used_for_scoring=FALSE,
      measurement_error_cross_covariance_scope="simultaneous_xy_only"))
}
