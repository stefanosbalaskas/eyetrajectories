# Pinned Python 1.2.0 reporting for generalized FoSR, mixed-effects
# residuals and sparse multivariate PACE. Text output is descriptive only.
# Published source c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R-list and numeric format domains are intentionally narrower.

#' Generalized function-on-scalar marginal model interpretation
#' @param result Explicit native R fit record with model specification.
#' @param band Optional explicit coefficient bootstrap band record.
#' @return A pinned-source descriptive character scalar.
#' @export
etr_generalized_function_on_scalar_reporting_text <- function(result,
    band=NULL) {
  .etr_scientific_frame_fields(result,c("dimension_name","family","link",
    "basis_size"),"result")
  dimension<-.etr_source_text_word(result$dimension_name,"dimension_name")
  family<-.etr_source_text_word(result$family,"family")
  link<-.etr_source_text_word(result$link,"link")
  .etr_assert(family %in% c("poisson","binomial","gaussian"),
    "family must be a declared generalized FoSR family")
  basis<-.etr_source_text_int(result$basis_size,"basis_size",min=1L)
  if(!is.null(band)){
    .etr_scientific_frame_fields(band,c("reference","confidence_level",
      "simultaneous_scope","bootstrap"),"band")
    .etr_assert(identical(band$reference,result),
      "band.reference must be the supplied result record")
    .etr_scientific_frame_fields(band$bootstrap,
      c("bootstrap_coefficient_functions"),"bootstrap")
    draws<-band$bootstrap$bootstrap_coefficient_functions
    .etr_assert(is.array(draws)&&length(dim(draws))==3L&&
      dim(draws)[1L]>=1L&&is.numeric(draws)&&all(is.finite(draws)),
      "bootstrap coefficient functions must contain finite refits")
    level<-.etr_source_text_number(band$confidence_level,
      "confidence_level",min=0,max=1)
    .etr_assert(level>0&&level<1,"confidence_level must be in (0,1)")
    scope<-.etr_source_text_word(band$simultaneous_scope,
      "simultaneous_scope")
    band_text<-paste0(" A ",sprintf("%.1f",100*level),
      "% observed-grid ",scope,
      "-simultaneous coefficient band was calibrated on the link scale ",
      "using whole-participant case bootstrap refits (",
      dim(draws)[1L]," replicates).")
  } else band_text<-" No simultaneous coefficient band was requested."
  grouped<-if(identical(family,"binomial") &&
    !is.null(result$binomial_denominators))
    paste0(" The response was modeled as explicit grouped-binomial ",
      "integer success counts with observed integer denominators; the ",
      "backend used success proportions with denominator weights. ",
      "Coefficients therefore describe marginal log odds of success. ",
      "Denominators were treated as observed and fixed, were not ",
      "inferred, and their measurement uncertainty was not modeled.")
    else ""
  exposure_text<-""
  if(identical(family,"poisson")){
    if(!is.null(result$exposure)){
      .etr_assert(is.matrix(result$exposure) &&
        is.numeric(result$exposure) && all(is.finite(result$exposure)) &&
        all(result$exposure>0),
        "exposure must be a positive finite numeric matrix")
      units<-if(is.null(result$exposure_units) ||
        identical(result$exposure_units,""))"units not declared" else
          .etr_source_text_word(result$exposure_units,"exposure_units")
      exposure_text<-paste0(
        " A strictly positive observed exposure was included explicitly (",
        units,"); coefficients therefore describe marginal log rates and ",
        "exponentiated coefficients are rate ratios holding exposure fixed. ",
        "Exposure was treated as observed and fixed, was not inferred, and ",
        "measurement uncertainty in exposure was not modeled.")
    } else exposure_text<-paste0(
      " No exposure was supplied, so Poisson coefficients describe ",
      "marginal log expected counts rather than rates.")
  }
  paste0("Marginal generalized function-on-scalar regression modeled '",
    dimension,"' using a ",family," family with ",link,
    " link and ",basis,
    " clamped B-spline basis functions per coefficient. Participants ",
    "were treated as independent clusters and within-participant ",
    "observations were fit with working independence; coefficient ",
    "uncertainty used the robust GEE sandwich covariance. Coefficients ",
    "therefore have a population-averaged marginal interpretation on the ",
    "link scale, not a conditional random-effects interpretation. No ",
    "working correlation, smoothing penalty, exposure definition, family, ",
    "link, or model was selected automatically.",
    grouped,exposure_text,band_text)
}

#' Descriptive residual-correlation diagnostics for functional mixed effects
#' @param result Native result record with trial diagnostics, declared
#'   residual scale, source model and maximum index lag.
#' @return One manuscript-oriented character scalar; no model selection.
#' @export
etr_functional_mixed_effects_residual_reporting_text <- function(result) {
  .etr_scientific_frame_fields(result,c("trial_diagnostics",
    "reference","residual_scale","max_lag"),"result")
  .etr_scientific_frame_fields(result$reference,
    c("random_slope_predictor","time_unit"),"reference")
  trials<-result$trial_diagnostics
  .etr_assert(is.data.frame(trials)&&
    all(c("lag_index","zero_residual_variance")%in%names(trials)) &&
    is.numeric(trials$lag_index) &&
    all(is.finite(trials$lag_index)) &&
    all(trials$lag_index>=0L) &&
    all(trials$lag_index==floor(trials$lag_index)) &&
    is.logical(trials$zero_residual_variance) &&
    !anyNA(trials$zero_residual_variance),
    "trial_diagnostics must retain finite index lags and zero-variance flags")
  max_lag<-.etr_source_text_int(result$max_lag,"max_lag")
  .etr_assert(any(trials$lag_index==0L),
    "trial_diagnostics requires lag-zero residual observations")
  .etr_assert(all(trials$lag_index<=max_lag),
    "trial_diagnostics lag_index exceeds declared maximum")
  zero<-sum(trials$zero_residual_variance[trials$lag_index==0L])
  scale<-.etr_source_text_word(result$residual_scale,"residual_scale")
  .etr_assert(scale%in%c("raw","whitened"),
    "residual_scale must be raw or whitened")
  slope<-result$reference$random_slope_predictor
  if(!is.null(slope))slope<-.etr_source_text_word(slope,
    "random_slope_predictor")
  unit<-.etr_source_text_word(result$reference$time_unit,"time_unit")
  structure<-if(is.null(slope))"random functional intercept only" else
    paste0("random functional intercept plus the declared random ",
      "functional slope for '",slope,"'")
  scale_text<-if(scale=="raw")"raw conditional residual functions" else
    paste0("conditional residual functions whitened within each trial ",
      "by the fitted residual covariance Cholesky factor")
  whitening<-if(scale=="raw")"" else
    paste0(" Whitening targets the declared residual covariance only; ",
      "fitted random effects and parameter uncertainty remain ",
      "conditioned on their estimates.")
  # The source repeats "residual functions from the converged ..."
  # verbatim; this is intentionally retained for exact-source parity.
  paste0("Within-trial residual dependence was inspected using the ",
    scale_text," from the converged functional mixed-effects fit ",
    "residual functions from the converged functional mixed-effects fit ",
    "(",structure,"). Diagnostics were computed through the explicitly ",
    "declared maximum index lag ",max_lag,
    ". For each trial, residuals were centered within trial before ",
    "calculating autocovariance and autocorrelation; empirical ",
    "semivariance used one-half of the mean squared residual difference ",
    "at each lag. The observed common time grid was retained in '",
    unit,"'; index lags retain their mean/minimum/maximum physical ",
    "separations and no physical-lag binning was performed. Participant ",
    "and overall summaries are descriptive pair-count-weighted summaries ",
    "of trial-level diagnostics. ",zero,
    " trial(s) had exactly zero residual variance; such trials were ",
    "retained and their autocorrelation was marked undefined. These ",
    "diagnostics do not automatically select AR(1), a trial-level ",
    "functional random effect, or any other residual covariance structure.",
    whitening)
}

.etr_sparse_mfpca_numpy_2x2 <- function(x,digits) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    identical(dim(x),c(2L,2L))&&all(is.finite(x)),
    "measurement_error_covariance must be a finite 2-by-2 matrix")
  .etr_assert(all(abs(x)<1e4)&&all(x==0 | abs(x)>=1e-3),
    "measurement_error_covariance source rendering is restricted to ordinary decimal magnitudes")
  # Python array2string(precision=3) prints decimal integers with a dot.
  f<-function(v){
    value<-format(round(v,digits),scientific=FALSE,trim=TRUE,
      nsmall=0L)
    if(!grepl(".",value,fixed=TRUE))paste0(value,".") else value
  }
  rows<-apply(x,1L,function(v)paste(vapply(v,f,character(1L)),
    collapse=", "))
  paste0("[[",rows[1L],"],\n [",rows[2L],"]]")
}

#' Reporting for explicitly audited native sparse multivariate PACE
#' @param result Native sparse MFPCA record with quadrature score,
#'   measurement error, covariance PSD and bandwidth audit fields.
#' @param digits Decimal precision for recorded measurement error and repair.
#' @return Source-aligned narrative, without fitting or inference.
#' @export
etr_sparse_mfpca_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_scientific_frame_fields(result,c("dimensions","curve_ids",
    "n_components","score_diagnostics","covariance_diagnostics",
    "measurement_error_covariance","provenance"))
  dimensions<-.etr_source_text_names(result$dimensions,"dimensions")
  .etr_assert(length(dimensions)==2L,"exactly two planar dimension labels are required")
  ids<-.etr_scientific_frame_ids(result$curve_ids,"curve_ids")
  k<-.etr_source_text_int(result$n_components,"n_components",min=1L)
  diagnostics<-result$score_diagnostics
  .etr_assert(is.data.frame(diagnostics)&&
    "status_code"%in%names(diagnostics)&&
    nrow(diagnostics)==length(ids)&&!anyNA(diagnostics$status_code),
    "score_diagnostics must contain a status per source curve")
  status<-as.character(diagnostics$status_code)
  .etr_assert(all(nzchar(status)), "status_code must be nonempty")
  success<-sum(status=="ok");failed<-sum(status!="ok")
  .etr_scientific_frame_fields(result$provenance,c("sparse_mfpca"),
    "provenance")
  config<-result$provenance$sparse_mfpca
  .etr_scientific_frame_fields(config,c("mean_bandwidth",
    "covariance_bandwidth","measurement_error_mode","score_ridge",
    "score_failure_action"),"sparse_mfpca provenance")
  mean_band<-.etr_source_text_number(config$mean_bandwidth,
    "mean_bandwidth",min=0)
  cov_band<-.etr_source_text_number(config$covariance_bandwidth,
    "covariance_bandwidth",min=0)
  ridge<-.etr_source_text_number(config$score_ridge,
    "score_ridge",min=0)
  mode<-.etr_source_text_word(config$measurement_error_mode,
    "measurement_error_mode")
  failure<-.etr_source_text_word(config$score_failure_action,
    "score_failure_action")
  psd<-result$covariance_diagnostics
  .etr_scientific_frame_fields(psd,c("requested_action",
    "applied_action","correction_frobenius_norm"),
    "covariance_diagnostics")
  requested<-.etr_source_text_word(psd$requested_action,"requested_action")
  applied<-.etr_source_text_word(psd$applied_action,"applied_action")
  repair<-.etr_source_text_number(psd$correction_frobenius_norm,
    "correction_frobenius_norm",min=0)
  error_text<-.etr_sparse_mfpca_numpy_2x2(
    result$measurement_error_covariance,d)
  paste0("Native sparse multivariate FPCA was fitted jointly to dimensions '",
    dimensions[1L],"' and '",dimensions[2L],"' for ",length(ids),
    " curve(s), retaining ",k," joint component(s). The vector mean ",
    "and direct Cxx/Cxy/Cyy latent covariance surfaces used declared ",
    "local-linear bandwidths ",mean_band," and ",cov_band,
    "; all latent covariance products excluded same-time pairs. Cxy ",
    "was fitted directionally, was not self-symmetrized, and Cyx was ",
    "defined as its transpose. The full joint operator used PSD action '",
    requested,"' (applied='",applied,
    "'; correction Frobenius norm=",
    .etr_manuscript_number(repair,d),
    "). Measurement error used mode '",mode,"' with R_epsilon=",
    error_text,". Joint PACE scores used the full fitted joint covariance ",
    "plus measurement error and ridge=",ridge,
    ", never a rank-K covariance reconstruction. ",success,
    " curve(s) were scored successfully and ",failed,
    " retained score-system failure(s) were recorded under failure_action='",
    failure,"'. Raw sparse trajectories were not pre-interpolated; ",
    "population functions were evaluated at retained native times.")
}
