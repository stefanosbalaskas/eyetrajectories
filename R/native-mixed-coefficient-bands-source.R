# Pinned Python: eyetrajectoriespy==1.2.0
# functional_mixed_effects_inference.py
# c1cd95ad718327550f7e55393ff38582872f7a94.
# This function never resamples/refits: it calibrates retained arrays only.
# An explicit bootstrap_type names the Python subclass unavailable in R;
# source dataclass identity and complete accepted domain remain uncertified.

#' Mixed functional coefficient simultaneous inference from retained bootstrap
#' @param bootstrap Native source-shaped mixed-effect coefficient bootstrap,
#'   including reference, bootstrap_mean, bootstrap_standard_errors, and
#'   bootstrap_coefficient_functions. Requires a declared bootstrap_type
#'   equal to conditional_covariance or full_refit.
#' @param confidence_level Nominal coverage probability in (0,1).
#' @param simultaneous_scope Coefficient-wise or family-wise observed-grid
#'   standardized maximum calibration.
#' @return Source-shaped coefficient bands with pointwise scales, bootstrap
#'   maximum statistics and explicit variance-refit provenance.
#' @export
etr_functional_mixed_effects_simultaneous_bands <- function(
    bootstrap,confidence_level=.95,simultaneous_scope="coefficient"){
  .etr_scientific_frame_fields(bootstrap,c("reference",
    "bootstrap_mean","bootstrap_standard_errors",
    "bootstrap_coefficient_functions","bootstrap_type"),
    "functional mixed-effects bootstrap")
  .etr_assert(is.character(bootstrap$bootstrap_type)&&
    length(bootstrap$bootstrap_type)==1L&&!is.na(bootstrap$bootstrap_type)&&
    bootstrap$bootstrap_type%in%c("conditional_covariance","full_refit"),
    "bootstrap_type must explicitly declare conditional_covariance or full_refit")
  fit<-bootstrap$reference
  .etr_assert(is.list(fit)&&!is.null(fit$time),
    "functional mixed-effects fit must retain observed time")
  coefficient_names<-if(is.null(fit$coefficient_names))
    fit$predictor_names else fit$coefficient_names
  coefficient_functions<-if(is.null(fit$coefficient_functions))
    fit$fixed_coefficient_functions else fit$coefficient_functions
  names<-.etr_scientific_frame_ids(coefficient_names,"coefficient_names")
  time<-.etr_scientific_frame_time(fit$time)
  nc<-length(names);nt<-length(time)
  estimate<-.etr_gfosr_predict_numeric_matrix(
    coefficient_functions,nc,nt,"coefficient_functions")
  mean<-.etr_gfosr_predict_numeric_matrix(
    bootstrap$bootstrap_mean,nc,nt,"bootstrap_mean")
  se<-.etr_gfosr_predict_numeric_matrix(
    bootstrap$bootstrap_standard_errors,nc,nt,
    "bootstrap_standard_errors")
  .etr_assert(all(se>.Machine$double.eps),
    "bootstrap pointwise standard errors contain zero-width cells; simultaneous studentization is undefined")
  .etr_assert(is.numeric(confidence_level)&&
    length(confidence_level)==1L&&!is.logical(confidence_level)&&
    is.finite(confidence_level)&&confidence_level>0&&
    confidence_level<1,"confidence_level must lie in (0,1)")
  .etr_assert(is.character(simultaneous_scope)&&
    length(simultaneous_scope)==1L&&!is.na(simultaneous_scope)&&
    simultaneous_scope%in%c("coefficient","family"),
    "simultaneous_scope must be coefficient or family")
  draws<-bootstrap$bootstrap_coefficient_functions
  .etr_assert(is.array(draws)&&is.numeric(draws)&&
    length(dim(draws))==3L&&dim(draws)[1L]>=1L&&
    identical(dim(draws)[2:3],c(nc,nt))&&all(is.finite(draws)),
    "bootstrap_coefficient_functions must be finite B-by-coefficient-by-time")
  B<-dim(draws)[1L]
  maxima<-matrix(NA_real_,B,nc)
  for(b in seq_len(B)){
    current<-matrix(draws[b,,],nrow=nc,ncol=nt)
    studentized<-abs((current-mean)/se)
    maxima[b,]<-apply(studentized,1L,max)
  }
  if(simultaneous_scope=="coefficient"){
    max_statistics<-maxima
    critical_values<-vapply(seq_len(nc),function(j)
      .etr_gfosr_numpy_higher(maxima[,j],confidence_level),numeric(1L))
  }else{
    m<-apply(maxima,1L,max)
    max_statistics<-matrix(m,ncol=1L)
    critical_values<-rep(.etr_gfosr_numpy_higher(m,confidence_level),nc)
  }
  width<-se*matrix(rep(critical_values,each=nt),nrow=nc,byrow=TRUE)
  lower<-estimate-width
  upper<-estimate+width
  .etr_assert(all(is.finite(lower))&&all(is.finite(upper)),
    "calibrated mixed model band endpoints must be finite")
  is_refit<-identical(bootstrap$bootstrap_type,"full_refit")
  provenance<-.etr_gfosr_source_provenance(bootstrap,
    "functional_mixed_effects_simultaneous_bands",list(
      method="participant_cluster_bootstrap_studentized_supremum",
      confidence_level=confidence_level,
      simultaneous_scope=simultaneous_scope,
      simultaneous_domain=if(simultaneous_scope=="coefficient")
        "observed_time_grid_per_coefficient" else
        "coefficient_by_observed_time_grid",
      bootstrap_centering_for_calibration="bootstrap_mean",
      band_center="reference_estimate",
      bias_correction=FALSE,
      pointwise_scale="participant_cluster_bootstrap_sd",
      continuous_between_grid_points=FALSE,
      variance_components_refit=is_refit,
      failed_replicate_policy="raise"))
  structure(list(reference=fit,lower=lower,upper=upper,
    pointwise_standard_errors=se,critical_values=critical_values,
    max_statistics=max_statistics,confidence_level=confidence_level,
    simultaneous_scope=simultaneous_scope,bootstrap=bootstrap,
    provenance=provenance),class="etr_mixed_effects_simultaneous_band")
}
