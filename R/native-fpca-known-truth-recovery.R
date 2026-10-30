# Frozen Python 1.2.0: recovery.py::evaluate_fpca_recovery
# commit c1cd95ad718327550f7e55393ff38582872f7a94
# Restricted to one estimated and one declared component. The Python
# multi-component optimal assignment/principal-angle domain remains open.
# No estimator, phase alignment, simulation, interpolation or scaling.

.etr_fpca_recovery_metric <- function(name){
  definitions<-switch(name,
    mean_ise=c("population mean function","lower_is_better",
      "squared signal × time","population",
      "Integrated squared error of the fitted mean function."),
    covariance_ise=c("population covariance operator","lower_is_better",
      "squared covariance × time²","population",
      "Quadrature-weighted integrated squared covariance error."),
    eigenvalue_relative_error=c("functional eigenvalue","lower_is_better",
      "relative","component",
      "Absolute eigenvalue error divided by the matched true eigenvalue."),
    component_absolute_similarity=c("functional eigenfunction","higher_is_better",
      "absolute weighted inner product","component",
      "Sign-invariant similarity after optimal component matching."),
    score_correlation=c("latent functional score","higher_is_better",
      "correlation","component",
      "Correlation after matched-component sign alignment."),
    score_rmse=c("latent functional score","lower_is_better",
      "score units","component",
      "Root-mean-square score error after sign alignment."),
    subspace_principal_cosine=c("retained functional subspace","higher_is_better",
      "cosine","subspace",
      "Principal cosine between retained fitted and true subspaces."),
    subspace_principal_angle_degrees=c("retained functional subspace","lower_is_better",
      "degrees","subspace",
      "Principal angle between retained fitted and true subspaces."),
    reconstruction_ise=c("latent trajectory reconstruction","lower_is_better",
      "squared signal × time","curve",
      "Mean curve-level integrated squared reconstruction error."),
    stop("unrecognized source FPCA recovery metric",call.=FALSE))
  list(name=name,quantity=definitions[[1L]],
    direction=definitions[[2L]],units=definitions[[3L]],
    scope=definitions[[4L]],description=definitions[[5L]])
}
.etr_fpca_recovery_value<-function(name,value,component=NULL){
  .etr_assert(is.numeric(value)&&length(value)==1L&&is.finite(value),
    paste(name,"must be a finite scalar"))
  list(metric=.etr_fpca_recovery_metric(name),
    value=as.numeric(value),component=component,source=NULL)
}

#' Known-truth FPCA recovery for one predeclared component
#'
#' Validates exact grid, unit scales, dimension order, and one fitted/true
#' mode. Computes source population covariance, signed component match,
#' subspace angle, score alignment and mean curve reconstruction error.
#' Does not match multiple components or claim full-domain parity.
#' @param result Explicit source-shaped unscaled FPCA fit.
#' @param truth Frozen functional simulation truth with one positive mode.
#' @return Source-shaped functional recovery assessment, with zero-based
#'   matched truth index and no automatic component selection.
#' @export
etr_evaluate_fpca_recovery<-function(result,truth){
  .etr_recovery_source_fields(result,c("time","provenance",
    "dimension_names","scale","mean","components","explained_variance",
    "scores","weights"),"FPCA fit")
  .etr_recovery_source_fields(truth,c("truth_grid","dimension_names",
    "mean","eigenfunctions","eigenvalues","scores",
    "latent_on_truth_grid"),"FPCA generating truth")
  time<-truth$truth_grid
  .etr_assert(is.numeric(time)&&is.null(dim(time))&&
    length(time)>=3L&&all(is.finite(time))&&all(diff(time)>0),
    "truth_grid must be finite and strictly increasing")
  .etr_assert(is.numeric(result$time)&&is.null(dim(result$time))&&
    identical(as.numeric(result$time),as.numeric(time)),
    "known-truth FPCA recovery requires exact source grid")
  .etr_assert(is.list(result$provenance),
    "FPCA provenance must be a source-shaped record")
  fpca<-result$provenance[["fpca",exact=TRUE]]
  .etr_assert(is.null(fpca)||is.list(fpca),
    "FPCA fit provenance must be source-shaped")
  scaling<-if(is.null(fpca))NULL else fpca[["scaling",exact=TRUE]]
  .etr_assert(is.null(scaling)||identical(scaling,"none"),
    "known-truth FPCA recovery requires scaling='none'")
  dimensions<-truth$dimension_names
  .etr_assert(is.character(dimensions)&&length(dimensions)>=1L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    identical(result$dimension_names,dimensions),
    "fitted dimension names/order do not match generating truth")
  nt<-length(time);nd<-length(dimensions)
  .etr_assert(is.numeric(result$scale)&&is.null(dim(result$scale))&&
    length(result$scale)==nd&&
    all(is.finite(result$scale))&&
    all(abs(result$scale-1)<=1e-12),
    "known-truth FPCA recovery requires unit dimension scales")
  weights<-result$weights
  .etr_assert(is.numeric(weights)&&is.null(dim(weights))&&
    length(weights)==nt&&all(is.finite(weights))&&all(weights>0),
    "functional quadrature weights must be finite and positive")
  for(field in c("mean")){
    .etr_assert(is.matrix(result[[field]])&&
      is.numeric(result[[field]])&&
      identical(dim(result[[field]]),c(nt,nd))&&
      all(is.finite(result[[field]])),
      "fitted mean must have observed time/dimension geometry")
    .etr_assert(is.matrix(truth[[field]])&&
      is.numeric(truth[[field]])&&
      identical(dim(truth[[field]]),c(nt,nd))&&
      all(is.finite(truth[[field]])),
      "truth mean must have the same observed time/dimension geometry")
  }
  comp<-result$components;truth_comp<-truth$eigenfunctions
  .etr_assert(is.array(comp)&&is.numeric(comp)&&
    length(dim(comp))==3L&&
    identical(dim(comp),c(1L,nt,nd))&&all(is.finite(comp)),
    "native source subset requires exactly one fitted FPCA component")
  .etr_assert(is.array(truth_comp)&&is.numeric(truth_comp)&&
    length(dim(truth_comp))==3L&&
    identical(dim(truth_comp),c(1L,nt,nd))&&
    all(is.finite(truth_comp)),
    "native source subset requires exactly one truth FPCA component")
  lambda<-result$explained_variance;true_lambda<-truth$eigenvalues
  .etr_assert(is.numeric(lambda)&&length(lambda)==1L&&
    is.finite(lambda),
    "one fitted eigenvalue must be finite")
  .etr_assert(is.numeric(true_lambda)&&length(true_lambda)==1L&&
    is.finite(true_lambda)&&true_lambda>0,
    "one generating eigenvalue must be finite and positive")
  scores<-result$scores;true_scores<-truth$scores
  .etr_assert(is.matrix(scores)&&is.numeric(scores)&&
    ncol(scores)==1L&&nrow(scores)>=2L&&
    all(is.finite(scores)),
    "fitted FPCA scores must be finite curve by one mode")
  n<-nrow(scores)
  .etr_assert(is.matrix(true_scores)&&is.numeric(true_scores)&&
    identical(dim(true_scores),c(n,1L))&&
    all(is.finite(true_scores)),
    "generating FPCA scores must match all source curves")
  latent<-truth$latent_on_truth_grid
  .etr_assert(is.array(latent)&&is.numeric(latent)&&
    length(dim(latent))==3L&&
    identical(dim(latent),c(n,nt,nd))&&all(is.finite(latent)),
    "latent source curves must match reconstruction geometry")
  # Time-major flattening: NumPy (time,dimension) C-order is as.vector(t(M)).
  estimated<-as.vector(t(matrix(comp,nrow=nt,ncol=nd)))
  true<-as.vector(t(matrix(truth_comp,nrow=nt,ncol=nd)))
  flat_w<-rep(weights,each=nd)
  norm_est<-sqrt(sum(estimated^2*flat_w))
  norm_true<-sqrt(sum(true^2*flat_w))
  .etr_assert(all(is.finite(c(norm_est,norm_true)))&&
    norm_est>0&&norm_true>0,
    "functional components contain an invalid norm")
  similarity_signed<-sum(estimated*true*flat_w)/(norm_est*norm_true)
  sign<-if(similarity_signed>=0)1.0 else -1.0
  similarity<-abs(similarity_signed)
  cosine<-min(1,max(0,similarity))
  values<-list()
  add<-function(name,value,component=NULL){
    values[[length(values)+1L]]<<-
      .etr_fpca_recovery_value(name,value,component)
  }
  add("mean_ise",sum(sweep(
    (result$mean-truth$mean)^2,1L,weights,"*")))
  cov_est<-lambda*tcrossprod(estimated)
  cov_truth<-true_lambda*tcrossprod(true)
  add("covariance_ise",sum((cov_est-cov_truth)^2*
    outer(flat_w,flat_w)))
  add("eigenvalue_relative_error",abs(lambda-true_lambda)/true_lambda,0L)
  add("component_absolute_similarity",similarity,0L)
  aligned<-sign*scores[,1L]
  if(length(aligned)>=2L){
    cor_value<-stats::cor(aligned,true_scores[,1L])
    .etr_assert(is.finite(cor_value),
      "source score correlation is undefined on constant scores")
    add("score_correlation",cor_value,0L)
    add("score_rmse",sqrt(mean(
      (aligned-true_scores[,1L])^2)),0L)
  }
  add("subspace_principal_cosine",cosine,0L)
  add("subspace_principal_angle_degrees",acos(cosine)*180/pi,0L)
  curve_ise<-numeric(n)
  for(i in seq_len(n)){
    reconstructed<-result$mean+
      scores[i,1L]*matrix(comp,nrow=nt,ncol=nd)
    original<-matrix(latent[i,,,drop=FALSE],nrow=nt,ncol=nd)
    curve_ise[i]<-sum(sweep(
      (reconstructed-original)^2,1L,weights,"*"))
  }
  add("reconstruction_ise",mean(curve_ise))
  structure(list(values=values,provenance=list(
    estimator="FPCA",multivariate=nd>1L,
    truth_grid_match="exact",scaling="none",
    matched_truth_components=0L,
    alignment_signs=as.numeric(sign))),
    class="etr_functional_recovery_assessment")
}
