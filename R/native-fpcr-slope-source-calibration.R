# Frozen Python 1.2.0: regression_inference.py
# fpca_regression_slope_simultaneous_band at
# c1cd95ad718327550f7e55393ff38582872f7a94
# Pure native postcalibration. No FPCR refitting or new bootstrap draws.

#' Observed-grid simultaneous band from paired FPCR slope bootstraps
#' @param result Native result containing paired-bootstrap slope replicates.
#' @param confidence_level Diagnostic confidence level strictly inside (0,1).
#' @param simultaneous_scope One source-declared maximum: global or per dimension.
#' @return Native scientific R-list of calibrated observed-grid slope bounds;
#'   no between-grid or operator-test inference is claimed.
#' @export
etr_fpca_regression_slope_simultaneous_band <- function(
    result,confidence_level=.95,simultaneous_scope="global") {
  .etr_scientific_frame_fields(result,
    c("reference_slope","bootstrap_slopes","reference_fpca"),
    "regression uncertainty")
  level<-.etr_wild_mc_confidence(confidence_level,"confidence_level")
  .etr_assert(is.character(simultaneous_scope)&&
    length(simultaneous_scope)==1L&&!is.na(simultaneous_scope)&&
    simultaneous_scope%in%c("global","dimension"),
    "simultaneous_scope must be 'global' or 'dimension'")
  ref<-result$reference_slope
  .etr_assert(is.matrix(ref)&&is.numeric(ref)&&
    all(dim(ref)>=1L)&&all(is.finite(ref)),
    "reference_slope must be a finite time-by-dimension matrix")
  boots<-result$bootstrap_slopes
  .etr_assert(is.array(boots)&&is.numeric(boots)&&
    length(dim(boots))==3L&&dim(boots)[1L]>=2L&&
    identical(as.integer(dim(boots)[-1L]),as.integer(dim(ref))),
    "bootstrap slope array is incompatible with reference slope")
  .etr_assert(all(is.finite(boots)),
    "reference and bootstrap slopes must be finite")
  t<-nrow(ref);d<-ncol(ref);B<-dim(boots)[1L]
  .etr_scientific_frame_fields(result$reference_fpca,
    c("dimension_names"),"reference FPCA")
  dims<-.etr_scientific_frame_ids(result$reference_fpca$dimension_names,
    "dimension_names")
  .etr_assert(length(dims)==d,
    "reference FPCA dimension_names must match reference_slope")
  # Use native matrix and array orientation, not row-major reshaping.
  residuals<-sweep(boots,c(2L,3L),ref,FUN="-")
  se<-matrix(apply(residuals,c(2L,3L),stats::sd),
    nrow=t,ncol=d)
  scale<-max(1,max(abs(ref)))
  threshold<-.Machine$double.eps*scale
  tol<-100*.Machine$double.eps*scale
  positive<-se>threshold
  discrepancy<-matrix(apply(abs(residuals),c(2L,3L),max),
    nrow=t,ncol=d)
  degeneracy<-(!positive)&discrepancy>tol
  .etr_assert(!any(degeneracy),
    paste0("FPCR slope-band calibration is degenerate: ",
      sum(degeneracy)," observed grid cell(s) have zero bootstrap ",
      "standard error but nonzero reference discrepancy"))
  studentized<-array(0,dim=dim(boots))
  for(j in seq_len(d))for(i in seq_len(t)){
    if(positive[i,j])studentized[,i,j]<-
      residuals[,i,j]/se[i,j]
  }
  abss<-abs(studentized)
  if(identical(simultaneous_scope,"global")) {
    maxima<-apply(abss,1L,max)
    crit<-rep(.etr_fpcr_higher_quantile(maxima,level),d)
  } else {
    maxima<-matrix(apply(abss,c(1L,3L),max),
      nrow=B,ncol=d)
    crit<-vapply(seq_len(d),function(j)
      .etr_fpcr_higher_quantile(maxima[,j],level),numeric(1L))
  }
  width<-sweep(se,2L,crit,FUN="*")
  original<-result$provenance
  if(is.null(original))original<-list()
  .etr_assert(is.list(original)&&!is.data.frame(original),
    "provenance must be a scientific list")
  original$fpca_regression_slope_band<-list(
    method="studentized_bootstrap_maximum_observed_grid",
    confidence_level=level,simultaneous_scope=simultaneous_scope,
    domain="observed_time_by_dimension_grid",
    continuous_between_grid_points=FALSE,
    operator_scaled_fpcr_test=FALSE,
    bootstrap_reused_from_regression_uncertainty=TRUE,
    n_bootstrap=B,zero_variance_cells=sum(!positive))
  structure(list(regression_uncertainty=result,
    lower=ref-width,upper=ref+width,
    pointwise_se=se,critical_values=as.numeric(crit),
    max_statistics=maxima,confidence_level=level,
    simultaneous_scope=simultaneous_scope,provenance=original),
    class="etr_fpcr_slope_simultaneous")
}
