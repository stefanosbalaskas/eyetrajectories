# Source: published eyetrajectoriespy 1.2.0 at
# c1cd95ad718327550f7e55393ff38582872f7a94
# functional_mixed_effects_full_refit.py::
# compare_functional_mixed_effects_bootstraps
# Descriptive retained arrays, no bootstrap or model refitting.
# R list equality cannot establish Python object identity: remains open.

#' Compare conditional and full-refit functional coefficient band widths
#'
#' This source-shaped native result is descriptive. Both stored bootstrap
#' arrays must come from the same reference fit; native structural equality
#' is necessary but is not Python's exact \code{is} identity contract.
#' @param fixed_covariance_bootstrap Retained conditional-covariance bootstrap.
#' @param full_refit_bootstrap Retained full covariance-refit bootstrap.
#' @param confidence_level Nominal simultaneous band confidence level.
#' @param simultaneous_scope One coefficient or the entire coefficient family.
#' @return Source column/row order table of band widths and refit/fixed ratio.
#' @export
etr_compare_functional_mixed_effects_bootstraps<-function(
    fixed_covariance_bootstrap,full_refit_bootstrap,
    confidence_level=.95,simultaneous_scope="coefficient"){
  .etr_scientific_frame_fields(fixed_covariance_bootstrap,
    c("reference","bootstrap_type","bootstrap_mean",
      "bootstrap_standard_errors","bootstrap_coefficient_functions"),
    "fixed-covariance bootstrap")
  .etr_scientific_frame_fields(full_refit_bootstrap,
    c("reference","bootstrap_type","bootstrap_mean",
      "bootstrap_standard_errors","bootstrap_coefficient_functions"),
    "full-refit bootstrap")
  .etr_assert(identical(fixed_covariance_bootstrap$bootstrap_type,
    "conditional_covariance"),
    "fixed_covariance_bootstrap must be a conditional covariance bootstrap")
  .etr_assert(identical(full_refit_bootstrap$bootstrap_type,"full_refit"),
    "full_refit_bootstrap must be a full-refit bootstrap")
  .etr_assert(identical(fixed_covariance_bootstrap$reference,
    full_refit_bootstrap$reference),
    "both bootstrap objects must share the exact reference fit")
  conditional<-etr_functional_mixed_effects_simultaneous_bands(
    fixed_covariance_bootstrap,confidence_level=confidence_level,
    simultaneous_scope=simultaneous_scope)
  refit<-etr_functional_mixed_effects_simultaneous_bands(
    full_refit_bootstrap,confidence_level=confidence_level,
    simultaneous_scope=simultaneous_scope)
  fit<-fixed_covariance_bootstrap$reference
  .etr_scientific_frame_fields(fit,c("coefficient_names","time"),
    "bootstrap reference")
  names<-fit$coefficient_names
  time<-fit$time
  .etr_assert(is.character(names)&&length(names)>=1L&&
    !anyNA(names)&&is.numeric(time)&&length(time)>=1L&&
    all(is.finite(time)),
    "reference coefficient names and time must be complete")
  rows<-vector("list",length(names)*length(time))
  counter<-0L
  for(j in seq_along(names)){
    for(i in seq_along(time)){
      counter<-counter+1L
      width_fixed<-conditional$upper[j,i]-conditional$lower[j,i]
      width_refit<-refit$upper[j,i]-refit$lower[j,i]
      .etr_assert(all(is.finite(c(width_fixed,width_refit)))&&
        width_fixed>=0&&width_refit>=0,
        "source bootstrap band widths must be finite nonnegative")
      rows[[counter]]<-data.frame(
        coefficient=names[[j]],time=as.numeric(time[[i]]),
        fixed_covariance_band_width=as.numeric(width_fixed),
        full_refit_band_width=as.numeric(width_refit),
        full_refit_to_fixed_covariance_width_ratio=
          if(width_fixed>0)as.numeric(width_refit/width_fixed) else Inf,
        confidence_level=as.numeric(confidence_level),
        simultaneous_scope=simultaneous_scope,
        stringsAsFactors=FALSE)
    }
  }
  do.call(rbind,rows)
}
