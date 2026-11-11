# Source: frozen eyetrajectoriespy==1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94
# prediction.py::cross_validate_fpca_regression
# Native Gaussian OLS and bounded binomial logit FPCR with
# whole-group held-out folds and source-seeded curve fold shuffle.
# Binomial stats::glm.fit is not identical to statsmodels IRLS.

#' Leakage-free native Gaussian and binomial FPCR held-out prediction
#'
#' Refits unsupervised dense FPCA and Gaussian OLS or binomial logit GLM
#' *inside* each training fold. Reuses the same training FPCA basis for
#' test projections.
#' Supports group holdout and native or source-seeded shuffled curve folds.
#' Mixed-size GroupKFold ties remain dependent on the source NumPy build.
#' For binomial outcomes, R stats::glm.fit may differ from statsmodels;
#' numeric covariates are fitted within training folds only.
#' @param trajectories Complete native common-grid trajectory set.
#' @param outcome Curve-aligned finite scalar outcomes.
#' @param candidate_components Positive integer FPC counts to compare.
#' @param family \code{"gaussian"} or \code{"binomial"} (binary 0/1).
#' @param loss Gaussian: \code{"rmse"} (default) or \code{"mae"}.
#'   Binomial: \code{"log_loss"} (default) or \code{"brier"}.
#' @param covariates NULL or a curve-aligned numeric data.frame with unique
#'   nonreserved column names and finite values. Training and held-out
#'   rows are separated within each fold.
#' @param n_splits Number of KFold or GroupKFold partitions (>=2).
#' @param scaling Native dense FPCA scaling.
#' @param cv_unit "curve" or "group"; group CV holds all trials
#'   of a participant/group together in the same held-out fold.
#' @param group_column For group CV, required metadata column containing
#'   nonmissing group identifiers. Ignored for curve CV.
#' @param shuffle Shuffle the curve folds. Group CV is deterministic.
#' @param random_state Nonnegative integer seed for shuffled curve folds.
#' @param random_engine Use `"numpy"` for the frozen NumPy RandomState
#'   shuffle, or `"base_R"` for the original R permutation.
#' @param group_tie_order Grouped fold sort profile: `"native"`,
#'   `"numpy_simd"` or `"numpy_scalar"`.
#' @return Source-shaped fold losses, test predictions, assignments and
#'   provenance; never fits on held-out curves.
#' @param coerce_numeric_text_covariates Native-only optional parsing of
#'   finite text/underscore numeric covariate columns. Default FALSE, since
#'   frozen Python 1.2 statsmodels rejects object-typed pandas covariates.
#'   This opt-in feature is NOT strict Python input-domain equivalence.
#' @param strict_source_record If TRUE, emit canonical frozen Python 1.2
#'   scientific provenance only and reject R-only explicit folds and text
#'   coercion. Shuffled folds require the native NumPy-compatible engine,
#'   while group CV requires an explicit NumPy group-sort profile. The
#'   default retains the expanded native R diagnostic provenance.
#' @export
etr_cross_validate_fpca_regression<-function(
    trajectories,outcome,candidate_components=c(1L,2L,3L,4L,5L),
    family="gaussian",loss=NULL,covariates=NULL,n_splits=5L,
    scaling="none",cv_unit="curve",group_column=NULL,
    shuffle=FALSE,random_state=0L,fold_assignments=NULL,
    coerce_numeric_text_covariates=FALSE,random_engine="base_R",
    group_tie_order="native",strict_source_record=FALSE){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a single TRUE or FALSE")
  if(isTRUE(strict_source_record)){
    .etr_assert(is.null(fold_assignments),
      "strict_source_record cannot import R-only fold_assignments")
    .etr_assert(identical(coerce_numeric_text_covariates,FALSE),
      "strict_source_record cannot enable R-only text covariate coercion")
    if(identical(cv_unit,"curve")&&isTRUE(shuffle))
      .etr_assert(identical(random_engine,"numpy"),
        "strict_source_record shuffled curve CV requires random_engine='numpy'")
    if(identical(cv_unit,"group"))
      .etr_assert(group_tie_order%in%c("numpy_simd","numpy_scalar"),
        "strict_source_record group CV requires an explicit NumPy tie-order profile")
  }
  etr_validate(trajectories,require_complete=TRUE)
  .etr_fpcr_validate_family(family)

  .etr_assert(is.character(cv_unit)&&length(cv_unit)==1L&&
    !is.na(cv_unit)&&cv_unit%in%c("curve","group"),
    "cv_unit must be 'curve' or 'group'")
  .etr_assert(is.null(group_column)||(
    is.character(group_column)&&length(group_column)==1L&&
    !is.na(group_column)&&nzchar(group_column)),
    "group_column must be a metadata column name or NULL")
  if(identical(cv_unit,"group"))
    .etr_assert(!is.null(group_column),
      "group_column is required for group CV")
  .etr_assert(is.logical(shuffle)&&length(shuffle)==1L&&!is.na(shuffle),
    "shuffle must be one explicit logical flag")
  random_engine<-match.arg(random_engine,c("base_R","numpy"))
  group_tie_order<-match.arg(group_tie_order,c("native","numpy_simd","numpy_scalar"))
  fold_source<-if(cv_unit=="group"&&group_tie_order!="native")
    paste0(group_tie_order,"_groupkfold") else "native_R"
  if(identical(cv_unit,"curve")&&shuffle){
    if(random_engine=="numpy"){
      .etr_cv_check_shuffle_seed(random_state,2^32-1,
        "random_state must be an unsigned 32-bit integer for NumPy shuffle")
    }else{
      .etr_cv_check_shuffle_seed(random_state,.Machine$integer.max,
        "random_state must be a nonnegative R integer seed for shuffled curve folds")
    }
  }else
    .etr_assert(is.null(random_state)||(
      is.numeric(random_state)&&length(random_state)==1L&&
      !is.na(random_state)&&is.finite(random_state)),
      "random_state must be numeric or NULL")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  resolved_loss<-.etr_fpcr_resolve_loss(family,loss)
  n<-length(trajectories$curve_ids)
  covariate_matrix<-.etr_fpcr_numeric_covariates(covariates,n,
    coerce_text=coerce_numeric_text_covariates)
  outcome<-.etr_fpcr_numeric_outcome(outcome,n,family,
    "outcome must contain one finite scalar per trajectory")
  .etr_assert(is.numeric(candidate_components)&&
    length(candidate_components)>=1L&&
    !anyNA(candidate_components)&&
    all(is.finite(candidate_components))&&
    all(candidate_components==floor(candidate_components))&&
    all(candidate_components>=1L)&&
    all(candidate_components<=.Machine$integer.max),
    "candidate_components must contain positive integers")
  components<-sort(unique(as.integer(candidate_components)))
  .etr_assert(is.numeric(n_splits)&&length(n_splits)==1L&&
    is.finite(n_splits)&&n_splits==floor(n_splits)&&
    n_splits>=2L&&n_splits<=n,
    "n_splits must be an integer between 2 and the number of curves")
  ns<-as.integer(n_splits)
  split<-if(is.null(fold_assignments))
    .etr_cv_fold_assignment(trajectories,ns,cv_unit,
      group_column,shuffle,random_state,random_engine=random_engine,
      group_tie_order=group_tie_order)
  else .etr_cv_explicit_fold_assignment(trajectories,ns,cv_unit,
    group_column,fold_assignments,group_tie_order)
  folds<-split$fold
  fold_rows<-vector("list",ns*length(components))
  assign_rows<-vector("list",ns)
  prediction_rows<-vector("list",n*length(components))
  pos<-0L;prediction_pos<-0L
  for(fold in 0:(ns-1L)){
    testing<-which(folds==fold)
    training<-which(folds!=fold)
    p<-length(trajectories$time)*length(trajectories$dimension_names)
    maximum<-min(length(training)-1L,p)
    .etr_assert(max(components)<=maximum,
      paste("candidate component count",max(components),
        "exceeds training-fold maximum",maximum))
    train<-.etr_cv_subset(trajectories,training)
    test<-.etr_cv_subset(trajectories,testing)
    fit<-if(length(train$dimension_names)>1L)
      etr_fit_mfpca(train,n_components=as.integer(max(components)),
        scaling=scaling)
    else
      etr_fit_fpca(train,n_components=as.integer(max(components)),
        scaling=scaling)
    test_scores<-etr_transform_fpca(fit,test)
    for(k in components){
      train_design<-cbind(rep(1,length(training)),
        fit$scores[,seq_len(k),drop=FALSE],
        if(!is.null(covariate_matrix))
          covariate_matrix[training,,drop=FALSE])
      test_design<-cbind(rep(1,length(testing)),
        test_scores[,seq_len(k),drop=FALSE],
        if(!is.null(covariate_matrix))
          covariate_matrix[testing,,drop=FALSE])
      .etr_assert(qr(train_design)$rank==ncol(train_design),
        "native regression CV requires full-rank training FPC design")
      predicted<-.etr_fpcr_predict_fold(train_design,test_design,
        outcome[training],family)
      fold_loss<-.etr_fpcr_loss(outcome[testing],predicted,
        family,resolved_loss)
      pos<-pos+1L
      fold_rows[[pos]]<-data.frame(
        fold=as.integer(fold),n_components=as.integer(k),
        loss=as.numeric(fold_loss),
        n_train_curves=as.integer(length(training)),
        n_test_curves=as.integer(length(testing)))
      for(v in seq_along(testing)){
        prediction_pos<-prediction_pos+1L
        prediction_rows[[prediction_pos]]<-data.frame(
          curve_id=trajectories$curve_ids[testing[[v]]],
          fold=as.integer(fold),n_components=as.integer(k),
          observed=as.numeric(outcome[testing[[v]]]),
          prediction=predicted[[v]],stringsAsFactors=FALSE)
      }
    }
    assignment<-data.frame(
      curve_id=trajectories$curve_ids[testing],
      fold=rep(as.integer(fold),length(testing)),
      stringsAsFactors=FALSE)
    if(!is.null(split$groups))assignment$group<-split$groups[testing]
    assign_rows[[fold+1L]]<-assignment
  }
  fold_losses<-do.call(rbind,fold_rows)
  assignments<-do.call(rbind,assign_rows)
  predictions<-do.call(rbind,prediction_rows)
  for(frame in c("fold_losses","assignments","predictions")){
    obj<-get(frame);rownames(obj)<-NULL
    assign(frame,obj)
  }
  result<-structure(list(
    fold_losses=fold_losses,assignments=assignments,
    predictions=predictions,component_counts=components,
    family=family,loss=resolved_loss,cv_unit=cv_unit,
    n_splits=ns,
    group_column=if(identical(cv_unit,"group"))group_column else NULL,
    scaling=scaling,
    random_state=if(identical(cv_unit,"curve")&&isTRUE(shuffle))
      random_state else NULL,provenance=list(
      method="outcome_tuned_fpca_regression_cv",
      fit_fpca_inside_fold=TRUE,
      fit_regression_inside_fold=TRUE,
      group_leakage_prevented=identical(cv_unit,"group"),
      shuffle=if(identical(cv_unit,"curve"))shuffle else FALSE,
      random_engine=if(!is.null(fold_assignments))"none_fixed_folds" else
        if(identical(cv_unit,"curve")&&isTRUE(shuffle))
          if(random_engine=="numpy")"numpy_randomstate_mt19937" else "base_R_sample_not_NumPy"
        else "deterministic",
      fold_source=if(is.null(fold_assignments))fold_source else
        "explicit_zero_based_source_replay",
      group_tie_policy=if(!is.null(fold_assignments))"source_supplied_exact_groups" else
        if(cv_unit=="group"&&group_tie_order!="native")fold_source else
          "native_size_descending_label_tie_break",
      covariates=if(is.null(covariate_matrix))list() else
        as.list(colnames(covariate_matrix)),
      scientific_warning=paste(
        "Grouped folds prevent train/test leakage but do not by themselves",
        "model within-group residual dependence or equalize group weights."))),
    class="etr_fpcr_regression_cv")
  if(isTRUE(strict_source_record)){
    source_fields<-c("method","fit_fpca_inside_fold","fit_regression_inside_fold","group_leakage_prevented","covariates","scientific_warning")
    .etr_assert(all(source_fields%in%names(result$provenance)),
      "strict FPCR CV source provenance fields are incomplete")
    result$provenance<-result$provenance[source_fields]
    .etr_assert(identical(names(result$provenance),source_fields),
      "strict FPCR CV source provenance order is invalid")
  }
  result
}
