# Frozen eyetrajectoriespy 1.2.0 prediction.py::nested_cross_validate_fpca_regression
# Commit c1cd95ad718327550f7e55393ff38582872f7a94
# Native source-bounded domain: Gaussian, no covariates, unshuffled curve folds.
#' Nested Gaussian FPCR cross-validation with independent outer assessment
#' @param trajectories Native complete common-grid trajectories.
#' @param outcome Finite scalar response per curve.
#' @param candidate_components Candidate positive integer retained counts.
#' @param family Currently only gaussian.
#' @param loss NULL (RMSE), rmse or mae.
#' @param covariates Currently NULL only.
#' @param outer_splits Outer KFold count.
#' @param inner_splits Inner KFold count.
#' @param selection_rule minimum or one_se.
#' @param scaling none or dimension_sd.
#' @param cv_unit Currently curve only.
#' @param group_column Currently NULL only.
#' @param shuffle Must be FALSE.
#' @param random_state Ignored because shuffle is FALSE.
#' @export
etr_nested_cross_validate_fpca_regression <- function(
  trajectories, outcome, candidate_components=c(1L,2L,3L,4L,5L),
  family="gaussian", loss=NULL, covariates=NULL,
  outer_splits=5L, inner_splits=4L, selection_rule="minimum",
  scaling="none", cv_unit="curve", group_column=NULL,
  shuffle=FALSE, random_state=0L) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(identical(family,"gaussian"),"family must equal gaussian")
  .etr_assert(is.null(covariates),"covariates must be NULL")
  .etr_assert(identical(cv_unit,"curve")&&is.null(group_column),
    "cv_unit must equal curve with NULL group_column")
  .etr_assert(identical(shuffle,FALSE),"shuffle must be FALSE")
  .etr_assert(is.character(selection_rule)&&length(selection_rule)==1L&&
    !is.na(selection_rule)&&selection_rule%in%c("minimum","one_se"),
    "selection_rule must be minimum or one_se")
  n<-length(trajectories$curve_ids)
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
    "outcome must be finite and curve aligned")
  .etr_assert(is.numeric(candidate_components)&&
    length(candidate_components)>0L&&all(is.finite(candidate_components))&&
    all(candidate_components==floor(candidate_components))&&
    all(candidate_components>=1),"candidate_components must be positive integers")
  counts<-sort(unique(as.integer(candidate_components)))
  .etr_assert(is.numeric(outer_splits)&&length(outer_splits)==1L&&
    is.finite(outer_splits)&&outer_splits==floor(outer_splits)&&
    outer_splits>=2&&outer_splits<=n,"outer_splits invalid")
  .etr_assert(is.numeric(inner_splits)&&length(inner_splits)==1L&&
    is.finite(inner_splits)&&inner_splits==floor(inner_splits)&&
    inner_splits>=2,"inner_splits invalid")
  no<-as.integer(outer_splits);ni<-as.integer(inner_splits)
  fold_ids<-.etr_cv_fold_assignment(trajectories,no,"curve",NULL,FALSE,NULL)$fold
  outer_rows<-vector("list",no);inner_rows<-vector("list",no)
  prediction_rows<-vector("list",n);cursor<-0L
  for(f in 0:(no-1L)) {
    train_idx<-which(fold_ids!=f);test_idx<-which(fold_ids==f)
    .etr_assert(length(train_idx)>=ni,"inner_splits exceeds outer training size")
    train<-.etr_cv_subset(trajectories,train_idx)
    inner_cv<-etr_cross_validate_fpca_regression(
      train,outcome[train_idx],candidate_components=counts,
      family=family,loss=loss,covariates=NULL,n_splits=ni,
      scaling=scaling,cv_unit="curve",group_column=NULL,
      shuffle=FALSE,random_state=NULL)
    selected<-etr_select_fpca_regression_components(inner_cv,rule=selection_rule)
    summary<-etr_summarise_fpca_regression_cv(inner_cv)
    inner_rows[[f+1L]]<-data.frame(outer_fold=rep(as.integer(f),nrow(summary)),
      summary,check.names=FALSE)
    fit<-if(length(train$dimension_names)>1L)
      etr_fit_mfpca(train,n_components=as.integer(selected),scaling=scaling)
    else etr_fit_fpca(train,n_components=as.integer(selected),scaling=scaling)
    scores<-etr_transform_fpca(fit,.etr_cv_subset(trajectories,test_idx))
    x_train<-cbind(1,fit$scores[,seq_len(selected),drop=FALSE])
    x_test<-cbind(1,scores[,seq_len(selected),drop=FALSE])
    .etr_assert(qr(x_train)$rank==ncol(x_train),"outer FPCR design is rank deficient")
    pred<-as.numeric(x_test%*%qr.solve(x_train,outcome[train_idx]))
    .etr_assert(all(is.finite(pred)),"outer FPCR predictions must be finite")
    error<-outcome[test_idx]-pred
    chosen_loss<-if(is.null(loss))"rmse" else loss
    score<-if(identical(chosen_loss,"rmse"))sqrt(mean(error^2)) else mean(abs(error))
    outer_rows[[f+1L]]<-data.frame(outer_fold=as.integer(f),
      selected_n_components=as.integer(selected),loss=score,
      n_train_curves=as.integer(length(train_idx)),
      n_test_curves=as.integer(length(test_idx)))
    for(j in seq_along(test_idx)){
      cursor<-cursor+1L
      prediction_rows[[cursor]]<-data.frame(
        curve_id=trajectories$curve_ids[test_idx[[j]]],
        outer_fold=as.integer(f),observed=outcome[test_idx[[j]]],
        prediction=pred[[j]],selected_n_components=as.integer(selected))
    }
  }
  outer<-do.call(rbind,outer_rows);inside<-do.call(rbind,inner_rows)
  predictions<-do.call(rbind,prediction_rows)
  rownames(outer)<-NULL;rownames(inside)<-NULL;rownames(predictions)<-NULL
  structure(list(outer_folds=outer,inner_summaries=inside,
    predictions=predictions,family="gaussian",
    loss=if(is.null(loss))"rmse" else loss,selection_rule=selection_rule,
    component_counts=counts,outer_splits=no,inner_splits=ni,
    cv_unit="curve",group_column=NULL,scaling=scaling,random_state=NULL,
    provenance=list(method="nested_outcome_tuned_fpca_regression_cv",
      nested_selection=TRUE,outer_performance_unseen_by_inner_selection=TRUE,
      group_leakage_prevented=FALSE,covariates=list(),
      scientific_warning=paste(
        "Outer-fold performance estimates the predictive pipeline with",
        "inner FPC-count selection. It does not remove within-group",
        "dependence from a curve-level outcome model."))),
    class="etr_nested_fpcr_cv")
}
