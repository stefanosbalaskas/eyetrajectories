# Frozen eyetrajectoriespy==1.2.0 prediction.py:
# _validate_outcome, _resolve_loss, _loss_value and _fit_predict_regression.
# Native source-bounded Bernoulli logit GLM; stats::glm.fit is a different
# numerical backend from statsmodels GLM and is not full-domain equivalence.

.etr_fpcr_validate_family <- function(family) {
  .etr_assert(is.character(family)&&length(family)==1L&&
    !is.na(family)&&family%in%c("gaussian","binomial"),
    "family must be 'gaussian' or 'binomial'")
  invisible(family)
}

# Frozen Python 1.2 _validate_outcome uses np.asarray(outcome,dtype=float).
# R logical vectors correspond to NumPy bools; canonical numeric strings
# also survive source conversion. Exclude factors and unsupported formats.
.etr_fpcr_numeric_outcome <- function(outcome,n,family,error_message) {
  .etr_assert((is.numeric(outcome)||is.logical(outcome)||
      is.character(outcome))&&!is.factor(outcome)&&
    is.null(dim(outcome))&&length(outcome)==n,error_message)
  if(is.character(outcome)) {
    literals<-trimws(outcome)
    # Source-compatible subset: decimal, optional exponent, signs and
    # surrounding whitespace; no locale-specific grouping separators.
    decimal<-"^[+-]?([0-9]+(\\\\.[0-9]*)?|\\\\.[0-9]+)([eE][+-]?[0-9]+)?$"
    .etr_assert(!anyNA(literals)&&
      all(grepl(decimal,literals,perl=TRUE)),error_message)
    numeric_outcome<-suppressWarnings(as.numeric(literals))
  } else numeric_outcome<-as.numeric(outcome)
  .etr_assert(all(is.finite(numeric_outcome)),error_message)
  .etr_fpcr_validate_binomial_outcome(numeric_outcome,family)
  numeric_outcome
}

.etr_fpcr_validate_binomial_outcome <- function(outcome,family) {
  if(identical(family,"binomial"))
    .etr_assert(all(outcome%in%c(0,1)),
      "binomial outcome must contain only 0/1 values")
  invisible(TRUE)
}

.etr_fpcr_resolve_loss <- function(family,loss) {
  if(identical(family,"gaussian")) {
    result<-if(is.null(loss))"rmse" else loss
    .etr_assert(is.character(result)&&length(result)==1L&&
      !is.na(result)&&result%in%c("rmse","mae"),
      "gaussian loss must be 'rmse' or 'mae'")
  } else {
    result<-if(is.null(loss))"log_loss" else loss
    .etr_assert(is.character(result)&&length(result)==1L&&
      !is.na(result)&&result%in%c("log_loss","brier"),
      "binomial loss must be 'log_loss' or 'brier'")
  }
  result
}

.etr_fpcr_predict_fold <- function(design_train,design_test,
                                  outcome_train,family) {
  if(identical(family,"gaussian")) {
    coefficients<-as.numeric(qr.solve(design_train,outcome_train))
    predicted<-as.numeric(design_test%*%coefficients)
    .etr_assert(all(is.finite(predicted)),
      "FPCR Gaussian fold predictions must be finite")
    return(predicted)
  }
  .etr_assert(length(unique(outcome_train))==2L,
    "each binomial training fold must contain both outcome classes")
  caught<-character()
  fitted<-withCallingHandlers(
    tryCatch(
      stats::glm.fit(
        x=design_train,y=outcome_train,
        family=stats::binomial(link="logit"),
        control=stats::glm.control(epsilon=1e-10,maxit=100L)),
      error=function(e)
        stop("binomial FPCA regression GLM fit failed: ",
             conditionMessage(e),call.=FALSE)),
    warning=function(w) {
      caught<<-c(caught,conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  if(any(grepl("fitted probabilities numerically 0 or 1 occurred",
               caught,fixed=TRUE))||isTRUE(fitted$boundary))
    stop("binomial FPCA regression encountered perfect separation",
         call.=FALSE)
  .etr_assert(isTRUE(fitted$converged),
    "binomial FPCA regression did not converge")
  .etr_assert(length(fitted$coefficients)==ncol(design_train)&&
    all(is.finite(fitted$coefficients)),
    "binomial FPCA regression returned non-finite coefficients")
  predicted<-stats::plogis(as.numeric(
    design_test%*%fitted$coefficients))
  .etr_assert(all(is.finite(predicted))&&
    all(predicted>=0&predicted<=1),
    "binomial FPCA regression returned invalid probabilities")
  as.numeric(predicted)
}

.etr_fpcr_loss <- function(observed,predicted,family,loss) {
  if(identical(family,"gaussian")) {
    error<-observed-predicted
    if(identical(loss,"rmse"))return(sqrt(mean(error^2)))
    return(mean(abs(error)))
  }
  if(identical(loss,"brier"))
    return(mean((observed-predicted)^2))
  eps<-.Machine$double.eps
  probability<-pmax(eps,pmin(1-eps,predicted))
  -mean(observed*log(probability)+
        (1-observed)*log1p(-probability))
}
