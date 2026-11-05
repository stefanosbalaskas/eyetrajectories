# Frozen Python 1.2 sparse_multivariate.py and workflows/_sparse_mfpca.py,
# _sparse_async.py: native R ALTERNATIVE only.
# Marginal R fdapace conditional-expectation scores are subsequently analyzed
# jointly by covariance PCA. This is not source custom joint covariance PACE.

.etr_native_sparse_channels<-function(trajectories,dimensions){
  .etr_assert(is.character(dimensions)&&length(dimensions)==2L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(nzchar(dimensions)),
    "dimensions must identify exactly two distinct channel names")
  if(inherits(trajectories,"etr_irregular_trajectory_set")){
    .etr_irregular_validate_samples(trajectories)
    .etr_assert(all(dimensions%in%trajectories$dimension_names),
      "dimensions must exist in native irregular trajectories")
    out<-setNames(lapply(dimensions,function(d)
      etr_to_fdapy_irregular(trajectories,d)),dimensions)
  }else{
    .etr_assert(is.list(trajectories)&&
      all(dimensions%in%names(trajectories)),
      "asynchronous input must name two independent etr_sparse_curves channels")
    out<-trajectories[dimensions]
    .etr_assert(all(vapply(out,inherits,logical(1L),"etr_sparse_curves")),
      "asynchronous channel inputs must be etr_sparse_curves")
  }
  ids<-out[[1L]]$curve_ids
  .etr_assert(all(vapply(out,function(z)
    identical(z$curve_ids,ids),logical(1L))),
    "both sparse channels must share identical source curve IDs and order")
  out
}

.etr_native_sparse_mfpca_channels<-function(channels,n_components,
    max_marginal_components,fve,options){
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==floor(n_components)&&
    n_components>=1L,"n_components must be explicit positive integer")
  .etr_assert(is.numeric(max_marginal_components)&&
    length(max_marginal_components)==1L&&
    is.finite(max_marginal_components)&&
    max_marginal_components==floor(max_marginal_components)&&
    max_marginal_components>=1L,
    "max_marginal_components must be explicit positive integer")
  fit<-etr_fit_marginal_sparse_pace(channels,
    max_components=as.integer(max_marginal_components),
    fve=fve,options=options)
  source_scores<-lapply(fit$models,function(m)m$model$xiEst)
  .etr_assert(all(vapply(source_scores,is.matrix,logical(1L)))&&
    all(vapply(source_scores,function(s)all(is.finite(s)),
      logical(1L))),"marginal PACE scores must be complete finite matrices")
  S<-do.call(cbind,source_scores)
  .etr_assert(nrow(S)>n_components&&ncol(S)>=n_components,
    "joint marginal score matrix has insufficient dimensions")
  cent<-sweep(S,2L,colMeans(S),"-")
  .etr_assert(qr(cent)$rank>=n_components,
    "joint marginal score covariance is rank deficient")
  dec<-svd(cent,nu=as.integer(n_components),
    nv=as.integer(n_components))
  scores<-sweep(dec$u[,seq_len(n_components),drop=FALSE],
    2L,dec$d[seq_len(n_components)],"*")
  eig<-dec$d^2/(nrow(cent)-1L)
  structure(list(
    backend="fdapace_marginal_PACE_joint_score_PCA",
    source_backend="custom_sparse_multivariate_joint_PACE",
    fit=fit,curve_ids=fit$curve_ids,dimensions=fit$channels,
    marginal_scores=S,centered_marginal_scores=cent,
    joint_scores=scores,
    scores=scores,
    loadings=dec$v[,seq_len(n_components),drop=FALSE],
    eigenvalues=eig[seq_len(n_components)],
    explained_variance_ratio=eig[seq_len(n_components)]/sum(eig),
    retained_components=as.integer(n_components),
    joint_score_covariance_estimated=TRUE,
    source_joint_functional_covariance_equivalent=FALSE,
    source_python_equivalent=FALSE,
    independently_fully_certified=FALSE),
    class="etr_native_sparse_mfpca")
}

#' Fit native marginal PACE plus joint-score sparse multivariate FPCA
#' @param trajectories Native irregular x/y curves or named asynchronous
#'   etr_sparse_curves channels with identical curve IDs.
#' @param dimensions Two distinct channels.
#' @param n_components Number of retained joint score components.
#' @param backend Must be explicit fdapace_joint_score_pca.
#' @param max_marginal_components Maximum native PACE components per channel.
#' @param fve Variance fraction used by each marginal fdapace fit.
#' @param options Native fdapace model options.
#' @param observation_process Must be NULL; source observation-process
#'   weighting is not modeled by the native alternative.
#' @return Joint score FPCA over marginal conditional-expectation scores.
#'   Not the Python 1.2 joint sparse covariance PACE model.
#' @export
etr_fit_sparse_mfpca<-function(trajectories,dimensions=c("x","y"),
    n_components=2L,backend=NULL,max_marginal_components=3L,
    fve=.95,options=list(),observation_process=NULL){
  .etr_assert(identical(backend,"fdapace_joint_score_pca"),
    "explicitly select fdapace_joint_score_pca; Python joint PACE not implemented")
  .etr_assert(is.null(observation_process),
    "native joint score fit cannot model observation_process")
  channels<-.etr_native_sparse_channels(trajectories,dimensions)
  .etr_native_sparse_mfpca_channels(channels,
    n_components=n_components,
    max_marginal_components=max_marginal_components,
    fve=fve,options=options)
}

.etr_native_sparse_mfpca_workflow<-function(fit,cfg,async=FALSE){
  parameters<-cfg[setdiff(names(cfg),"preprocessing")]
  scores<-data.frame(curve_id=fit$curve_ids,
    as.data.frame(fit$joint_scores),check.names=FALSE)
  names(scores)[-1L]<-paste0("MFPCA",seq_len(ncol(fit$joint_scores)))
  variance<-data.frame(
    component=seq_along(fit$eigenvalues),
    eigenvalue=as.numeric(fit$eigenvalues),
    variance_ratio=as.numeric(fit$explained_variance_ratio))
  structure(list(
    workflow_schema_version=1L,
    workflow_contract=if(async)
      "sparse_mfpca_async:native_marginal_joint_score" else
      "sparse_mfpca:native_marginal_joint_score",
    config=cfg,fit=fit,
    steps=list(.etr_source_workflow_step(
      "marginal_fdapace_PACE_then_joint_score_PCA",parameters)),
    decisions=lapply(parameters,.etr_source_workflow_decision),
    provenance=list(
      input_layout=if(async)"asynchronous_sparse_channels" else
        "paired_irregular_native",
      preprocessing_executed=FALSE,
      observation_process_assessed=FALSE,
      original_observations_interpolated_to_common_grid=FALSE,
      source_custom_joint_covariance_fitted=FALSE,
      native_joint_score_covariance_fitted=TRUE,
      source_python_equivalent=FALSE,
      full_source_contract_certified=FALSE),
    reports=list(fit=paste(
      "Explicit native marginal fdapace PACE and joint score PCA;",
      "not frozen Python joint sparse multivariate PACE.")),
    tables=list(scores=scores,variance=variance)),
    class=if(async)
      "etr_native_sparse_mfpca_async_workflow" else
      "etr_native_sparse_mfpca_workflow")
}

#' Run native paired sparse two-channel joint-score workflow
#' @param trajectories Native two-channel irregular trajectories.
#' @param config Explicit dimensions, backend, component counts and empty
#'   preprocessing. No implicit bandwidth optimization.
#' @param observation_process Must be NULL.
#' @export
etr_run_sparse_mfpca_workflow<-function(trajectories,config,
    observation_process=NULL){
  cfg<-.etr_source_workflow_config(config,list(
    dimensions=c("x","y"),backend=NULL,n_components=2L,
    max_marginal_components=3L,fve=.95,options=list(),
    preprocessing=list()),required=c("dimensions","backend","n_components"))
  .etr_assert(inherits(trajectories,"etr_irregular_trajectory_set"),
    "paired sparse workflow requires native irregular trajectory collection")
  fit<-etr_fit_sparse_mfpca(trajectories,dimensions=cfg$dimensions,
    n_components=cfg$n_components,backend=cfg$backend,
    max_marginal_components=cfg$max_marginal_components,
    fve=cfg$fve,options=cfg$options,
    observation_process=observation_process)
  .etr_native_sparse_mfpca_workflow(fit,cfg,FALSE)
}

#' Run two-channel asynchronous marginal PACE joint-score workflow
#' @param trajectories Named list of distinct-channel etr_sparse_curves,
#'   each with its own original observation times and shared curve IDs.
#' @param config Explicit backend and component controls with empty plan.
#' @param observation_process Must be NULL.
#' @export
etr_run_sparse_mfpca_async_workflow<-function(trajectories,config,
    observation_process=NULL){
  cfg<-.etr_source_workflow_config(config,list(
    dimensions=c("x","y"),backend=NULL,n_components=2L,
    max_marginal_components=3L,fve=.95,options=list(),
    preprocessing=list()),required=c("dimensions","backend","n_components"))
  .etr_assert(is.list(trajectories)&&
    !inherits(trajectories,"etr_irregular_trajectory_set"),
    "asynchronous sparse workflow requires separately timed native channel collections")
  fit<-etr_fit_sparse_mfpca(trajectories,dimensions=cfg$dimensions,
    n_components=cfg$n_components,backend=cfg$backend,
    max_marginal_components=cfg$max_marginal_components,
    fve=cfg$fve,options=cfg$options,
    observation_process=observation_process)
  .etr_native_sparse_mfpca_workflow(fit,cfg,TRUE)
}
