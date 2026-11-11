# Stage 12: Python-free leakage-aware FPCA reconstruction CV,
# explicit selection criteria, uncertainty and predictive reporting frames.
# Source: eyetrajectoriespy 1.2.0 selection.py, prediction.py,
# score_uncertainty.py, spectrum_inference.py, conformal.py,
# regression_inference.py, similarity_sensitivity.py.
# No reticulate/Python or estimator uncertainty bootstrap is invoked.

.etr_cv_fields <- function(x, fields, label) {
  .etr_assert(is.list(x) && all(fields %in% names(x)),
    paste(label, "requires declared fields",paste(fields,collapse=", ")))
}
.etr_cv_numeric_vector <- function(x,n,label,finite=TRUE) {
  .etr_assert(is.numeric(x) && is.null(dim(x)) && length(x)==n &&
    (!finite||all(is.finite(x))),
    paste(label,"requires a numeric vector of declared length"))
  as.numeric(x)
}
.etr_cv_numeric_matrix <- function(x,n,m,label) {
  .etr_assert(is.matrix(x) && is.numeric(x) &&
    identical(dim(x),c(as.integer(n),as.integer(m))) && all(is.finite(x)),
    paste(label,"requires finite numeric matrix with declared dimensions"))
  x
}
.etr_cv_curve_ids <- function(ids) {
  .etr_assert(is.character(ids) && length(ids)>0L &&
    !anyNA(ids) && !anyDuplicated(ids),
    "curve identifiers must be unique and complete")
  ids
}
.etr_cv_check_shuffle_seed <- function(seed,maximum,message) {
  .etr_assert(is.numeric(seed)&&is.null(dim(seed))&&length(seed)==1L&&
    is.finite(seed)&&seed==floor(seed)&&seed>=0&&seed<=maximum,message)
}

.etr_cv_group_labels <- function(x,group_column,group_tie_order) {
  .etr_assert(is.character(group_column)&&length(group_column)==1L&&
    !is.na(group_column)&&group_column%in%names(x$metadata),
    "group_column is required and must exist in metadata")
  raw <- x$metadata[[group_column]]
  .etr_assert(length(raw)==length(x$curve_ids)&&!anyNA(raw),
    "group_column must have one nonmissing group per curve")
  if(group_tie_order=="native") return(as.character(raw))
  enc2utf8(.etr_gfosr_pandas_labels(raw,"group_column"))
}

.etr_cv_fold_assignment <- function(x,n_splits,cv_unit,group_column,shuffle,
    random_state,sparse_source_order=FALSE,random_engine="base_R",
    group_tie_order="native") {
  n<-length(x$curve_ids)
  if(identical(cv_unit,"curve")) {
    .etr_assert(n_splits<=n,"n_splits cannot exceed number of trajectories")
    indices<-seq_len(n)
    if(shuffle && random_engine=="numpy"){
      indices<-.etr_numpy_randomstate_permutation(n,random_state)
    }else if(shuffle) {
      .etr_cv_check_shuffle_seed(random_state,.Machine$integer.max,
        "random_state must be a nonnegative R seed for shuffle")
      old_exists<-exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
      if(old_exists)old_seed<-get(".Random.seed",envir=.GlobalEnv)
      on.exit({
        if(old_exists)assign(".Random.seed",old_seed,envir=.GlobalEnv)
        else if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
          rm(".Random.seed",envir=.GlobalEnv)
      },add=TRUE)
      set.seed(as.integer(random_state))
      indices<-sample(indices)
    }
    counts<-rep(n%/%n_splits,n_splits)
    if(n%%n_splits>0L)counts[seq_len(n%%n_splits)]<-
      counts[seq_len(n%%n_splits)]+1L
    assignment<-integer(n)
    cursor<-1L
    for(i in seq_len(n_splits)) {
      j<-cursor+counts[i]-1L
      assignment[indices[cursor:j]]<-i-1L
      cursor<-j+1L
    }
    return(list(fold=assignment,groups=NULL))
  }
  gr<-.etr_cv_group_labels(x,group_column,group_tie_order)
  labels<-if(sparse_source_order||group_tie_order!="native")
    sort(unique(gr),method="radix") else sort(unique(gr))
  .etr_assert(n_splits<=length(labels),
    "n_splits cannot exceed number of unique groups")
  group_index<-match(gr,labels)
  sizes<-tabulate(group_index,nbins=length(labels))
  # Frozen GroupKFold visits the reversed result of np.argsort(counts).
  # The native mode keeps the established deterministic tie policy.
  order<-if(group_tie_order=="numpy_simd"){
    rev(.etr_numpy_group_argsort_simd(sizes))
  }else if(group_tie_order=="numpy_scalar"){
    rev(.etr_numpy_group_argsort_scalar(sizes))
  }else if(all(diff(sizes)>=0L)){
    rev(seq_along(labels))
  }else if(sparse_source_order&&length(sizes)<=3L){
    # NumPy's scalar and SIMD paths agree on descending label order
    # within ties for up to three groups, including mixed group sizes.
    order(-sizes,-seq_along(labels))
  }else order(-sizes,seq_along(labels))
  totals<-numeric(n_splits)
  group_folds<-integer(length(labels))
  for(j in order) {
    fold<-which.min(totals)
    group_folds[j]<-fold-1L
    totals[fold]<-totals[fold]+sizes[j]
  }
  list(fold=group_folds[group_index],groups=gr)
}

# Exact predeclared source folds. Fold labels are 0-based, as in scikit-learn.
# The caller may replay NumPy-shuffled KFold or GroupKFold assignments, while
# the estimator and leakage barrier stay fully native R. No Python runtime.
.etr_cv_explicit_fold_assignment <- function(x,n_splits,cv_unit,
    group_column,fold_assignments,group_tie_order="native") {
  n<-length(x$curve_ids)
  .etr_assert(is.numeric(fold_assignments)&&
    is.null(dim(fold_assignments))&&length(fold_assignments)==n&&
    !anyNA(fold_assignments)&&all(is.finite(fold_assignments))&&
    all(fold_assignments==floor(fold_assignments))&&
    all(fold_assignments>=0L)&&all(fold_assignments<n_splits),
    "fold_assignments must contain one zero-based integer fold per curve")
  fold<-as.integer(fold_assignments)
  .etr_assert(identical(sort(unique(fold)),seq.int(0L,n_splits-1L)),
    "fold_assignments must populate every declared fold")
  if(identical(cv_unit,"curve"))
    return(list(fold=fold,groups=NULL))
  groups<-.etr_cv_group_labels(x,group_column,group_tie_order)
  per_group<-split(fold,groups)
  .etr_assert(all(vapply(per_group,function(z)length(unique(z))==1L,
    logical(1L))),
    "fold_assignments split a group between training and held-out folds")
  list(fold=fold,groups=groups)
}

.etr_cv_subset <- function(x,ids) {
  d<-dim(x$values)
  arr<-array(x$values[ids,,,drop=FALSE],
             c(length(ids),d[2L],d[3L]))
  etr_trajectory_set(x$time,arr,x$curve_ids[ids],x$dimension_names,
    x$metadata[ids,,drop=FALSE],x$coordinate_system,
    x$time_unit,x$provenance)
}

#' Leakage-aware held-out reconstruction CV for native dense FPCA
#' @param trajectories Native complete trajectories on the observed grid.
#' @param candidate_components Distinct positive integer retained counts.
#' @param n_splits Number of out-of-fold partitions (>=2).
#' @param scaling Explicit native FPCA channel scaling.
#' @param cv_unit Curve or group (participant) independent fold unit.
#' @param group_column Required for group folds, from curve metadata.
#' @param shuffle Shuffle curves for CV using an isolated R RNG.
#' @param random_state Nonnegative seed for the selected curve-fold RNG.
#' @param random_engine Use `"numpy"` for the frozen NumPy RandomState
#'   shuffle, or `"base_R"` for the original R permutation.
#' @param group_tie_order Use `"numpy_simd"` or `"numpy_scalar"` for
#'   the specified NumPy 2.3.5 GroupKFold sort, or `"native"` for the
#'   existing native grouped fold policy.
#' @export
etr_cross_validate_fpca_reconstruction <- function(trajectories,
    candidate_components=c(1L,2L,3L,4L,5L),n_splits=5L,scaling="none",
    cv_unit="curve",group_column=NULL,shuffle=TRUE,random_state=0L,
    fold_assignments=NULL,random_engine="base_R",group_tie_order="native") {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(candidate_components) &&
    length(candidate_components)>=1L &&
    all(is.finite(candidate_components)) &&
    all(candidate_components==as.integer(candidate_components)) &&
    all(candidate_components>=1L),
    "candidate_components must contain positive integer counts")
  counts<-sort(unique(as.integer(candidate_components)))
  .etr_assert(is.numeric(n_splits) && length(n_splits)==1L &&
    is.finite(n_splits) && n_splits==as.integer(n_splits) &&
    n_splits>=2L,"n_splits must be an integer >= 2")
  .etr_assert(is.character(cv_unit) && length(cv_unit)==1L &&
    cv_unit %in% c("curve","group"),
    "cv_unit must be 'curve' or 'group'")
  .etr_assert(is.character(scaling) && length(scaling)==1L &&
    scaling %in% c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  .etr_assert(is.logical(shuffle) && length(shuffle)==1L && !is.na(shuffle),
    "shuffle must be one explicit logical flag")
  random_engine<-match.arg(random_engine,c("base_R","numpy"))
  group_tie_order<-match.arg(group_tie_order,c("native","numpy_simd","numpy_scalar"))
  fold_source<-if(cv_unit=="group"&&group_tie_order!="native")
    paste0(group_tie_order,"_groupkfold") else "native_R"
  n_splits<-as.integer(n_splits)
  split<-if(is.null(fold_assignments))
    .etr_cv_fold_assignment(trajectories,n_splits,cv_unit,
      group_column,shuffle,random_state,random_engine=random_engine,
      group_tie_order=group_tie_order)
  else .etr_cv_explicit_fold_assignment(trajectories,n_splits,
    cv_unit,group_column,fold_assignments,group_tie_order)
  fold_errors<-vector("list",length(counts)*n_splits)
  assigns<-vector("list",n_splits)
  krow<-0L
  for(fold in 0:(n_splits-1L)) {
    test_ids<-which(split$fold==fold)
    train_ids<-which(split$fold!=fold)
    .etr_assert(length(test_ids)>=1L && length(train_ids)>=2L,
      "each fold requires one test curve and at least two training curves")
    p<-length(trajectories$time)*length(trajectories$dimension_names)
    max_k<-min(length(train_ids)-1L,p)
    .etr_assert(max(counts)<=max_k,
      paste("candidate component count",max(counts),
        "exceeds training-fold maximum",max_k))
    train<-.etr_cv_subset(trajectories,train_ids)
    test<-.etr_cv_subset(trajectories,test_ids)
    fit<-if(length(train$dimension_names)>1L)
      etr_fit_mfpca(train,n_components=as.integer(max(counts)),
                    scaling=scaling)
    else etr_fit_fpca(train,n_components=as.integer(max(counts)),
                      scaling=scaling)
    scores<-etr_transform_fpca(fit,test)
    for(k in counts) {
      reconstructed<-.etr_fpca_reconstruct_scores(fit,scores,k)
      w<-fit$weights;nd<-length(test$dimension_names)
      rmse<-vapply(seq_along(test_ids),function(i){
        total<-0
        for(d in seq_len(nd))
          total<-total+sum(w*(reconstructed[i,,d]-
            test$values[i,,d])^2)
        sqrt(total/(sum(w)*nd))
      },numeric(1L))
      krow<-krow+1L
      fold_errors[[krow]]<-data.frame(fold=as.integer(fold),
        n_components=as.integer(k),mean_integrated_rmse=mean(rmse),
        median_integrated_rmse=stats::median(rmse),
        n_train_curves=as.integer(length(train_ids)),
        n_test_curves=as.integer(length(test_ids)))
    }
    af<-data.frame(curve_id=trajectories$curve_ids[test_ids],
                   fold=rep(as.integer(fold),length(test_ids)),
                   stringsAsFactors=FALSE)
    if(!is.null(split$groups))af$group<-split$groups[test_ids]
    assigns[[fold+1L]]<-af
  }
  structure(list(fold_errors=do.call(rbind,fold_errors),
    assignments=do.call(rbind,assigns),
    component_counts=counts,cv_unit=cv_unit,n_splits=n_splits,
    group_column=if(cv_unit=="group")group_column else NULL,
    scaling=scaling,
    random_state=if(cv_unit=="curve" && shuffle)random_state else NULL,
    provenance=list(method="heldout_reconstruction_cv",
      fit_inside_fold=TRUE,
      shuffle=if(cv_unit=="curve")shuffle else FALSE,
      group_leakage_prevented=cv_unit=="group",
      fold_source=if(is.null(fold_assignments))fold_source else
        "explicit_zero_based_source_replay",
      random_engine=if(!is.null(fold_assignments))"none_fixed_folds" else
        if(cv_unit=="curve" && shuffle)
          if(random_engine=="numpy")"numpy_randomstate_mt19937" else "base_R_sample"
        else "deterministic",
      algorithmic_difference_from_python=if(cv_unit=="curve" && shuffle &&
          is.null(fold_assignments) && random_engine=="base_R")
        "R sample() and NumPy KFold RNG do not share permutations"
        else if(cv_unit=="group"&&group_tie_order=="native")
          "GroupKFold tie ordering is implementation-specific" else NULL)),
    class="etr_fpca_cv")
}

.etr_cv_summary <- function(fold_errors,value) {
  .etr_assert(is.data.frame(fold_errors) &&
    all(c("n_components",value)%in%names(fold_errors)) &&
    nrow(fold_errors)>0L && all(is.finite(fold_errors[[value]])) &&
    all(is.finite(fold_errors$n_components)) &&
    all(fold_errors$n_components>=1L),
    "fold errors must have finite loss and component counts")
  counts<-sort(unique(as.integer(fold_errors$n_components)))
  out<-lapply(counts,function(k){
    x<-fold_errors[[value]][fold_errors$n_components==k]
    data.frame(n_components=as.integer(k),mean=mean(x),
      sd=if(length(x)>1L)stats::sd(x) else 0,
      n_folds=as.integer(length(x)),se=if(length(x)>1L)
        stats::sd(x)/sqrt(length(x)) else 0)
  })
  do.call(rbind,out)
}

#' Aggregate held-out reconstruction RMSE by candidate component count
#' @param result Native FPCA CV result with frozen fold errors.
#' @export
etr_summarise_fpca_cross_validation <- function(result) {
  .etr_cv_fields(result,"fold_errors","FPCA CV")
  x<-.etr_cv_summary(result$fold_errors,"mean_integrated_rmse")
  names(x)<-c("n_components","mean_rmse","sd_rmse","n_folds","se_rmse")
  rownames(x)<-NULL;x
}

#' Explicit minimum or one-standard-error FPCA component rule
#' @param rule Minimum mean RMSE or parsimonious one-SE rule.
#' @inheritParams etr_summarise_fpca_cross_validation
#' @export
etr_select_fpca_components_cv <- function(result,rule="minimum") {
  .etr_assert(is.character(rule)&&length(rule)==1L &&
    rule%in%c("minimum","one_se"),
    "rule must be 'minimum' or 'one_se'")
  s<-etr_summarise_fpca_cross_validation(result)
  best<-which.min(s$mean_rmse)
  if(rule=="minimum")return(as.integer(s$n_components[best]))
  eligible<-s$n_components[s$mean_rmse<=
    s$mean_rmse[best]+s$se_rmse[best]]
  as.integer(min(eligible))
}

#' Aggregate held-out FPCA regression loss by component count
#' @inheritParams etr_summarise_fpca_cross_validation
#' @export
etr_summarise_fpca_regression_cv <- function(result) {
  .etr_cv_fields(result,"fold_losses","FPCA regression CV")
  x<-.etr_cv_summary(result$fold_losses,"loss")
  names(x)<-c("n_components","mean_loss","sd_loss","n_folds","se_loss")
  rownames(x)<-NULL;x
}

#' Select a regression FPC count by minimum-loss or one-SE criterion
#' @inheritParams etr_select_fpca_components_cv
#' @export
etr_select_fpca_regression_components <- function(result,rule="minimum") {
  .etr_assert(is.character(rule)&&length(rule)==1L &&
    rule%in%c("minimum","one_se"),
    "rule must be 'minimum' or 'one_se'")
  s<-etr_summarise_fpca_regression_cv(result)
  i<-which.min(s$mean_loss)
  if(rule=="minimum")return(as.integer(s$n_components[i]))
  as.integer(min(s$n_components[s$mean_loss<=
    s$mean_loss[i]+s$se_loss[i]]))
}

#' Fixed-target FPCA score uncertainty as an explicit long table
#' @param result Declared score uncertainty with fixed target scores.
#' @export
etr_fpca_score_uncertainty_frame <- function(result) {
  fields<-c("target_curve_ids","n_components","reference_scores",
    "median","score_se","lower","upper","similarities")
  .etr_cv_fields(result,fields,"score uncertainty")
  ids<-.etr_cv_curve_ids(result$target_curve_ids)
  n<-length(ids);k<-as.integer(result$n_components)
  .etr_assert(length(k)==1L && !is.na(k) && k>0L,
    "n_components must be positive")
  for(field in c("reference_scores","median","score_se","lower","upper"))
    .etr_cv_numeric_matrix(result[[field]],n,k,field)
  ss<-result$similarities
  .etr_assert(is.matrix(ss)&&is.numeric(ss)&&ncol(ss)==k&&
    nrow(ss)>0L && all(is.finite(ss)),
    "matched similarities must be finite bootstrap-by-component matrix")
  med<-apply(ss,2L,stats::median)
  rows<-vector("list",n*k);p<-0L
  for(i in seq_len(n))for(j in seq_len(k)){
    p<-p+1L
    rows[[p]]<-data.frame(curve_id=ids[i],component=as.integer(j),
      reference_score=result$reference_scores[i,j],
      bootstrap_median=result$median[i,j],bootstrap_se=result$score_se[i,j],
      lower=result$lower[i,j],upper=result$upper[i,j],
      median_matched_abs_similarity=med[j])
  }
  do.call(rbind,rows)
}

#' Frozen component-level FPCA eigenvalue/ratio bootstrap summaries
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_fpca_spectrum_uncertainty_frame <- function(result) {
  .etr_cv_fields(result,c("reference","n_components","similarities"),
    "spectrum uncertainty")
  .etr_fpca_fitted_check(result$reference)
  k<-as.integer(result$n_components)
  .etr_assert(length(k)==1L&&!is.na(k)&&k>=1L&&
    k<=result$reference$n_components,"n_components outside fitted spectrum")
  fields<-c("eigenvalue_se","eigenvalue_lower","eigenvalue_upper",
    "explained_variance_ratio_se","explained_variance_ratio_lower",
    "explained_variance_ratio_upper","cumulative_variance_ratio_se",
    "cumulative_variance_ratio_lower","cumulative_variance_ratio_upper")
  .etr_cv_fields(result,fields,"spectrum uncertainty")
  for(f in fields).etr_cv_numeric_vector(result[[f]],k,f)
  ss<-result$similarities
  .etr_assert(is.matrix(ss)&&is.numeric(ss)&&nrow(ss)>0L&&
    ncol(ss)==k&&all(is.finite(ss)),
    "similarities must be a finite bootstrap-by-component matrix")
  data.frame(component=seq_len(k),
    eigenvalue=result$reference$explained_variance[seq_len(k)],
    eigenvalue_se=result$eigenvalue_se,
    eigenvalue_lower=result$eigenvalue_lower,
    eigenvalue_upper=result$eigenvalue_upper,
    explained_variance_ratio=
      result$reference$explained_variance_ratio[seq_len(k)],
    explained_variance_ratio_se=result$explained_variance_ratio_se,
    explained_variance_ratio_lower=result$explained_variance_ratio_lower,
    explained_variance_ratio_upper=result$explained_variance_ratio_upper,
    cumulative_variance_ratio=cumsum(
      result$reference$explained_variance_ratio[seq_len(k)]),
    cumulative_variance_ratio_se=result$cumulative_variance_ratio_se,
    cumulative_variance_ratio_lower=result$cumulative_variance_ratio_lower,
    cumulative_variance_ratio_upper=result$cumulative_variance_ratio_upper,
    median_matched_abs_similarity=apply(ss,2L,stats::median))
}

#' Fixed-target split-conformal anomaly calibration as a decision table
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_conformal_fpca_anomaly_frame <- function(result) {
  .etr_cv_fields(result,c("target_curve_ids","target_scores","p_values",
    "alpha","review_flags","minimum_attainable_p"),
    "conformal anomaly")
  ids<-.etr_cv_curve_ids(result$target_curve_ids)
  n<-length(ids)
  scores<-.etr_cv_numeric_vector(result$target_scores,n,"target_scores")
  pv<-.etr_cv_numeric_vector(result$p_values,n,"p_values")
  .etr_assert(all(pv>=0 & pv<=1),"conformal p-values must lie in [0,1]")
  .etr_assert(is.logical(result$review_flags)&&length(result$review_flags)==n &&
    !anyNA(result$review_flags),
    "review flags must be declared logical per target")
  alpha<-.etr_nonlinear_report_number(result$alpha,"alpha")
  minp<-.etr_nonlinear_report_number(result$minimum_attainable_p,"minimum_attainable_p")
  .etr_assert(alpha>0&&alpha<1&&minp>0&&minp<=1,
    "alpha and minimum attainable p must be valid")
  data.frame(curve_id=ids,nonconformity_score=scores,
    conformal_p_value=pv,alpha=rep(alpha,n),
    review_flag=result$review_flags,minimum_attainable_p=rep(minp,n))
}

#' Declared trajectory distance specification comparisons
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_trajectory_distance_comparison_frame <- function(result) {
  .etr_cv_fields(result,"comparison_table","distance sensitivity")
  .etr_assert(is.data.frame(result$comparison_table),
    "comparison_table must be a data frame")
  result$comparison_table
}

#' Declared per-curve nearest-neighbor agreement across distances
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_trajectory_distance_neighbor_frame <- function(result) {
  .etr_cv_fields(result,"neighbor_overlap_table","distance sensitivity")
  .etr_assert(is.data.frame(result$neighbor_overlap_table),
    "neighbor_overlap_table must be a data frame")
  result$neighbor_overlap_table
}

#' Long-form observed-grid simultaneous FPCR slope-band values
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_fpca_regression_slope_band_frame <- function(result) {
  .etr_cv_fields(result,c("regression_uncertainty","pointwise_se",
    "critical_values","lower","upper"),"FPCR slope band")
  base<-result$regression_uncertainty
  .etr_cv_fields(base,c("reference_fpca","reference_slope"),"FPCR uncertainty")
  fit<-base$reference_fpca
  .etr_fpca_fitted_check(fit);n<-length(fit$time);d<-length(fit$dimension_names)
  for(f in c("reference_slope"))
    .etr_cv_numeric_matrix(base[[f]],n,d,f)
  for(f in c("pointwise_se","lower","upper"))
    .etr_cv_numeric_matrix(result[[f]],n,d,f)
  critical<-.etr_cv_numeric_vector(result$critical_values,d,"critical_values")
  rows<-vector("list",n*d);p<-0L
  for(i in seq_len(n))for(j in seq_len(d)){
    p<-p+1L
    rows[[p]]<-data.frame(time=fit$time[i],
      dimension=fit$dimension_names[j],
      reference_slope=base$reference_slope[i,j],
      pointwise_se=result$pointwise_se[i,j],
      critical_value=critical[j],lower=result$lower[i,j],
      upper=result$upper[i,j])
  }
  do.call(rbind,rows)
}

#' Long-form pointwise FPCR slope bootstrap interval summaries
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_fpca_regression_slope_uncertainty_frame <- function(result) {
  .etr_cv_fields(result,c("reference_fpca","reference_slope",
    "slope_median","slope_se","slope_lower","slope_upper"),
    "FPCR slope uncertainty")
  fit<-result$reference_fpca
  .etr_fpca_fitted_check(fit);n<-length(fit$time);d<-length(fit$dimension_names)
  for(f in c("reference_slope","slope_median","slope_se",
             "slope_lower","slope_upper"))
    .etr_cv_numeric_matrix(result[[f]],n,d,f)
  rows<-vector("list",n*d);p<-0L
  for(i in seq_len(n))for(j in seq_len(d)){
    p<-p+1L
    rows[[p]]<-data.frame(time=fit$time[i],dimension=fit$dimension_names[j],
      reference_slope=result$reference_slope[i,j],
      bootstrap_median=result$slope_median[i,j],
      bootstrap_se=result$slope_se[i,j],
      lower=result$slope_lower[i,j],upper=result$slope_upper[i,j])
  }
  do.call(rbind,rows)
}

#' Fixed-target conditional mean FPCR prediction uncertainty table
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_fpca_regression_prediction_uncertainty_frame <- function(result) {
  fields<-c("target_curve_ids","reference_mean_predictions",
    "prediction_median","prediction_se","prediction_lower","prediction_upper")
  .etr_cv_fields(result,fields,"FPCR conditional predictions")
  ids<-.etr_cv_curve_ids(result$target_curve_ids)
  n<-length(ids)
  for(f in fields[-1L]).etr_cv_numeric_vector(result[[f]],n,f)
  data.frame(curve_id=ids,
    reference_mean_prediction=result$reference_mean_predictions,
    bootstrap_median=result$prediction_median,
    bootstrap_se=result$prediction_se,
    lower=result$prediction_lower,upper=result$prediction_upper)
}

#' Fixed-target FPCR future-outcome prediction interval table
#' @inheritParams etr_fpca_score_uncertainty_frame
#' @export
etr_fpca_regression_future_prediction_frame <- function(result) {
  .etr_cv_fields(result,c("regression_uncertainty","median",
    "predictive_se","lower","upper"),"FPCR future prediction")
  base<-result$regression_uncertainty
  .etr_cv_fields(base,c("target_curve_ids","reference_mean_predictions",
    "prediction_lower","prediction_upper"),"FPCR regression uncertainty")
  ids<-.etr_cv_curve_ids(base$target_curve_ids)
  n<-length(ids)
  for(f in c("reference_mean_predictions","prediction_lower","prediction_upper"))
    .etr_cv_numeric_vector(base[[f]],n,f)
  for(f in c("median","predictive_se","lower","upper"))
    .etr_cv_numeric_vector(result[[f]],n,f)
  data.frame(curve_id=ids,
    reference_mean_prediction=base$reference_mean_predictions,
    mean_response_lower=base$prediction_lower,
    mean_response_upper=base$prediction_upper,
    future_prediction_median=result$median,
    future_prediction_se=result$predictive_se,
    future_prediction_lower=result$lower,
    future_prediction_upper=result$upper)
}
