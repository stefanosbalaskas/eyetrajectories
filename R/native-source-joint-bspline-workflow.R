# Explicit Python-1.2-inspired Gaussian functional mixed-effects workflow.
# The native likelihood estimators are R/nlme implementations, not a
# reimplementation of Python's scipy/statsmodels optimizer or result dataclass.
# No implicit estimator, covariance, trial or optimizer fallback is permitted.
# Pinned source: eyetrajectoriespy 1.2.0 c1cd95ad718327550f7e55393ff38582872f7a94
# workflows/_dense_regression.py::run_functional_mixed_effects_workflow.

.etr_joint_workflow_config <- function(config, trajectories, design) {
  etr_validate(trajectories, require_complete=TRUE)
  .etr_assert(is.data.frame(design), "design must be a data.frame")
  cfg <- .etr_source_workflow_config(config, list(
    predictors=NULL, participant_column=NULL, dimension=NULL,
    estimator="native_joint_bspline_gaussian",
    fixed_basis_size=6L, random_basis_size=4L,
    random_slope_predictor=NULL, trial_column=NULL,
    trial_random_effect=NULL, trial_random_basis_size=4L,
    residual_correlation="iid", spline_degree=3L,
    reml=TRUE, method="nlme::lme", maxiter=500L,
    preprocessing=list()
  ), required=c("predictors","participant_column","dimension","estimator"))
  .etr_assert(identical(cfg$estimator,"native_joint_bspline_gaussian"),
    "estimator must explicitly be native_joint_bspline_gaussian")
  .etr_assert(is.character(cfg$predictors) &&
    length(cfg$predictors)>=1L && !anyNA(cfg$predictors) &&
    all(nzchar(cfg$predictors)) && !anyDuplicated(cfg$predictors),
    "predictors must be distinct nonempty character names")
  for(nm in c("participant_column","dimension")) {
    .etr_assert(is.character(cfg[[nm]]) &&
      length(cfg[[nm]])==1L && !is.na(cfg[[nm]]) &&
      nzchar(cfg[[nm]]),paste(nm,"must be a nonempty character scalar"))
  }
  .etr_assert(cfg$participant_column %in% names(trajectories$metadata),
    "participant_column must be in trajectory metadata")
  .etr_assert(cfg$dimension %in% trajectories$dimension_names,
    "dimension must identify an existing trajectory channel")
  .etr_assert(is.character(cfg$residual_correlation) &&
    length(cfg$residual_correlation)==1L && !is.na(cfg$residual_correlation) &&
    cfg$residual_correlation %in% c("iid","ar1","exponential"),
    "residual_correlation must be iid, ar1 or exponential")
  .etr_assert(identical(cfg$method,"nlme::lme"),
    "only method='nlme::lme' is supported; Python lbfgs is not a native optimizer")
  .etr_assert(is.logical(cfg$reml) && length(cfg$reml)==1L &&
    !is.na(cfg$reml), "reml must be a nonmissing logical scalar")
  for(nm in c("fixed_basis_size","random_basis_size",
              "trial_random_basis_size","spline_degree","maxiter")) {
    z <- cfg[[nm]]
    .etr_assert(is.numeric(z) && length(z)==1L && is.finite(z) &&
      z==floor(z) && z>=1, paste(nm,"must be a positive integer"))
  }
  .etr_assert(cfg$spline_degree>=1 && cfg$spline_degree<=5,
    "spline_degree must be between 1 and 5")
  .etr_assert(cfg$maxiter>=10, "maxiter must be at least 10")
  .etr_assert(cfg$fixed_basis_size>=cfg$spline_degree+1L &&
    cfg$random_basis_size>=cfg$spline_degree+1L,
    "fixed and participant random basis sizes must exceed spline_degree")
  .etr_assert(cfg$fixed_basis_size<=length(trajectories$time) &&
    cfg$random_basis_size<=length(trajectories$time),
    "basis sizes cannot exceed the observed time-grid length")
  has_slope <- !is.null(cfg$random_slope_predictor)
  if(has_slope) {
    .etr_assert(is.character(cfg$random_slope_predictor) &&
      length(cfg$random_slope_predictor)==1L &&
      !is.na(cfg$random_slope_predictor) &&
      cfg$random_slope_predictor %in% cfg$predictors,
      "random_slope_predictor must name a declared predictor")
  }
  has_trial <- !is.null(cfg$trial_column) ||
    !is.null(cfg$trial_random_effect)
  if(has_trial) {
    .etr_assert(is.character(cfg$trial_column) &&
      length(cfg$trial_column)==1L && !is.na(cfg$trial_column) &&
      nzchar(cfg$trial_column) &&
      cfg$trial_column != cfg$participant_column &&
      cfg$trial_column %in% names(trajectories$metadata),
      "trial_column must name distinct trajectory metadata")
    .etr_assert(identical(cfg$trial_random_effect,"functional_intercept"),
      "trial_random_effect must explicitly equal functional_intercept")
    .etr_assert(cfg$trial_random_basis_size>=cfg$spline_degree+1L &&
      cfg$trial_random_basis_size<=length(trajectories$time),
      "trial_random_basis_size must be between degree+1 and grid length")
  } else {
    .etr_assert(identical(cfg$residual_correlation,"iid"),
      "serial residual correlation requires an explicitly declared nested trial")
  }
  cfg
}

.etr_joint_workflow_route <- function(cfg) {
  nested <- !is.null(cfg$trial_column)
  slope <- !is.null(cfg$random_slope_predictor)
  if(nested && slope) return("etr_fit_joint_bspline_functional_nested_slope")
  if(nested) return("etr_fit_joint_bspline_functional_nested_trial")
  if(slope) return("etr_fit_joint_bspline_functional_random_slope")
  "etr_fit_joint_bspline_functional_mixed_effects"
}

.etr_joint_workflow_coefficient_frame <- function(fit, dimension) {
  frame <- etr_joint_bspline_mixed_coefficient_frame(fit)
  .etr_assert(is.data.frame(frame) &&
    all(c("coefficient","time","estimate","se","lower","upper") %in%
      names(frame)), "joint coefficient table schema is incomplete")
  frame$dimension <- dimension
  frame <- frame[,c("coefficient","time","dimension","estimate",
                    "se","lower","upper"),drop=FALSE]
  names(frame)[5:7] <- c("standard_error","lower_95_wald","upper_95_wald")
  rownames(frame) <- NULL
  frame
}

.etr_source_joint_bspline_workflow <- function(trajectories, design, config) {
  cfg <- .etr_joint_workflow_config(config,trajectories,design)
  route <- .etr_joint_workflow_route(cfg)
  args <- list(trajectories=trajectories,design=design,
    predictors=cfg$predictors,
    participant_column=cfg$participant_column,dimension=cfg$dimension,
    fixed_basis_size=cfg$fixed_basis_size,
    random_basis_size=cfg$random_basis_size,
    spline_degree=cfg$spline_degree,reml=cfg$reml,maxiter=cfg$maxiter)
  if(!is.null(cfg$random_slope_predictor))
    args$random_slope_predictor <- cfg$random_slope_predictor
  if(!is.null(cfg$trial_column)) {
    args$trial_column <- cfg$trial_column
    args$trial_random_basis_size <- cfg$trial_random_basis_size
    args$residual_correlation <- cfg$residual_correlation
  }
  # The call is explicit and synchronous: the fitting function reports any
  # failed convergence or identifiability, without a fallback estimator.
  fit <- do.call(get(route,mode="function"),args)
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed"),
    "selected joint estimator returned an unexpected native result type")
  p <- cfg[c("predictors","participant_column","dimension",
    "fixed_basis_size","random_basis_size","random_slope_predictor",
    "trial_column","trial_random_effect","trial_random_basis_size",
    "residual_correlation","spline_degree","reml","method","maxiter")]
  structure(list(
    workflow_schema_version=1L,
    workflow_contract="functional_mixed_effects:native_joint_bspline_gaussian",
    config=cfg, fit=fit,
    steps=list(.etr_source_workflow_step(route,p)),
    decisions=lapply(p,.etr_source_workflow_decision),
    provenance=list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,
      automatic_random_effect_selection=FALSE,
      automatic_residual_correlation_selection=FALSE,
      automatic_optimizer_fallback=FALSE,
      automatic_model_selection_performed=FALSE,
      likelihood_optimized=TRUE,REML=isTRUE(cfg$reml),
      source_python_equivalent=FALSE,
      optimizer="nlme::lme",
      random_slope_supported=!is.null(cfg$random_slope_predictor),
      trial_random_effect_supported=!is.null(cfg$trial_column),
      full_source_contract_certified=FALSE),
    reports=list(fit=paste0(
      "Native R/nlme joint B-spline Gaussian mixed-effects fit (",route,
      "); ",fit$n_participants," participants and ",fit$n_curves,
      " curves. The SciPy/statsmodels Python 1.2 optimizer and typed ",
      "workflow result are NOT claimed equivalent.")),
    tables=list(coefficients=.etr_joint_workflow_coefficient_frame(
      fit,cfg$dimension))
  ),class="etr_functional_mixed_effects_workflow")
}
