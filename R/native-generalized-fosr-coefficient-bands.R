# Frozen source: eyetrajectoriespy==1.2.0
# src/eyetrajectoriespy/generalized_function_on_scalar.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Applies an observed-grid max-standardized calibration to precomputed
# coefficient bootstrap draws. Does not refit models or resample participants.
# Python class typing/error schemas remain unresolved source differences.

#' Simultaneous link-scale generalized function-on-scalar coefficient bands
#'
#' Calibrates observed-grid coefficient-wise or family-wise maxima from
#' retained whole-participant bootstrap coefficient functions. Matches
#' NumPy's higher empirical quantile and ignores deviations at coordinates
#' with standard errors at or below the machine epsilon, as in Python 1.2.
#' @param bootstrap Source-shaped native generalized FoSR coefficient
#'   bootstrap record with reference and B by coefficient by time draws.
#' @param confidence_level Nominal probability strictly between zero and one.
#' @param simultaneous_scope Either coefficient or family.
#' @return Native source-shaped link-scale band and calibration diagnostics.
#' @export
etr_generalized_function_on_scalar_simultaneous_bands <- function(
    bootstrap,confidence_level=.95,
    simultaneous_scope="coefficient"){
  .etr_scientific_frame_fields(bootstrap,c("reference",
    "bootstrap_coefficient_functions"),"generalized FoSR coefficient bootstrap")
  reference<-bootstrap$reference
  .etr_scientific_frame_fields(reference,c("coefficient_names",
    "time","coefficient_functions","coefficient_standard_errors"),
    "generalized FoSR reference")
  ids<-.etr_scientific_frame_ids(reference$coefficient_names,
    "coefficient_names")
  time<-.etr_scientific_frame_time(reference$time)
  nc<-length(ids);nt<-length(time)
  center<-.etr_gfosr_predict_numeric_matrix(reference$coefficient_functions,
    nc,nt,"coefficient_functions")
  se<-.etr_gfosr_predict_numeric_matrix(
    reference$coefficient_standard_errors,nc,nt,
    "coefficient_standard_errors")
  .etr_assert(all(se>=0),
    "coefficient_standard_errors must be nonnegative")
  .etr_assert(is.numeric(confidence_level)&&
    !is.logical(confidence_level)&&length(confidence_level)==1L&&
    is.finite(confidence_level)&&
    confidence_level>0&&confidence_level<1,
    "confidence_level must lie in (0, 1)")
  .etr_assert(is.character(simultaneous_scope)&&
    length(simultaneous_scope)==1L&&!is.na(simultaneous_scope)&&
    simultaneous_scope%in%c("coefficient","family"),
    "simultaneous_scope must be coefficient or family")
  draws<-bootstrap$bootstrap_coefficient_functions
  .etr_assert(is.array(draws)&&is.numeric(draws)&&
    length(dim(draws))==3L&&dim(draws)[1L]>=1L&&
    identical(dim(draws)[2:3],c(nc,nt))&&
    all(is.finite(draws)),
    "bootstrap_coefficient_functions must be finite B-by-coefficient-by-time")
  n_boot<-dim(draws)[1L]
  maxima<-matrix(NA_real_,nrow=n_boot,ncol=nc)
  positive<-se>.Machine$double.eps
  for(b in seq_len(n_boot)){
    deviations<-matrix(draws[b,,],nrow=nc,ncol=nt)-center
    standardized<-matrix(0,nrow=nc,ncol=nt)
    standardized[positive]<-deviations[positive]/se[positive]
    maxima[b,]<-apply(abs(standardized),1L,max)
  }
  if(identical(simultaneous_scope,"coefficient")){
    max_statistics<-maxima
    critical_values<-vapply(seq_len(nc),function(j)
      .etr_gfosr_numpy_higher(maxima[,j],confidence_level),numeric(1L))
  }else{
    max_family<-apply(maxima,1L,max)
    max_statistics<-matrix(max_family,ncol=1L)
    critical_values<-rep(.etr_gfosr_numpy_higher(
      max_family,confidence_level),nc)
  }
  spread<-se*matrix(rep(critical_values,each=nt),nrow=nc,byrow=TRUE)
  lower<-center-spread
  upper<-center+spread
  .etr_assert(all(is.finite(lower))&&all(is.finite(upper)),
    "calibrated link-scale coefficient endpoints must be finite")
  provenance<-.etr_gfosr_source_provenance(bootstrap,
    "generalized_function_on_scalar_simultaneous_band",list(
      confidence_level=confidence_level,
      simultaneous_scope=simultaneous_scope,
      coefficient_scale="link",
      calibration="participant_bootstrap_max_standardized_deviation",
      pointwise_standard_error="gee_robust_sandwich",
      response_scale_coefficient_band=FALSE,
      automatic_model_selection=FALSE))
  structure(list(reference=reference,lower=lower,upper=upper,
    critical_values=as.numeric(critical_values),
    max_statistics=max_statistics,
    confidence_level=confidence_level,
    simultaneous_scope=simultaneous_scope,
    bootstrap=bootstrap,provenance=provenance),
    class="etr_generalized_fosr_coefficient_band")
}
