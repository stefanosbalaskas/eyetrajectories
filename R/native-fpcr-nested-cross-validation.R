# Frozen eyetrajectoriespy 1.2.0 prediction.py::nested_cross_validate_fpca_regression
# Commit c1cd95ad718327550f7e55393ff38582872f7a94
# Source-bounded Gaussian OLS or Bernoulli logit FPCR nested CV with
# group-held-out folds; Python statsmodels and R glm.fit can differ.
#' Nested Gaussian or binomial FPCR cross-validation with outer assessment
#' @param trajectories Native complete common-grid trajectories.
#' @param outcome Finite scalar response per curve.
#' @param candidate_components Candidate positive integer retained counts.
#' @param family Gaussian continuous or binomial 0/1 outcome family.
#' @param loss Gaussian: rmse (default) or mae. Binomial: log_loss
#'   (default) or brier.
#' @param covariates NULL or a curve-aligned finite numeric data.frame.
#'   All inner and outer regression fits use training-only rows.
#' @param outer_splits Outer KFold count.
#' @param inner_splits Inner KFold count.
#' @param selection_rule minimum or one_se.
#' @param scaling none or dimension_sd.
#' @param cv_unit Curve or grouped participant holdout unit.
#' @param group_column Required metadata column for group CV.
#' @param shuffle Shuffle the curve folds inside and outside selection.
#' @param random_state Seed for shuffled curve folds; group folds ignore it.
#' @param random_engine Use `"numpy"` for the frozen NumPy RandomState
#'   shuffle, or `"base_R"` for the original R permutation.
#' @param group_tie_order Grouped fold sort profile at both levels:
#'   `"native"`, `"numpy_simd"` or `"numpy_scalar"`.
#' @param coerce_numeric_text_covariates Native-only optional parsing of
#'   finite text/underscore numeric covariate columns. Default FALSE: the
#'   full Python 1.2 statsmodels model rejects object-typed pandas columns.
#' @param strict_source_record If TRUE, emit canonical frozen Python 1.2
#'   scientific provenance only and reject R-only explicit folds and text
#'   coercion. Shuffled folds require the native NumPy-compatible engine,
#'   while group CV requires an explicit NumPy group-sort profile. The
#'   default retains the expanded native R diagnostic provenance.
#' @export
etr_nested_cross_validate_fpca_regression <- function(
  trajectories, outcome, candidate_components=c(1L,2L,3L,4L,5L),
  family="gaussian", loss=NULL, covariates=NULL,
  outer_splits=5L, inner_splits=4L, selection_rule="minimum",
  scaling="none", cv_unit="curve", group_column=NULL,
  shuffle=FALSE, random_state=0L,
  outer_fold_assignments=NULL,inner_fold_assignments=NULL,
  coerce_numeric_text_covariates=FALSE,random_engine="base_R",
  group_tie_order="native",strict_source_record=FALSE) {
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a single TRUE or FALSE")
  if(isTRUE(strict_source_record)){
    .etr_assert(is.null(outer_fold_assignments)&&
      is.null(inner_fold_assignments),
      "strict_source_record cannot import R-only outer or inner fold assignments")
    .etr_assert(identical(coerce_numeric_text_covariates,FALSE),
      "strict_source_record cannot enable R-only text covariate coercion")
    if(identical(cv_unit,"curve")&&isTRUE(shuffle))
      .etr_assert(identical(random_engine,"numpy"),
        "strict_source_record shuffled nested CV requires random_engine='numpy'")
    if(identical(cv_unit,"group"))
      .etr_assert(group_tie_order%in%c("numpy_simd","numpy_scalar"),
        "strict_source_record group nested CV requires an explicit NumPy tie-order profile")
  }
  etr_validate(trajectories,require_complete=TRUE)
  .etr_fpcr_validate_family(family)
  resolved_loss<-.etr_fpcr_resolve_loss(family,loss)
  covariate_matrix<-.etr_fpcr_numeric_covariates(covariates,
    length(trajectories$curve_ids),coerce_text=coerce_numeric_text_covariates)
  .etr_assert(is.character(cv_unit)&&length(cv_unit)==1L&&
    !is.na(cv_unit)&&cv_unit%in%c("curve","group"),
    "cv_unit must be curve or group")
  if(identical(cv_unit,"group"))
    .etr_assert(is.character(group_column)&&
      length(group_column)==1L&&!is.na(group_column)&&
      nzchar(group_column),
      "group_column is required for grouped nested CV")
  n<-length(trajectories$curve_ids)
  .etr_assert(is.numeric(outer_splits)&&length(outer_splits)==1L&&
    !is.na(outer_splits)&&is.finite(outer_splits)&&
    outer_splits==floor(outer_splits)&&
    outer_splits>=2&&outer_splits<=n,
    "outer_splits invalid")
  .etr_assert(is.numeric(inner_splits)&&length(inner_splits)==1L&&
    !is.na(inner_splits)&&is.finite(inner_splits)&&
    inner_splits==floor(inner_splits)&&inner_splits>=2,
    "inner_splits invalid")
  .etr_assert(is.logical(shuffle)&&length(shuffle)==1L&&!is.na(shuffle),
    "shuffle must be one explicit logical flag")
  random_engine<-match.arg(random_engine,c("base_R","numpy"))
  group_tie_order<-match.arg(group_tie_order,c("native","numpy_simd","numpy_scalar"))
  fold_source<-if(cv_unit=="group"&&group_tie_order!="native")
    paste0(group_tie_order,"_groupkfold") else "native_R"
  if(identical(cv_unit,"curve")&&shuffle){
    if(random_engine=="numpy"){
      .etr_cv_check_shuffle_seed(random_state,2^32-1-outer_splits,
        "random_state must allow unsigned 32-bit inner/outer NumPy shuffle seeds")
    }else{
      .etr_cv_check_shuffle_seed(random_state,.Machine$integer.max-outer_splits-1L,
        "random_state must allow nonnegative inner/outer R shuffle seeds")
    }
  }
  .etr_assert(is.character(selection_rule)&&length(selection_rule)==1L&&
    !is.na(selection_rule)&&selection_rule%in%c("minimum","one_se"),
    "selection_rule must be minimum or one_se")
  outcome<-.etr_fpcr_numeric_outcome(outcome,n,family,
    "outcome must be finite and curve aligned")
  .etr_assert(is.numeric(candidate_components)&&
    length(candidate_components)>0L&&!anyNA(candidate_components)&&
    all(is.finite(candidate_components))&&
    all(candidate_components==floor(candidate_components))&&
    all(candidate_components>=1)&&
    all(candidate_components<=.Machine$integer.max),
    "candidate_components must be positive integers")
  counts<-sort(unique(as.integer(candidate_components)))
  no<-as.integer(outer_splits);ni<-as.integer(inner_splits)
  if(!is.null(inner_fold_assignments))
    .etr_assert(is.list(inner_fold_assignments)&&
      length(inner_fold_assignments)==no,
      "inner_fold_assignments must be one fold vector per outer fold")
  splits<-if(is.null(outer_fold_assignments))
    .etr_cv_fold_assignment(trajectories,no,cv_unit,
      group_column,shuffle,random_state,random_engine=random_engine,
      group_tie_order=group_tie_order)
  else .etr_cv_explicit_fold_assignment(trajectories,no,cv_unit,
    group_column,outer_fold_assignments,group_tie_order)
  fold_ids<-splits$fold
  outer_rows<-vector("list",no);inner_rows<-vector("list",no)
  prediction_rows<-vector("list",n);cursor<-0L
  for(f in 0:(no-1L)) {
    train_idx<-which(fold_ids!=f);test_idx<-which(fold_ids==f)
    .etr_assert(length(train_idx)>=ni,"inner_splits exceeds outer training size")
    train<-.etr_cv_subset(trajectories,train_idx)
    inner_cv<-etr_cross_validate_fpca_regression(
      train,outcome[train_idx],candidate_components=counts,
      family=family,loss=loss,
      covariates=if(is.null(covariate_matrix))NULL else
        as.data.frame(covariate_matrix[train_idx,,drop=FALSE]),
      n_splits=ni,
      scaling=scaling,cv_unit=cv_unit,group_column=group_column,
      shuffle=if(identical(cv_unit,"curve"))shuffle else FALSE,
      random_state=if(identical(cv_unit,"curve")&&shuffle)
        random_state+f+1L else NULL,
      fold_assignments=if(is.null(inner_fold_assignments))NULL else
        inner_fold_assignments[[f+1L]],
      random_engine=random_engine,group_tie_order=group_tie_order,
      strict_source_record=strict_source_record)
    selected<-etr_select_fpca_regression_components(inner_cv,rule=selection_rule)
    summary<-etr_summarise_fpca_regression_cv(inner_cv)
    inner_rows[[f+1L]]<-data.frame(outer_fold=rep(as.integer(f),nrow(summary)),
      summary,check.names=FALSE)
    fit<-if(length(train$dimension_names)>1L)
      etr_fit_mfpca(train,n_components=as.integer(selected),scaling=scaling)
    else etr_fit_fpca(train,n_components=as.integer(selected),scaling=scaling)
    scores<-etr_transform_fpca(fit,.etr_cv_subset(trajectories,test_idx))
    x_train<-cbind(rep(1,length(train_idx)),
      fit$scores[,seq_len(selected),drop=FALSE],
      if(!is.null(covariate_matrix))
        covariate_matrix[train_idx,,drop=FALSE])
    x_test<-cbind(rep(1,length(test_idx)),
      scores[,seq_len(selected),drop=FALSE],
      if(!is.null(covariate_matrix))
        covariate_matrix[test_idx,,drop=FALSE])
    .etr_assert(qr(x_train)$rank==ncol(x_train),"outer FPCR design is rank deficient")
    pred<-.etr_fpcr_predict_fold(x_train,x_test,outcome[train_idx],family)
    score<-.etr_fpcr_loss(outcome[test_idx],pred,family,resolved_loss)
    outer_rows[[f+1L]]<-data.frame(outer_fold=as.integer(f),
      selected_n_components=as.integer(selected),loss=score,
      n_train_curves=as.integer(length(train_idx)),
      n_test_curves=as.integer(length(test_idx)))
    for(j in seq_along(test_idx)){
      cursor<-cursor+1L
      row<-data.frame(
        curve_id=trajectories$curve_ids[test_idx[[j]]],
        outer_fold=as.integer(f),observed=outcome[test_idx[[j]]],
        prediction=pred[[j]],selected_n_components=as.integer(selected))
      if(!is.null(splits$groups))
        row$group<-splits$groups[test_idx[[j]]]
      prediction_rows[[cursor]]<-row
    }
  }
  outer<-do.call(rbind,outer_rows);inside<-do.call(rbind,inner_rows)
  predictions<-do.call(rbind,prediction_rows)
  rownames(outer)<-NULL;rownames(inside)<-NULL;rownames(predictions)<-NULL
  result<-structure(list(outer_folds=outer,inner_summaries=inside,
    predictions=predictions,family=family,
    loss=resolved_loss,selection_rule=selection_rule,
    component_counts=counts,outer_splits=no,inner_splits=ni,
    cv_unit=cv_unit,
    group_column=if(identical(cv_unit,"group"))group_column else NULL,
    scaling=scaling,
    random_state=if(identical(cv_unit,"curve")&&shuffle)
      random_state else NULL,
    provenance=list(method="nested_outcome_tuned_fpca_regression_cv",
      nested_selection=TRUE,outer_performance_unseen_by_inner_selection=TRUE,
      group_leakage_prevented=identical(cv_unit,"group"),
      outer_fold_source=if(is.null(outer_fold_assignments))fold_source else
        "explicit_zero_based_source_replay",
      inner_fold_source=if(is.null(inner_fold_assignments))fold_source else
        "explicit_zero_based_source_replay",
      random_engine=if(!is.null(outer_fold_assignments)&&
        !is.null(inner_fold_assignments))"none_fixed_folds" else
        if(identical(cv_unit,"curve")&&shuffle)
          if(random_engine=="numpy")"numpy_randomstate_mt19937" else "base_R_sample_not_NumPy"
        else "deterministic",
      covariates=if(is.null(covariate_matrix))list() else
        as.list(colnames(covariate_matrix)),
      scientific_warning=paste(
        "Outer-fold performance estimates the predictive pipeline with",
        "inner FPC-count selection. It does not remove within-group",
        "dependence from a curve-level outcome model."))),
    class="etr_nested_fpcr_cv")
  if(isTRUE(strict_source_record)){
    source_fields<-c("method","nested_selection","outer_performance_unseen_by_inner_selection","group_leakage_prevented","covariates","scientific_warning")
    .etr_assert(all(source_fields%in%names(result$provenance)),
      "strict FPCR CV source provenance fields are incomplete")
    result$provenance<-result$provenance[source_fields]
    .etr_assert(identical(names(result$provenance),source_fields),
      "strict FPCR CV source provenance order is invalid")
  }
  result
}
