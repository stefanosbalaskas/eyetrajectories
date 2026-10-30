# Native manuscript wording for published Python 1.2.0 inference summaries.
# Source: eyetrajectoriespy/reporting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# This is a declared R-list subset, NOT Python dataclass identity parity.
# No scientific calibration, estimator fitting or automatic model selection.
.etr_inference_report_fields <- function(x,fields,what="result") {
  .etr_assert(is.list(x) && !is.data.frame(x) &&
    all(fields %in% names(x)),
    paste0(what," must contain: ",paste(fields,collapse=", ")))
}
.etr_inference_report_numeric <- function(x,what,min_length=1L) {
  .etr_assert(is.numeric(x) && length(x)>=min_length &&
    all(is.finite(x)),paste0(what," must contain finite numeric values"))
  as.numeric(x)
}
.etr_inference_report_integer <- function(x,what,minimum=1L) {
  .etr_assert(is.numeric(x) && !is.logical(x) && length(x)==1L &&
    is.finite(x) && x==floor(x) && x>=minimum,
    paste0(what," must be an integer >= ",minimum))
  as.integer(x)
}
.etr_inference_report_level <- function(x,what) {
  .etr_assert(is.numeric(x) && length(x)==1L && is.finite(x) &&
    x>0 && x<1,paste0(what," must be between 0 and 1"))
  as.numeric(x)
}
.etr_inference_report_word <- function(x,what) {
  .etr_assert(is.character(x) && length(x)==1L && !is.na(x) &&
    grepl("^[A-Za-z0-9_]+$",x),
    paste0(what," must be a simple unquoted identifier"))
  x
}
.etr_inference_report_bounds <- function(lower,upper,what) {
  lo<-.etr_inference_report_numeric(lower,paste0(what," lower"))
  hi<-.etr_inference_report_numeric(upper,paste0(what," upper"))
  .etr_assert(identical(dim(lower),dim(upper)) &&
    length(lo)==length(hi) && all(lo<=hi),
    paste0(what," bounds must have matching shape and lower <= upper"))
  invisible(TRUE)
}
.etr_inference_report_f <- function(value,digits) {
  sprintf(paste0("%.",digits,"f"),value)
}

#' Native text for fixed-target FPCR wild-bootstrap projection uncertainty
#' @param result Explicit named-list source-aligned result record.
#' @param digits Nonnegative display precision.
#' @return Descriptive character scalar; not a confidence calibration.
#' @export
etr_fpca_wild_bootstrap_projection_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("upper","lower","reference_se",
    "n_bootstrap","multiplier","residual_components","inference_components",
    "confidence_level","independent_unit_column"))
  .etr_inference_report_bounds(result$lower,result$upper,"projection")
  .etr_inference_report_numeric(result$reference_se,"reference_se")
  .etr_assert(length(result$upper)==length(result$reference_se),
    "reference_se must match target intervals")
  b<-.etr_inference_report_integer(result$n_bootstrap,"n_bootstrap")
  k<-.etr_inference_report_integer(result$residual_components,
    "residual_components")
  h<-.etr_inference_report_integer(result$inference_components,
    "inference_components")
  multiplier<-.etr_inference_report_word(result$multiplier,"multiplier")
  level<-.etr_inference_report_level(result$confidence_level,
    "confidence_level")
  unit<-result$independent_unit_column
  .etr_assert(is.null(unit) ||
    (is.character(unit)&&length(unit)==1L&&!is.na(unit)&&
      grepl("^[A-Za-z0-9_]+$",unit)),
    "independent_unit_column must be NULL or a simple identifier")
  unit_note<-if(is.null(unit))
    " Curve rows were assumed to be independent sampling units." else
    paste0(" Independence was declared by unique values of '",unit,"'.")
  paste0("Centered Gaussian FPCR projections were evaluated with ",b,
    " fixed-regressor multiplier wild-bootstrap replicates using '",
    multiplier,"' multipliers. Residuals and the bootstrap pseudo-truth ",
    "used k=g=",k," FPCs, while target inference used h=",h," FPCs. ",
    "Each bootstrap root was studentized with a bootstrap-level ",
    "heteroscedastic score-covariance scale. The ",
    sprintf("%.1f",100*level),"% target-wise symmetrized intervals had ",
    "median reference SE=",
    .etr_inference_report_f(stats::median(result$reference_se),d),
    " and median width=",
    .etr_inference_report_f(stats::median(result$upper-result$lower),d),
    ".",unit_note," The estimand is the centered projection relative to ",
    "the training functional mean; these are not future-outcome prediction ",
    "intervals, not clustered wild bootstrap intervals, and not ",
    "simultaneous across targets.")
}

#' Native text for future noisy-outcome FPCR prediction intervals
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_regression_future_prediction_reporting_text <- function(
    result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("upper","lower",
    "centered_residuals","n_bootstrap","n_targets","confidence_level"))
  .etr_inference_report_bounds(result$lower,result$upper,"future prediction")
  .etr_inference_report_numeric(result$centered_residuals,
    "centered_residuals",min_length=2L)
  n<-.etr_inference_report_integer(result$n_targets,"n_targets")
  .etr_assert(length(result$upper)==n,"n_targets must match interval lengths")
  b<-.etr_inference_report_integer(result$n_bootstrap,"n_bootstrap")
  level<-.etr_inference_report_level(result$confidence_level,
    "confidence_level")
  paste0("Future scalar outcomes for ",n," fixed target trajectory(ies) ",
    "were summarized with ",sprintf("%.1f",100*level),
    "% marginal Gaussian FPCR prediction intervals. The predictive ",
    "distribution reused ",b," paired-bootstrap conditional-mean ",
    "predictions and added independent draws from the centered empirical ",
    "residual distribution of the full-sample FPCR fit (residual SD=",
    .etr_inference_report_f(stats::sd(result$centered_residuals),d),
    "; median predictive width=",
    .etr_inference_report_f(stats::median(result$upper-result$lower),d),
    "). Residual exchangeability and a common response-error ",
    "distribution across targets are assumed. The intervals are not ",
    "heteroscedasticity-robust and are not simultaneous or joint across ",
    "multiple target trajectories.")
}

#' Native text for paired-bootstrap conditional-mean FPCR uncertainty
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_regression_uncertainty_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("slope_upper","slope_lower",
    "prediction_upper","prediction_lower","n_bootstrap","n_components",
    "resampling_unit","scaling","level"))
  .etr_inference_report_bounds(result$slope_lower,result$slope_upper,"slope")
  .etr_inference_report_bounds(result$prediction_lower,
    result$prediction_upper,"conditional mean")
  b<-.etr_inference_report_integer(result$n_bootstrap,"n_bootstrap")
  k<-.etr_inference_report_integer(result$n_components,"n_components")
  level<-.etr_inference_report_level(result$level,"level")
  .etr_assert(identical(result$resampling_unit,"participant") ||
    identical(result$resampling_unit,"curve"),
    "resampling_unit must be participant or curve")
  scaling<-.etr_inference_report_word(result$scaling,"scaling")
  paste0("Gaussian scalar-on-function FPCR uncertainty was evaluated with ",
    b," paired ",result$resampling_unit,"-level bootstrap refits. ",
    "FPCA/MFPCA and the score regression were refitted in every replicate ",
    "using ",k," fixed component(s) and scaling='",scaling,"'. ",
    "Pointwise ",sprintf("%.1f",100*level),
    "% percentile envelopes were formed for the reconstructed functional ",
    "slope in the original trajectory units (median grid-point width=",
    .etr_inference_report_f(stats::median(result$slope_upper-
      result$slope_lower),d),
    "). Fixed-target response intervals summarize uncertainty in the ",
    "fitted conditional mean (median width=",
    .etr_inference_report_f(stats::median(result$prediction_upper-
      result$prediction_lower),d),
    "); they are not prediction intervals for future noisy outcomes. ",
    "Component count was not reselected inside bootstrap replicates, ",
    "and this routine does not implement the operator-scaled FPCR ",
    "hypothesis test from recent theory.")
}

#' Native text for observed-grid simultaneous FPCR slope bands
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_regression_slope_band_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("regression_uncertainty",
    "critical_values","confidence_level","simultaneous_scope"))
  .etr_inference_report_fields(result$regression_uncertainty,
    "reference_fpca","regression_uncertainty")
  .etr_inference_report_fields(
    result$regression_uncertainty$reference_fpca,"dimension_names",
    "reference_fpca")
  nms<-result$regression_uncertainty$reference_fpca$dimension_names
  vals<-.etr_inference_report_numeric(result$critical_values,
    "critical_values")
  .etr_assert(is.character(nms) && length(nms)==length(vals) &&
    !anyNA(nms) && all(nzchar(nms)) && !anyDuplicated(nms),
    "critical values must match distinct functional dimension names")
  .etr_assert(result$simultaneous_scope %in% c("global","per_dimension") &&
    length(result$simultaneous_scope)==1L,
    "simultaneous_scope must be global or per_dimension")
  level<-.etr_inference_report_level(result$confidence_level,
    "confidence_level")
  critical<-paste(paste0(nms,"=",
    .etr_inference_report_f(vals,d)),collapse=", ")
  scope<-if(result$simultaneous_scope=="global")
    "one maximum over the full observed time-by-dimension grid" else
    "a separate maximum over observed time within each functional dimension"
  paste0("A ",sprintf("%.1f",100*level),
    "% observed-grid simultaneous Gaussian FPCR slope band was ",
    "calibrated from the retained paired bootstrap slope refits using ",
    scope,". Studentized maximum-deviation critical value(s) were ",
    critical,". The band is simultaneous only over the sampled grid ",
    "represented in the fit and does not claim coverage between grid ",
    "points. This calibration reuses the 0.12 paired-bootstrap FPCR ",
    "distribution and is not the operator-scaled FPCR significance ",
    "test developed in recent asymptotic theory.")
}

#' Native reporting of nested FPCR model-selection performance
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_nested_regression_cv_reporting_text <- function(result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("outer_folds","outer_splits",
    "inner_splits","cv_unit","selection_rule","loss"))
  f<-result$outer_folds
  .etr_assert(is.data.frame(f) && nrow(f)>=2L &&
    all(c("loss","selected_n_components") %in% names(f)),
    "outer_folds must contain >=2 rows of loss and selected_n_components")
  loss<-.etr_inference_report_numeric(f$loss,"outer loss")
  selected<-.etr_inference_report_numeric(
    f$selected_n_components,"selected_n_components")
  .etr_assert(all(selected>=1 & selected==floor(selected)),
    "selected_n_components must be positive whole numbers")
  outer<-.etr_inference_report_integer(result$outer_splits,"outer_splits",2L)
  inner<-.etr_inference_report_integer(result$inner_splits,"inner_splits",2L)
  .etr_assert(nrow(f)==outer,"outer_folds must match outer_splits")
  .etr_assert(result$cv_unit %in% c("group","curve") &&
    length(result$cv_unit)==1L,"cv_unit must be group or curve")
  rule<-.etr_inference_report_word(result$selection_rule,"selection_rule")
  label<-.etr_inference_report_word(result$loss,"loss")
  counts<-table(as.integer(selected))
  summary<-paste(paste0(names(counts),"\u00d7",as.integer(counts)),
    collapse=", ")
  unit<-if(result$cv_unit=="group")"grouped" else "curve-level"
  paste0("Nested FPCA regression used ",outer," outer and ",inner,
    " inner ",unit," folds. Inner folds selected the retained FPC count ",
    "using the '",rule,"' rule; outer folds were untouched by ",
    "selection. Mean outer held-out ",label," was ",
    .etr_inference_report_f(mean(loss),d), " (SD=",
    .etr_inference_report_f(stats::sd(loss),d),
    "). Selected component counts across outer fits were ",summary,
    ". This outer loss estimates the complete selection-and-fit ",
    "pipeline rather than reusing the inner selection loss as ",
    "performance evidence.")
}

#' Native reporting of familywise fixed-target wild-bootstrap tests
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_wild_bootstrap_family_test_reporting_text <- function(
    result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("projection_result",
    "reject_familywise","n_targets","pvalue_correction",
    "significance_level","global_statistic","global_p_value"))
  .etr_inference_report_fields(result$projection_result,
    "n_bootstrap","projection_result")
  b<-.etr_inference_report_integer(
    result$projection_result$n_bootstrap,"n_bootstrap")
  n<-.etr_inference_report_integer(result$n_targets,"n_targets")
  .etr_assert(is.logical(result$reject_familywise) &&
    !anyNA(result$reject_familywise) &&
    length(result$reject_familywise)==n,
    "reject_familywise must be a complete logical vector per target")
  alpha<-.etr_inference_report_level(result$significance_level,
    "significance_level")
  v<-.etr_inference_report_numeric(result$global_statistic,
    "global_statistic")
  p<-.etr_inference_report_numeric(result$global_p_value,"global_p_value")
  .etr_assert(length(v)==1L && length(p)==1L && p>=0 && p<=1,
    "global statistic/p-value must be scalars and p within [0,1]")
  .etr_assert(result$pvalue_correction %in% c("plus_one","raw") &&
    length(result$pvalue_correction)==1L,
    "pvalue_correction must be plus_one or raw")
  correction<-if(result$pvalue_correction=="plus_one")
    "(exceedances + 1)/(B + 1)" else "empirical exceedance proportion"
  paste0("Two-sided fixed-target Gaussian FPCR projection hypotheses ",
    "were evaluated for a declared family of ",n,
    " target(s) using the exact studentized roots retained from ",b,
    " heteroscedastic wild-bootstrap replicates. Target-wise bootstrap ",
    "tail probabilities and single-step max-|t| adjusted values used ",
    correction,". At alpha=", .etr_inference_report_f(alpha,d),
    ", ",sum(result$reject_familywise)," target(s) were rejected after ",
    "familywise adjustment; the complete-family global max statistic ",
    "was ",.etr_inference_report_f(v,d)," with bootstrap p=",
    .etr_inference_report_f(p,d),". No second bootstrap was run. ",
    "The resampling distribution was not generated under an explicitly ",
    "imposed null, and strong family-wise error control for arbitrary ",
    "subsets of null hypotheses is not claimed without additional ",
    "subset-pivotality conditions. The tests concern fixed centered ",
    "projections, not future observed outcomes or clustered/repeated-",
    "participant inference.")
}

#' Native reporting of wild-bootstrap Monte Carlo diagnostic precision
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_wild_bootstrap_monte_carlo_reporting_text <- function(
    result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("family_test_result",
    "adjusted_decision_stable","n_bootstrap","confidence_level",
    "global_tail_probability","global_interval_lower",
    "global_interval_upper","n_targets"))
  .etr_inference_report_fields(result$family_test_result,
    "significance_level","family_test_result")
  n<-.etr_inference_report_integer(result$n_targets,"n_targets")
  b<-.etr_inference_report_integer(result$n_bootstrap,"n_bootstrap")
  .etr_assert(is.logical(result$adjusted_decision_stable) &&
    length(result$adjusted_decision_stable)==n &&
    !anyNA(result$adjusted_decision_stable),
    "adjusted_decision_stable must be complete logical values per target")
  level<-.etr_inference_report_level(result$confidence_level,
    "confidence_level")
  alpha<-.etr_inference_report_level(
    result$family_test_result$significance_level,"significance_level")
  vals<-vapply(c("global_tail_probability","global_interval_lower",
    "global_interval_upper"),function(x){
    z<-.etr_inference_report_numeric(result[[x]],x)
    .etr_assert(length(z)==1L && z>=0 && z<=1,paste0(x," must be a probability"))
    z
  },numeric(1L))
  .etr_assert(vals[2L]<=vals[1L] && vals[1L]<=vals[3L],
    "global Monte Carlo interval must contain the estimated probability")
  paste0("Finite-resample Monte Carlo precision was assessed for the ",
    "existing fixed-family wild-bootstrap test using the same ",b,
    " retained bootstrap replicates; no additional multipliers or model ",
    "fits were generated. Raw exceedance proportions were accompanied ",
    "by ",sprintf("%.1f",100*level),
    "% Clopper-Pearson exact binomial intervals and plug-in binomial ",
    "Monte Carlo standard errors. The global max-statistic exceedance ",
    "proportion was ",.etr_inference_report_f(vals[1L],d)," (",
    .etr_inference_report_f(vals[2L],d),", ",
    .etr_inference_report_f(vals[3L],d),"); ",
    sum(!result$adjusted_decision_stable)," of ",n,
    " maxT-adjusted target decision(s) were Monte-Carlo-sensitive at ",
    "alpha=", .etr_inference_report_f(alpha,d),
    ". These diagnostics quantify only finite-bootstrap simulation ",
    "precision. They do not replace the reported plus-one/raw test ",
    "p-values, reverse test decisions, quantify scientific sampling ",
    "uncertainty, add subset-pivotality or strong-FWER guarantees, or ",
    "address clustered/repeated-participant or component-selection uncertainty.")
}

#' Native reporting of simultaneous fixed-target wild-bootstrap intervals
#' @inheritParams etr_fpca_wild_bootstrap_projection_reporting_text
#' @export
etr_fpca_wild_bootstrap_simultaneous_reporting_text <- function(
    result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("projection_result","upper",
    "lower","confidence_level","n_targets","critical_value"))
  .etr_inference_report_fields(result$projection_result,
    c("n_bootstrap","residual_components","inference_components",
      "multiplier"),"projection_result")
  .etr_inference_report_bounds(result$lower,result$upper,"simultaneous")
  n<-.etr_inference_report_integer(result$n_targets,"n_targets")
  .etr_assert(length(result$lower)==n,"n_targets must match interval lengths")
  level<-.etr_inference_report_level(result$confidence_level,
    "confidence_level")
  critical<-.etr_inference_report_numeric(result$critical_value,
    "critical_value")
  .etr_assert(length(critical)==1L && critical>=0,
    "critical_value must be a nonnegative scalar")
  base<-result$projection_result
  b<-.etr_inference_report_integer(base$n_bootstrap,"n_bootstrap")
  k<-.etr_inference_report_integer(base$residual_components,
    "residual_components")
  h<-.etr_inference_report_integer(base$inference_components,
    "inference_components")
  multiplier<-.etr_inference_report_word(base$multiplier,"multiplier")
  paste0("A ",sprintf("%.1f",100*level),
    "% familywise simultaneous interval was calibrated across ",n,
    " fixed Gaussian FPCR target projection(s) by taking the bootstrap ",
    "distribution of the maximum absolute studentized root across ",
    "the complete target family. The resulting max-|t| critical value ",
    "was ",.etr_inference_report_f(critical,d),
    " and the median simultaneous width was ",
    .etr_inference_report_f(stats::median(result$upper-result$lower),d),
    ". The calibration reused the ",b,
    " fixed-regressor wild-bootstrap replicates from the base result ",
    "(k=g=",k,", h=",h,", multiplier='",multiplier,
    "') without rerunning FPCA or the bootstrap. Simultaneity ",
    "applies only to the fixed target trajectories contained in ",
    "that base result; these intervals are not future-outcome prediction ",
    "intervals and do not provide clustered or repeated-participant ",
    "wild-bootstrap inference.")
}
