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
  dimension<-.etr_python_workflow_identifier_repr(
    .etr_gfosr_predict_scalar(result$dimension_name,"dimension_name"))
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
          .etr_gfosr_predict_scalar(result$exposure_units,"exposure_units")
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
  paste0("Marginal generalized function-on-scalar regression modeled ",
    dimension," using a ",family," family with ",link,
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
  # Align the decimal points across the complete matrix, as array2string
  # does. Scientific notation uses equal mantissa and exponent widths.
  values<-as.vector(t(x))
  magnitude<-abs(values[values!=0])
  scientific<-length(magnitude)>0L&&(max(magnitude)>=1e8||
    min(magnitude)<1e-4||max(magnitude)/min(magnitude)>1e3)
  formatted<-sprintf(paste0("%#.",digits,if(scientific)"e"else"f"),values)
  mantissa<-sub("e.*$","",formatted)
  whole<-sub("\\..*$","",mantissa)
  fraction<-sub("0+$","",sub("^[^.]*\\.","",mantissa))
  left<-strrep(" ",max(nchar(whole))-nchar(whole))
  right_width<-max(nchar(fraction))-nchar(fraction)
  if(scientific){
    exponent<-as.integer(sub("^.*e","",formatted))
    exponent_width<-max(2L,nchar(abs(exponent)))+1L
    right<-paste0(strrep("0",right_width),"e",
      sprintf(paste0("%+0",exponent_width,"d"),exponent))
  }else right<-strrep(" ",right_width)
  fields<-paste0(left,whole,".",fraction,right)
  paste0("[[",fields[1L],", ",fields[2L],"],\n [",
    fields[3L],", ",fields[4L],"]]")
}

.etr_sparse_dimension_repr <- function(x) {
  vapply(x,function(value){
    quote<-if(grepl("'",value,fixed=TRUE)&&!grepl('"',value,fixed=TRUE))
      '"' else "'"
    encodeString(value,quote=quote)
  },character(1L),USE.NAMES=FALSE)
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
  dimensions<-.etr_scientific_frame_ids(result$dimensions,"dimensions")
  .etr_assert(length(dimensions)==2L,"exactly two planar dimension labels are required")
  dimensions<-.etr_sparse_dimension_repr(dimensions)
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
  paste0("Native sparse multivariate FPCA was fitted jointly to dimensions ",
    dimensions[1L]," and ",dimensions[2L]," for ",length(ids),
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


.etr_sparse_univariate_repr <- function(x,name) {
  if(is.null(x))return("None")
  paste0("'",.etr_source_text_word(x,name),"'")
}

.etr_sparse_async_workflow_report <- function(fit) {
  config <- fit$provenance$sparse_mfpca_async
  dimensions <- .etr_sparse_dimension_repr(fit$dimensions)
  psd <- fit$covariance_diagnostics
  status <- fit$score_diagnostics$status_code
  paste0(
    "Native asynchronous sparse planar MFPCA was fitted to dimensions ",
    dimensions[1L], " and ", dimensions[2L], " for ", length(fit$curve_ids),
    " curve(s), retaining ", fit$n_components, " joint component(s). ",
    "Coordinate-specific native timestamps were retained without ",
    "interpolation, nearest-neighbour synchronization, or time binning. ",
    "Separate coordinate means and direct Cxx/Cxy/Cyy latent covariance ",
    "surfaces used declared local-linear bandwidths ",
    .etr_python_json_float(config$mean_bandwidth), " and ",
    .etr_python_json_float(config$covariance_bandwidth), ". Cxy used asynchronous ",
    "x-y residual products and excluded ",
    config$cross_covariance_same_time_pair_count_excluded,
    " simultaneous cross-product(s) from latent covariance fitting. Cyx ",
    "was defined as Cxy transpose. The full joint operator used PSD action '",
    psd$requested_action, "' (applied='", psd$applied_action,
    "'; relative operator correction=",
    sprintf("%.3f", psd$relative_operator_correction_frobenius_norm),
    "). Measurement error used mode '", config$measurement_error_mode,
    "' with R_epsilon=", .etr_sparse_mfpca_numpy_2x2(fit$measurement_error_covariance, 3L),
    "; off-diagonal measurement-error covariance was added only for ",
    "simultaneous x/y observations. Asynchronous joint PACE used the full ",
    "fitted covariance plus measurement error and ridge=",
    .etr_python_json_float(config$score_ridge),
    ", never a rank-K covariance reconstruction. ", sum(status == "ok"),
    " curve(s) were scored successfully and ", sum(status != "ok"),
    " retained score-system failure(s) were recorded under failure_action='",
    config$score_failure_action, "'."
  )
}

.etr_sparse_multilevel_workflow_report <- function(fit) {
  psd <- fit$covariance_diagnostics
  paste0(
    "Native sparse multilevel FPCA modeled irregular trials as ",
    "Y_ij(t)=mu(t)+U_i(t)+V_ij(t)+epsilon_ij(t), with ",
    length(fit$participant_ids), " participants and ", length(fit$curve_ids),
    " trials. The grand mean used pooled native observations; total latent ",
    "covariance used within-trial off-diagonal products and between-participant ",
    "covariance used same-participant cross-trial products. The within-trial ",
    "operator was defined as smoothed total minus smoothed between covariance ",
    "before the declared PSD policy (between=", psd$between$applied_action,
    ", within=", psd$within$applied_action, "). Measurement-error variance was ",
    sprintf("%.3g", fit$noise_variance), ". Participant and trial scores were ",
    "recovered jointly by Gaussian BLUP using the full repaired between/within ",
    "covariance surfaces at native timestamps, not rank-truncated reconstructions. ",
    sum(fit$score_diagnostics$status_code != "ok"),
    " participant score systems failed under the declared policy. ",
    "The first sparse multilevel tranche assumes exchangeable repeated trials, ",
    "does not estimate trial-condition fixed functional effects, uses observation/",
    "raw-pair weighting rather than equal-participant weighting, does not ",
    "interpolate raw sparse trajectories, and does not propagate population-",
    "estimation or bandwidth uncertainty."
  )
}

.etr_sparse_conformal_workflow_report <- function(band) {
  calibration <- band$calibration
  unit <- if (is.null(calibration$group_column)) "curve" else "participant/group"
  paste0(
    "A split-conformal simultaneous prediction band was calibrated from ",
    calibration$n_calibration_units, " exchangeability unit(s) (", unit,
    ") at alpha=", sprintf("%.3f", calibration$alpha),
    ". Nonconformity was the maximum standardized absolute future residual ",
    "over the declared ", length(calibration$prediction_grid),
    "-point target grid, with critical value ",
    sprintf("%.3f", calibration$critical_value),
    ". Calibration responses were required to be actually observed at every ",
    "target-grid timestamp; no interpolation was used. The resulting coverage ",
    "interpretation is simultaneous for future observed measurements on that ",
    "declared finite grid under the exchangeability/grouping contract. ",
    "No continuous-domain or latent-function coverage claim is made."
  )
}

.etr_sparse_univariate_scalar <- function(x,name,zero=TRUE) {
  val<-.etr_source_text_number(x,name,min=if(zero)0 else .Machine$double.eps)
  format(val,scientific=FALSE,trim=TRUE)
}
.etr_sparse_univariate_bounds <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)==2L&&all(is.finite(x))&&
    x[1L]<x[2L],
    paste(name,"must declare finite increasing endpoints"))
  paste0("[",format(x[1L],scientific=FALSE,trim=TRUE),", ",
    format(x[2L],scientific=FALSE,trim=TRUE),"]")
}

#' Frozen-source sparse univariate PACE reporting for native or FDApy records
#' @param result Explicit sparse FPCA record with eigenvalues and recorded
#'   native or FDApy fitting diagnostics.
#' @param digits Decimal output precision for eigenvalue and PSD audit values.
#' @return Exact-source descriptive manuscript text on declared R domains.
#' @export
etr_sparse_fpca_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_scientific_frame_fields(result,c("dimension","n_components",
    "eigenvalues","provenance"),"sparse_fpca")
  dimension<-.etr_scientific_frame_ids(result$dimension,"dimension")
  .etr_assert(length(dimension)==1L,"dimension must be a single name")
  dimension<-.etr_sparse_dimension_repr(dimension)
  k<-.etr_source_text_int(result$n_components,"n_components",min=1L)
  eigen<-.etr_source_text_vector(result$eigenvalues,"eigenvalues")
  .etr_assert(length(eigen)==k&&all(eigen>=0),
    "eigenvalues must contain one nonnegative finite number per component")
  .etr_scientific_frame_fields(result$provenance,c("sparse_fpca"),
    "provenance")
  sparse<-result$provenance$sparse_fpca
  .etr_assert(is.list(sparse),"sparse_fpca provenance must be a list")
  count<-sparse$sample_counts
  if(is.null(count)||length(count)==0L)sample_range<-"not recorded"
  else{
    .etr_assert(is.numeric(count)&&all(is.finite(count))&&
      all(count>=0)&&all(count==floor(count)),
      "sample_counts must be nonnegative whole counts")
    sample_range<-paste0(min(count),"\u2013",max(count))
  }
  eigentext<-paste(vapply(eigen,function(x)
    .etr_manuscript_number(x,d),character(1L)),collapse=", ")
  grid<-sparse$evaluation_grid
  grid_text<-if(is.null(grid)||length(grid)==0L)
    "backend-default evaluation points" else {
      .etr_assert(is.numeric(grid)&&length(grid)>=2L&&
        all(is.finite(grid))&&all(diff(grid)>0),
        "evaluation_grid must be finite increasing values")
      paste0(length(grid)," points over [",
        format(grid[1L],scientific=FALSE,trim=TRUE),", ",
        format(tail(grid,1L),scientific=FALSE,trim=TRUE),"]")
    }
  if(identical(sparse$backend,"native")){
    psd<-sparse$covariance_psd
    if(is.null(psd))psd<-list()
    .etr_assert(is.list(psd),"covariance_psd must be a list")
    correction<-if(is.null(psd$applied_action))"unknown" else
      .etr_source_text_word(psd$applied_action,"applied_action")
    noise<-if(is.null(sparse$noise_variance_method))"unknown" else
      .etr_source_text_word(sparse$noise_variance_method,
        "noise_variance_method")
    ridge<-if(is.null(sparse$score_ridge))0 else
      .etr_source_text_number(sparse$score_ridge,"score_ridge",min=0)
    support_text<-""
    if(!is.null(sparse$analysis_support)){
      x<-.etr_sparse_univariate_bounds(
        sparse$analysis_support,"analysis_support")
      action<-if(is.null(sparse$analysis_support_action))"unknown" else
        .etr_source_text_word(sparse$analysis_support_action,
          "analysis_support_action")
      outside<-if(is.null(sparse$outside_observation_count))0L else
        .etr_source_text_int(sparse$outside_observation_count,
          "outside_observation_count")
      support_text<-paste0(" The declared analysis support was ",x,
        " with support action '",action,"'; ",outside,
        " observations lay outside it.")
    }
    noise_text<-if(is.null(sparse$noise_support))"" else paste0(
      " Diagonal-difference noise estimation used support ",
      .etr_sparse_univariate_bounds(sparse$noise_support,"noise_support"),".")
    relative<-psd$relative_operator_correction_frobenius_norm
    repair_text<-if(is.null(relative))"" else {
      rel<-.etr_source_text_number(relative,
        "relative_operator_correction_frobenius_norm",min=0)
      paste0(" The relative quadrature-weighted PSD-repair magnitude was ",
        sprintf(paste0("%.",d,"g"),rel),".")
    }
    score_text<-""
    diagnostics<-result$score_diagnostics
    if(!is.null(diagnostics)){
      .etr_assert(is.data.frame(diagnostics),
        "score_diagnostics must be a data frame")
      if(nrow(diagnostics)>0L){
        if("status_code"%in%names(diagnostics)){
          .etr_assert(!anyNA(diagnostics$status_code),
            "status_code cannot be missing")
          failed<-sum(as.character(diagnostics$status_code)!="ok")
          score_text<-paste0(score_text,
            " PACE scoring returned ",failed,
            " non-ok systems among ",nrow(diagnostics)," curves.")
        }
        if("condition_number"%in%names(diagnostics)){
          conditions<-suppressWarnings(as.numeric(
            diagnostics$condition_number))
          finite<-conditions[is.finite(conditions)&conditions>0]
          if(length(finite)>0L)
            score_text<-paste0(score_text,
              " The median finite conditional covariance condition ",
              "number was ",sprintf(paste0("%.",d,"g"),
                stats::median(finite)),".")
        }
      }
    }
    return(paste0(
      "Sparse univariate FPCA was fitted natively to the ",dimension,
      " trajectory dimension using explicit local-linear pooled mean ",
      "and covariance smoothing (",k," components; per-curve sample-count ",
      "range=",sample_range,"; retained eigenvalues=",eigentext,"). ",
      "Raw sparse trajectories were not interpolated to a common grid. ",
      "Population functions were represented on ",grid_text," and ",
      "evaluated at each curve's native observation times for PACE ",
      "scoring. The conditional score system used the full fitted ",
      "covariance surface plus measurement-error variance rather than ",
      "the retained-rank covariance reconstruction.",support_text,
      " Measurement-error variance used '",noise,"'.",noise_text,
      " Covariance PSD handling applied '",correction,
      "'; the declared score ridge was ",
      format(ridge,scientific=FALSE,trim=TRUE),".",repair_text,
      score_text," The analysis was univariate and did not model ",
      "cross-channel covariance."))
  }
  .etr_scientific_frame_fields(result,
    c("fit_smoothing","tolerance","score_smoothing"),
    "FDApy sparse FPCA")
  fit_text<-.etr_sparse_univariate_repr(result$fit_smoothing,
    "fit_smoothing")
  smooth_text<-.etr_sparse_univariate_repr(result$score_smoothing,
    "score_smoothing")
  tol<-.etr_sparse_univariate_scalar(result$tolerance,
    "tolerance")
  custom<-length(sparse$kwargs_mean)>0L||
    length(sparse$kwargs_covariance)>0L
  custom_text<-if(custom)
    " Custom mean/covariance smoothing parameters were supplied." else ""
  paste0(
    "Sparse univariate FPCA was fitted to the ",dimension,
    " trajectory dimension using FDApy's covariance-operator estimator, ",
    "with ",fit_text," fitting smoothness and PACE conditional-expectation ",
    "scores (",k," components; per-curve sample-count range=",
    sample_range,"; retained eigenvalues=",eigentext,
    "). eyetrajectoriespy did not pre-interpolate raw sparse curves ",
    "before passing them to FDApy; the FDApy irregular PACE backend ",
    "may smooth/interpolate internally as part of its score path. ",
    "Eigenfunctions/covariance were evaluated on ",grid_text,
    ". PACE tolerance was ",tol," and score smoothing was ",
    smooth_text,".",custom_text)
}
