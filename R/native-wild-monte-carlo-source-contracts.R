# Frozen Python 1.2.0 finite-wild-bootstrap diagnostic contract:
# src/eyetrajectoriespy/wild_testing.py and plotting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Source-aligned native R numerical subset. No new bootstrap draws,
# scientific effect confidence intervals, re-testing or Matplotlib parity.

.etr_wild_mc_numeric <- function(x,n,label,probability=FALSE) {
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)==n&&
    all(is.finite(x))&&(!probability||all(x>=0&x<=1)),
    paste(label,"must contain",n,"finite",
      if(probability)"probability" else "numeric","values"))
  as.numeric(x)
}
.etr_wild_mc_boolean <- function(x,n,label) {
  .etr_assert(is.logical(x)&&length(x)==n&&!anyNA(x),
    paste(label,"must contain",n,"nonmissing logical flags"))
  as.logical(x)
}
.etr_wild_mc_positive_integer <- function(x,label) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.logical(x)&&
    is.finite(x)&&x>=1&&x==floor(x)&&x<=.Machine$integer.max,
    paste(label,"must be a positive integer"))
  as.integer(x)
}
.etr_wild_mc_confidence <- function(x,label) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.logical(x)&&
    is.finite(x)&&x>0&&x<1,
    paste(label,"must be numeric inside (0,1)"))
  as.numeric(x)
}
.etr_wild_mc_interval <- function(counts,B,level) {
  a<-(1-level)/2
  n<-length(counts)
  low<-numeric(n);up<-rep(1,n)
  k<-which(counts>0L)
  if(length(k))low[k]<-stats::qbeta(a,counts[k],B-counts[k]+1L)
  k<-which(counts<B)
  if(length(k))up[k]<-stats::qbeta(1-a,counts[k]+1L,B-counts[k])
  list(lower=low,upper=up)
}
.etr_wild_mc_source_ids <- function(result) {
  .etr_scientific_frame_fields(result,c("projection_result"),
    "family test")
  .etr_scientific_frame_fields(result$projection_result,
    c("target_curve_ids"),"family-test projection")
  .etr_scientific_frame_ids(result$projection_result$target_curve_ids,
    "target_curve_ids")
}

#' Exact finite-bootstrap Monte Carlo diagnostics for a fixed FPCR family
#'
#' Reuses the retained studentized roots, observed statistics, and
#' maxT statistics. Binomial confidence intervals describe Monte Carlo
#' precision, NOT scientific estimand uncertainty or new FWER guarantees.
#' @param result Explicit native fixed-family wild bootstrap result.
#' @param confidence_level Clopper-Pearson diagnostic confidence level.
#' @return Descriptive exact-binomial diagnostics, with original rejection
#'   decisions preserved; not a Python dataclass.
#' @export
etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics <- function(
    result,confidence_level=.95) {
  level<-.etr_wild_mc_confidence(confidence_level,"confidence_level")
  required<-c("projection_result","observed_statistics",
    "max_statistics","global_statistic","reject_targetwise",
    "reject_familywise","reject_global","significance_level",
    "pvalue_correction")
  .etr_scientific_frame_fields(result,required,"family test")
  ids<-.etr_wild_mc_source_ids(result)
  n<-length(ids)
  base<-result$projection_result
  .etr_scientific_frame_fields(base,c("studentized_roots"),
    "family-test projection")
  roots<-base$studentized_roots
  .etr_assert(is.matrix(roots)&&is.numeric(roots)&&
    ncol(roots)==n&&nrow(roots)>=1L&&all(is.finite(roots)),
    "studentized_roots must be a finite bootstrap-by-target matrix")
  B<-nrow(roots)
  if(!is.null(base$bootstrap_projections))
    .etr_assert(is.matrix(base$bootstrap_projections)&&
      nrow(base$bootstrap_projections)==B&&
      ncol(base$bootstrap_projections)==n,
      "bootstrap_projections and studentized_roots must have identical shapes")
  obs<-.etr_wild_mc_numeric(result$observed_statistics,n,
    "observed_statistics")
  maximum<-.etr_wild_mc_numeric(result$max_statistics,B,
    "max_statistics")
  .etr_assert(is.numeric(result$global_statistic)&&
    length(result$global_statistic)==1L&&
    is.finite(result$global_statistic),
    "global_statistic must be finite")
  reject_t<-.etr_wild_mc_boolean(result$reject_targetwise,n,
    "reject_targetwise")
  reject_a<-.etr_wild_mc_boolean(result$reject_familywise,n,
    "reject_familywise")
  reject_g<-.etr_wild_mc_boolean(result$reject_global,1L,
    "reject_global")
  alpha<-.etr_wild_mc_confidence(result$significance_level,
    "significance_level")
  correction<-.etr_source_text_word(result$pvalue_correction,
    "pvalue_correction")
  .etr_assert(correction%in%c("plus_one","none"),
    "pvalue_correction must be 'plus_one' or 'none'")
  counts_t<-colSums(abs(roots)>=matrix(rep(abs(obs),each=B),B,n))
  counts_a<-vapply(abs(obs),function(x)as.integer(sum(maximum>=x)),integer(1L))
  count_g<-sum(maximum>=result$global_statistic)
  tail_t<-as.numeric(counts_t)/B
  tail_a<-as.numeric(counts_a)/B
  tail_g<-as.numeric(count_g)/B
  mt<-.etr_wild_mc_interval(counts_t,B,level)
  ma<-.etr_wild_mc_interval(counts_a,B,level)
  mg<-.etr_wild_mc_interval(count_g,B,level)
  stable_t<-ifelse(reject_t,mt$upper<alpha,mt$lower>alpha)
  stable_a<-ifelse(reject_a,ma$upper<alpha,ma$lower>alpha)
  stable_g<-if(reject_g)mg$upper[1L]<alpha else mg$lower[1L]>alpha
  # Match the published Python 1.2 nested provenance record. Preserve
  # pre-existing source provenance without changing hypothesis decisions.
  prior<-result$provenance
  if(is.null(prior))prior<-list()
  .etr_assert(is.list(prior) &&
    (!length(prior) || (!is.null(names(prior)) &&
       !anyNA(names(prior)) && all(nzchar(names(prior))))),
    "family-test provenance must be a named record")
  prior[["fpca_wild_bootstrap_monte_carlo_diagnostics"]]<-list(
    method="binomial_monte_carlo_precision_diagnostic",
    interval_method="clopper_pearson_exact_binomial",
    confidence_level=level,n_bootstrap=B,
    exceedance_model="binomial_conditional_on_observed_statistic_and_bootstrap_design",
    tail_probability_estimator="exceedances_over_B",
    monte_carlo_standard_error="sqrt(qhat*(1-qhat)/B)",
    reported_test_pvalue_correction=correction,
    reported_test_minimum_attainable_p=if(correction=="plus_one")1/(B+1) else 0,
    decision_stability_rule="complete_monte_carlo_interval_on_reported_decision_side_of_alpha",
    changes_reported_test_decisions=FALSE,
    additional_bootstrap_draws=FALSE,bootstrap_roots_reused=TRUE,
    scientific_sampling_uncertainty_quantified=FALSE,
    monte_carlo_sampling_uncertainty_quantified=TRUE,
    strong_fwer_claim_added=FALSE,clustered_wild_bootstrap=FALSE,
    component_selection_uncertainty_included=FALSE)
  structure(list(
    family_test_result=result,confidence_level=level,
    targetwise_exceedances=as.integer(counts_t),
    adjusted_exceedances=as.integer(counts_a),
    global_exceedances=as.integer(count_g),
    targetwise_tail_probabilities=tail_t,
    adjusted_tail_probabilities=tail_a,
    global_tail_probability=tail_g,
    targetwise_mcse=sqrt(tail_t*(1-tail_t)/B),
    adjusted_mcse=sqrt(tail_a*(1-tail_a)/B),
    global_mcse=sqrt(tail_g*(1-tail_g)/B),
    targetwise_interval_lower=mt$lower,
    targetwise_interval_upper=mt$upper,
    adjusted_interval_lower=ma$lower,
    adjusted_interval_upper=ma$upper,
    global_interval_lower=mg$lower[1L],
    global_interval_upper=mg$upper[1L],
    targetwise_decision_stable=as.logical(stable_t),
    adjusted_decision_stable=as.logical(stable_a),
    global_decision_stable=as.logical(stable_g),
    provenance=prior),
    class="etr_fpca_wild_mc_diagnostics")
}

#' Plot precomputed finite-bootstrap Monte Carlo precision for FPCR tests
#' @param result Source-shaped or native exact-binomial diagnostic record.
#' @param max_targets Maximum fixed targets displayed, positive integer.
#' @param show_targetwise Whether to show targetwise precision intervals.
#' @return Invisibly the source-aligned numeric drawing geometry.
#' @export
etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics <- function(
    result,max_targets=30L,show_targetwise=FALSE) {
  .etr_scientific_frame_fields(result,c("family_test_result",
    "adjusted_tail_probabilities","adjusted_interval_lower",
    "adjusted_interval_upper","targetwise_tail_probabilities",
    "targetwise_interval_lower","targetwise_interval_upper"),
    "Monte Carlo diagnostic")
  ids<-.etr_wild_mc_source_ids(result$family_test_result)
  B<-length(ids)
  top<-.etr_wild_mc_positive_integer(max_targets,"max_targets")
  .etr_wild_mc_boolean(show_targetwise,1L,"show_targetwise")
  alpha<-.etr_wild_mc_confidence(
    result$family_test_result$significance_level,"significance_level")
  values<-lapply(c("adjusted_tail_probabilities",
    "adjusted_interval_lower","adjusted_interval_upper",
    "targetwise_tail_probabilities","targetwise_interval_lower",
    "targetwise_interval_upper"),function(n)
      .etr_wild_mc_numeric(result[[n]],B,n,probability=TRUE))
  names(values)<-c("adjusted","adjusted_lower","adjusted_upper",
    "targetwise","targetwise_lower","targetwise_upper")
  .etr_assert(all(values$adjusted_lower<=values$adjusted)&
    all(values$adjusted<=values$adjusted_upper)&
    all(values$targetwise_lower<=values$targetwise)&
    all(values$targetwise<=values$targetwise_upper),
    "Monte Carlo interval bounds must enclose their estimates")
  n<-min(B,top);ix<-seq_len(n);x<-ix-1L
  graphics::plot(NA_real_,NA_real_,type="n",
    xlim=if(n==1L)c(-.5,.5)else range(x),
    ylim=c(-.02,1.02),xaxt="n",
    xlab="Fixed target trajectory",
    ylab="Bootstrap exceedance probability",
    main="Monte Carlo precision of fixed-family wild-bootstrap tests")
  graphics::segments(x,values$adjusted_lower[ix],
    x,values$adjusted_upper[ix])
  graphics::points(x,values$adjusted[ix],pch=1L)
  if(show_targetwise){
    graphics::segments(x,values$targetwise_lower[ix],
      x,values$targetwise_upper[ix],col="grey45")
    graphics::points(x,values$targetwise[ix],pch=4L)
  }
  graphics::abline(h=alpha,lty=2L)
  graphics::axis(1L,at=x,labels=ids[ix],las=2L,cex.axis=.8)
  graphics::legend("topright",legend=c("maxT tail probability",
    if(show_targetwise)"target-wise tail probability",
    paste0("alpha=",alpha)),
    pch=c(1L,if(show_targetwise)4L,NA_integer_),
    lty=c(NA_integer_,if(show_targetwise)NA_integer_,2L),
    bty="n",cex=.75)
  invisible(data.frame(target_index=x,target_curve_id=ids[ix],
    adjusted=values$adjusted[ix],
    adjusted_lower=values$adjusted_lower[ix],
    adjusted_upper=values$adjusted_upper[ix],
    targetwise=values$targetwise[ix],
    targetwise_lower=values$targetwise_lower[ix],
    targetwise_upper=values$targetwise_upper[ix]))
}

#' Plot familywise simultaneous and targetwise FPCR projection intervals
#' @param result Pre-calibrated fixed-family wild-bootstrap interval result.
#' @inheritParams etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics
#' @return Invisibly displayed fixed-target projection and interval data.
#' @export
etr_plot_fpca_wild_bootstrap_simultaneous_interval <- function(
    result,max_targets=30L,show_targetwise=TRUE) {
  .etr_scientific_frame_fields(result,c("projection_result",
    "lower","upper","targetwise_critical_values"),"simultaneous interval")
  base<-result$projection_result
  .etr_scientific_frame_fields(base,c("target_curve_ids",
    "reference_projection","reference_se"),"projection")
  ids<-.etr_scientific_frame_ids(base$target_curve_ids,
    "target_curve_ids")
  B<-length(ids)
  top<-.etr_wild_mc_positive_integer(max_targets,"max_targets")
  .etr_wild_mc_boolean(show_targetwise,1L,"show_targetwise")
  center<-.etr_wild_mc_numeric(base$reference_projection,B,
    "reference_projection")
  se<-.etr_wild_mc_numeric(base$reference_se,B,"reference_se")
  crit<-.etr_wild_mc_numeric(result$targetwise_critical_values,B,
    "targetwise_critical_values")
  .etr_assert(all(se>=0)&&all(crit>=0),
    "reference standard errors and critical values must be nonnegative")
  low<-.etr_wild_mc_numeric(result$lower,B,"lower")
  high<-.etr_wild_mc_numeric(result$upper,B,"upper")
  .etr_assert(all(low<=center)&all(center<=high),
    "simultaneous interval must enclose reference projections")
  target_lo<-center-crit*se;target_hi<-center+crit*se
  n<-min(B,top);ix<-seq_len(n);x<-ix-1L
  bounds<-c(low[ix],high[ix],center[ix],
    if(show_targetwise)target_lo[ix],
    if(show_targetwise)target_hi[ix],0)
  span<-range(bounds)
  if(span[1L]==span[2L])span<-span+c(-.05,.05)*max(1,abs(span[1L]))
  graphics::plot(NA_real_,NA_real_,type="n",
    xlim=if(n==1L)c(-.5,.5)else range(x),ylim=span,xaxt="n",
    xlab="Fixed target trajectory",
    ylab="Centered FPCR projection",
    main="Familywise heteroscedastic Gaussian FPCR projection inference")
  graphics::segments(x,low[ix],x,high[ix])
  graphics::points(x,center[ix],pch=1L)
  if(show_targetwise){
    graphics::segments(x,target_lo[ix],x,target_hi[ix],
      col="grey45")
    graphics::points(x,center[ix],pch=20L,col="grey45")
  }
  graphics::abline(h=0,lty=2L)
  graphics::axis(1L,at=x,labels=ids[ix],las=2L,cex.axis=.8)
  graphics::legend("topright",legend=c(
    "familywise simultaneous interval",
    if(show_targetwise)"target-wise interval"),
    pch=c(1L,if(show_targetwise)20L),bty="n")
  invisible(data.frame(target_index=x,target_curve_id=ids[ix],
    reference_projection=center[ix],
    simultaneous_lower=low[ix],
    simultaneous_upper=high[ix],
    targetwise_lower=target_lo[ix],targetwise_upper=target_hi[ix]))
}
