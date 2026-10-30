# Source: frozen eyetrajectoriespy==1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94
# prediction.py::cross_validate_fpca_regression
# Bounded native Gaussian, curve-wise, nonshuffled fold contract.
# No Python, reticulate, shuffled or grouped fold equivalence claimed.

#' Leakage-free native Gaussian FPCR held-out prediction
#'
#' Refits unsupervised dense FPCA and Gaussian scalar OLS *inside* each
#' training fold. Reuses the same training FPCA basis for test projections.
#' This implementation deliberately refuses Python source domains requiring
#' shuffled/sklearn RNG, grouped folds, binomial outcomes or covariates.
#' @param trajectories Complete native common-grid trajectory set.
#' @param outcome Curve-aligned finite scalar outcomes.
#' @param candidate_components Positive integer FPC counts to compare.
#' @param family Must be \code{"gaussian"}.
#' @param loss \code{"rmse"} or \code{"mae"}, default RMSE.
#' @param covariates Must be NULL in the native source-aligned subset.
#' @param n_splits Deterministic KFold count >=2.
#' @param scaling Native dense FPCA scaling.
#' @param cv_unit Must be \code{"curve"}.
#' @param group_column Must be NULL.
#' @param shuffle Must be FALSE to use source-equivalent KFold assignment.
#' @param random_state Ignored with nonshuffled KFold, as in Python.
#' @return Source-shaped fold losses, test predictions, assignments and
#'   provenance; never fits on held-out curves.
#' @export
etr_cross_validate_fpca_regression<-function(
    trajectories,outcome,candidate_components=c(1L,2L,3L,4L,5L),
    family="gaussian",loss=NULL,covariates=NULL,n_splits=5L,
    scaling="none",cv_unit="curve",group_column=NULL,
    shuffle=FALSE,random_state=0L){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(identical(family,"gaussian"),
    "bounded native regression CV requires family='gaussian'")
  .etr_assert(is.null(covariates),
    "native regression CV does not accept covariates yet")
  .etr_assert(identical(cv_unit,"curve")&&is.null(group_column),
    "bounded native regression CV only supports curve folds")
  .etr_assert(identical(shuffle,FALSE),
    "bounded native regression CV requires shuffle=FALSE")
  .etr_assert(is.null(random_state)||(
    is.numeric(random_state)&&length(random_state)==1L&&
      !is.na(random_state)&&is.finite(random_state)),
    "random_state must be numeric or NULL")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  resolved_loss<-if(is.null(loss))"rmse" else loss
  .etr_assert(is.character(resolved_loss)&&
    length(resolved_loss)==1L&&!is.na(resolved_loss)&&
    resolved_loss%in%c("rmse","mae"),
    "gaussian loss must be 'rmse' or 'mae'")
  n<-length(trajectories$curve_ids)
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
    "outcome must contain one finite scalar per trajectory")
  .etr_assert(is.numeric(candidate_components)&&
    length(candidate_components)>=1L&&
    !anyNA(candidate_components)&&
    all(is.finite(candidate_components))&&
    all(candidate_components==floor(candidate_components))&&
    all(candidate_components>=1L),
    "candidate_components must contain positive integers")
  components<-sort(unique(as.integer(candidate_components)))
  .etr_assert(is.numeric(n_splits)&&length(n_splits)==1L&&
    is.finite(n_splits)&&n_splits==floor(n_splits)&&
    n_splits>=2L&&n_splits<=n,
    "n_splits must be an integer between 2 and the number of curves")
  ns<-as.integer(n_splits)
  # The existing native assignment follows deterministic sklearn KFold
  # blocks exactly for shuffle=FALSE; group tie permutations are excluded.
  folds<-.etr_cv_fold_assignment(trajectories,ns,"curve",
    NULL,FALSE,NULL)$fold
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
        fit$scores[,seq_len(k),drop=FALSE])
      test_design<-cbind(rep(1,length(testing)),
        test_scores[,seq_len(k),drop=FALSE])
      .etr_assert(qr(train_design)$rank==ncol(train_design),
        "native regression CV requires full-rank training FPC design")
      coef<-as.numeric(qr.solve(train_design,outcome[training]))
      predicted<-as.numeric(test_design%*%coef)
      .etr_assert(all(is.finite(predicted)),
        "FPCR Gaussian fold predictions must be finite")
      err<-outcome[testing]-predicted
      fold_loss<-if(identical(resolved_loss,"rmse"))
        sqrt(mean(err^2)) else mean(abs(err))
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
    assign_rows[[fold+1L]]<-data.frame(
      curve_id=trajectories$curve_ids[testing],
      fold=rep(as.integer(fold),length(testing)),
      stringsAsFactors=FALSE)
  }
  fold_losses<-do.call(rbind,fold_rows)
  assignments<-do.call(rbind,assign_rows)
  predictions<-do.call(rbind,prediction_rows)
  for(frame in c("fold_losses","assignments","predictions")){
    obj<-get(frame);rownames(obj)<-NULL
    assign(frame,obj)
  }
  structure(list(
    fold_losses=fold_losses,assignments=assignments,
    predictions=predictions,component_counts=components,
    family="gaussian",loss=resolved_loss,cv_unit="curve",
    n_splits=ns,group_column=NULL,scaling=scaling,
    random_state=NULL,provenance=list(
      method="outcome_tuned_fpca_regression_cv",
      fit_fpca_inside_fold=TRUE,
      fit_regression_inside_fold=TRUE,
      group_leakage_prevented=FALSE,
      covariates=list(),
      scientific_warning=paste(
        "Grouped folds prevent train/test leakage but do not by themselves",
        "model within-group residual dependence or equalize group weights."))),
    class="etr_fpcr_regression_cv")
}
