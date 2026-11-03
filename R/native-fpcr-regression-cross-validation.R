# Source: frozen eyetrajectoriespy==1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94
# prediction.py::cross_validate_fpca_regression
# Native Gaussian FPCR with unshuffled/shuffled curve folds and
# whole-participant held-out folds. R shuffle uses base R RNG,
# not sklearn NumPy RandomState; sklearn GroupKFold ties can differ.

#' Leakage-free native Gaussian FPCR held-out prediction
#'
#' Refits unsupervised dense FPCA and Gaussian scalar OLS *inside* each
#' training fold. Reuses the same training FPCA basis for test projections.
#' Supports group held-out and R-seeded curve shuffled folds.
#' Exact Python shuffle RNG and GroupKFold tie semantics are unresolved;
#' binomial outcomes remain out of this bounded domain; numeric covariates\n#' are fitted inside each training fold and are never outcome-tuned globally.
#' @param trajectories Complete native common-grid trajectory set.
#' @param outcome Curve-aligned finite scalar outcomes.
#' @param candidate_components Positive integer FPC counts to compare.
#' @param family Must be \code{"gaussian"}.
#' @param loss \code{"rmse"} or \code{"mae"}, default RMSE.
#' @param covariates NULL or a curve-aligned numeric data.frame with unique\n#'   nonreserved column names and finite values. Training and held-out\n#'   rows are separated within each fold.
#' @param n_splits Number of KFold or GroupKFold partitions (>=2).
#' @param scaling Native dense FPCA scaling.
#' @param cv_unit "curve" or "group"; group CV holds all trials
#'   of a participant/group together in the same held-out fold.
#' @param group_column For group CV, required metadata column containing
#'   nonmissing group identifiers. Ignored for curve CV.
#' @param shuffle Logical flag; for curve CV uses isolated base-R
#'   random assignment. Group CV is deterministic regardless of shuffle.
#' @param random_state Nonnegative native R seed for shuffled curve folds;
#'   ignored for unshuffled/group modes. Does not reproduce NumPy draws.
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
  if(identical(cv_unit,"curve")&&isTRUE(shuffle))
    .etr_assert(is.numeric(random_state)&&
      length(random_state)==1L&&is.finite(random_state)&&
      random_state==floor(random_state)&&random_state>=0&&
      random_state<=.Machine$integer.max,
      "random_state must be a nonnegative R integer seed for shuffled curve folds")
  else
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
  covariate_matrix<-.etr_fpcr_numeric_covariates(covariates,n)
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
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
  # Group identity stays intact. Shuffled folds use isolated base-R RNG,
  # so a shared seed need not reproduce NumPy/Scikit-learn permutations.
  split<-.etr_cv_fold_assignment(trajectories,ns,cv_unit,
    group_column,shuffle,random_state)
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
  structure(list(
    fold_losses=fold_losses,assignments=assignments,
    predictions=predictions,component_counts=components,
    family="gaussian",loss=resolved_loss,cv_unit=cv_unit,
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
      random_engine=if(identical(cv_unit,"curve")&&isTRUE(shuffle))
        "base_R_sample_not_NumPy" else "deterministic",
      group_tie_policy="native_size_descending_label_tie_break",
      covariates=if(is.null(covariate_matrix))list() else
        as.list(colnames(covariate_matrix)),
      scientific_warning=paste(
        "Grouped folds prevent train/test leakage but do not by themselves",
        "model within-group residual dependence or equalize group weights."))),
    class="etr_fpcr_regression_cv")
}
