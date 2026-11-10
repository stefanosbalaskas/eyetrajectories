# Frozen scientific source: eyetrajectoriespy==1.2.0
# recovery.py::evaluate_functional_mixed_effects_recovery
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Computes retained known-truth evaluation, never model fit, simulation,
# bootstrap or reweighting. Source dataclass identity remains uncertified.

.etr_mixed_recovery_variance <- function(basis,covariance,nt,label) {
  .etr_assert(is.matrix(basis)&&is.numeric(basis)&&
    nrow(basis)==nt&&ncol(basis)>=1L&&all(is.finite(basis)),
    paste(label,"basis must be finite time by basis dimension"))
  k<-ncol(basis)
  .etr_assert(is.matrix(covariance)&&is.numeric(covariance)&&
    identical(dim(covariance),c(k,k))&&all(is.finite(covariance)),
    paste(label,"basis covariance must be finite square matrix"))
  rowSums((basis%*%covariance)*basis)
}

#' Evaluate functional mixed-effects intercept and random-effect variance recovery
#'
#' Evaluates fixed intercept error and the **time-domain** participant/trial
#' functional variance, without comparing spline covariance coefficients
#' directly to simulator KL eigenvalues or treating the curve-level KL process
#' as fitted scalar residual variance.
#' @param result Native source-shaped Gaussian functional mixed-effects fit.
#' @param truth Frozen simulator truth with exact grid, one or more modes,
#'   dimension-specific mean, and participant/trial eigenvalues.
#' @param intercept_name Explicit fitted fixed-intercept name.
#' @return Source-shaped recovery assessment with per-source metrics and
#'   transparent known-truth provenance. Full Python typed contract is open.
#' @export
etr_evaluate_functional_mixed_effects_recovery <- function(
    result,truth,intercept_name="Intercept") {
  .etr_recovery_source_fields(result,c(
    "time","random_slope_predictor","dimension_name",
    "coefficient_names","coefficient_functions",
    "random_basis","random_intercept_covariance"),"mixed-effects fit")
  # trial_random_effect defaults to None in frozen Python 1.2.
  # R x$trial_random_effect <- NULL removes a list element rather than
  # retaining a named NULL; absence must therefore mean no trial effect.
  .etr_recovery_source_fields(truth,c(
    "truth_grid","dimension_names","mean","eigenfunctions",
    "participant_eigenvalues","trial_eigenvalues"),"simulation truth")
  grid<-truth$truth_grid
  .etr_assert(is.numeric(grid)&&is.null(dim(grid))&&length(grid)>=3L&&
    all(is.finite(grid))&&all(diff(grid)>0),
    "truth_grid must be finite strictly increasing numeric grid")
  .etr_assert(is.numeric(result$time)&&is.null(dim(result$time))&&
    identical(as.numeric(result$time),as.numeric(grid)),
    "recovery evaluation requires the fitted grid to equal truth.truth_grid exactly")
  .etr_assert(is.null(result[["random_slope_predictor",exact=TRUE]]),
    "mixed-effects recovery supports functional random intercepts only")
  dimensions<-truth$dimension_names
  coefficients<-result$coefficient_names
  .etr_assert(is.character(dimensions)&&length(dimensions)>=1L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions),
    "dimension_names must be unique nonmissing strings")
  .etr_assert(is.character(coefficients)&&length(coefficients)>=1L&&
    !anyNA(coefficients)&&!anyDuplicated(coefficients),
    "coefficient_names must be unique nonmissing strings")
  .etr_assert(is.character(intercept_name)&&length(intercept_name)==1L&&
    !is.na(intercept_name)&&nzchar(intercept_name),
    "intercept_name must be a nonempty string")
  d<-match(result$dimension_name,dimensions)
  .etr_assert(length(d)==1L&&!is.na(d),
    "mixed-effects response dimension is absent from generating truth")
  intercept_index<-match(intercept_name,coefficients)
  .etr_assert(length(intercept_index)==1L&&!is.na(intercept_index),
    "intercept_name is absent from fitted model")
  nt<-length(grid)
  .etr_assert(is.matrix(truth$mean)&&is.numeric(truth$mean)&&
    identical(dim(truth$mean),c(nt,length(dimensions)))&&
    all(is.finite(truth$mean)),
    "truth mean must be time by dimension finite matrix")
  fit_coeff<-result$coefficient_functions
  .etr_assert(is.matrix(fit_coeff)&&is.numeric(fit_coeff)&&
    identical(dim(fit_coeff),c(length(coefficients),nt))&&
    all(is.finite(fit_coeff)),
    "fitted coefficient functions must be coefficient by time")
  eigenfunctions<-truth$eigenfunctions
  .etr_assert(is.array(eigenfunctions)&&is.numeric(eigenfunctions)&&
    length(dim(eigenfunctions))==3L&&dim(eigenfunctions)[1L]>=1L&&
    identical(dim(eigenfunctions)[2:3],c(nt,length(dimensions)))&&
    all(is.finite(eigenfunctions)),
    "truth eigenfunctions must be mode by time by dimension")
  nk<-dim(eigenfunctions)[1L]
  for(name in c("participant_eigenvalues","trial_eigenvalues")) {
    eig<-truth[[name]]
    .etr_assert(is.numeric(eig)&&is.null(dim(eig))&&length(eig)==nk&&
      all(is.finite(eig))&&all(eig>=0),
      paste(name,"must contain finite nonnegative simulator mode variances"))
  }
  weights<-etr_trapezoid_weights(grid)
  mean_difference<-fit_coeff[intercept_index,]-truth$mean[,d]
  value<-.etr_recovery_value_factory()
  values<-list(value("coefficient_function_ise",
    sum(mean_difference^2*weights),source="intercept"))
  truth_modes<-matrix(eigenfunctions[,,d,drop=FALSE],nrow=nk,ncol=nt)
  assess_source<-function(source,fitted,eigenvalues) {
    declared<-colSums(sweep(truth_modes^2,1L,eigenvalues,"*"))
    .etr_assert(length(fitted)==nt&&all(is.finite(fitted)),
      paste(source,"fitted variance function geometry is invalid"))
    result<-list(
      value("source_variance_function_ise",
        sum((fitted-declared)^2*weights),source=source))
    fitted_int<-sum(fitted*weights)
    declared_int<-sum(declared*weights)
    absolute<-abs(fitted_int-declared_int)
    result[[length(result)+1L]]<-value(
      "source_integrated_variance_absolute_error",absolute,source=source)
    if(declared_int>0) result[[length(result)+1L]]<-
      value(
        "source_integrated_variance_relative_error",
        absolute/declared_int,source=source)
    result
  }
  participant<- .etr_mixed_recovery_variance(result$random_basis,
    result$random_intercept_covariance,nt,"participant")
  values<-c(values,assess_source("participant",participant,
    truth$participant_eigenvalues))
  has_trial_truth<-any(truth$trial_eigenvalues>0)
  # Never use partial matching: when the optional name is absent, R can
  # match trial_random_effect_covariance and misread a covariance matrix
  # as a random-effect type. Python None is semantically distinct.
  trial_kind<-result[["trial_random_effect",exact=TRUE]]
  .etr_assert(is.null(trial_kind)||identical(trial_kind,"functional_intercept"),
    "unsupported trial_random_effect in mixed-effects recovery")
  if(identical(trial_kind,"functional_intercept")){
    .etr_recovery_source_fields(result,
      c("trial_random_basis","trial_random_effect_covariance"),"trial random effect")
    .etr_assert(!is.null(result$trial_random_basis)&&
      !is.null(result$trial_random_effect_covariance),
      "trial random-effect fit is missing its basis/covariance")
    trial<-.etr_mixed_recovery_variance(result$trial_random_basis,
      result$trial_random_effect_covariance,nt,"trial")
    values<-c(values,assess_source("trial",trial,
      truth$trial_eigenvalues))
  }else if(has_trial_truth){
    stop("generating truth contains trial functional variance but the fitted model does not contain a trial functional random intercept",
      call.=FALSE)
  }
  structure(list(values=values,provenance=list(
    estimator="functional_mixed_effects",
    truth_grid_match="exact",
    dimension=result$dimension_name,
    intercept_name=intercept_name,
    participant_variance_target="time_domain_variance_function",
    trial_variance_target="time_domain_variance_function",
    basis_covariance_compared_directly_to_kl_eigenvalues=FALSE,
    curve_level_kl_variance_scored_as_scalar_residual=FALSE)),
    class="etr_functional_recovery_assessment")
}
