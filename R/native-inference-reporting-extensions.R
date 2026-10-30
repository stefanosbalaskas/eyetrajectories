# Published Python 1.2.0 reporting.py — three read-only native R
# summaries, pinned commit c1cd95ad718327550f7e55393ff38582872f7a94.
# All result inputs are conservative R-list analogues, not Python dataclasses.

#' Predictive FPCA cross-validation source-summary wording
#' @param result Explicit regression CV result with fold_losses, n_splits,
#'   family, loss and cv_unit.
#' @param rule Declared minimum or one-SE selection policy.
#' @param digits Number of decimal display places.
#' @return One descriptive reporting string; no model is refitted.
#' @export
etr_fpca_regression_cv_reporting_text <- function(
    result,rule="minimum",digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("fold_losses","n_splits",
    "family","loss","cv_unit"))
  .etr_assert(identical(result$cv_unit,"group") ||
    identical(result$cv_unit,"curve"),
    "cv_unit must be group or curve")
  .etr_assert(is.character(rule) && length(rule)==1L && !is.na(rule) &&
    rule %in% c("minimum","one_se"),
    "rule must be minimum or one_se")
  folds<-.etr_inference_report_integer(result$n_splits,"n_splits",2L)
  family<-.etr_inference_report_word(result$family,"family")
  loss<-.etr_inference_report_word(result$loss,"loss")
  s<-etr_summarise_fpca_regression_cv(result)
  .etr_assert(nrow(s)>0L && all(is.finite(s$mean_loss)) &&
    all(is.finite(s$se_loss)) && all(s$n_folds>0),
    "cross-validation summary must contain finite loss and SE")
  selected<-etr_select_fpca_regression_components(result,rule=rule)
  row<-s[s$n_components==selected,,drop=FALSE]
  .etr_assert(nrow(row)==1L,"selected component row must be unique")
  unit<-if(result$cv_unit=="group")"grouped" else "curve-level"
  heuristic<-if(rule=="one_se")
    " The one-standard-error rule was used as a parsimony heuristic." else ""
  paste0("Outcome-tuned FPCA regression used ",folds,"-fold ",unit,
    " cross-validation with family='",family,"' and held-out ",loss,
    ". FPCA and the scalar regression were refitted inside every ",
    "training fold. The explicit '",rule,"' rule selected ",selected,
    " component(s) (mean held-out loss=",
    .etr_inference_report_f(row$mean_loss,d),
    ", SE=",.etr_inference_report_f(row$se_loss,d),").",heuristic)
}

#' Descriptive matched-bootstrap FPC envelopes (not confidence bands)
#' @param result Explicit record with nonempty finite bootstrap-by-component
#'   similarities, level, and resampling_unit.
#' @param digits Number of decimal display places.
#' @return A scientific-scope-qualified reporting string.
#' @export
etr_fpca_component_envelope_reporting_text <- function(
    result,digits=2L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("similarities","resampling_unit",
    "level"))
  sim<-result$similarities
  .etr_assert(is.matrix(sim) && is.numeric(sim) &&
    nrow(sim)>=1L && ncol(sim)>=1L && all(is.finite(sim)) &&
    all(sim>=0) && all(sim<=1),
    "similarities must be a nonempty finite bootstrap-by-component matrix in [0,1]")
  .etr_assert(identical(result$resampling_unit,"curve") ||
    identical(result$resampling_unit,"participant"),
    "resampling_unit must be curve or participant")
  level<-.etr_inference_report_level(result$level,"level")
  med<-apply(sim,2L,stats::median)
  similarity<-paste(paste0("FPC",seq_along(med),"=",
    .etr_inference_report_f(med,d)),collapse=", ")
  paste0("Functional principal-component shape uncertainty was ",
    "summarized with ",nrow(sim)," ",result$resampling_unit,
    "-level bootstrap replicates. Replicate components were ",
    "matched and sign-aligned to the full-sample reference before ",
    "forming ",sprintf("%.1f",100*level),
    "% pointwise descriptive envelopes. Median matched absolute ",
    "similarities were ",similarity,
    ". These envelopes are descriptive and are not simultaneous ",
    "confidence bands.")
}

#' Shared-multiplier stabilized-volatility truncation reporting
#' @param result Explicit selection record with scan, selected_components,
#'   width_threshold, center_threshold and stability_run.
#' @param digits Number of decimal display places.
#' @return Source-aligned descriptive reporting string, without selection.
#' @export
etr_fpca_wild_bootstrap_truncation_reporting_text <- function(
    result,digits=3L) {
  d<-.etr_manuscript_digits(digits)
  .etr_inference_report_fields(result,c("scan","selected_components",
    "width_threshold","center_threshold","stability_run"))
  .etr_inference_report_fields(result$scan,
    c("candidate_components","residual_components"),"scan")
  h<-result$scan$candidate_components
  .etr_assert(is.numeric(h) && length(h)>=2L && !anyNA(h) &&
    all(is.finite(h)) && all(h>=1L) && all(h==floor(h)) &&
    all(diff(h)>0) && all(diff(h)==1),
    "candidate_components must contain consecutive positive integers")
  k<-.etr_inference_report_integer(
    result$scan$residual_components,"residual_components")
  selected<-result$selected_components
  .etr_assert(is.numeric(selected) && length(selected)>=1L &&
    all(is.finite(selected) | is.na(selected) | is.nan(selected)),
    "selected_components must be finite integers or missing")
  ok<-is.finite(selected)
  .etr_assert(all(selected[ok]>=1L) &&
    all(selected[ok]==floor(selected[ok])) &&
    all(selected[ok] %in% h),
    "finite selected_components must be candidate integers")
  w<-result$width_threshold
  center<-result$center_threshold
  .etr_assert(is.numeric(w) && length(w)==1L && is.finite(w) && w>=0,
    "width_threshold must be nonnegative finite scalar")
  .etr_assert(is.numeric(center) && length(center)==1L &&
    is.finite(center) && center>=0,
    "center_threshold must be nonnegative finite scalar")
  run<-.etr_inference_report_integer(result$stability_run,"stability_run",0L)
  .etr_assert(run+1L<length(h),
    "stability_run requires at least run+1 transitions")
  n<-sum(ok)
  selection<-if(n>0L)paste0("Selected h ranged from ",
    format(min(selected[ok]),scientific=FALSE,trim=TRUE)," to ",
    format(max(selected[ok]),scientific=FALSE,trim=TRUE),
    " across ",n," target(s).") else "No target received a qualifying h."
  candidate_text<-paste0("(",paste(h,collapse=", "),")")
  paste0("Wild-bootstrap inference truncation was evaluated by a ",
    "shared-multiplier stabilized-volatility scan over consecutive h ",
    "values ",candidate_text,". Residual estimation and the bootstrap ",
    "pseudo-truth used k=g=",k,". A transition was width-stable when ",
    "its absolute width change was <= ",.etr_inference_report_f(w,d),
    " and center-stable when its absolute center change was <= ",
    .etr_inference_report_f(center,d),
    "; both conditions were required. The paper run parameter was r=",
    run,", requiring ",run+1L,
    " consecutive stable transitions, and the earliest qualifying h ",
    "was selected separately for each target. ",selection,
    " Thresholds were analyst supplied in scalar-outcome units; the ",
    "package imposed no 0.01 default and did not silently substitute ",
    "the largest candidate when stability was absent.")
}
