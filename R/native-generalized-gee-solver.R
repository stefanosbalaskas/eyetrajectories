# Working independence numerical path for the frozen Python 1.2 boundary.
# Statsmodels 0.15 initializes GEE with GLM IRLS, then applies its
# declared GEE tolerance to the unscaled score.

.etr_gfosr_design_rank<-function(x,source_mode){
  if(!source_mode)return(qr(x)$rank)
  singular<-svd(x,nu=0L,nv=0L)$d
  as.integer(sum(singular>max(dim(x))*.Machine$double.eps*singular[1L]))
}

.etr_gfosr_source_wls_coef<-function(decomposition,response,rcond){
  keep<-decomposition$d>rcond*decomposition$d[1L]
  as.vector(decomposition$v[,keep,drop=FALSE]%*%
    (crossprod(decomposition$u[,keep,drop=FALSE],response)/
      decomposition$d[keep]))
}

.etr_gfosr_source_gee_mean<-function(eta,binomial){
  if(binomial)1/(1+exp(-eta)) else exp(eta)
}

.etr_gfosr_source_glm_start<-function(x,y,w,offset,binomial){
  eps<-.Machine$double.eps
  separation<-"Perfect separation or prediction detected, parameter may not be identified"
  warnings<-character()
  mu<-if(binomial)(y+.5)/2 else (y+mean(y))/2
  eta<-if(binomial)log(mu/(1-mu)) else log(pmax(mu,eps))
  deviance<-function(mu){
    if(binomial) {
      a<-y*log(pmax(y/(mu+1e-20),eps))
      b<-(1-y)*log(pmax((1-y)/(1-mu+1e-20),eps))
      return(sum(2*w*(a+b)))
    }
    sum(2*w*(y*log(pmax(y/mu,eps))-(y-mu)))
  }
  last_deviance<-deviance(mu)
  .etr_assert(!is.nan(last_deviance),
    "The first guess on the deviance function returned a nan")
  for(iteration in seq_len(100L)){
    if(binomial){
      p<-pmin(pmax(mu,eps),1-eps)
      variance<-p*(1-p)
      derivative<-1/variance
    }else{
      variance<-mu
      derivative<-1/pmax(mu,eps)
    }
    weights<-sqrt(w/(derivative^2*variance))
    response<-weights*(eta+derivative*(y-mu)-offset)
    .etr_assert(all(is.finite(weights))&&all(is.finite(response)),
      "NaN, inf or invalid value detected in GLM starting weights or response")
    decomposition<-svd(x*weights)
    # MinimalWLS uses lstsq(rcond=-1), the LAPACK precision threshold.
    beta<-.etr_gfosr_source_wls_coef(decomposition,response,eps/2)
    eta<-as.vector(x%*%beta)+offset
    mu<-.etr_gfosr_source_gee_mean(eta,binomial)
    if(isTRUE(all(abs(mu-y)<=1e-8)))warnings<-c(warnings,separation)
    dev<-deviance(mu)
    if(isTRUE(dev==last_deviance||abs(dev-last_deviance)<=1e-8))break
    last_deviance<-dev
  }
  # Statsmodels uses its WLS pseudoinverse for the retained initial fit.
  list(beta=.etr_gfosr_source_wls_coef(decomposition,response,1e-15),
    iterations=iteration,warnings=warnings)
}

.etr_gfosr_source_bread_solve<-function(bread,rhs){
  tryCatch(solve(bread,rhs,tol=0),error=function(e){
    decomposition<-svd(bread)
    keep<-decomposition$d>1e-15*decomposition$d[1L]
    decomposition$v[,keep,drop=FALSE]%*%
      (crossprod(decomposition$u[,keep,drop=FALSE],rhs)/
        decomposition$d[keep])
  })
}

.etr_gfosr_source_gee_fit<-function(x,y,w,offset,groups,family,maxiter,ctol){
  binomial<-identical(family,"binomial")
  start<-.etr_gfosr_source_glm_start(x,y,w,offset,binomial)
  beta<-start$beta
  # np.unique orders the cluster labels for score and covariance accumulation.
  rows<-split(seq_along(y),match(groups,sort(unique(groups),method="radix")))
  designs<-lapply(rows,function(i)x[i,,drop=FALSE])
  ncoef<-ncol(x)
  equations<-function(beta,robust=FALSE){
    eta<-as.vector(x%*%beta)+offset
    mu<-.etr_gfosr_source_gee_mean(eta,binomial)
    eps<-.Machine$double.eps
    if(binomial){
      p<-pmin(pmax(mu,eps),1-eps)
      variance<-p*(1-p)
      e<-exp(eta)
      slope<-e/(1+e)^2
    }else{
      variance<-mu
      slope<-mu
    }
    # Independence divides each RHS by squared working standard deviation.
    variance<-sqrt(variance)^2
    bread<-matrix(0,ncoef,ncoef)
    score<-numeric(ncoef)
    scores<-if(robust)matrix(0,ncoef,length(rows))
    for(j in seq_along(rows)){
      i<-rows[[j]]
      derivative<-designs[[j]]*slope[i]
      bread<-bread+crossprod(derivative,(derivative*w[i])/variance[i])
      local_score<-as.vector(crossprod(derivative,((y[i]-mu[i])*w[i])/variance[i]))
      score<-score+local_score
      if(robust)scores[,j]<-local_score
    }
    list(bread=bread,score=score,scores=scores)
  }
  for(iteration in seq_len(maxiter)){
    state<-equations(beta)
    .etr_assert(all(is.finite(state$bread))&&all(is.finite(state$score)),
      "generalized function-on-scalar GEE score or information is nonfinite")
    beta<-beta+as.vector(.etr_gfosr_source_bread_solve(state$bread,state$score))
    score_norm<-sqrt(sum(state$score^2))
    if(score_norm<ctol)break
  }
  .etr_assert(score_norm<ctol,paste(
    "generalized function-on-scalar GEE did not converge under the",
    "declared working-independence specification"))
  .etr_assert(all(is.finite(beta)),"GEE coefficient parameters are non-finite")
  state<-equations(beta,robust=TRUE)
  .etr_assert(all(is.finite(state$bread))&&all(is.finite(state$scores)),
    "GEE robust parameter covariance contains non-finite values")
  # Form the sandwich as a cross-product of cluster influence vectors.
  # This avoids amplifying roundoff asymmetry in a separately formed meat.
  influence<-.etr_gfosr_source_bread_solve(state$bread,state$scores)
  covariance<-tcrossprod(influence)
  .etr_assert(all(is.finite(covariance)),
    "GEE robust parameter covariance contains non-finite values")
  list(beta=beta,covariance=covariance,warnings=start$warnings,
    glm_iterations=start$iterations,gee_iterations=iteration,score_norm=score_norm)
}
