# Frozen source eyetrajectoriespy 1.2 _sparse_multilevel.py:
# source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Raw same-participant/different-trial cross-products and full-covariance
# joint Gaussian BLUP, no raw interpolation or rank-k approximation.

.etr_spml_cross_pairs<-function(times,residuals,participant){
  ids<-unique(as.character(participant))
  parts<-vector("list",length(ids))
  counts<-integer(length(ids))
  for(g in seq_along(ids)){
    index<-which(participant==ids[g])
    if(length(index)<2L)next
    pieces<-list()
    for(a in seq_len(length(index)-1L)){
      i<-index[a]
      for(b in seq.int(a+1L,length(index))){
        j<-index[b]
        ti<-times[[i]];tj<-times[[j]]
        if(!length(ti)||!length(tj))next
        ix<-rep(seq_along(ti),each=length(tj))
        iy<-rep(seq_along(tj),times=length(ti))
        products<-residuals[[i]][ix]*residuals[[j]][iy]
        pieces[[length(pieces)+1L]]<-list(
          s=c(ti[ix],tj[iy]),t=c(tj[iy],ti[ix]),
          products=c(products,products))
      }
    }
    if(length(pieces)){
      parts[[g]]<-lapply(c("s","t","products"),function(k)
        unlist(lapply(pieces,function(z)z[[k]]),use.names=FALSE))
      names(parts[[g]])<-c("s","t","products")
      counts[g]<-length(parts[[g]]$products)
    }
  }
  valid<-Filter(Negate(is.null),parts)
  out<-lapply(c("s","t","products"),function(k)
    unlist(lapply(valid,function(z)z[[k]]),use.names=FALSE))
  names(out)<-c("s","t","products")
  if(length(out$products)<3L)
    .etr_spn_fail("insufficient_between_curve_covariance_pairs",
      "between-participant covariance requires distinct-trial cross-products")
  list(pairs=out,participant_pair_counts=stats::setNames(counts,ids))
}

.etr_spml_interp_cross<-function(grid,C,left,right){
  if(!length(left)||!length(right))
    return(matrix(0,length(left),length(right)))
  both<-c(left,right)
  eval<-.etr_spn_cov_eval(grid,C,both)
  n<-length(left);m<-length(right)
  eval[seq_len(n),n+seq_len(m),drop=FALSE]
}

.etr_spml_blup<-function(curve_ids,participant,times,values,grid,mu,
    between,within,participant_eigen,trial_eigen,noise,ridge,
    condition_limit,min_samples,failure_action){
  ids<-unique(as.character(participant))
  n<-length(curve_ids)
  kp<-length(participant_eigen$eigenvalues)
  kt<-length(trial_eigen$eigenvalues)
  scores_p<-matrix(NaN,length(ids),kp)
  scores_t<-matrix(NaN,n,kt)
  diagnostics<-vector("list",length(ids))
  for(g in seq_along(ids)){
    index<-which(participant==ids[g])
    local_t<-times[index]
    local_y<-values[index]
    sizes<-lengths(local_t)
    offsets<-c(0L,cumsum(sizes))
    nobs<-sum(sizes)
    status<-"ok"
    solved_status<-"not_attempted"
    min_eig<-max_eig<-condition<-solve_residual<-NaN
    if(nobs<min_samples){
      status<-"participant_too_sparse_for_multilevel_score_system"
    }else{
      Sigma<-matrix(0,nobs,nobs)
      residual<-numeric(nobs)
      for(a in seq_along(index)){
        ta<-local_t[[a]]
        ia<-seq.int(offsets[a]+1L,offsets[a+1L])
        residual[ia]<-local_y[[a]]-.etr_spn_eval(grid,mu,ta)
        for(b in seq_along(index)){
          tb<-local_t[[b]]
          ib<-seq.int(offsets[b]+1L,offsets[b+1L])
          block<-.etr_spml_interp_cross(grid,between,ta,tb)
          if(a==b){
            block<-block+.etr_spml_interp_cross(grid,within,ta,tb)
            block<-block+diag(noise+ridge,length(ta))
          }
          Sigma[ia,ib]<-block
        }
      }
      Sigma<-(Sigma+t(Sigma))/2
      spectrum<-eigen(Sigma,symmetric=TRUE,only.values=TRUE)$values
      min_eig<-min(spectrum);max_eig<-max(spectrum)
      condition<-if(min_eig<=0)Inf else max_eig/min_eig
      if(min_eig<=0){
        status<-"multilevel_score_covariance_not_positive_definite"
      }else if(condition>condition_limit){
        status<-"multilevel_score_covariance_ill_conditioned"
      }else{
        solved<-tryCatch(solve(Sigma,residual),error=function(e)
          .etr_spn_fail("multilevel_score_covariance_solve_failed",
            conditionMessage(e)))
        solve_residual<-sqrt(sum((Sigma%*%solved-residual)^2))/
          max(sqrt(sum(residual^2)),.Machine$double.eps)
        Phi<-matrix(NA_real_,nobs,kp)
        for(k in seq_len(kp))Phi[,k]<-unlist(
          lapply(local_t,function(t)
            .etr_spn_eval(grid,
              participant_eigen$eigenfunctions[k,],t)),
          use.names=FALSE)
        scores_p[g,]<-participant_eigen$eigenvalues*
          as.numeric(crossprod(Phi,solved))
        for(a in seq_along(index)){
          ia<-seq.int(offsets[a]+1L,offsets[a+1L])
          P<-matrix(NA_real_,length(ia),kt)
          for(k in seq_len(kt))P[,k]<-.etr_spn_eval(
            grid,trial_eigen$eigenfunctions[k,],
            local_t[[a]])
          scores_t[index[a],]<-trial_eigen$eigenvalues*
            as.numeric(crossprod(P,solved[ia]))
        }
        solved_status<-"solved"
      }
    }
    diagnostics[[g]]<-data.frame(
      participant_id=ids[g],n_trials=length(index),
      n_samples=nobs,status_code=status,solve_status=solved_status,
      condition_number=condition,
      minimum_eigenvalue=min_eig,maximum_eigenvalue=max_eig,
      solve_relative_residual=solve_residual,score_ridge=ridge,
      condition_limit=condition_limit,stringsAsFactors=FALSE)
  }
  audit<-do.call(rbind,diagnostics)
  if(failure_action=="error"&&any(audit$status_code!="ok")){
    i<-which(audit$status_code!="ok")[1L]
    .etr_spn_fail(audit$status_code[i],
      paste0("multilevel score system failed for participant ",
        ids[i]))
  }
  list(participant_ids=ids,curve_ids=as.character(curve_ids),
    participant_scores=scores_p,trial_scores=scores_t,
    diagnostics=audit,
    covariance_source=
      "full_fitted_repaired_between_plus_within_plus_noise_and_declared_score_ridge",
    rank_k_covariance_used_for_scoring=FALSE)
}
