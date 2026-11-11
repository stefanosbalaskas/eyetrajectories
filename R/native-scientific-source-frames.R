# Pinned Python 1.2.0 observational frame adapters.
# The input domain is explicitly validated native R list records and MUST NOT
# be interpreted as Python dataclass interchangeability or estimator parity.
# Frozen source: c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_scientific_frame_fields <- function(result, fields, name="result") {
  .etr_assert(is.list(result) && !is.data.frame(result) &&
    all(fields %in% names(result)),
    paste(name,"must be an explicit native R record containing",
      paste(fields,collapse=", ")))
  invisible(TRUE)
}
.etr_scientific_frame_ids <- function(x,name) {
  .etr_assert(is.character(x) && length(x)>=1L &&
    !anyNA(x) && all(nzchar(x)) && !anyDuplicated(x),
    paste(name,"must be nonempty distinct identifiers"))
  x
}
.etr_scientific_frame_time <- function(x) {
  .etr_assert(is.numeric(x) && is.null(dim(x)) &&
    length(x)>=2L && all(is.finite(x)) && all(diff(x)>0),
    "time must be strictly increasing finite numeric vector")
  as.numeric(x)
}
.etr_scientific_frame_matrix <- function(x,n,k,name,nonnegative=FALSE,
    strictly_positive=FALSE) {
  .etr_assert(is.matrix(x) && is.numeric(x) && nrow(x)==n &&
    ncol(x)==k && all(is.finite(x)) &&
    (!nonnegative || all(x>=0)) &&
    (!strictly_positive || all(x>0)),
    paste(name,"must be a finite",n,"by",k,"numeric matrix"))
  invisible(TRUE)
}
.etr_scientific_frame_vector <- function(x,n,name,logical=FALSE) {
  .etr_assert(length(x)==n && !anyNA(x) &&
    if(logical)is.logical(x) else
      (is.numeric(x) && all(is.finite(x))),
    paste(name,"must be a finite vector of required length and type"))
  invisible(TRUE)
}
.etr_scientific_frame_string <- function(x,name) {
  .etr_assert(is.character(x) && length(x)==1L &&
    !is.na(x) && nzchar(x) && !grepl("[\r\n]",x),
    paste(name,"must be a nonempty string without line breaks"))
  x
}
.etr_scientific_frame_row_major <- function(x) as.vector(t(x))
.etr_scientific_frame_optional <- function(x,n,k,name) {
  if(is.null(x))return(rep(NA_real_,n*k))
  .etr_scientific_frame_matrix(x,n,k,name)
  .etr_scientific_frame_row_major(x)
}
.etr_scientific_frame_band <- function(result,base,group_count,grid_size,
    fields) {
  for(nm in fields).etr_scientific_frame_matrix(
    result[[nm]],group_count,grid_size,nm)
  .etr_scientific_frame_vector(result$critical_values,
    group_count,"critical_values")
  invisible(TRUE)
}
.etr_scientific_frame_metadata <- function(result, prefix,
    preserve_workflow_metadata=FALSE) {
  .etr_scientific_frame_fields(result,c("curve_ids","metadata",
    "scores","n_components"))
  ids<-.etr_scientific_frame_ids(result$curve_ids,"curve_ids")
  n<-length(ids)
  metadata<-result$metadata
  .etr_assert(is.data.frame(metadata) && nrow(metadata)==n,
    "metadata must be a data frame with one row per curve")
  .etr_assert(is.numeric(result$n_components) &&
    length(result$n_components)==1L &&
    is.finite(result$n_components) &&
    result$n_components==floor(result$n_components) &&
    result$n_components>=1L,
    "n_components must be a positive integer")
  k<-as.integer(result$n_components)
  scores<-result$scores
  .etr_assert(is.matrix(scores)&&is.numeric(scores)&&
    identical(dim(scores),c(n,k))&&!any(is.infinite(scores)),
    "scores must be a numeric matrix with one row per curve and no infinities")
  output_names<-paste0(prefix,seq_len(k))
  reserved<-"curve_id"
  # Frozen Python sparse.py and sparse_multivariate.py both start with
  # metadata.reset_index(drop=True).copy(), then insert 'curve_id' at 0.
  # Pandas raises for a preexisting curve_id column. It does *not* raise
  # for an existing SFPC/SMFPC column: subsequent label assignment replaces
  # the value(s) in place, preserving their original position. Pandas also
  # retains duplicated nonreserved metadata names.
  if(!preserve_workflow_metadata)
    .etr_assert(!any(reserved%in%names(metadata)),
      "metadata must not overwrite curve_id (pandas insert would fail)")
  if(preserve_workflow_metadata){
    # The legacy opt-in workflow uses unique metadata aliases, retained for
    # callers that explicitly request a no-collision table.
    labels<-names(metadata)
    labels[is.na(labels)|!nzchar(labels)]<-"metadata"
    names(metadata)<-utils::tail(make.unique(c(reserved,output_names,labels)),
      ncol(metadata))
  }
  output<-data.frame(curve_id=ids,stringsAsFactors=FALSE)
  # data.frame(..., check.names=FALSE) keeps the source metadata order,
  # duplicate labels and original factor/integer/logical column types.
  output<-data.frame(output,metadata,check.names=FALSE,
    stringsAsFactors=FALSE)
  # Nested data.frame arguments may normalize duplicate names even under
  # check.names=FALSE. Restore the exact pandas metadata column index.
  schema_names<-c("curve_id",names(metadata))
  names(output)<-schema_names
  for(j in seq_len(k)){
    existing<-which(schema_names==output_names[[j]])
    if(length(existing)){
      # Base R's [[<-.data.frame may auto-repair duplicated names during
      # column replacement. Track the authoritative labels separately.
      for(pos in existing)output[[pos]]<-scores[,j]
    }else{
      output[[output_names[[j]]]]<-scores[,j]
      schema_names<-c(schema_names,output_names[[j]])
    }
  }
  # Restore the exact pandas column index after all base-R mutations.
  names(output)<-schema_names
  rownames(output)<-NULL
  output
}

#' Score table for an explicitly declared sparse FPCA result
#' @param result Native list containing curve_ids, metadata, scores,
#'   n_components, as returned by a separately qualified sparse fit.
#'   Missing scores from a retained fit failure are kept in their original rows.
#' @return A data frame with source curve IDs, metadata and SFPC scores.
#' @export
etr_sparse_fpca_score_frame <- function(result) {
  .etr_scientific_frame_metadata(result,"SFPC")
}

#' Score table for explicitly declared multivariate sparse FPCA
#' @inheritParams etr_sparse_fpca_score_frame
#' @return A data frame with source curve IDs, metadata and SMFPC scores.
#' @export
etr_sparse_mfpca_score_frame <- function(result) {
  # The frozen sparse_multivariate.py frame is typed, unlike the univariate
  # sparse.py frame. Map SparseMFPCAResult to the native fitted S3 class.
  .etr_assert(inherits(result,"etr_sparse_mfpca_source"),
    "result must be a native sparse MFPCA source result")
  .etr_scientific_frame_metadata(result,"SMFPC")
}

#' Per-time coefficient table for generalized function-on-scalar regression
#' @param result Explicit native coefficient record or band with reference.
#' @return Data frame in coefficient/time order on the observed grid.
#' @export
etr_generalized_function_on_scalar_coefficient_frame <- function(result) {
  band<-is.list(result) && "reference" %in% names(result) &&
    "lower" %in% names(result)
  fit<-if(band)result$reference else result
  .etr_scientific_frame_fields(fit,
    c("coefficient_names","time","coefficient_functions",
      "coefficient_standard_errors","family","link"),"fit")
  ids<-.etr_scientific_frame_ids(fit$coefficient_names,
    "coefficient_names")
  time<-.etr_scientific_frame_time(fit$time)
  n<-length(ids);k<-length(time)
  .etr_scientific_frame_matrix(fit$coefficient_functions,n,k,
    "coefficient_functions")
  .etr_scientific_frame_matrix(fit$coefficient_standard_errors,n,k,
    "coefficient_standard_errors",nonnegative=TRUE)
  family<-.etr_scientific_frame_string(fit$family,"family")
  link<-.etr_scientific_frame_string(fit$link,"link")
  out<-data.frame(coefficient=rep(ids,each=k),
    time=rep(time,times=n),
    estimate=.etr_scientific_frame_row_major(fit$coefficient_functions),
    standard_error=.etr_scientific_frame_row_major(
      fit$coefficient_standard_errors),
    scale="link",family=family,link=link,stringsAsFactors=FALSE)
  if(band){
    .etr_scientific_frame_fields(result,
      c("lower","upper","critical_values"),"coefficient band")
    .etr_scientific_frame_band(result,fit,n,k,c("lower","upper"))
    .etr_assert(all(result$lower<=result$upper),
      "coefficient band lower must not exceed upper")
    out$lower<-.etr_scientific_frame_row_major(result$lower)
    out$upper<-.etr_scientific_frame_row_major(result$upper)
    out$critical_value<-rep(as.numeric(result$critical_values),each=k)
  }
  out
}

#' Per-time profile predictions for generalized function-on-scalar models
#' @param result Declared native prediction record or prediction band.
#' @return A source-ordered prediction frame, optionally including bands.
#' @export
etr_generalized_function_on_scalar_prediction_frame <- function(result) {
  band<-is.list(result) && "prediction" %in% names(result) &&
    "linear_lower" %in% names(result)
  prediction<-if(band)result$prediction else result
  .etr_scientific_frame_fields(prediction,
    c("profile_ids","reference","linear_predictor_functions",
      "linear_predictor_standard_errors","mean_functions",
      "mean_standard_errors","prediction_scale","extrapolation_flags"),
    "prediction")
  .etr_scientific_frame_fields(prediction$reference,
    c("time","family","link"),"prediction reference")
  ids<-.etr_scientific_frame_ids(prediction$profile_ids,"profile_ids")
  time<-.etr_scientific_frame_time(prediction$reference$time)
  n<-length(ids);k<-length(time)
  for(nm in c("linear_predictor_functions",
    "linear_predictor_standard_errors","mean_functions",
    "mean_standard_errors")){
    .etr_scientific_frame_matrix(prediction[[nm]],n,k,nm,
      nonnegative=nm %in% c("linear_predictor_standard_errors",
        "mean_standard_errors"))
  }
  .etr_scientific_frame_vector(prediction$extrapolation_flags,n,
    "extrapolation_flags",logical=TRUE)
  family<-.etr_scientific_frame_string(
    prediction$reference$family,"family")
  link<-.etr_scientific_frame_string(prediction$reference$link,"link")
  scale<-.etr_scientific_frame_string(
    prediction$prediction_scale,"prediction_scale")
  out<-data.frame(profile_id=rep(ids,each=k),time=rep(time,n),
    linear_predictor=.etr_scientific_frame_row_major(
      prediction$linear_predictor_functions),
    linear_predictor_standard_error=.etr_scientific_frame_row_major(
      prediction$linear_predictor_standard_errors),
    mean=.etr_scientific_frame_row_major(prediction$mean_functions),
    mean_standard_error=.etr_scientific_frame_row_major(
      prediction$mean_standard_errors),
    family=family,link=link,prediction_scale=scale,
    rate=.etr_scientific_frame_optional(prediction$rate_functions,
      n,k,"rate_functions"),
    expected_count=.etr_scientific_frame_optional(
      prediction$expected_count_functions,n,k,"expected_count_functions"),
    exposure=.etr_scientific_frame_optional(
      prediction$exposure_profiles,n,k,"exposure_profiles"),
    extrapolation=rep(prediction$extrapolation_flags,each=k),
    stringsAsFactors=FALSE)
  if(band){
    .etr_scientific_frame_fields(result,c("linear_lower","linear_upper",
      "mean_lower","mean_upper","critical_values"),"prediction band")
    .etr_scientific_frame_band(result,prediction,n,k,
      c("linear_lower","linear_upper","mean_lower","mean_upper"))
    .etr_assert(all(result$linear_lower<=result$linear_upper) &&
      all(result$mean_lower<=result$mean_upper),
      "prediction lower must not exceed upper")
    out$linear_lower<-.etr_scientific_frame_row_major(result$linear_lower)
    out$linear_upper<-.etr_scientific_frame_row_major(result$linear_upper)
    out$mean_lower<-.etr_scientific_frame_row_major(result$mean_lower)
    out$mean_upper<-.etr_scientific_frame_row_major(result$mean_upper)
    out$critical_value<-rep(as.numeric(result$critical_values),each=k)
  }
  out
}

#' Observed-grid marginal mean-difference contrast table
#' @param result Explicit native mean-difference result referencing a
#'   prediction bootstrap, with response contrast inference provenance.
#' @return A source-schema-compatible contrast data frame.
#' @export
etr_generalized_function_on_scalar_mean_difference_frame <- function(result) {
  .etr_scientific_frame_fields(result,c("prediction_bootstrap",
    "estimate","standard_error","lower","upper","profile_a",
    "profile_b","critical_value","contrast_scale","inference_scale",
    "interval_exceeds_physical_bounds"))
  .etr_scientific_frame_fields(result$prediction_bootstrap,
    c("prediction"),"prediction_bootstrap")
  .etr_scientific_frame_fields(result$prediction_bootstrap$prediction,
    c("reference"),"prediction")
  .etr_scientific_frame_fields(
    result$prediction_bootstrap$prediction$reference,
    c("time"),"prediction reference")
  time<-.etr_scientific_frame_time(
    result$prediction_bootstrap$prediction$reference$time)
  n<-length(time)
  for(nm in c("estimate","standard_error","lower","upper"))
    .etr_scientific_frame_vector(result[[nm]],n,nm)
  .etr_assert(all(result$standard_error>=0) &&
    all(result$lower<=result$upper),
    "standard_error must be nonnegative and lower may not exceed upper")
  for(nm in c("profile_a","profile_b"))
    .etr_gfosr_predict_scalar(result[[nm]],nm)
  for(nm in c("contrast_scale","inference_scale"))
    .etr_scientific_frame_string(result[[nm]],nm)
  .etr_scientific_frame_vector(result$critical_value,1L,"critical_value")
  .etr_scientific_frame_vector(
    result$interval_exceeds_physical_bounds,1L,
    "interval_exceeds_physical_bounds",logical=TRUE)
  data.frame(time=time,estimate=as.numeric(result$estimate),
    standard_error=as.numeric(result$standard_error),
    lower=as.numeric(result$lower),upper=as.numeric(result$upper),
    profile_a=result$profile_a,profile_b=result$profile_b,
    critical_value=as.numeric(result$critical_value),
    contrast_scale=result$contrast_scale,
    inference_scale=result$inference_scale,
    interval_exceeds_physical_bounds=
      result$interval_exceeds_physical_bounds,
    stringsAsFactors=FALSE)
}

#' Explicit Poisson exposure audit for generalized function-on-scalar fits
#' @param result Native fit record with positive exposure matrix and
#'   declared source curve IDs and exposure provenance.
#' @return Per-curve exposure data frame with source-equivalent
#'   exposure_audit attribute.
#' @export
etr_generalized_function_on_scalar_exposure_frame <- function(result) {
  .etr_scientific_frame_fields(result,c("source_curve_ids","exposure",
    "exposure_units","exposure_expanded_from_curve"))
  ids<-.etr_scientific_frame_ids(result$source_curve_ids,"source_curve_ids")
  .etr_assert(!is.null(result$exposure),
    "the fitted model does not contain an exposure array")
  exposure<-result$exposure
  .etr_assert(is.matrix(exposure) && is.numeric(exposure) &&
    nrow(exposure)==length(ids) && ncol(exposure)>=2L &&
    all(is.finite(exposure)) && all(exposure>0),
    "exposure must be a finite strictly positive curve-by-time matrix")
  .etr_assert(is.logical(result$exposure_expanded_from_curve) &&
    length(result$exposure_expanded_from_curve)==1L &&
    !is.na(result$exposure_expanded_from_curve),
    "exposure_expanded_from_curve must be boolean")
  if(!is.null(result$exposure_units))
    .etr_gfosr_predict_scalar(result$exposure_units,"exposure_units")
  minima<-apply(exposure,1L,min);maxima<-apply(exposure,1L,max)
  varies<-apply(exposure,1L,function(v)any(v!=v[1L]))
  # Base-R data.frame has no Python None scalar column. The nullable source
  # string is encoded as NA_character_; this remains a documented gap.
  units<-if(is.null(result$exposure_units))NA_character_ else
    result$exposure_units
  out<-data.frame(curve_id=ids,minimum_exposure=minima,
    maximum_exposure=maxima,exposure_range=maxima-minima,
    exposure_ratio=maxima/minima,varies_over_time=varies,
    exposure_units=units,stringsAsFactors=FALSE)
  means<-rowMeans(exposure)
  attr(out,"exposure_audit")<-list(
    minimum_exposure=min(exposure),maximum_exposure=max(exposure),
    exposure_range=max(exposure)-min(exposure),
    extreme_exposure_ratio=max(exposure)/min(exposure),
    varies_over_time=any(varies),
    varies_between_curves=any(means!=means[1L]),
    exposure_units=if(is.null(result$exposure_units))NULL else
      result$exposure_units,
    exposure_expanded_from_curve=
      result$exposure_expanded_from_curve,
    exposure_observed_and_fixed=TRUE,
    exposure_measurement_uncertainty=FALSE)
  out
}
