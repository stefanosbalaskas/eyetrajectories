# Native fixed-truth evaluator equivalents for published Python 1.2.0
# recovery.py @ c1cd95ad718327550f7e55393ff38582872f7a94
# No simulator or estimator is invoked. These are observational truth audits.
# Source dataclass type identity is not certified as equivalent to native records.

.etr_recovery_source_fields <- function(x,required,name) {
  .etr_assert(is.list(x)&&!is.data.frame(x)&&
    all(required %in% names(x)),
    paste(name,"requires explicit fields:",paste(required,collapse=", ")))
  invisible(TRUE)
}
.etr_recovery_value_factory <- function() {
  catalog <- lapply(etr_functional_recovery_metric_catalog(), unclass)
  function(name, value, component = NULL, source = NULL) {
    .etr_assert(is.numeric(value) && length(value) == 1L && is.finite(value),
      paste(name, "must be a finite recovery value"))
    list(metric = catalog[[name]], value = as.numeric(value),
      component = component, source = source)
  }
}
.etr_recovery_source_matrix <- function(x,ncols,name) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    nrow(x)>=1L&&ncol(x)==ncols&&all(is.finite(x)),
    paste(name,"must be a finite matrix with expected columns and observations"))
  x
}
#' Evaluate known simulator hierarchy score-source variances
#'
#' Compares each realized curve, participant and trial score variance
#' (population ddof=0) to its declared simulator eigenvalue.
#' @param truth Source-shaped latent truth record, with all three score
#'   matrices and corresponding source eigenvalue vectors.
#' @return Native source-shaped assessment with zero-based components and
#'   explicit semantic metric metadata.
#' @export
etr_evaluate_hierarchy_truth_recovery <- function(truth) {
  fields<-c("curve_scores","participant_scores","trial_scores",
    "eigenvalues","participant_eigenvalues","trial_eigenvalues")
  .etr_recovery_source_fields(truth,fields,"truth")
  sources<-list(
    curve=list(scores=truth$curve_scores,target=truth$eigenvalues),
    participant=list(scores=truth$participant_scores,
      target=truth$participant_eigenvalues),
    trial=list(scores=truth$trial_scores,target=truth$trial_eigenvalues))
  values<-list()
  value<-.etr_recovery_value_factory()
  for(source in names(sources)){
    x<-sources[[source]]
    target<-x$target
    .etr_assert(is.numeric(target)&&is.null(dim(target))&&
      length(target)>=0L&&all(is.finite(target)),
      paste(source,"declared eigenvalues must be finite numeric vector"))
    scores<-.etr_recovery_source_matrix(x$scores,length(target),
      paste(source,"scores"))
    # Python np.var(..., axis=0, ddof=0) returns an empty vector when
    # the validated scientific score source has zero retained components.
    # An empty source must contribute no recovery metrics, not an error.
    if(!length(target))next
    estimate<-colMeans(sweep(scores,2L,colMeans(scores),"-")^2)
    for(k in seq_along(target)){
      err<-abs(as.numeric(estimate[k])-as.numeric(target[k]))
      values[[length(values)+1L]]<-value(
        "source_variance_absolute_error",err,component=as.integer(k-1L),
        source=source)
      if(target[k]>0)
        values[[length(values)+1L]]<-value(
          "source_variance_relative_error",err/as.numeric(target[k]),
          component=as.integer(k-1L),source=source)
    }
  }
  # The Python source returns FunctionalRecoveryAssessment(values=())
  # for a zero-component truth and retains its provenance unchanged.
  structure(list(values=values,provenance=list(
    estimator="none",purpose="simulation_source_variance_audit",ddof=0L)),
    class="etr_functional_recovery_assessment")
}

#' Evaluate known inverse phase-warp recovery on the exact simulator grid
#'
#' The simulator evaluates latent(w(t)); registration estimates h(t) = w^-1(t).
#' This evaluator compares estimated h against the explicit inverse generated
#' by source-equivalent linear interpolation on the original time grid.
#' @param result Explicit source-shaped registration fit with original time
#'   and estimated curve-by-time warping functions.
#' @param truth Latent truth record with truth_grid and generated phase warps.
#' @return Native source-shaped integrated and maximal inverse-warp errors.
#' @export
etr_evaluate_registration_recovery <- function(result,truth) {
  .etr_recovery_source_fields(result,
    c("original","warping_functions"),"registration result")
  .etr_recovery_source_fields(result$original,c("time"),
    "registration original")
  .etr_recovery_source_fields(truth,
    c("truth_grid","phase_warps_on_truth_grid"),"truth")
  grid<-truth$truth_grid
  .etr_recovery_require_grid(result$original$time,grid,
    "recovery evaluation requires the fitted grid to equal truth.truth_grid exactly")
  estimate<-result$warping_functions
  generated<-truth$phase_warps_on_truth_grid
  .etr_assert(is.matrix(generated)&&is.numeric(generated)&&
    nrow(generated)>=1L&&ncol(generated)==length(grid)&&
    all(is.finite(generated)),
    "generated phase warps must be finite curve-by-time matrix")
  .etr_assert(is.matrix(estimate)&&is.numeric(estimate)&&
    identical(dim(estimate),dim(generated))&&all(is.finite(estimate)),
    "registration warps and generating phase warps must have identical curve/time geometry")
  inverse<-t(vapply(seq_len(nrow(generated)),function(i){
    knots<-generated[i,]
    .etr_assert(all(diff(knots)>=0),"generating phase warps must be nondecreasing to invert")
    # NumPy interpolation starts from the last knot at or below the
    # query and clamps the outer intervals to the supplied endpoints.
    left<-findInterval(grid,knots)
    values<-grid[pmax(1L,left)]
    inside<-which(left>0L&left<length(grid))
    lo<-left[inside]
    hi<-lo+1L
    values[inside]<-grid[lo]+(grid[hi]-grid[lo])/(knots[hi]-knots[lo])*
      (grid[inside]-knots[lo])
    values
  },numeric(length(grid))))
  difference<-estimate-inverse
  weights<-etr_trapezoid_weights(grid)
  curve_ise<-rowSums(sweep(difference^2,2L,weights,"*"))
  value<-.etr_recovery_value_factory()
  values<-list(value("phase_warp_ise",mean(curve_ise)),
    value("phase_warp_max_absolute_error",max(abs(difference))))
  structure(list(values=values,provenance=list(
    estimator="landmark_registration",truth_grid_match="exact",
    truth_target="inverse_phase_warp",
    simulator_phase_relation="observed(t)=latent(w(t))")),
    class="etr_functional_recovery_assessment")
}
