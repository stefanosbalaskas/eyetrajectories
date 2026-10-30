# Pure native R postcalibration for the full fixed-target FPCR family.
# Frozen Python 1.2 wild_simultaneous.py @
# c1cd95ad718327550f7e55393ff38582872f7a94.
# This computation draws no new bootstrap multipliers and does not refit FPCR.

.etr_fpcr_higher_quantile <- function(x,confidence) {
  .etr_assert(is.numeric(x)&&length(x)>=1L&&all(is.finite(x)),
    "higher quantile requires nonempty finite numeric bootstrap statistics")
  .etr_assert(is.numeric(confidence)&&length(confidence)==1L&&
    is.finite(confidence)&&confidence>0&&confidence<1,
    "confidence_level must lie in (0,1)")
  # NumPy quantile(method='higher') is CEIL((B-1)*p) + 1 in R indexing,
  # not R type=1, which differs at e.g B=4, p=.5.
  sorted<-sort(x,method="quick")
  sorted[ceiling((length(x)-1L)*confidence)+1L]
}

#' Familywise simultaneous fixed-target Gaussian FPCR wild-bootstrap interval
#' @param result Precomputed native wild-bootstrap FPCR projection record.
#' @param confidence_level Optional source diagnostic level; defaults to
#'   the explicit confidence level recorded in the projection.
#' @return An R scientific record with source-derived max-absolute
#'   studentized critical values and observed-grid fixed-family intervals.
#' @export
etr_fpca_wild_bootstrap_projection_simultaneous_interval <- function(
    result,confidence_level=NULL) {
  .etr_scientific_frame_fields(result,c("target_curve_ids",
    "bootstrap_projections","studentized_roots",
    "reference_projection","reference_se","confidence_level"),
    "wild-bootstrap projection")
  ids<-.etr_scientific_frame_ids(result$target_curve_ids,
    "target_curve_ids")
  n<-length(ids)
  roots<-result$studentized_roots
  draws<-result$bootstrap_projections
  .etr_assert(is.matrix(draws)&&is.numeric(draws)&&
    nrow(draws)>=1L&&ncol(draws)==n,
    "bootstrap_projections must retain B-by-N target draws")
  B<-nrow(draws)
  .etr_assert(is.matrix(roots)&&is.numeric(roots)&&
    identical(dim(roots),c(B,n))&&all(is.finite(roots)),
    "studentized_roots shape is inconsistent with the base result")
  level<-.etr_wild_mc_confidence(
    if(is.null(confidence_level))result$confidence_level else confidence_level,
    "confidence_level")
  center<-.etr_wild_mc_numeric(result$reference_projection,n,
    "reference_projection")
  se<-.etr_wild_mc_numeric(result$reference_se,n,"reference_se")
  .etr_assert(all(se>=0),
    "reference standard errors must be finite and non-negative")
  absroots<-abs(roots)
  target_critical<-apply(absroots,2L,.etr_fpcr_higher_quantile,
    confidence=level)
  maxima<-apply(absroots,1L,max)
  critical<-.etr_fpcr_higher_quantile(maxima,level)
  lower<-center-critical*se
  upper<-center+critical*se
  source_provenance<-result$provenance
  if(is.null(source_provenance))source_provenance<-list()
  .etr_assert(is.list(source_provenance)&&!is.data.frame(source_provenance),
    "provenance must be a scientific list")
  metadata<-list(
    method="postcalibrated_max_abs_studentized_root",
    family="gaussian",
    estimand="centered_projection_relative_to_training_functional_mean",
    confidence_level=level,n_targets=n,
    family_definition="all_fixed_targets_in_base_projection_result",
    bootstrap_roots_reused=TRUE,bootstrap_rerun=FALSE,
    simultaneous_across_targets=TRUE,
    future_outcome_prediction_interval=FALSE,
    clustered_wild_bootstrap=FALSE,
    component_selection_uncertainty_included=FALSE)
  source_provenance$fpca_wild_bootstrap_simultaneous<-metadata
  structure(list(projection_result=result,
    targetwise_critical_values=as.numeric(target_critical),
    critical_value=as.numeric(critical),
    max_statistics=as.numeric(maxima),
    lower=as.numeric(lower),upper=as.numeric(upper),
    confidence_level=level,provenance=source_provenance),
    class="etr_fpca_wild_simultaneous")
}
