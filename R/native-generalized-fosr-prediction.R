# Frozen source: eyetrajectoriespy 1.2.0,
# generalized_function_on_scalar_prediction.py, c1cd95ad718327550f7e55393ff38582872f7a94.
# Fixed profile predictions only; no participant resampling or model fitting.
# Python dataclass identity/pandas coercion and upstream GEE estimator parity
# are separate source-contract differences, not silently approved here.

.etr_gfosr_predict_scalar <- function(x,name) {
  .etr_assert(is.character(x)&&length(x)==1L&&!is.na(x)&&nzchar(x),
    paste(name,"must be a nonempty string"))
  x
}

.etr_gfosr_predict_numeric_matrix <- function(x,n,k,name) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    nrow(x)==n&&ncol(x)==k&&all(is.finite(x)),
    paste(name,"must be a finite",n,"by",k,"numeric matrix"))
  x
}

# Pandas to_numeric accepts Boolean and decimal text columns. NumPy's
# separate float conversion for exposure also accepts digit underscores.
.etr_gfosr_numeric_values <- function(x,name,numpy=FALSE) {
  if(is.factor(x))x<-as.character(x)
  if(is.numeric(x)&&!is.complex(x))return(x)
  if(is.logical(x))return(as.numeric(x))
  .etr_assert(is.character(x),
    paste(name,"must be finite numeric or numeric-compatible text"))
  raw<-trimws(x,whitespace="[ \\t\\r\\n\\f\\v]")
  digits<-if(numpy)"[0-9](?:_?[0-9])*" else "[0-9]+"
  decimal<-paste0("^[+-]?(?:",digits,"(?:\\.(?:",digits,")?)?|\\.",
    digits,")(?:[eE][+-]?",digits,")?$")
  special<-if(numpy)"^[+-]?(?:inf(?:inity)?|nan)$" else "^[+-]?inf(?:inity)?$"
  .etr_assert(all(is.na(raw)|grepl(decimal,raw,perl=TRUE)|
    grepl(special,raw,ignore.case=TRUE,perl=TRUE)|(!numpy&x=="")),
    paste(name,"must be finite numeric or numeric-compatible text"))
  if(numpy)raw<-gsub("_","",raw,fixed=TRUE)
  suppressWarnings(as.numeric(raw))
}

.etr_gfosr_pandas_labels <- function(x,name) {
  .etr_assert(is.null(dim(x))&&!anyNA(x)&&
    (is.character(x)||is.factor(x)||is.logical(x)||
      (is.numeric(x)&&!is.complex(x))),
    paste(name,"must be a nonmissing vector of scalar labels"))
  labels<-as.character(x)
  if(is.logical(x))labels<-ifelse(x,"True","False")
  if(is.double(x)&&!is.object(x)){
    finite<-is.finite(x)
    labels[finite]<-vapply(x[finite],.etr_python_json_float,character(1L))
    labels[x==Inf]<-"inf"
    labels[x==-Inf]<-"-inf"
  }
  labels
}

.etr_gfosr_predict_inverse_link <- function(eta,family) {
  if(family=="binomial") {
    # Stable expit for large positive and negative linear predictors.
    positive<-eta>=0
    ans<-eta
    ans[positive]<-1/(1+exp(-eta[positive]))
    e<-exp(eta[!positive])
    ans[!positive]<-e/(1+e)
    return(ans)
  }
  ans<-exp(eta)
  .etr_assert(all(is.finite(ans)),
    "Poisson marginal mean prediction overflowed on the declared profile(s)")
  ans
}

#' Fixed marginal generalized function-on-scalar profile prediction
#'
#' Native R prediction from pre-fitted generalized FoSR coefficients, with
#' robust covariance on the observed time grid. Target profiles are not
#' selected, recentered, encoded or resampled. Extrapolations are retained.
#' @param result Explicit native source-shaped generalized FoSR fit record.
#' @param profiles Data frame with exactly profile_id_column and declared
#'   predictors, in their original scale. Numeric text and logical
#'   predictor values follow the source's numeric conversion.
#' @param profile_id_column Name of the unique target identifier column.
#' @param exposure_profiles Positive Poisson target exposure vector or matrix.
#' @param prediction_scale Source rate, expected_count or probability scale.
#' @param python_boundary_mode Use pandas-style text conversion for
#'   Boolean and floating-point profile identifiers.
#' @return Source-field-ordered native R prediction record. Cross-language
#'   class and upstream estimator equivalence are not yet certified.
#' @export
etr_generalized_function_on_scalar_predict <- function(
    result,profiles,profile_id_column="profile_id",
    exposure_profiles=NULL,prediction_scale=NULL,python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode)&&length(python_boundary_mode)==1L&&
    !is.na(python_boundary_mode),"python_boundary_mode must be TRUE or FALSE")
  .etr_scientific_frame_fields(result,c("time","family","link",
    "predictor_names","basis","basis_coefficients",
    "parameter_covariance","scalar_design_matrix"),
    "generalized FoSR fit")
  time<-.etr_scientific_frame_time(result$time)
  family<-.etr_gfosr_predict_scalar(result$family,"family")
  .etr_assert(family%in%c("binomial","poisson"),
    "family must be binomial or poisson")
  link<-.etr_gfosr_predict_scalar(result$link,"link")
  .etr_assert(identical(link,if(family=="binomial")"logit" else "log"),
    "family and link must agree with the frozen source")
  predictors<-result$predictor_names
  .etr_assert(is.character(predictors)&&length(predictors)>0L&&
    !anyNA(predictors)&&all(nzchar(predictors))&&
    !anyDuplicated(predictors),"predictor_names must be unique nonempty names")
  p<-length(predictors)
  .etr_assert(is.data.frame(profiles)&&nrow(profiles)>=1L&&
    !anyDuplicated(names(profiles)),
    "profiles must be a nonempty data frame with distinct columns")
  profile_id_column<-.etr_gfosr_predict_scalar(
    profile_id_column,"profile_id_column")
  .etr_assert(!profile_id_column%in%predictors,
    "profile_id_column must not reuse a declared predictor name")
  expected<-c(profile_id_column,predictors)
  .etr_assert(length(names(profiles))==length(expected)&&
    setequal(names(profiles),expected),
    "profiles must contain exactly the profile id plus declared predictors")
  ids<-if(python_boundary_mode)
    .etr_gfosr_pandas_labels(profiles[[profile_id_column]],"profile identifiers")
    else as.character(profiles[[profile_id_column]])
  .etr_assert(length(ids)==nrow(profiles)&&!anyNA(ids)&&
    all(nzchar(ids))&&!anyDuplicated(ids),
    "profile identifiers must be nonmissing, unique and nonempty")
  x<-matrix(NA_real_,nrow(profiles),p)
  for(j in seq_len(p)){
    v<-profiles[[predictors[[j]]]]
    label<-paste("profile predictor",predictors[[j]])
    .etr_assert(is.null(dim(v))&&length(v)==nrow(profiles),
      paste(label,"must have one finite numeric value per profile"))
    v<-.etr_gfosr_numeric_values(v,label)
    .etr_assert(all(is.finite(v)),paste(label,"must be finite numeric"))
    x[,j]<-v
  }
  n<-length(ids);nt<-length(time)
  basis<-result$basis
  .etr_assert(is.matrix(basis)&&is.numeric(basis)&&
    nrow(basis)==nt&&ncol(basis)>=1L&&all(is.finite(basis)),
    "basis must be a finite time-by-basis matrix")
  k<-ncol(basis);nc<-p+1L
  coefs<-.etr_gfosr_predict_numeric_matrix(result$basis_coefficients,
    nc,k,"basis_coefficients")
  covariance<-.etr_gfosr_predict_numeric_matrix(
    result$parameter_covariance,nc*k,nc*k,"parameter_covariance")
  observed<-result$scalar_design_matrix
  .etr_assert(is.matrix(observed)&&is.numeric(observed)&&
    nrow(observed)>=1L&&ncol(observed)==nc&&
    all(is.finite(observed)),
    "scalar_design_matrix must contain finite observed predictor values")
  .etr_assert(isTRUE(all(abs(observed[,1L]-1)<1e-12)),
    "scalar_design_matrix must include the intercept in its first column")
  .etr_assert(is.null(prediction_scale)||
    (is.character(prediction_scale)&&length(prediction_scale)==1L&&
     !is.na(prediction_scale)), "prediction_scale must be a single string or NULL")
  exposed<-!is.null(result$exposure)
  if(!is.null(exposure_profiles)){
    .etr_assert(family=="poisson"&&exposed,
      "exposure_profiles require an exposure-adjusted Poisson fit")
  }
  target_exposure<-NULL
  target_log_exposure<-NULL
  if(!is.null(exposure_profiles)){
    target_exposure<-.etr_native_generalized_response_array(
      exposure_profiles,n,nt,"exposure_profiles",positive=TRUE)
    target_log_exposure<-log(target_exposure)
  }
  selected_scale<-NULL
  if(family=="binomial"){
    .etr_assert(is.null(prediction_scale)||
      identical(prediction_scale,"probability"),
      "binomial prediction_scale must be probability or NULL")
    selected_scale<-"probability"
  }else if(!exposed){
    .etr_assert(is.null(prediction_scale)||
      identical(prediction_scale,"expected_count"),
      "Poisson fit without exposure supports expected_count only")
    selected_scale<-"expected_count"
  }else{
    selected_scale<-if(is.null(prediction_scale))"rate" else prediction_scale
    .etr_assert(selected_scale%in%c("rate","expected_count"),
      "Poisson exposure prediction_scale must be rate or expected_count")
    .etr_assert(!(selected_scale=="rate"&&!is.null(target_exposure)),
      "exposure_profiles must be omitted for rate predictions")
    .etr_assert(!(selected_scale=="expected_count"&&
      is.null(target_exposure)),
      "expected_count prediction requires explicit exposure_profiles")
  }
  scalar_design<-cbind(Intercept=rep(1,n),x)
  colnames(scalar_design)<-c("Intercept",predictors)
  # Python _fixed_effect_design stacks each coefficient's B-spline block
  # after repeating the observed time grid for each declared target.
  rows<-rep(seq_len(nt),times=n)
  expanded<-do.call(cbind,lapply(seq_len(nc),function(j)
    basis[rows,,drop=FALSE]*rep(scalar_design[,j],each=nt)))
  coefficient_vector<-as.vector(t(coefs))
  linear_rate<-matrix(as.numeric(expanded%*%coefficient_vector),
    nrow=n,ncol=nt,byrow=TRUE)
  linear<-if(selected_scale=="expected_count"&&
      !is.null(target_log_exposure))
    linear_rate+target_log_exposure else linear_rate
  variance<-rowSums((expanded%*%covariance)*expanded)
  .etr_assert(all(is.finite(variance)),
    "parameter covariance generated nonfinite prediction variances")
  linear_se<-matrix(sqrt(pmax(variance,0)),nrow=n,ncol=nt,
    byrow=TRUE)
  mean<-.etr_gfosr_predict_inverse_link(linear,family)
  rate<-if(family=="poisson"&&exposed)
    .etr_gfosr_predict_inverse_link(linear_rate,"poisson") else NULL
  expected_count<-if(family=="poisson"&&selected_scale=="expected_count")
    mean else NULL
  derivative<-if(family=="binomial")mean*(1-mean) else mean
  mean_se<-derivative*linear_se
  .etr_assert(all(is.finite(linear_se))&&all(is.finite(mean_se)),
    "prediction standard errors must remain finite")
  minima<-apply(observed[,-1L,drop=FALSE],2L,min)
  maxima<-apply(observed[,-1L,drop=FALSE],2L,max)
  tolerance<-1e-12*pmax(1,pmax(abs(minima),abs(maxima)))
  extrapolation<-vapply(seq_len(n),function(i)
    any(x[i,]<minima-tolerance|x[i,]>maxima+tolerance),
    logical(1L))
  provenance<-result$provenance
  if(is.null(provenance))provenance<-list()
  .etr_assert(is.list(provenance)&&
    (length(provenance)==0L||
      (!is.null(names(provenance))&&
       !anyNA(names(provenance))&&all(nzchar(names(provenance))))),
    "provenance must be a named record")
  provenance[["generalized_function_on_scalar_prediction"]]<-list(
    method="fixed_profile_marginal_prediction",
    profile_id_column=profile_id_column,profile_ids=ids,n_profiles=n,
    predictors=predictors,profile_values_fixed=TRUE,
    profile_values_resampled=FALSE,categorical_encoding=FALSE,
    predictor_centering=FALSE,predictor_scaling=FALSE,
    marginal_population_averaged_interpretation=TRUE,
    linear_predictor_scale=link,mean_scale=selected_scale,
    poisson_rate_estimand=family=="poisson"&&exposed,
    target_exposure_supplied=!is.null(target_exposure),
    target_exposure_assumed_unit=FALSE,
    pointwise_linear_predictor_standard_error=
      "delta_from_gee_robust_parameter_covariance",
    pointwise_mean_standard_error="inverse_link_delta_method",
    predictor_minima=as.numeric(minima),
    predictor_maxima=as.numeric(maxima),
    extrapolation_flags=as.logical(extrapolation),
    extrapolated_profiles_retained=TRUE,
    automatic_profile_selection=FALSE,simultaneous_inference=FALSE)
  structure(list(reference=result,profile_ids=ids,
    profile_design_matrix=scalar_design,predictor_values=x,
    linear_predictor_functions=linear,
    linear_predictor_standard_errors=linear_se,
    mean_functions=mean,mean_standard_errors=mean_se,
    extrapolation_flags=extrapolation,predictor_minima=as.numeric(minima),
    predictor_maxima=as.numeric(maxima),prediction_scale=selected_scale,
    exposure_profiles=target_exposure,
    log_exposure_profiles=target_log_exposure,
    rate_functions=rate,expected_count_functions=expected_count,
    linear_predictor_rate=if(family=="poisson")linear_rate else NULL,
    linear_predictor_count=if(family=="poisson"&&
      selected_scale=="expected_count")linear else NULL,
    provenance=provenance),class="etr_generalized_fosr_prediction")
}
