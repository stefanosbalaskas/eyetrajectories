# Frozen source: eyetrajectoriespy 1.2.0 wild_testing.py
# Fixed-family Gaussian FPCR maxT hypothesis tests, with no rebootstrap.
# Numeric source law can be compared on retained bootstrap draws.
# Full Python dataclass and accepted-type contract remain independently unsigned.

#' Fixed-family wild-bootstrap hypothesis tests from retained FPCR roots
#'
#' @description Reuses a previously computed matrix of studentized wild
#'   bootstrap roots; neither FPCA nor a bootstrap sample is fitted again.
#'   Single-step max-absolute-root adjusted probabilities apply to the exact
#'   fixed family. Arbitrary-subset strong FWER is NOT asserted.
#' @param result Source-shaped native projection record with retained roots,
#'   bootstrap projections, reference projection and reference SE.
#' @param null_values Finite numeric or decimal-text scalar or vector of
#'   target null values.
#' @param significance_level Strict numeric threshold in (0,1).
#' @param pvalue_correction "plus_one" or "none".
#' @return Native result with targetwise and adjusted p-values, max
#'   statistics, global p-value, explicit decision records and provenance.
#' @export
etr_fpca_wild_bootstrap_projection_family_test<-function(
    result,null_values=0,significance_level=.05,
    pvalue_correction="plus_one"){
  .etr_assert(is.list(result)&&
    all(c("bootstrap_projections","studentized_roots",
      "reference_projection","reference_se")%in%names(result)),
    "result must contain source projection and bootstrap root records")
  draws<-result$bootstrap_projections
  .etr_assert(is.matrix(draws)&&is.numeric(draws)&&
    nrow(draws)>=1L&&ncol(draws)>=1L,
    "bootstrap_projections must retain the B-by-target shape")
  B<-nrow(draws);nt<-ncol(draws)
  roots<-result$studentized_roots
  .etr_assert(is.matrix(roots)&&is.numeric(roots)&&
    identical(dim(roots),c(B,nt))&&all(is.finite(roots)),
    "studentized_roots must match bootstrap projections dimensions")
  reference<-result$reference_projection
  se<-result$reference_se
  .etr_assert(is.numeric(reference)&&is.null(dim(reference))&&
    length(reference)==nt&&all(is.finite(reference)),
    "reference_projection must be finite with one value per target")
  .etr_assert(is.numeric(se)&&is.null(dim(se))&&
    length(se)==nt&&all(is.finite(se))&&all(se>=0),
    "reference_se must be finite and nonnegative per target")
  .etr_assert(is.numeric(significance_level)&&
    is.null(dim(significance_level))&&
    length(significance_level)==1L&&
    is.finite(significance_level)&&
    significance_level>0&&significance_level<1,
    "significance_level must lie strictly between 0 and 1")
  .etr_assert(is.character(pvalue_correction)&&
    length(pvalue_correction)==1L&&!is.na(pvalue_correction)&&
    pvalue_correction%in%c("plus_one","none"),
    "pvalue_correction must be plus_one or none")
  if(is.character(null_values)&&is.null(dim(null_values)))
    null_values<-suppressWarnings(as.numeric(.etr_numpy_float_text(null_values,
      "null_values must be numeric")))
  .etr_assert(is.numeric(null_values)&&is.null(dim(null_values))&&
    length(null_values)%in%c(1L,nt)&&all(is.finite(null_values)),
    "null_values must be finite numeric scalar or one value per target")
  null<-rep(as.numeric(null_values),length.out=nt)
  delta<-as.numeric(reference)-null
  positive<-as.numeric(se)>.Machine$double.eps*
    max(1,as.numeric(se))
  tolerance<-100*.Machine$double.eps*
    max(1,abs(as.numeric(reference)),abs(null))
  bad<-which(!positive & abs(delta)>tolerance)
  .etr_assert(length(bad)==0L,
    paste0("zero reference standard error with a non-zero null ",
      "discrepancy for target index/indices ",
      paste(head(bad-1L,8L),collapse=", ")))
  observed<-numeric(nt)
  observed[positive]<-delta[positive]/se[positive]
  absolute_roots<-abs(roots)
  obs<-abs(observed)
  max_stats<-apply(absolute_roots,1L,max)
  global_stat<-max(obs)
  target_count<-colSums(sweep(absolute_roots,2L,obs,">="))
  adjusted_count<-vapply(obs,function(threshold)
    sum(max_stats>=threshold),integer(1L))
  global_count<-sum(max_stats>=global_stat)
  if(pvalue_correction=="plus_one"){
    tail<-function(x)(as.numeric(x)+1)/(B+1)
    min_p<-1/(B+1)
  }else{
    tail<-function(x)as.numeric(x)/B
    min_p<-0
  }
  tp<-tail(target_count)
  ap<-tail(adjusted_count)
  gp<-as.numeric(tail(global_count))
  provenance<-if(is.null(result$provenance))list()
    else result$provenance
  .etr_assert(is.list(provenance)&&
    (length(provenance)==0L||(!is.null(names(provenance))&&
       !anyDuplicated(names(provenance))&&
       all(nzchar(names(provenance))))),
    "projection provenance must be a named mapping")
  settings<-provenance$fpca_wild_bootstrap_projection
  provenance$fpca_wild_bootstrap_family_test<-list(
    method="single_step_max_abs_studentized_root",
    family="gaussian",
    estimand="centered_projection_relative_to_training_functional_mean",
    alternative="two_sided",
    global_null="all_target_projections_equal_supplied_null_values",
    n_targets=nt,
    family_definition="all_fixed_targets_in_base_projection_result",
    significance_level=significance_level,
    pvalue_correction=pvalue_correction,
    minimum_attainable_p=min_p,
    bootstrap_roots_reused=TRUE,bootstrap_rerun=FALSE,
    null_enforced_bootstrap=FALSE,
    studentization=if(is.list(settings))settings$studentization else NULL,
    multiplier=if(!is.null(result$multiplier))result$multiplier else NULL,
    residual_components_k=result$residual_components,
    pseudo_truth_components_g=result$residual_components,
    inference_components_h=result$inference_components,
    single_step_familywise_adjustment=TRUE,
    strong_fwer_for_arbitrary_subset_nulls_claimed=FALSE,
    subset_pivotality_assumed_by_package=FALSE,
    future_outcome_test=FALSE,clustered_wild_bootstrap=FALSE,
    component_selection_uncertainty_included=FALSE,
    source_full_contract_certified=FALSE)
  structure(list(
    projection_result=result,
    null_values=null,
    observed_statistics=observed,
    targetwise_p_values=as.numeric(tp),
    adjusted_p_values=as.numeric(ap),
    max_statistics=as.numeric(max_stats),
    global_statistic=as.numeric(global_stat),
    global_p_value=gp,
    reject_targetwise=as.logical(tp<=significance_level),
    reject_familywise=as.logical(ap<=significance_level),
    reject_global=isTRUE(gp<=significance_level),
    significance_level=as.numeric(significance_level),
    pvalue_correction=pvalue_correction,
    n_bootstrap=B,n_targets=nt,
    minimum_attainable_p=as.numeric(min_p),
    provenance=provenance),
    class="etr_fpca_wild_bootstrap_family_test")
}
