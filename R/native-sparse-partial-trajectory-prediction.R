# Frozen Python 1.2 sparse_partial_prediction.py, source commit:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native conditional Gaussian future trajectory, without raw interpolation,
# truncated-rank substitution, conformal assumptions or R/Python bridge.

#' Source-model conditional sparse future trajectory prediction
#'
#' @description Gaussian conditional prediction from observed native-time
#' sparse history and the full fitted PACE population covariance. Returns
#' latent future uncertainty separately from measurement-error predictive
#' uncertainty. Not a conformal coverage interval or posterior over the
#' estimated population fit.
#' @param fit Native sparse FPCA/PACE covariance fit.
#' @param trajectory Exactly one native irregular target trajectory.
#' @param history_cutoff Finite time inside fitted support, before its end.
#' @param prediction_grid Nonempty strictly increasing future times.
#' @param min_history_observations Minimum history samples.
#' @param condition_limit Optional positive numerical conditioning limit.
#' @param history_ridge Optional nonnegative history regularization.
#' @return Conditional mean, latent and observed covariance, history and
#'   prediction counts, and diagnostics.
#' @export
etr_sparse_fpca_partial_trajectory_prediction_native<-function(
    fit,trajectory,history_cutoff,prediction_grid,
    min_history_observations=2L,condition_limit=NULL,
    history_ridge=NULL){
  .etr_assert(inherits(fit,"etr_sparse_fpca_native")&&
    identical(fit$fit_method,"native_covariance")&&
    identical(fit$provenance$sparse_fpca$backend,"native"),
    "fit must retain a native sparse FPCA covariance population")
  .etr_irregular_validate_samples(trajectory)
  .etr_assert(length(trajectory$curve_ids)==1L,
    "trajectory must contain exactly one target curve")
  .etr_assert(fit$dimension%in%trajectory$dimension_names&&
    identical(fit$coordinate_system,trajectory$coordinate_system)&&
    identical(fit$time_unit,trajectory$time_unit),
    "target dimension or measurement units do not match fitted population")
  grid<-.etr_spn_grid(fit$evaluation_grid)
  n<-length(grid)
  .etr_assert(is.numeric(fit$mean)&&is.null(dim(fit$mean))&&
    length(fit$mean)==n&&all(is.finite(fit$mean)),
    "fitted mean must align with population evaluation grid")
  .etr_assert(is.matrix(fit$covariance)&&
    identical(dim(fit$covariance),c(n,n))&&
    all(is.finite(fit$covariance)),
    "fitted full covariance must align with population evaluation grid")
  .etr_assert(is.numeric(fit$noise_variance)&&
    length(fit$noise_variance)==1L&&
    is.finite(fit$noise_variance)&&fit$noise_variance>=0,
    "fitted measurement error must be finite nonnegative")
  .etr_assert(is.numeric(history_cutoff)&&
    length(history_cutoff)==1L&&is.finite(history_cutoff),
    "history_cutoff must be finite")
  cutoff<-as.numeric(history_cutoff)
  support<-list(grid_start=grid[1L],grid_end=tail(grid,1L))
  if(cutoff<grid[1L]||cutoff>=tail(grid,1L))
    .etr_spn_fail("history_cutoff_outside_fitted_support",
      "history cutoff must lie inside fitted grid before its end",
      c(list(history_cutoff=cutoff),support))
  .etr_assert(is.numeric(prediction_grid)&&is.null(dim(prediction_grid))&&
    length(prediction_grid)>=1L&&all(is.finite(prediction_grid))&&
    (length(prediction_grid)==1L||all(diff(prediction_grid)>0)),
    "prediction_grid must be finite nonempty strictly increasing 1D")
  future<-as.numeric(prediction_grid)
  if(any(future<=cutoff))
    .etr_spn_fail("prediction_grid_not_strictly_future",
      "all predictions must follow the history cutoff",
      list(history_cutoff=cutoff,prediction_grid_min=min(future)))
  if(future[1L]<grid[1L]||tail(future,1L)>tail(grid,1L))
    .etr_spn_fail("prediction_grid_outside_fitted_support",
      "future prediction times must lie within fitted grid",
      c(support,list(prediction_start=future[1L],prediction_end=tail(future,1L))))
  .etr_assert(is.numeric(min_history_observations)&&
    length(min_history_observations)==1L&&
    !is.logical(min_history_observations)&&
    is.finite(min_history_observations)&&
    min_history_observations==floor(min_history_observations)&&
    min_history_observations>=1L,
    "min_history_observations must be a positive integer")
  idx<-match(fit$dimension,trajectory$dimension_names)
  t<-trajectory$time[[1L]]
  y<-as.numeric(trajectory$values[[1L]][,idx])
  id<-as.character(trajectory$curve_ids[1L])
  history<-t<=cutoff
  to<-t[history];yo<-y[history]
  if(length(to)<min_history_observations)
    .etr_spn_fail("insufficient_history_observations",
      "target history has fewer native observations than required",
      list(curve_id=id,history_cutoff=cutoff,n_history=length(to),
        min_history_observations=as.integer(min_history_observations)))
  if(any(!is.finite(yo)))
    .etr_spn_fail("nonfinite_history_observation",
      "target history contains nonfinite observations",
      list(curve_id=id,n_nonfinite=sum(!is.finite(yo))))
  if(to[1L]<grid[1L]||tail(to,1L)>tail(grid,1L))
    .etr_spn_fail("history_observations_outside_fitted_support",
      "native history times exceed fitted support",
      c(list(curve_id=id,history_min=to[1L],history_max=tail(to,1L)),support))
  params<-fit$provenance$sparse_fpca
  selected_limit<-if(is.null(condition_limit))
    params$score_condition_limit else condition_limit
  selected_ridge<-if(is.null(history_ridge))
    params$score_ridge else history_ridge
  .etr_assert(is.numeric(selected_limit)&&
    length(selected_limit)==1L&&is.finite(selected_limit)&&
    selected_limit>1,
    "condition_limit must be finite greater than one")
  .etr_assert(is.numeric(selected_ridge)&&
    length(selected_ridge)==1L&&is.finite(selected_ridge)&&
    selected_ridge>=0,
    "history_ridge must be finite nonnegative")
  m<-length(to);k<-length(future)
  combined<-.etr_spn_cov_eval(grid,fit$covariance,c(to,future))
  observed<-seq_len(m);predicted<-m+seq_len(k)
  Coo<-combined[observed,observed,drop=FALSE]
  Cof<-combined[observed,predicted,drop=FALSE]
  Cfo<-combined[predicted,observed,drop=FALSE]
  Cff<-combined[predicted,predicted,drop=FALSE]
  mu_o<-.etr_spn_eval(grid,fit$mean,to)
  mu_f<-.etr_spn_eval(grid,fit$mean,future)
  Sigma<-Coo+diag(fit$noise_variance+selected_ridge,m)
  Sigma<-(Sigma+t(Sigma))/2
  e<-eigen(Sigma,symmetric=TRUE,only.values=TRUE)$values
  emin<-min(e);emax<-max(e)
  condition<-if(emin<=0)Inf else emax/emin
  if(emin<=0)
    .etr_spn_fail("history_covariance_not_positive_definite",
      "history conditioning covariance is not positive definite",
      list(curve_id=id,minimum_eigenvalue=emin,history_ridge=selected_ridge))
  if(condition>selected_limit)
    .etr_spn_fail("history_covariance_ill_conditioned",
      "history conditioning covariance exceeds condition_limit",
      list(curve_id=id,condition_number=condition,condition_limit=selected_limit))
  rhs<-cbind(yo-mu_o,Cof)
  solved<-tryCatch(solve(Sigma,rhs),error=function(e)
    .etr_spn_fail("history_covariance_solve_failed",
      conditionMessage(e)))
  conditional_mean<-mu_f+as.numeric(Cfo%*%solved[,1L])
  latent<-Cff-Cfo%*%solved[,-1L,drop=FALSE]
  latent<-(latent+t(latent))/2
  pe<-eigen(latent,symmetric=TRUE)
  pmin<-min(pe$values)
  ptol<-1e-10*max(1,max(abs(Cff)))
  if(pmin < -ptol)
    .etr_spn_fail("conditional_future_covariance_not_psd",
      "latent conditional covariance has substantial negative eigenvalues",
      list(curve_id=id,minimum_eigenvalue=pmin,tolerance=ptol))
  repaired<-FALSE
  if(pmin<0){
    latent<-pe$vectors%*%diag(pmax(pe$values,0),nrow=k)%*%
      t(pe$vectors)
    latent<-(latent+t(latent))/2
    repaired<-TRUE
  }
  se<-sqrt(pmax(diag(latent),0))
  predictive<-latent+diag(fit$noise_variance,k)
  predictive_se<-sqrt(pmax(diag(predictive),0))
  solve_relative<-sqrt(sum((Sigma%*%solved-rhs)^2))/
    max(1,sqrt(sum(rhs^2)))
  audit<-data.frame(
    curve_id=id,history_cutoff=cutoff,
    n_history=m,n_prediction=k,
    future_rows_ignored=sum(t>cutoff),
    condition_number=condition,
    minimum_eigenvalue=emin,maximum_eigenvalue=emax,
    conditional_covariance_minimum_eigenvalue=pmin,
    conditional_covariance_psd_repair_applied=repaired,
    solve_relative_residual=solve_relative,
    measurement_error_variance=fit$noise_variance,
    history_ridge=selected_ridge,condition_limit=selected_limit,
    status_code="ok",stringsAsFactors=FALSE)
  method<-"conditional_gaussian_future_given_native_sparse_history"
  provenance<-list(method=method,
    prediction_target=
      "latent_future_trajectory_conditional_on_fitted_population",
    observed_predictive_covariance_includes_measurement_error=TRUE,
    history_ridge_in_observed_future_noise=FALSE,
    covariance_source="full_fitted_repaired_covariance",
    rank_k_covariance_used_for_prediction=FALSE,
    raw_history_interpolation_performed=FALSE,
    future_observations_after_cutoff_used=FALSE,
    population_function_evaluation_at_native_and_target_times=TRUE,
    measurement_error_variance=fit$noise_variance,
    history_ridge=selected_ridge,
    history_ridge_source=if(is.null(history_ridge))
      "fitted_score_ridge"else"explicit_override",
    condition_limit=selected_limit,
    condition_limit_source=if(is.null(condition_limit))
      "fitted_score_condition_limit"else"explicit_override",
    population_estimation_uncertainty_included=FALSE,
    bandwidth_uncertainty_included=FALSE,
    conformal_calibration_applied=FALSE,
    coverage_claim="none_model_based_conditional_moments_only")
  structure(list(reference=fit,curve_id=id,dimension=fit$dimension,
    history_cutoff=cutoff,history_times=to,history_values=yo,
    prediction_grid=future,conditional_mean=conditional_mean,
    latent_covariance=latent,latent_standard_errors=se,
    observed_predictive_covariance=predictive,
    observed_predictive_standard_errors=predictive_se,
    n_history=m,n_prediction=k,
    diagnostics=audit,method=method,provenance=provenance,
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE),
    class="etr_sparse_fpca_partial_trajectory_prediction_native")
}

#' Tidy native conditional sparse PACE future prediction
#' @param result Conditional sparse native future prediction.
#' @return One row per future time with latent and observed standard errors.
#' @export
etr_sparse_fpca_partial_prediction_frame_native<-function(result){
  .etr_assert(inherits(result,
    "etr_sparse_fpca_partial_trajectory_prediction_native"),
    "result must be native sparse conditional future prediction")
  data.frame(curve_id=result$curve_id,
    dimension=result$dimension,time=result$prediction_grid,
    conditional_mean=result$conditional_mean,
    latent_standard_error=result$latent_standard_errors,
    observed_predictive_standard_error=
      result$observed_predictive_standard_errors,
    stringsAsFactors=FALSE)
}
