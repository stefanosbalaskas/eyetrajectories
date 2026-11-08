# Native pointwise Gaussian random-intercept REML for functional trajectories.
# Independent scientific method: NOT the Python joint B-spline MixedLM estimator.
# No Python, reticulate, or external optimization package is required.

.etr_reml34_profile <- function(lambda, y, X, group_index, group_sizes,
                                group_X) {
  n <- nrow(X); p <- ncol(X); G <- length(group_sizes)
  if(!is.finite(lambda) || lambda < 0) return(list(objective=Inf))
  alpha <- lambda / (1 + lambda * group_sizes)
  grp_y <- numeric(G)
  for(g in seq_len(G)) grp_y[g] <- sum(y[group_index == g])
  # Sherman-Morrison inverse for random-intercept blocks:
  # W_g^{-1}=I_g - lambda/(1+n_g*lambda) 1_g 1_g'.
  xx <- crossprod(X) - crossprod(group_X, alpha * group_X)
  xx <- (xx + t(xx)) / 2
  U <- tryCatch(chol(xx), error=function(e) NULL)
  if(is.null(U)) return(list(objective=Inf))
  xy <- crossprod(X, y) - crossprod(group_X, alpha * grp_y)
  beta <- as.numeric(backsolve(U, forwardsolve(t(U), xy)))
  residual <- as.numeric(y - X %*% beta)
  group_residual <- as.numeric(grp_y - group_X %*% beta)
  # Stable within-group and between-group decomposition of r'W^{-1}r.
  within <- 0
  for(g in seq_len(G)) {
    v <- residual[group_index == g]
    within <- within + sum((v - mean(v))^2)
  }
  q <- within + sum(group_residual^2 /
                    (group_sizes * (1 + lambda * group_sizes)))
  df <- n - p
  if(!is.finite(q) || q <= 0 || df <= 0)
    return(list(objective=Inf))
  sigma2 <- q / df
  determinant_W <- sum(log1p(lambda * group_sizes))
  determinant_XX <- 2 * sum(log(diag(U)))
  # Restricted profile likelihood, with constants not depending on lambda
  # removed. Variance parameter is profiled as sigma2=q/(n-p).
  objective <- df * log(sigma2) + determinant_W + determinant_XX
  list(objective=as.numeric(objective), beta=beta, sigma2=sigma2,
       tau2=lambda*sigma2, lambda=lambda,
       beta_se=sqrt(pmax(0, diag(chol2inv(U)) * sigma2)),
       group_random=alpha * group_residual,
       residual=residual, q=q)
}

#' Pointwise restricted maximum-likelihood functional random-intercept model
#'
#' Estimates independent Gaussian random-intercept and residual variances
#' separately at each observed time point. Repeated curves are grouped by
#' participant; fixed effects are explicit scalar design columns. This is a
#' native scientific alternative, NOT the joint B-spline Python 1.2 model.
#' The returned Wald standard errors are POINTWISE and not simultaneous bands.
#'
#' @param trajectories Complete native `etr_trajectory_set`.
#' @param dimension One existing functional channel name.
#' @param participant_column One metadata column with complete group IDs.
#' @param design Optional one-row-per-curve data frame containing `curve_id`.
#' @param predictors Character names of numeric fixed predictors in `design`.
#' @param lambda_bounds Two positive finite search limits for tau2/sigma2.
#' @return Native list with pointwise fixed coefficients, standard errors,
#'   participant BLUPs, residual variances, variance ratios, and fitted curves.
#' @export
etr_fit_functional_random_intercept_reml <- function(
    trajectories, dimension, participant_column, design=NULL,
    predictors=character(), lambda_bounds=c(1e-8,1e6)) {
  etr_validate(trajectories, require_complete=TRUE)
  .etr_assert(!identical(trajectories$coordinate_system,
                        "probability_simplex"),
              "Gaussian random-intercept REML is not for raw simplex data")
  .etr_assert(is.character(dimension) && length(dimension)==1L &&
              !is.na(dimension) && dimension %in% trajectories$dimension_names,
              "dimension must select one known channel")
  .etr_assert(is.character(participant_column) &&
              length(participant_column)==1L &&
              !is.na(participant_column) &&
              participant_column %in% names(trajectories$metadata),
              "participant_column must exist in trajectory metadata")
  .etr_assert(is.character(predictors) && !anyNA(predictors) &&
              !anyDuplicated(predictors) && all(nzchar(predictors)),
              "predictors must be distinct nonempty column names")
  .etr_assert(is.numeric(lambda_bounds) && length(lambda_bounds)==2L &&
              all(is.finite(lambda_bounds)) &&
              lambda_bounds[1L]>0 && lambda_bounds[2L]>lambda_bounds[1L] &&
              lambda_bounds[2L]<=1e12,
              "lambda_bounds must be finite, positive, increasing (upper <= 1e12)")
  n <- length(trajectories$curve_ids)
  if(is.null(design)) {
    .etr_assert(length(predictors)==0L,
                "design required when predictors are requested")
    design <- data.frame(curve_id=trajectories$curve_ids,
                         stringsAsFactors=FALSE)
  }
  .etr_assert(is.data.frame(design) && "curve_id" %in% names(design) &&
              nrow(design)==n && !anyNA(design$curve_id) &&
              !anyDuplicated(design$curve_id) &&
              all(predictors %in% names(design)) &&
              !"curve_id" %in% predictors,
              "design must contain one unique curve_id and all predictors")
  perm <- match(trajectories$curve_ids, as.character(design$curve_id))
  .etr_assert(!anyNA(perm), "design must match trajectory curve IDs")
  X <- matrix(1, n, 1L, dimnames=list(NULL,"Intercept"))
  for(predictor in predictors) {
    v <- design[[predictor]][perm]
    .etr_assert(is.numeric(v) && is.null(dim(v)) &&
                length(v)==n && all(is.finite(v)),
                paste0("predictor ",predictor," must be finite numeric"))
    X <- cbind(X, v)
    colnames(X)[ncol(X)] <- predictor
  }
  .etr_assert(qr(X)$rank==ncol(X) && n > ncol(X)+1L,
              "fixed effects must have full rank and residual degrees of freedom")
  groups <- as.character(trajectories$metadata[[participant_column]])
  .etr_assert(length(groups)==n && !anyNA(groups) &&
              all(nzchar(groups)),
              "participant identifiers must be complete")
  unique_groups <- unique(groups)
  gi <- match(groups, unique_groups)
  G <- length(unique_groups)
  ng <- tabulate(gi, nbins=G)
  .etr_assert(G>=3L && any(ng>=2L),
              "requires at least three participants and repeated curves")
  group_X <- matrix(0, G, ncol(X))
  for(g in seq_len(G)) group_X[g,] <- colSums(X[gi==g,,drop=FALSE])
  nt <- length(trajectories$time)
  Y <- matrix(trajectories$values[,,match(dimension,
      trajectories$dimension_names),drop=FALSE],nrow=n,ncol=nt)
  .etr_assert(all(is.finite(Y)),"REML requires complete finite response")
  beta <- matrix(NA_real_, ncol(X), nt,
                 dimnames=list(colnames(X),NULL))
  beta_se <- beta
  random <- matrix(NA_real_,G,nt,dimnames=list(unique_groups,NULL))
  fitted <- matrix(NA_real_,n,nt,
                   dimnames=list(trajectories$curve_ids,NULL))
  conditional_residual <- fitted
  sigma2 <- tau2 <- ratio <- icc <- score <- numeric(nt)
  boundary <- logical(nt)
  for(t in seq_len(nt)) {
    y <- Y[,t]
    profile <- function(lambda) .etr_reml34_profile(lambda,y,X,gi,ng,group_X)
    best <- stats::optimize(function(log_lambda)
        profile(exp(log_lambda))$objective,
        interval=log(lambda_bounds),tol=1e-8)
    candidates <- c(0,exp(best$minimum),lambda_bounds[1L],
                    lambda_bounds[2L])
    choices <- lapply(candidates,profile)
    objectives <- vapply(choices,`[[`,numeric(1),"objective")
    .etr_assert(any(is.finite(objectives)),
                paste0("REML failed for time index ",t))
    selected <- which.min(objectives)
    fit <- choices[[selected]]
    beta[,t] <- fit$beta
    beta_se[,t] <- fit$beta_se
    random[,t] <- fit$group_random
    fitted[,t] <- as.numeric(X%*%fit$beta) + fit$group_random[gi]
    conditional_residual[,t] <- y - fitted[,t]
    sigma2[t] <- fit$sigma2
    tau2[t] <- fit$tau2
    ratio[t] <- fit$lambda
    icc[t] <- fit$tau2 / (fit$tau2 + fit$sigma2)
    score[t] <- fit$objective
    boundary[t] <- selected!=2L
  }
  structure(list(time=trajectories$time, dimension=dimension,
    predictors=predictors, participant_column=participant_column,
    participant_ids=unique_groups, group_sizes=ng,
    curve_ids=trajectories$curve_ids, fixed_coefficients=beta,
    fixed_se=beta_se, random_intercepts=random,
    marginal_fixed_predictions=X%*%beta,
    fitted=fitted, residuals=conditional_residual,
    residual_variance=sigma2, random_intercept_variance=tau2,
    variance_ratio=ratio, intraclass_correlation=icc,
    restricted_profile_objective=score, at_search_boundary=boundary,
    provenance=list(estimator="pointwise_random_intercept_gaussian_REML",
      optimization="profile_likelihood_1d_with_zero_variance_boundary",
      across_time_covariance="not_estimated",
      scientific_python_joint_bspline_equivalence=FALSE,
      pointwise_uncertainty_only=TRUE)),
    class="etr_functional_random_intercept_reml")
}

#' Tidy pointwise fixed-effect REML coefficient intervals
#' @param fit Native `etr_functional_random_intercept_reml` fit.
#' @param confidence_level Pointwise normal-Wald confidence level in (0,1).
#' @return Data frame of estimate, standard error, and POINTWISE interval.
#' @export
etr_functional_random_intercept_reml_frame <- function(
    fit, confidence_level=.95) {
  .etr_assert(inherits(fit,"etr_functional_random_intercept_reml") &&
              is.matrix(fit$fixed_coefficients) &&
              identical(dim(fit$fixed_coefficients),dim(fit$fixed_se)),
              "fit must be a native pointwise REML result")
  .etr_assert(is.numeric(confidence_level) && length(confidence_level)==1L &&
              is.finite(confidence_level) && confidence_level>0 &&
              confidence_level<1,
              "confidence_level must be in (0,1)")
  q <- stats::qnorm((1+confidence_level)/2)
  p <- nrow(fit$fixed_coefficients); T <- length(fit$time)
  term <- rep(rownames(fit$fixed_coefficients),times=T)
  tim <- rep(fit$time,each=p)
  est <- as.vector(fit$fixed_coefficients)
  se <- as.vector(fit$fixed_se)
  data.frame(term=term,time=tim,estimate=est,pointwise_se=se,
             lower=est-q*se,upper=est+q*se,
             confidence_level=confidence_level,stringsAsFactors=FALSE)
}
