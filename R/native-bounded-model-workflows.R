# Frozen Python 1.2 source workflows/_dense_regression.py, _sparse_fpca.py.
# Native ALTERNATIVE estimators, not source-equivalent source algorithms.
# Explicit estimator/backend declaration is mandatory. No auto-fallback.

#' Explicit native functional mixed-moments workflow (not source MixedLM)
#' @param trajectories Complete native functional trajectories.
#' @param design Curve-aligned predictor table with curve_id.
#' @param config Named list of predictors, participant_column, dimension,
#'   estimator="two_level_functional_method_of_moments", covariance_ridge
#'   and empty preprocessing.
#' @return Native bounded workflow with honest non-Python-equivalent provenance.
#' @export
etr_run_functional_mixed_effects_workflow<-function(
    trajectories,design,config){
  etr_validate(trajectories,require_complete=TRUE)
  cfg<-.etr_source_workflow_config(config,
    list(predictors=NULL,participant_column=NULL,dimension=NULL,
      estimator="two_level_functional_method_of_moments",
      covariance_ridge=1e-6,preprocessing=list()),
    required=c("predictors","participant_column","dimension",
      "estimator"))
  .etr_assert(identical(cfg$estimator,
    "two_level_functional_method_of_moments"),
    "source Gaussian spline MixedLM/REML not implemented; explicitly choose native two-level moments")
  .etr_assert(is.character(cfg$predictors)&&
    !anyNA(cfg$predictors)&&!anyDuplicated(cfg$predictors)&&
    all(nzchar(cfg$predictors)),
    "predictors must contain unique nonempty names")
  .etr_assert(is.character(cfg$participant_column)&&
    length(cfg$participant_column)==1L&&!is.na(cfg$participant_column)&&
    nzchar(cfg$participant_column)&&
    is.character(cfg$dimension)&&length(cfg$dimension)==1L&&
    !is.na(cfg$dimension)&&nzchar(cfg$dimension),
    "participant_column and dimension must identify explicit source fields")
  fit<-etr_fit_functional_mixed_effects_regression(
    trajectories=trajectories,design=design,
    predictors=cfg$predictors,
    participant_column=cfg$participant_column,
    dimension=cfg$dimension,
    covariance_ridge=cfg$covariance_ridge)
  parameters<-cfg[c("predictors","participant_column",
    "dimension","estimator","covariance_ridge")]
  structure(list(workflow_schema_version=1L,
    workflow_contract="functional_mixed_effects:native_moments_only",
    config=cfg,fit=fit,
    steps=list(.etr_source_workflow_step(
      "fit_functional_mixed_effects_regression_native_moments",parameters)),
    decisions=lapply(parameters,.etr_source_workflow_decision),
    provenance=list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,
      automatic_optimizer_fallback=FALSE,
      likelihood_optimized=FALSE,REML=FALSE,
      source_python_equivalent=FALSE,
      random_slope_supported=FALSE,trial_random_effect_supported=FALSE,
      full_source_contract_certified=FALSE),
    reports=list(fit=paste0(
      "Native method-of-moments functional random intercept; ",
      fit$n_participants," independent participants, ",
      fit$n_curves," curves. NOT Python spline MixedLM/REML.")),
    tables=list(
      coefficients=etr_functional_mixed_effects_coefficient_frame(fit))),
    class="etr_functional_mixed_effects_workflow")
}

#' Explicit fdapace-backed native sparse FPCA workflow (not source PACE)
#'
#' @description This is a deliberately separate native R approximation.
#'   Source Python uses explicitly supplied bandwidths and custom sparse PACE;
#'   fdapace has a DIFFERENT smoothing and covariance estimator. Neither
#'   matching numerical estimates nor coverage calibration is asserted.
#' @param trajectories Native etr_irregular_trajectory_set or etr_sparse_curves.
#' @param config Named list containing dimension, backend="fdapace",
#'   max_components, fve, fdapace options, empty preprocessing.
#' @param observation_process Must be NULL; no silent observation diagnostics.
#' @return Native workflow with fdapace fit and source-difference provenance.
#' @export
etr_run_sparse_fpca_workflow<-function(
    trajectories,config,observation_process=NULL){
  cfg<-.etr_source_workflow_config(config,
    list(dimension=NULL,backend=NULL,max_components=3L,fve=.95,
      options=list(),preprocessing=list()),
    required=c("dimension","backend","max_components","fve"))
  .etr_assert(identical(cfg$backend,"fdapace"),
    "native R supports only explicitly declared fdapace backend; not Python sparse FPCA")
  .etr_assert(is.null(observation_process),
    "observation_process diagnostics not implemented in native fdapace workflow")
  .etr_assert(is.character(cfg$dimension)&&length(cfg$dimension)==1L&&
    !is.na(cfg$dimension)&&nzchar(cfg$dimension),
    "dimension must be explicitly named")
  if(inherits(trajectories,"etr_irregular_trajectory_set")){
    .etr_irregular_validate_samples(trajectories)
    .etr_assert(cfg$dimension%in%trajectories$dimension_names,
      "dimension must identify an observed irregular channel")
    d<-match(cfg$dimension,trajectories$dimension_names)
    .etr_assert(all(vapply(trajectories$values,function(v)
      all(is.finite(v[,d])),logical(1L))),
      "sparse FPCA requires complete finite selected dimension")
    .etr_assert(all(lengths(trajectories$time)>=3L),
      "fdapace native adapter requires >=3 samples per curve")
    sparse<-etr_sparse_curves(trajectories$time,
      lapply(trajectories$values,function(v)as.numeric(v[,d])),
      trajectories$curve_ids,trajectories$time_unit)
  }else{
    .etr_assert(inherits(trajectories,"etr_sparse_curves"),
      "trajectories must be native irregular trajectory set or sparse curves")
    .etr_assert(identical(cfg$dimension,"value"),
      "etr_sparse_curves supports only dimension='value'")
    sparse<-trajectories
  }
  fit<-etr_fit_sparse_pace(sparse,
    max_components=cfg$max_components,
    fve=cfg$fve,options=cfg$options)
  parameters<-cfg[c("dimension","backend","max_components","fve","options")]
  structure(list(workflow_schema_version=1L,
    workflow_contract="sparse_fpca:native_fdapace_only",
    config=cfg,fit=fit,
    steps=list(.etr_source_workflow_step(
      "fdapace_FPCA_sparse_conditional_expectation",parameters)),
    decisions=lapply(parameters,.etr_source_workflow_decision),
    provenance=list(input_layout="native_irregular",
      raw_interpolation_performed=FALSE,
      preprocessing_executed=FALSE,
      bandwidth_selection_performed=FALSE,
      automatic_python_model_selection_performed=FALSE,
      source_python_equivalent=FALSE,
      source_python_bandwidth_contract_supported=FALSE,
      full_source_contract_certified=FALSE),
    reports=list(fit=paste0(
      "Native R fdapace conditional-expectation sparse FPCA, ",
      length(fit$curve_ids)," curves; NOT custom Python 1.2 PACE.")),
    tables=list(scores=etr_sparse_pace_scores(fit))),
    class="etr_sparse_fpca_workflow")
}
