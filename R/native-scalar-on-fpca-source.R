# Source-aligned scalar-on-function via FPCA score regression.
# Frozen reference: eyetrajectoriespy==1.2.0,
# analysis.py::fit_scalar_on_function_regression()
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# This is a bounded native R scientific implementation. No reticulate.

.etr_scalar_on_fpca_source_covariates <- function(frame,covariates,
    expected_names=NULL) {
  .etr_assert(is.data.frame(frame) && nrow(frame)>=1L,
    "scores must supply a nonempty aligned numeric frame")
  if(is.null(covariates)){
    .etr_assert(is.null(expected_names)||length(expected_names)==0L,
      "matching covariates are required for this source fit")
    return(frame)
  }
  .etr_assert(is.data.frame(covariates) &&
    nrow(covariates)==nrow(frame),
    "covariates must contain one row per trajectory")
  cols<-names(covariates)
  .etr_assert(!anyNA(cols)&&all(nzchar(cols))&&!anyDuplicated(cols)&&
    all(make.names(cols)==cols)&&
    !any(cols%in%c(names(frame),"outcome","const","curve_id")),
    "covariate names must be distinct valid numeric predictors")
  if(!is.null(expected_names))
    .etr_assert(identical(cols,expected_names),
      "prediction covariate names and order must match source fit")
  for(nm in cols){
    z<-covariates[[nm]]
    .etr_assert((is.numeric(z)||is.logical(z))&&
      all(is.finite(z))&&!anyNA(z),
      paste("covariate",nm,"must be finite numeric with no missing values"))
    frame[[nm]]<-as.numeric(z)
  }
  frame
}

.etr_scalar_on_fpca_source_fit <- function(fit,outcome,n_components,
    family,covariates) {
  .etr_assert(inherits(fit,"etr_fpca")&&is.matrix(fit$scores)&&
    is.numeric(fit$scores)&&all(is.finite(fit$scores))&&
    is.character(fit$curve_ids)&&length(fit$curve_ids)==nrow(fit$scores),
    "fit must contain finite native FPCA scores aligned with curve IDs")
  .etr_assert(is.character(family)&&length(family)==1L&&
    !is.na(family)&&family%in%c("gaussian","binomial"),
    "family must be 'gaussian' or 'binomial'")
  if(is.null(n_components))n_components<-as.integer(fit$n_components)
  # Python bool is a valid __index__ value, while 1.0 is not.
  .etr_assert((is.integer(n_components)||is.logical(n_components))&&
    length(n_components)==1L&&!is.na(n_components),
    "n_components must be a Python integer or Boolean slice index")
  n_components<-as.integer(n_components)
  .etr_assert(n_components>=1L&&n_components<=fit$n_components&&
    n_components<=ncol(fit$scores),
    "n_components is outside the fitted range")
  n<-length(fit$curve_ids)
  .etr_assert((is.numeric(outcome)||is.logical(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
    "outcome must contain exactly one finite numeric value per trajectory")
  y<-as.numeric(outcome)
  if(identical(family,"binomial"))
    .etr_assert(all(y%in%c(0,1)),"binomial outcome must contain only 0/1 values")
  frame<-as.data.frame(fit$scores[,seq_len(n_components),drop=FALSE])
  names(frame)<-paste0("FPC",seq_len(n_components))
  frame<-.etr_scalar_on_fpca_source_covariates(frame,covariates)
  x<-cbind(const=rep(1,n),as.matrix(frame))
  .etr_assert(nrow(x)>ncol(x)&&qr(x)$rank==ncol(x),
    "source-compatible score regression requires a full-rank design")
  frame$outcome<-y
  # Statsmodels OLS and Gaussian lm share the full-rank least-squares
  # estimand; Statsmodels Binomial GLM and glm(..., logit) share the IRLS
  # estimating equations. Source-specific solver precision is assessed
  # against direct Python numerical oracles, not assumed.
  model<-if(identical(family,"gaussian"))
    stats::lm(outcome~.,data=frame) else
    stats::glm(outcome~.,data=frame,
      family=stats::binomial(link="logit"))
  coef_native<-stats::coef(model)
  .etr_assert(length(coef_native)==ncol(x)&&
    all(is.finite(coef_native)),
    "source-compatible regression returned invalid coefficients")
  coef_source<-as.numeric(coef_native)
  names(coef_source)<-c("const",names(frame)[names(frame)!="outcome"])
  predictions<-as.numeric(stats::predict(model,type="response"))
  .etr_assert(length(predictions)==n&&all(is.finite(predictions)),
    "source-compatible regression returned invalid predictions")
  cov_names<-setdiff(names(frame),c(paste0("FPC",seq_len(n_components)),
    "outcome"))
  structure(list(model=model,curve_ids=fit$curve_ids,
    n_components=n_components,score_basis=fit,
    method="scalar_on_function_via_fpca_scores",
    family=family,component_indices=as.integer(seq_len(n_components)-1L),
    coefficients=coef_source,predictions=predictions,
    source_covariate_names=cov_names,python_source_mode=TRUE,
    uncertainty="conditional_on_fitted_scores",
    provenance=list(method="scalar_on_function_via_fpca_scores",
      n_components=n_components,family=family,covariates=cov_names,
      full_python_source_contract_certified=FALSE)),
    class="etr_scalar_on_fpca")
}
