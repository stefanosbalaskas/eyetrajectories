# Native frozen-Python 1.2 wild bootstrap inference and selection.
# Source: eyetrajectoriespy==1.2.0
# src/eyetrajectoriespy/wild_selection.py, wild_regression.py,
# wild_testing.py, wild_simultaneous.py
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Numeric selection is independent R, no Python backend.

.etr_wild_source_projection <- function(result){
  .etr_frame_record(result,c("target_curve_ids",
    "reference_projection","reference_se"),"projection_result")
  ids<-.etr_frame_ids(result$target_curve_ids,"target_curve_ids")
  n<-length(ids)
  .etr_frame_vector(result$reference_projection,n,"reference_projection")
  .etr_frame_vector(result$reference_se,n,"reference_se")
  .etr_assert(all(result$reference_se>=0),
    "reference_se must be nonnegative")
  list(ids=ids,n=n,reference=as.numeric(result$reference_projection),
    se=as.numeric(result$reference_se))
}
.etr_wild_source_probability <- function(x,n,what){
  .etr_frame_vector(x,n,what)
  .etr_assert(all(x>=0&x<=1),paste0(what," must lie in [0, 1]"))
  as.numeric(x)
}
.etr_wild_source_flags <- function(x,n,what){
  .etr_assert(is.logical(x)&&length(x)==n&&!anyNA(x),
    paste0(what," must be n complete logical decisions"))
  x
}
.etr_wild_source_threshold <- function(x,what){
  if(is.character(x)&&is.null(dim(x)))
    x<-suppressWarnings(as.numeric(.etr_numpy_float_text(x,
      paste0(what," must be numeric"))))
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)==1L&&
    is.finite(x)&&x>0,
    paste0(what," must be a finite positive scalar"))
  as.numeric(x)
}

#' Native stabilized-volatility selection of FPCA inference truncation
#' @param scan Previously computed source-compatible wild-bootstrap scan.
#' @param width_threshold Positive width-change stability threshold.
#' @param center_threshold Positive center-change stability threshold.
#' @param stability_run Nonnegative integer r requiring r+1 transitions.
#' @param on_failure One of "error", "warn", "ignore". No fallback.
#' @return Source-compatible named selection record, including zero-based
#'   selected candidate indices, stability matrices and provenance.
#' @details Implements the published rule, not a fitted FPCA or bootstrap.
#' @export
etr_select_fpca_wild_bootstrap_truncation <- function(
    scan,width_threshold,center_threshold,stability_run,
    on_failure="error"){
  required<-c("candidate_components","target_curve_ids",
    "widths","centers","lower","upper")
  .etr_frame_record(scan,required,"scan")
  ids<-.etr_frame_ids(scan$target_curve_ids,"target_curve_ids")
  h<-scan$candidate_components
  .etr_assert(is.numeric(h)&&length(h)>=2L&&
    all(is.finite(h))&&all(h>0)&&all(h==floor(h))&&
    !anyDuplicated(h),
    "candidate_components must be distinct positive integers")
  nh<-length(h);nt<-length(ids)
  for(nm in c("widths","centers","lower","upper"))
    .etr_frame_matrix(scan[[nm]],nh,nt,nm)
  wt<-.etr_wild_source_threshold(width_threshold,"width_threshold")
  ct<-.etr_wild_source_threshold(center_threshold,"center_threshold")
  .etr_assert(is.numeric(stability_run)&&length(stability_run)==1L&&
    is.finite(stability_run)&&stability_run>=0&&
    stability_run==floor(stability_run),
    "stability_run must be a nonnegative integer")
  # Bound the transition count *before* coercing to R's 32-bit integer.
  # Frozen Python integers can exceed that range; every such count fails
  # because it exceeds the finite source candidate grid. Never allow an
  # integer-overflow NA to obscure the source validation error.
  .etr_assert(stability_run+1<=nh-1L,
    "stability_run requires more consecutive stable transitions than candidate grid can provide")
  need<-as.integer(stability_run+1)
  .etr_assert(is.character(on_failure)&&length(on_failure)==1L&&
    !is.na(on_failure)&&on_failure%in%c("error","warn","ignore"),
    "on_failure must be error, warn or ignore")
  width_changes<-abs(scan$widths[-1L,,drop=FALSE]-
    scan$widths[-nh,,drop=FALSE])
  center_changes<-abs(scan$centers[-1L,,drop=FALSE]-
    scan$centers[-nh,,drop=FALSE])
  stable_width<-width_changes<=wt
  stable_center<-center_changes<=ct
  stable_both<-stable_width&stable_center
  selection_idx<-rep(-1L,nt)
  selected_components<-rep(NaN,nt)
  selected_centers<-rep(NaN,nt)
  selected_widths<-rep(NaN,nt)
  selected_lower<-rep(NaN,nt)
  selected_upper<-rep(NaN,nt)
  last_start<-nrow(stable_both)-need+1L
  for(j in seq_len(nt))for(start in seq_len(last_start)){
    idx<-seq.int(start,length.out=need)
    if(all(stable_both[idx,j])){
      selection_idx[j]<-as.integer(start-1L)
      selected_components[j]<-as.numeric(h[start])
      selected_centers[j]<-scan$centers[start,j]
      selected_widths[j]<-scan$widths[start,j]
      selected_lower[j]<-scan$lower[start,j]
      selected_upper[j]<-scan$upper[start,j]
      break
    }
  }
  failed<-which(selection_idx<0L)
  if(length(failed)){
    message<-paste0("stabilized-volatility selection found no qualifying run for ",
      length(failed)," target(s): ",
      paste(head(ids[failed],8L),collapse=", "),
      ". Expand the pre-specified candidate grid or reconsider the pre-specified thresholds; ",
      "the package will not silently choose the largest h.")
    if(on_failure=="error")stop(message,call.=FALSE)
    if(on_failure=="warn")warning(message,call.=FALSE)
  }
  provenance<-if(is.null(scan$provenance))list() else scan$provenance
  .etr_assert(is.list(provenance),
    "scan$provenance must be an R list")
  provenance$fpca_wild_bootstrap_truncation_selection<-list(
    method="stabilized_volatility",width_threshold_rho_w=wt,
    center_threshold_rho_c=ct,
    stability_run_r=as.integer(stability_run),
    required_consecutive_stable_transitions=need,
    selection="earliest_candidate_h_starting_qualifying_stable_run",
    threshold_units="scalar_outcome_units",
    thresholds_package_defaulted=FALSE,
    on_failure=on_failure,silent_largest_h_fallback=FALSE,
    target_specific_selection=TRUE)
  list(scan=scan,width_changes=width_changes,
    center_changes=center_changes,stable_width=stable_width,
    stable_center=stable_center,stable_both=stable_both,
    selected_candidate_indices=selection_idx,
    selected_components=selected_components,
    selected_centers=selected_centers,selected_widths=selected_widths,
    selected_lower=selected_lower,selected_upper=selected_upper,
    width_threshold=wt,center_threshold=ct,
    stability_run=as.integer(stability_run),on_failure=on_failure,
    provenance=provenance)
}

#' Source-aligned wild-bootstrap target-projection summary frame
#' @param result Explicit realized projection record.
#' @return Source-order data frame with fixed-target projection intervals.
#' @export
etr_fpca_wild_bootstrap_projection_frame <- function(result){
  x<-.etr_wild_source_projection(result);n<-x$n
  fields<-c("pseudo_truth_projection","critical_values","lower","upper")
  .etr_frame_record(result,fields,"result")
  for(nm in fields).etr_frame_vector(result[[nm]],n,nm)
  data.frame(curve_id=x$ids,reference_projection=x$reference,
    pseudo_truth_projection=as.numeric(result$pseudo_truth_projection),
    heteroscedastic_se=x$se,
    critical_value=as.numeric(result$critical_values),
    lower=as.numeric(result$lower),upper=as.numeric(result$upper),
    stringsAsFactors=FALSE)
}

#' Source-aligned simultaneous wild-bootstrap target interval frame
#' @param result Explicit simultaneous inference record with projection_result.
#' @return Source-order targetwise and simultaneous interval summaries.
#' @export
etr_fpca_wild_bootstrap_simultaneous_frame <- function(result){
  .etr_frame_record(result,c("projection_result",
    "targetwise_critical_values","critical_value","lower","upper"),
    "result")
  x<-.etr_wild_source_projection(result$projection_result);n<-x$n
  tcrit<-.etr_frame_vector(result$targetwise_critical_values,n,
    "targetwise_critical_values")
  crit<-.etr_frame_vector(result$critical_value,1L,"familywise critical_value")
  .etr_assert(crit>=0,"familywise critical_value must be nonnegative")
  for(nm in c("lower","upper"))
    .etr_frame_vector(result[[nm]],n,nm)
  data.frame(curve_id=x$ids,reference_projection=x$reference,
    heteroscedastic_se=x$se,targetwise_critical_value=tcrit,
    familywise_critical_value=rep(crit,n),
    targetwise_lower=x$reference-tcrit*x$se,
    targetwise_upper=x$reference+tcrit*x$se,
    simultaneous_lower=as.numeric(result$lower),
    simultaneous_upper=as.numeric(result$upper),
    stringsAsFactors=FALSE)
}

#' Source-aligned fixed-family wild-bootstrap target test frame
#' @param result Explicit family test record with projection_result.
#' @return Source-order target statistics, p-values and decisions.
#' @export
etr_fpca_wild_bootstrap_family_test_frame <- function(result){
  names<-c("projection_result","null_values",
    "observed_statistics","targetwise_p_values","adjusted_p_values",
    "reject_targetwise","reject_familywise","global_statistic",
    "global_p_value")
  .etr_frame_record(result,names,"result")
  x<-.etr_wild_source_projection(result$projection_result);n<-x$n
  for(nm in c("null_values","observed_statistics"))
    .etr_frame_vector(result[[nm]],n,nm)
  target_p<-.etr_wild_source_probability(
    result$targetwise_p_values,n,"targetwise_p_values")
  adjusted_p<-.etr_wild_source_probability(
    result$adjusted_p_values,n,"adjusted_p_values")
  target_reject<-.etr_wild_source_flags(
    result$reject_targetwise,n,"reject_targetwise")
  family_reject<-.etr_wild_source_flags(
    result$reject_familywise,n,"reject_familywise")
  global_stat<-.etr_frame_vector(result$global_statistic,1L,
    "global_statistic")
  global_p<-.etr_wild_source_probability(result$global_p_value,1L,
    "global_p_value")
  data.frame(curve_id=x$ids,reference_projection=x$reference,
    null_value=as.numeric(result$null_values),
    heteroscedastic_se=x$se,
    observed_statistic=as.numeric(result$observed_statistics),
    targetwise_p_value=target_p,adjusted_p_value=adjusted_p,
    reject_targetwise=target_reject,reject_familywise=family_reject,
    global_statistic=rep(global_stat,n),global_p_value=rep(global_p,n),
    stringsAsFactors=FALSE)
}

#' Source-aligned wild-bootstrap Monte Carlo precision audit frame
#' @param result Explicit realized Monte Carlo precision record and family test.
#' @return Target-level precision and decision stability diagnostics.
#' @export
etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame <- function(result){
  cols<-c("family_test_result","targetwise_exceedances",
    "targetwise_tail_probabilities","targetwise_mcse",
    "targetwise_interval_lower","targetwise_interval_upper",
    "targetwise_decision_stable","adjusted_exceedances",
    "adjusted_tail_probabilities","adjusted_mcse",
    "adjusted_interval_lower","adjusted_interval_upper",
    "adjusted_decision_stable")
  .etr_frame_record(result,cols,"result")
  family<-result$family_test_result
  .etr_frame_record(family,c("projection_result","reject_targetwise",
    "reject_familywise","targetwise_p_values","adjusted_p_values",
    "significance_level"),"family_test_result")
  x<-.etr_wild_source_projection(family$projection_result);n<-x$n
  a<-.etr_wild_source_flags(result$targetwise_decision_stable,n,
    "targetwise_decision_stable")
  b<-.etr_wild_source_flags(result$adjusted_decision_stable,n,
    "adjusted_decision_stable")
  reject_a<-.etr_wild_source_flags(family$reject_targetwise,n,
    "reject_targetwise")
  reject_b<-.etr_wild_source_flags(family$reject_familywise,n,
    "reject_familywise")
  exp_a<-.etr_frame_vector(result$targetwise_exceedances,n,
    "targetwise_exceedances")
  exp_b<-.etr_frame_vector(result$adjusted_exceedances,n,
    "adjusted_exceedances")
  .etr_assert(all(exp_a==floor(exp_a))&&all(exp_a>=0)&&
    all(exp_b==floor(exp_b))&&all(exp_b>=0),
    "exceedances must be nonnegative integers")
  for(nm in c("targetwise_tail_probabilities",
    "adjusted_tail_probabilities","targetwise_interval_lower",
    "targetwise_interval_upper","adjusted_interval_lower",
    "adjusted_interval_upper"))
    .etr_wild_source_probability(result[[nm]],n,nm)
  for(nm in c("targetwise_mcse","adjusted_mcse"))
    .etr_frame_vector(result[[nm]],n,nm)
  for(nm in c("targetwise_p_values","adjusted_p_values"))
    .etr_wild_source_probability(family[[nm]],n,nm)
  alpha<-.etr_wild_source_probability(family$significance_level,1L,
    "significance_level")
  status<-function(stable,reject)
    ifelse(!stable,"monte_carlo_sensitive",
      ifelse(reject,"stable_reject","stable_non_reject"))
  data.frame(curve_id=x$ids,targetwise_exceedances=as.integer(exp_a),
    targetwise_tail_probability=as.numeric(
      result$targetwise_tail_probabilities),
    targetwise_mcse=as.numeric(result$targetwise_mcse),
    targetwise_mc_lower=as.numeric(result$targetwise_interval_lower),
    targetwise_mc_upper=as.numeric(result$targetwise_interval_upper),
    targetwise_precision_status=status(a,reject_a),
    adjusted_exceedances=as.integer(exp_b),
    adjusted_tail_probability=as.numeric(
      result$adjusted_tail_probabilities),
    adjusted_mcse=as.numeric(result$adjusted_mcse),
    adjusted_mc_lower=as.numeric(result$adjusted_interval_lower),
    adjusted_mc_upper=as.numeric(result$adjusted_interval_upper),
    adjusted_precision_status=status(b,reject_b),
    reported_targetwise_p_value=as.numeric(family$targetwise_p_values),
    reported_adjusted_p_value=as.numeric(family$adjusted_p_values),
    alpha=rep(alpha,n),stringsAsFactors=FALSE)
}
