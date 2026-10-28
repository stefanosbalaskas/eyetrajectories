# Stage 11 — independent R scientific reporting and nonlinear result adapters.
# eyetrajectoriespy==1.2.0 nonlinear_reporting.py source inspected.
# No Python, reticulate, automatic parameter selection or estimator execution.

.etr11_fields <- function(x,fields,label="result") {
  .etr_assert(is.list(x) && all(fields %in% names(x)),
    paste(label,"lacks required validated result fields"))
  invisible(TRUE)
}
.etr11_num <- function(x,label="value",positive=FALSE) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.na(x)&&
    is.finite(x)&&(!positive||x>0),
    paste(label,"must be a finite scalar"))
  as.numeric(x)
}
.etr11_g <- function(x,d=4L) {
  if(length(x)!=1L || !(is.numeric(x)||is.integer(x)))return("nan")
  if(is.na(x)||is.nan(x))return("nan")
  if(is.infinite(x))return(if(x>0)"inf" else "-inf")
  sprintf(paste0("%.",d,"g"),x)
}
.etr11_f <- function(x,d=1L) {
  if(length(x)!=1L||!is.numeric(x)||is.na(x)||is.nan(x))return("nan")
  if(is.infinite(x))return(if(x>0)"inf" else "-inf")
  sprintf(paste0("%.",d,"f"),x)
}
.etr11_repr <- function(x)paste0("'",x,"'")
.etr11_summary <- function(result,metric) {
  .etr11_fields(result,c("summary_table","table","curve_id"))
  z<-result$summary_table
  .etr_assert(is.data.frame(z) && all(c("metric","minimum","maximum") %in% names(z)),
    "summary_table must supply metric/minimum/maximum columns")
  row<-z[z$metric==metric,,drop=FALSE]
  .etr_assert(nrow(row)==1L,paste("summary metric missing or duplicated:",metric))
  row
}

#' Report synchronized joint-recurrence source contracts
#' @param result Native joint recurrence result.
#' @param metrics Optional native RQA metrics including line thresholds.
#' @export
etr_joint_recurrence_reporting_text <- function(result,metrics=NULL) {
  .etr_assert(inherits(result,"etr_joint_recurrence"),
    "result must be a native joint recurrence")
  comps<-vapply(seq_along(result$component_labels),function(i){
    x<-result$component_recurrences[[i]]
    policy<-if(!is.null(x$target_recurrence_rate))
      paste0("target RR=",.etr11_g(x$target_recurrence_rate)) else
      paste0("fixed radius=",.etr11_g(x$radius))
    paste0(result$component_labels[i],": ",
      if(is.null(x$metric))"euclidean" else x$metric,", ",policy,
      ", achieved RR=",.etr11_g(x$recurrence_rate),
      ", state dimension=",x$state_dimension)
  },character(1L))
  suffix<-""
  if(!is.null(metrics)){
    .etr11_fields(metrics,c("min_diagonal_length","min_vertical_length",
      "determinism","laminarity","trapping_time"),"metrics")
    suffix<-paste0(" Joint-RQA used minimum diagonal/vertical line lengths ",
      metrics$min_diagonal_length,"/",metrics$min_vertical_length,
      "; DET=",.etr11_g(metrics$determinism),", LAM=",
      .etr11_g(metrics$laminarity),", trapping time=",
      .etr11_g(metrics$trapping_time),".")
  }
  paste0("Joint recurrence was computed as the logical intersection of ",
    length(result$component_recurrences),
    " synchronized auto-recurrence matrices on the same time grid with a shared Theiler window of ",
    result$theiler_window_samples,
    " samples. Component contracts were ",paste(comps,collapse="; "),
    ". The joint recurrence rate was ",.etr11_g(result$joint_recurrence_rate),
    " (",result$n_joint_recurrent_pairs,"/",result$eligible_pair_count,
    " eligible unordered pairs). No resampling, lag shifting, threshold harmonization, or automatic threshold selection was performed.",
    suffix," Joint recurrence was interpreted as coincident recurrence within the declared component systems, not as cross-recurrence between states or as evidence of causal coupling.")
}

#' Describe independent native R recurrence-network topology
#' @export
etr_recurrence_network_reporting_text <- function(result) {
  .etr_assert(inherits(result,"etr_recurrence_network"),
    "result must be native recurrence network")
  rec<-result$source_recurrence
  policy<-if(!is.null(rec$target_recurrence_rate))
    paste0("target RR=",.etr11_g(rec$target_recurrence_rate),
      ", achieved RR=",.etr11_g(rec$recurrence_rate))
    else paste0("fixed radius=",.etr11_g(rec$radius),
      ", achieved RR=",.etr11_g(rec$recurrence_rate))
  tr<-if(is.finite(result$transitivity))
    .etr11_g(result$transitivity) else
      "undefined because the network contained no connected triples"
  paste0("An undirected recurrence network was constructed from ",
    length(result$degree)," recurrence-state nodes using the source ",
    if(is.null(rec$metric))"euclidean" else rec$metric,
    " recurrence relation (",policy,") and a Theiler window of ",
    rec$theiler," samples. The network contained ",result$edge_count,
    " undirected edges, graph density ",.etr11_g(result$graph_density),
    ", mean local clustering ",.etr11_g(result$mean_local_clustering),
    ", and transitivity ",tr,". It had ",result$n_connected_components,
    " connected component(s), with ",.etr11_f(100*result$largest_component_fraction),
    "% of nodes in the largest component and ",
    .etr11_f(100*result$isolated_node_fraction),
    "% isolated nodes. Graph density used all unordered node pairs, whereas the source recurrence rate used its declared eligible-pair denominator. No threshold tuning, community optimization, edge weighting, or automatic dimensionality interpretation was performed.")
}

#' Describe analyst-declared recurrence-threshold radius grid
#' @export
etr_recurrence_radius_profile_reporting_text <- function(result) {
  .etr_assert(inherits(result,"etr_recurrence_radius_profile"),
    "result must be native recurrence radius profile")
  tab<-result$table
  .etr_assert(is.data.frame(tab) && nrow(tab)>=2L &&
    "recurrence_rate" %in% names(tab),
    "radius profile table must include recurrence rates")
  cov<-result$provenance$maximum_radius_coverage_fraction
  if(is.null(cov))cov<-tail(tab$recurrence_rate,1L)
  full<-isTRUE(result$provenance$full_distance_distribution_captured)
  coverage<-if(full)
    "the supplied maximum radius covered the complete eligible pair-distance distribution"
    else paste0("the supplied maximum radius covered ",
      .etr11_f(100*cov),"% of eligible pair distances")
  paste0("Recurrence-threshold diagnostics evaluated ",nrow(tab),
    " predeclared radii for curve ",.etr11_repr(result$curve_id),
    " using the ",result$metric," state-space distance and a Theiler window of ",
    result$theiler_window_samples," samples. RR increased from ",
    .etr11_g(tab$recurrence_rate[1L])," to ",
    .etr11_g(tail(tab$recurrence_rate,1L)),"; ",coverage,
    ". Cumulative and shell pair counts were computed with the same eligible-pair denominator and inclusive radius rule as the base recurrence estimator. No radius was selected automatically.")
}

#' Report a native recurrence and explicit RQA line metrics
#' @export
etr_rqa_reporting_text <- function(recurrence,metrics) {
  .etr_assert(inherits(recurrence,"etr_recurrence"),
    "recurrence must be native recurrence")
  .etr11_fields(metrics,c("min_diagonal_length","min_vertical_length",
    "recurrence_rate","determinism","laminarity","trapping_time"),"metrics")
  policy<-if(identical(recurrence$provenance$radius_policy,
    "target_recurrence_rate"))
      paste0("target recurrence rate ",.etr11_g(recurrence$target_recurrence_rate),
        ", yielding radius ",.etr11_g(recurrence$radius),
        " and achieved RR ",.etr11_g(recurrence$recurrence_rate))
    else paste0("fixed radius ",.etr11_g(recurrence$radius))
  paste0("Recurrence analysis used ",recurrence$kind," recurrence with the ",
    if(is.null(recurrence$metric))"euclidean" else recurrence$metric,
    " metric, ",policy,", and a Theiler window of ",recurrence$theiler,
    " samples. RQA used minimum diagonal and vertical line lengths of ",
    metrics$min_diagonal_length," and ",metrics$min_vertical_length,
    ", respectively. The resulting RR was ",
    .etr11_g(metrics$recurrence_rate),", DET ",
    .etr11_g(metrics$determinism),", LAM ",
    .etr11_g(metrics$laminarity),", and trapping time ",
    .etr11_g(metrics$trapping_time),".")
}

#' Descriptive report of fixed-specification RQA bootstrap means
#' @export
etr_rqa_metric_mean_bootstrap_reporting_text <- function(result) {
  .etr11_fields(result,c("metrics","unit","unit_ids","n_bootstrap","confidence_level"))
  .etr11_num(result$confidence_level,"confidence_level")
  unit_text<-if(identical(result$unit,"participant"))
    paste0(length(result$unit_ids)," equal-weight participant units defined by ",
      .etr11_repr(result$participant_column),
      "; repeated curve-level RQA metrics were averaged within participant before resampling")
    else paste0(length(result$unit_ids)," curve-level independent units")
  paste0("Population-average RQA uncertainty for ",
    paste(result$metrics,collapse=", ")," used ",result$n_bootstrap,
    " percentile bootstrap replicates at the ",
    .etr11_f(100*result$confidence_level),
    "% level and ",unit_text,
    ". Each source curve was summarized under one fixed declared RQA specification before unit-level resampling. Undefined selected curve-level metrics caused analysis failure rather than deletion or imputation. These intervals describe between-unit population sampling uncertainty conditional on the declared RQA specification; they do not estimate within-single-trajectory recurrence uncertainty, recurrence-line resampling uncertainty, or parameter-selection uncertainty.")
}

#' Describe sliding-window RQA temporal support
#' @export
etr_windowed_rqa_reporting_text <- function(result) {
  .etr_assert(inherits(result,"etr_windowed_rqa"),
    "result must be native windowed RQA")
  paste0("Windowed RQA used full windows of ",result$window_samples,
    " samples advanced by ",result$step_samples,
    " samples, producing ",nrow(result$table)," windows. The final ",
    result$dropped_tail_samples,
    " samples outside a complete window were retained in the audit record but not analyzed as a partial window.")
}

#' Describe native RQA functional trajectories and overlapping support
#' @export
etr_windowed_rqa_functional_reporting_text <- function(result) {
  .etr_assert(inherits(result,"etr_windowed_rqa_functional"),
    "result must be native functional RQA")
  .etr_assert(inherits(result$trajectories,"etr_trajectory_set"),
    "functional RQA trajectories missing")
  paste0("Windowed RQA was converted to functional trajectories for ",
    length(result$trajectories$curve_ids)," source curve(s) using ",
    length(result$trajectories$time)," complete windows of ",
    result$window_samples," samples, advanced by ",result$step_samples,
    " samples (",.etr11_f(100*result$overlap_fraction),
    "% sample overlap). Functional dimensions were ",
    paste(result$metrics,collapse=", "),
    "; the recurrence-radius policy was ",
    if(is.null(result$trajectories$provenance$radius_policy))"unknown"
      else result$trajectories$provenance$radius_policy,
    ". Window centers formed the functional time grid and ",
    result$dropped_tail_samples,
    " trailing samples outside a complete window were excluded explicitly. Window rows were not treated as independent observations; downstream inference retained the source curve/participant as the sampling unit.")
}

#' Describe declared window/step sensitivity specifications
#' @export
etr_windowed_rqa_sensitivity_reporting_text <- function(result) {
  .etr11_fields(result,c("analyses","design_table"))
  tab<-result$design_table
  .etr_assert(is.data.frame(tab)&&nrow(tab)>0L &&
    all(c("overlap_fraction","profile_grid_spacing_time","profile_time_unit")%in%names(tab)) &&
    all(is.finite(tab$overlap_fraction)) &&
    all(is.finite(tab$profile_grid_spacing_time)),
    "design_table requires finite overlap and grid spacing")
  paste0("Functional RQA sensitivity was evaluated across ",
    length(result$analyses)," predeclared window/step specifications. Sample overlap ranged from ",
    .etr11_f(100*min(tab$overlap_fraction)),"% to ",
    .etr11_f(100*max(tab$overlap_fraction)),
    "% and derived-profile grid spacing ranged from ",
    .etr11_g(min(tab$profile_grid_spacing_time))," to ",
    .etr11_g(max(tab$profile_grid_spacing_time))," ",
    tab$profile_time_unit[1L],
    ". Overlap diagnostics quantified deterministic source-sample reuse; they were not converted into an effective independent sample size. Pairwise profile comparisons used exact shared window centers only, with no interpolation and no automatic selection of a preferred window/step specification.")
}

#' Describe independent-unit simultaneous windowed RQA mean bands
#' @export
etr_windowed_rqa_mean_band_reporting_text <- function(result) {
  .etr11_fields(result,c("functional_rqa","band","unit"))
  fr<-result$functional_rqa
  band<-result$band
  .etr11_fields(fr,c("window_samples","step_samples","overlap_fraction"))
  .etr11_fields(band,c("unit_ids","confidence_level"))
  unit_text<-if(identical(result$unit,"participant"))
    paste0("participant-level units defined by ",
      .etr11_repr(result$participant_column))
    else "curve-level units"
  paste0("Windowed RQA functions used ",fr$window_samples,
    "-sample windows advanced by ",fr$step_samples," samples (",
    .etr11_f(100*fr$overlap_fraction),
    "% overlap). Simultaneous observed-grid mean inference used ",
    length(band$unit_ids)," independent ",unit_text," and a ",
    .etr11_f(100*band$confidence_level),
    "% Gaussian multiplier band. Complete derived functions, not window rows, were the resampling objects, preserving within-function temporal dependence. The procedure does not provide a within-trajectory block-bootstrap guarantee or treat overlapping windows as independent observations.")
}

#' Describe RQA parameter-grid robustness with explicit outcomes
#' @export
etr_rqa_parameter_sensitivity_reporting_text <- function(result) {
  det<-.etr11_summary(result,"determinism")
  lam<-.etr11_summary(result,"laminarity")
  rr<-.etr11_summary(result,"recurrence_rate")
  controlled<-if(identical(result$provenance$threshold_policy,
                           "target_recurrence_rate"))
    " Recurrence rate was controlled by the target-rate design and was not treated as an independent robustness outcome."
    else ""
  paste0("RQA robustness was evaluated across ",nrow(result$table),
    " predeclared parameter specifications for curve ",
    .etr11_repr(result$curve_id),". DET ranged from ",
    .etr11_g(det$minimum)," to ",.etr11_g(det$maximum),
    ", LAM from ",.etr11_g(lam$minimum)," to ",
    .etr11_g(lam$maximum),", and RR from ",
    .etr11_g(rr$minimum)," to ",.etr11_g(rr$maximum),
    ". Every Cartesian-product specification was retained in the sensitivity table; no parameter combination was selected automatically and invalid specifications were configured to fail the analysis rather than disappear silently.",
    controlled)
}

#' Describe Kantz neighborhood divergence sensitivity
#' @export
etr_kantz_parameter_sensitivity_reporting_text <- function(result) {
  ex<-.etr11_summary(result,"exponent")
  sup<-.etr11_summary(result,"initial_supported_reference_fraction")
  .etr11_fields(result,c("exponent_unit"))
  .etr_assert("positive_specification_fraction" %in% names(ex),
    "exponent summary lacks positive fraction")
  paste0("Kantz local-divergence sensitivity was evaluated across ",
    nrow(result$table),
    " predeclared reconstruction, radius, minimum-neighbor, Theiler-window, and fit-interval specifications for curve ",
    .etr11_repr(result$curve_id),". Estimated exponents ranged from ",
    .etr11_g(ex$minimum)," to ",.etr11_g(ex$maximum),
    " ",result$exponent_unit,"; ",
    .etr11_f(100*ex$positive_specification_fraction),
    "% of finite declared specifications had positive slopes. Initial supported-reference fractions ranged from ",
    .etr11_f(sup$minimum,3L)," to ",.etr11_f(sup$maximum,3L),
    ". These quantities describe sensitivity across the declared analysis grid, not sampling uncertainty or a probability of deterministic chaos. No radius, reconstruction, minimum-neighbor rule, or fit interval was selected automatically.")
}

#' Describe Rosenstein Lyapunov sensitivity
#' @export
etr_lyapunov_parameter_sensitivity_reporting_text <- function(result) {
  ex<-.etr11_summary(result,"exponent")
  .etr11_fields(result,c("exponent_unit"))
  .etr_assert("positive_specification_fraction" %in% names(ex),
    "exponent summary lacks positive fraction")
  paste0("Rosenstein local-divergence sensitivity was evaluated across ",
    nrow(result$table),
    " predeclared reconstruction, Theiler-window, and fit-interval specifications for curve ",
    .etr11_repr(result$curve_id),". Estimated exponents ranged from ",
    .etr11_g(ex$minimum)," to ",.etr11_g(ex$maximum)," ",
    result$exponent_unit,"; ",
    .etr11_f(100*ex$positive_specification_fraction),
    "% of finite declared specifications had positive slopes. This percentage was reported only as descriptive sensitivity across the declared analysis grid, not as a probability of deterministic chaos. No reconstruction or fit interval was selected automatically.")
}

#' Describe a fitted local-divergence slope without claiming chaos
#' @export
etr_largest_lyapunov_reporting_text <- function(result) {
  .etr11_fields(result,c("divergence","fit_start","fit_end","n_fit_points",
    "exponent","exponent_unit","r_squared","standard_error"))
  div<-result$divergence
  method<-if(!is.null(div$radius) && !is.null(div$min_neighbors))
    paste0("Kantz fixed-radius neighborhood divergence (radius=",
      .etr11_g(div$radius),", min_neighbors=",div$min_neighbors,")")
    else "Rosenstein nearest-neighbor divergence"
  paste0("A ",method," estimate was fitted over ",
    .etr11_g(result$fit_start)," to ",.etr11_g(result$fit_end)," ",
    div$time_unit," using ",result$n_fit_points,
    " divergence points. The estimated largest Lyapunov exponent was ",
    .etr11_g(result$exponent)," ",result$exponent_unit,
    " (R^2=",.etr11_f(result$r_squared,3L),
    ", slope SE=",.etr11_g(result$standard_error),
    "). This quantity was interpreted as a conditional local-divergence estimate and not as standalone evidence of deterministic chaos.")
}

#' Report an explicit surrogate nonlinearity test without a chaos claim
#' @export
etr_surrogate_nonlinearity_reporting_text <- function(result) {
  .etr11_fields(result,c("surrogate_statistics","n_surrogates","method",
    "statistic","alternative","p_value","random_state","spectral_errors"))
  .etr_assert(is.numeric(result$surrogate_statistics) &&
    all(is.finite(result$surrogate_statistics)) &&
    is.numeric(result$spectral_errors) && length(result$spectral_errors)>0L &&
    all(is.finite(result$spectral_errors)),
    "surrogate statistics and spectral errors must all be finite")
  paste0("Nonlinearity was assessed with ",result$n_surrogates," ",
    toupper(result$method)," surrogates using the ",
    gsub("_"," ",result$statistic,fixed=TRUE),
    " statistic and a ",result$alternative,
    " alternative. A plus-one Monte Carlo p-value was used (p=",
    .etr11_g(result$p_value),"; random_state=",
    if(is.null(result$random_state))"None" else result$random_state,
    "); the maximum retained final relative spectrum mismatch was ",
    .etr11_g(max(result$spectral_errors)),
    ". The test was interpreted relative to the declared surrogate null, not as proof of a unique nonlinear or chaotic mechanism.")
}

#' Report empirical Poincare return-map stability with declared scope
#' @param fit Declared local return-map fit.
#' @param result Eigenvalue-based return-map stability summary.
#' @export
etr_return_map_stability_reporting_text <- function(fit,result) {
  .etr11_fields(fit,c("neighborhood_policy","neighborhood_value",
    "n_transitions","design_condition_number","r_squared"))
  .etr11_fields(result,c("eigenvalues","spectral_radius","tolerance",
    "classification"))
  eig<-vapply(as.complex(result$eigenvalues),function(v)
    if(abs(Im(v))>1e-12)
      paste0(.etr11_g(Re(v)),if(Im(v)>=0) "+" else "",
        .etr11_g(Im(v)),"i")
      else .etr11_g(Re(v)),character(1L))
  r2<-paste(vapply(fit$r_squared,function(v).etr11_f(v,3L),
    character(1L)),collapse=", ")
  crossing<-fit$provenance$crossing_provenance
  if(is.null(crossing))crossing<-list()
  get<-function(x)if(is.null(crossing[[x]]))"unknown" else crossing[[x]]
  paste0("Experimental empirical return-map stability used section ",
    get("section_dimension"),"=",get("section_value"),
    " with ",get("direction")," crossings and a ",
    fit$neighborhood_policy," neighborhood (",fit$neighborhood_value,
    "); ",fit$n_transitions,
    " transitions were fitted. The local design condition number was ",
    .etr11_g(fit$design_condition_number),
    " and per-state R^2 values were [",r2,
    "]. Jacobian eigenvalues were (",paste(eig,collapse=", "),
    "), with spectral radius ",.etr11_g(result$spectral_radius),
    " and tolerance ",.etr11_g(result$tolerance),
    "; the map was classified as ",result$classification,
    ". These eigenvalues were not interpreted as classical Floquet multipliers and the fitted Jacobian was not described as a monodromy matrix.")
}
