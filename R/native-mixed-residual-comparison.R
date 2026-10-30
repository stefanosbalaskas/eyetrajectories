# Source-aligned descriptive comparison for restricted native mixed-moments
# fits. Frozen Python 1.2.0 compare_functional_mixed_effects_residual_diagnostics
# in functional_mixed_effects_diagnostics.py, commit:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native moment-based fits are NOT Python MixedLM estimates.

#' Compare two declared native functional mixed-effects residual diagnostics
#' @param reference Native converged restricted mixed-moments fitted result.
#' @param comparison Matched converged restricted mixed-moments fitted result.
#' @param max_lag Positive maximum index lag within observed grid.
#' @param reference_label Name for the reference diagnostic model.
#' @param comparison_label Name for the comparison diagnostic model.
#' @param residual_scale One of raw or whitened (declared in advance).
#' @return Source-column-ordered descriptive sensitivity frame.
#' @export
etr_compare_functional_mixed_effects_residual_diagnostics <- function(
    reference,comparison,max_lag,reference_label="reference",
    comparison_label="comparison",residual_scale="raw") {
  .etr_mixed_moments_fit(reference)
  .etr_mixed_moments_fit(comparison)
  .etr_assert(is.character(reference$dimension_name)&&
    length(reference$dimension_name)==1L &&
    identical(reference$dimension_name,comparison$dimension_name),
    "Fits must use the same response dimension")
  .etr_assert(is.character(reference$time_unit)&&
    length(reference$time_unit)==1L &&
    identical(reference$time_unit,comparison$time_unit),
    "Fits must use the same time unit")
  .etr_assert(identical(as.character(reference$source_curve_ids),
    as.character(comparison$source_curve_ids)),
    "Fits must contain the same source curves in the same order")
  .etr_assert(identical(as.character(reference$curve_participant_ids),
    as.character(comparison$curve_participant_ids)),
    "Fits must contain the same participant mapping in the same order")
  .etr_assert(identical(as.numeric(reference$time),
    as.numeric(comparison$time)),
    "Fits must use exactly the same observed time grid")
  .etr_assert(is.character(reference_label)&&length(reference_label)==1L&&
    !is.na(reference_label)&&nzchar(reference_label)&&
    is.character(comparison_label)&&length(comparison_label)==1L&&
    !is.na(comparison_label)&&nzchar(comparison_label),
    "reference and comparison labels must be nonempty strings")
  .etr_assert(is.character(residual_scale)&&length(residual_scale)==1L&&
    !is.na(residual_scale)&&residual_scale%in%c("raw","whitened"),
    "residual_scale must be raw or whitened")
  lag<-.etr_nonlinear_integer(max_lag,1L,"max_lag")
  .etr_assert(lag<length(reference$time),
    "max_lag must be smaller than n_time")
  a<-etr_functional_mixed_effects_residual_diagnostics(reference,
    max_lag=lag,residual_scale=residual_scale)$overall_diagnostics
  b<-etr_functional_mixed_effects_residual_diagnostics(comparison,
    max_lag=lag,residual_scale=residual_scale)$overall_diagnostics
  keys<-c("lag_index","lag_time_mean","lag_time_min","lag_time_max",
    "n_pairs","n_trials_total")
  metrics<-c("n_trials_acf_defined","autocovariance","autocorrelation",
    "semivariance")
  keep<-c(keys,metrics)
  .etr_assert(all(keep%in%names(a))&&all(keep%in%names(b)),
    "overall diagnostics must retain all source comparison columns")
  .etr_assert(!anyDuplicated(a[keys])&&!anyDuplicated(b[keys]),
    "overall diagnostics require unique declared lag keys")
  # Source Python merge is inner one-to-one. Fail closed on dropped lag
  # rows rather than disguising unmatched source exposure as equivalence.
  out<-merge(a[,keep,drop=FALSE],b[,keep,drop=FALSE],
    by=keys,all=FALSE,sort=TRUE,
    suffixes=c("_reference","_comparison"))
  .etr_assert(nrow(out)==nrow(a)&&nrow(out)==nrow(b),
    "source fits have unmatched residual lag exposure")
  for(metric in c("autocovariance","autocorrelation","semivariance"))
    out[[paste0("delta_",metric)]] <-
      out[[paste0(metric,"_comparison")]] -
      out[[paste0(metric,"_reference")]]
  data.frame(reference_label=rep(reference_label,nrow(out)),
    comparison_label=rep(comparison_label,nrow(out)),
    residual_scale=rep(residual_scale,nrow(out)),
    out,check.names=FALSE,stringsAsFactors=FALSE)
}
