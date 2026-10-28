# Stage 23. Python-free manuscript-oriented reporting built from audited
# native scientific result containers. Source-aligned to published Python
# eyetrajectoriespy 1.2.0 reporting.py, not full type-system equivalence.
# A reporting string never upgrades an estimator's scientific validation.

.etr23_digits <- function(digits) {
  .etr_assert(is.numeric(digits)&&!is.logical(digits)&&
    length(digits)==1L&&is.finite(digits)&&
    digits==as.integer(digits)&&digits>=0L&&digits<=15L,
    "digits must be a finite nonnegative integer up to 15")
  as.integer(digits)
}
.etr23_num <- function(value,digits) {
  sprintf(paste0("%.",digits,"f"),value)
}
.etr23_check <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)>=1L&&
    all(is.finite(x)),paste(name,"must contain finite numeric values"))
}

#' Published-source descriptive DTW alignment reporting
#' @param result Audited native DTW result returned with return_path=TRUE.
#' @param digits Nonnegative decimal display precision.
#' @return A manuscript-ready text string; descriptive only.
#' @export
etr_dynamic_time_warping_reporting_text <- function(result,digits=3L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_dtw_result")&&
    is.matrix(result$path)&&ncol(result$path)==2L&&
    is.numeric(result$distance)&&length(result$distance)==1L&&
    is.finite(result$distance)&&
    is.numeric(result$raw_distance)&&length(result$raw_distance)==1L&&
    is.finite(result$raw_distance)&&
    result$step_pattern%in%c("symmetric1","symmetric2"),
    "result must be an audited native DTW alignment with a path")
  window<-if(is.null(result$window_radius)) "unconstrained" else
    sprintf("Sakoe-Chiba radius=%d sample indices",result$window_radius)
  dt<-if(is.null(result$normalized_distance))paste0(
    "raw cumulative distance=",.etr23_num(result$raw_distance,d),
    "; no path-independent normalization is defined for symmetric1")
    else paste0("raw cumulative distance=",
      .etr23_num(result$raw_distance,d),
      ", N+M-normalized distance=",
      .etr23_num(result$normalized_distance,d))
  returned<-if(isTRUE(result$provenance$normalization_requested))
    "normalized" else "raw cumulative"
  paste0("Dynamic time warping used the ",result$step_pattern,
    " step pattern with ",window,". ",dt,
    ". The reported scalar was the ",returned,
    " value. The optimal monotone path contained ",
    result$path_length,
    " matched index pairs; recorded timestamps were not used by the ",
    "recurrence, and no step pattern, window, preprocessing, or ",
    "normalization rule was selected automatically.")
}

#' Manuscript wording for predeclared native trajectory-distance sensitivity
#' @param result Native multiverse trajectory-distance sensitivity output.
#' @param digits Nonnegative display precision.
#' @export
etr_trajectory_distance_sensitivity_reporting_text <- function(result,
    digits=3L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_trajectory_distance_sensitivity")&&
    is.data.frame(result$comparison_table)&&
    all(c("spearman_rank_correlation",
      "mean_top_k_neighbor_jaccard",
      "nearest_neighbor_identity_agreement_fraction")%in%
      names(result$comparison_table))&&
    nrow(result$comparison_table)>=1L&&
    length(result$specification_names)>=2L&&
    length(result$curve_ids)>=3L&&
    length(result$dimensions)>=1L,
    "result must be a complete native trajectory distance multiverse")
  c<-result$comparison_table
  rho<-c$spearman_rank_correlation
  j<-c$mean_top_k_neighbor_jaccard
  nearest<-c$nearest_neighbor_identity_agreement_fraction
  .etr_assert(is.numeric(rho)&&all(is.finite(rho)|is.nan(rho)),
    "Spearman correlations must be finite or NaN when undefined")
  .etr23_check(j,"Jaccard agreement")
  .etr23_check(nearest,"nearest neighbor agreement")
  rho<-rho[is.finite(rho)]
  rho_text<-if(!length(rho))
    "undefined for at least one constant pair-distance vector"
    else paste0(.etr23_num(min(rho),d)," to ",.etr23_num(max(rho),d))
  ties<-sum(result$neighbor_cutoff_ties)
  .etr_assert(is.finite(ties)&&ties>=0,"cutoff ties must be countable")
  paste0("Trajectory-similarity robustness was evaluated across ",
    length(result$specification_names)," predeclared distance specifications (",
    paste(result$specification_names,collapse=", "),") for ",
    length(result$curve_ids)," curves using dimensions ",
    paste(result$dimensions,collapse=", "),". Pairwise distance matrices were ",
    "retained on their native scales; no standardization, rescaling, ",
    "consensus distance, or preferred metric was constructed. ",
    "Across specification pairs, descriptive Spearman rank agreement ",
    "ranged from ",rho_text,". Mean top-",result$neighbor_k,
    " neighbor-set Jaccard agreement ranged from ",
    .etr23_num(min(j),d)," to ",.etr23_num(max(j),d),
    ", and nearest-neighbor identity agreement ranged from ",
    .etr23_num(min(nearest),d)," to ",.etr23_num(max(nearest),d),
    ". ",ties,
    " specification-by-curve neighborhood cutoff ties were flagged. ",
    "These quantities describe sensitivity to the declared distance ",
    "contract; they are not p-values and do not identify a statistically ",
    "or scientifically 'best' distance metric.")
}

#' Source-aligned descriptive report of FPCA bootstrap component stability
#' @param result Native matched bootstrap FPCA component stability.
#' @param similarity_threshold Declared absolute-similarity screen.
#' @param digits Display precision.
#' @export
etr_fpca_stability_reporting_text <- function(result,
    similarity_threshold=.80,digits=2L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_fpca_stability")&&
    is.matrix(result$similarities)&&is.numeric(result$similarities)&&
    nrow(result$similarities)>=1L&&ncol(result$similarities)>=1L&&
    all(is.finite(result$similarities))&&
    ncol(result$similarities)==result$reference$n_components,
    "result must contain matched native FPCA bootstrap similarities")
  .etr_assert(is.numeric(similarity_threshold)&&
    length(similarity_threshold)==1L&&
    is.finite(similarity_threshold)&&
    similarity_threshold>=0&&similarity_threshold<=1,
    "similarity_threshold must be in [0,1]")
  values<-result$similarities
  pieces<-vapply(seq_len(ncol(values)),function(k)
    paste0("FPC",k,": median |similarity|=",
      .etr23_num(stats::median(values[,k]),d),
      ", fraction >= ",.etr23_num(similarity_threshold,d),"=",
      .etr23_num(mean(values[,k]>=similarity_threshold),d)),
    character(1L))
  paste0("Bootstrap FPCA stability used ",nrow(values)," ",
    result$resampling_unit,
    "-level replicates with component matching by absolute functional ",
    "similarity. ",paste(pieces,collapse="; "),
    ". Stability fractions are descriptive robustness summaries, ",
    "not inferential probabilities.")
}

#' Descriptive FPCA functional anomaly review statement
#' @param result Native FPCA reconstruction/score outlier diagnostics.
#' @export
etr_fpca_outlier_reporting_text <- function(result) {
  .etr_assert(inherits(result,"etr_fpca_outliers")&&
    is.data.frame(result$diagnostics)&&
    "review_flag"%in%names(result$diagnostics)&&
    is.logical(result$diagnostics$review_flag)&&
    !anyNA(result$diagnostics$review_flag),
    "result diagnostics must contain complete logical review_flag")
  paste0("Functional anomaly screening (",result$method,
    ") flagged ",sum(result$diagnostics$review_flag)," of ",
    nrow(result$diagnostics)," trajectories for review. Flags were ",
    "treated as diagnostic signals only and were not used as automatic ",
    "exclusion criteria.")
}

#' Leave-one-group-out native FPCA influence reporting
#' @param result Native influence summary and fitted-group information.
#' @param digits Display precision.
#' @export
etr_fpca_influence_reporting_text <- function(result,digits=2L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_fpca_influence")&&
    is.data.frame(result$summary)&&nrow(result$summary)>0L&&
    all(c("group","min_abs_component_similarity",
      "influence_score")%in%names(result$summary)),
    "influence summary is empty or incomplete")
  s<-result$summary
  .etr23_check(s$influence_score,"influence score")
  .etr23_check(s$min_abs_component_similarity,"minimum similarity")
  i<-which.max(s$influence_score)
  unit<-if(is.null(result$group_column))"curve_id" else
    result$group_column
  paste0("Leave-one-",unit,
    "-out FPCA influence analysis evaluated ",nrow(s),
    " omission fits. The largest observed influence was for '",
    as.character(s$group[i]),
    "', with minimum matched component similarity ",
    .etr23_num(s$min_abs_component_similarity[i],d),
    ". Influence diagnostics were used for sensitivity assessment ",
    "rather than automatic exclusion.")
}

#' Native FPCA eigenspace stability manuscript report
#' @param result Native bootstrapped principal-angle subspace result.
#' @param digits Display precision.
#' @export
etr_fpca_subspace_stability_reporting_text <- function(result,digits=3L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_fpca_subspace_stability")&&
    is.matrix(result$principal_cosines)&&
    nrow(result$principal_cosines)>=1L&&
    length(result$component_indices)>=1L,
    "result must be a native FPCA subspace stability analysis")
  s<-etr_summarise_fpca_subspace_stability(result)
  row<-s[1L,,drop=FALSE]
  paste0("Bootstrap FPCA subspace stability evaluated FPC",
    row$component_start,"\u2013FPC",row$component_end," using ",
    nrow(result$principal_cosines)," ",result$resampling_unit,
    "-level resamples. The median minimum principal cosine was ",
    .etr23_num(row$median_min_principal_cosine,d),
    ", the median maximum principal angle was ",
    .etr23_num(row$median_max_principal_angle_degrees,d),
    " degrees, and the median normalized projector distance was ",
    .etr23_num(row$median_normalized_projector_distance,d),
    ". These are descriptive eigenspace-stability summaries; they ",
    "do not establish identifiability of individual FPC labels within ",
    "the selected block.")
}

#' Source-aligned held-out FPCA reconstruction cross-validation summary
#' @param result Native leakage-aware held-out FPCA reconstruction CV.
#' @param rule Declared minimum or one-SE selection rule.
#' @param digits Display precision.
#' @export
etr_fpca_cross_validation_reporting_text <- function(result,
    rule="minimum",digits=3L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_fpca_cv")&&
    result$cv_unit%in%c("group","curve")&&
    is.numeric(result$n_splits)&&length(result$n_splits)==1L,
    "result must be a native FPCA cross-validation result")
  selected<-etr_select_fpca_components_cv(result,rule=rule)
  summary<-etr_summarise_fpca_cross_validation(result)
  row<-summary[summary$n_components==selected,,drop=FALSE]
  .etr_assert(nrow(row)==1L&&is.finite(row$mean_rmse)&&
    is.finite(row$se_rmse),"selected CV row must have finite error/SE")
  unit<-if(result$cv_unit=="group")"grouped" else "curve-level"
  suffix<-if(rule=="one_se")
    " The one-standard-error rule was used as a parsimony heuristic." else ""
  paste0("FPCA component selection used ",result$n_splits,
    "-fold ",unit," held-out reconstruction cross-validation, with FPCA ",
    "refitted inside every training fold. The explicit '",rule,
    "' rule selected ",selected," component(s) (mean integrated RMSE=",
    .etr23_num(row$mean_rmse,d),
    ", SE=",.etr23_num(row$se_rmse,d),").",suffix)
}

#' Two-level between/within native FPCA variance description
#' @param result Two-level descriptive native FPCA result.
#' @param digits Display precision.
#' @export
etr_multilevel_fpca_reporting_text <- function(result,digits=1L) {
  d<-.etr23_digits(digits)
  .etr_assert(inherits(result,"etr_multilevel_fpca")&&
    is.numeric(result$between$explained_variance_ratio)&&
    is.numeric(result$within$explained_variance_ratio),
    "result must be a native two-level FPCA decomposition")
  p<-100*sum(result$between$explained_variance_ratio)
  t<-100*sum(result$within$explained_variance_ratio)
  .etr_assert(is.finite(p)&&is.finite(t),
    "fitted cumulative component proportions must be finite")
  paste0("Two-level functional decomposition separated participant-level ",
    "from within-participant trial variation. The retained participant ",
    "components explained ",.etr23_num(p,d),
    "% of fitted participant-level variance; the retained trial ",
    "components explained ",.etr23_num(t,d),
    "% of fitted trial-level variance.")
}
