# Source: eyetrajectoriespy 1.2.0 wild_regression.py, immutable
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Independent R FPCA/least squares/studentization; no Python backend.
# Seeded normal and Mammen multipliers follow the frozen source draws.

.etr_wild_fpcr_multipliers <- function(replicates, curves, multiplier, seed,
                                      random_engine = "numpy") {
  rng <- NULL
  if (!is.null(seed)) {
    if (random_engine == "numpy") {
      rng <- .etr_numpy_pcg64(seed)
    } else {
      restore <- .etr_simulation_rng(seed)
      on.exit(restore(), add = TRUE)
    }
  }
  n <- as.double(replicates) * curves
  if (multiplier == "normal") {
    values <- if (is.null(rng)) stats::rnorm(n) else rng$normal(n)
  } else {
    u <- if (is.null(rng)) stats::runif(n) else rng$uniform(n)
    sqrt5 <- sqrt(5)
    values <- ifelse(u < (sqrt5 + 1) / (2 * sqrt5), (1 - sqrt5) / 2, (1 + sqrt5) / 2)
  }
  matrix(values, nrow = replicates, ncol = curves, byrow = TRUE)
}

.etr_wild_fpcr_prepared_fit<-function(scores,k){
  # Factorize the identical, fixed FPCA design once for every bootstrap.
  # Reusing the pivoted QR changes neither the model nor the least-squares
  # coefficient estimates; it avoids thousands of redundant factorizations.
  design<-cbind(1,scores[,seq_len(k),drop=FALSE])
  decomp<-qr(design)
  .etr_assert(decomp$rank==k+1L,
    "FPCR score regression is rank deficient")
  function(y){
    .etr_assert(is.numeric(y)&&length(y)==nrow(design)&&
      all(is.finite(y)),"FPCR response must be finite per score row")
    beta<-as.numeric(qr.coef(decomp,y))
    fit<-as.vector(design%*%beta)
    .etr_assert(all(is.finite(beta))&&all(is.finite(fit)),
      "FPCR score regression produced nonfinite values")
    list(beta=beta,fitted=fit,residual=y-fit)
  }
}
.etr_wild_fpcr_fixed_fit<-function(scores,y,k){
  .etr_wild_fpcr_prepared_fit(scores,k)(y)
}

.etr_wild_fpcr_hetero_se<-function(scores,residual,targets){
  n<-nrow(scores);h<-ncol(scores)
  .etr_assert(is.matrix(scores)&&is.numeric(scores)&&
    length(residual)==n&&is.matrix(targets)&&ncol(targets)==h,
    "heteroscedastic FPCR score geometry is incompatible")
  gamma<-crossprod(scores)/n
  .etr_assert(qr(gamma)$rank==h,"score covariance is rank deficient")
  products<-scores*as.numeric(residual)
  centered<-sweep(products,2L,colMeans(products),"-")
  lambda<-crossprod(centered)/(n-1L)
  direction<-targets%*%solve(gamma)
  variance<-rowSums((direction%*%lambda)*direction)
  tolerance<-100*.Machine$double.eps*max(1,abs(variance))
  .etr_assert(!any(variance< -tolerance),
    "heteroscedastic projection variance is materially negative")
  se<-sqrt(pmax(variance,0)/n)
  .etr_assert(all(is.finite(se)),"nonfinite heteroscedastic SE")
  se
}

#' Native wild bootstrap of fixed-target centered FPCR projections
#'
#' @description Frozen Python 1.2 numerical method: fixed dense FPCA,
#'   k-component Gaussian score residuals and pseudo truth, h-component
#'   inferential projection, bootstrap-refitted heteroscedastic scaling,
#'   NumPy "higher" targetwise bootstrap criticals. Independent curves only.
#' @param trajectories Complete native common-grid training trajectories.
#' @param outcome Finite scalar response per curve.
#' @param targets Optional compatible target trajectories.
#' @param n_bootstrap Number of multiplier replicates, at least 20.
#' @param residual_components, inference_components Predeclared k and h.
#' @param scaling Exact "none" or "dimension_sd".
#' @param multiplier Exact "normal" or "mammen".
#' @param confidence_level Interval probability in (0,1).
#' @param independent_unit_column If supplied, metadata IDs must be unique.
#' @param random_state Nonnegative integer seed below 2^53 for NumPy-compatible
#'   PCG64 normal or Mammen draws. NULL uses the current R RNG stream.
#' @param multiplier_draws Optional finite B-by-n numeric matrix of fixed
#'   source draws; overrides R RNG and permits numerical oracle replay.
#' @param random_engine Seeded multiplier RNG. Use `"base_R"` to replay
#'   previous native normal multipliers, or `"numpy"` for source draws.
#' @return Native result reusing source schema numerical fields. Full-domain
#'   source accepted-type and dataclass contracts remain unsigned.
#' @export
etr_wild_bootstrap_fpca_projection<-function(
    trajectories,outcome,targets=NULL,n_bootstrap=1000L,
    residual_components=2L,inference_components=3L,
    scaling="none",multiplier="normal",
    confidence_level=.95,independent_unit_column=NULL,
    random_state=0L,multiplier_draws=NULL,random_engine="numpy"){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(all(is.finite(trajectories$values)),
    "training trajectories must be complete finite")
  n<-length(trajectories$curve_ids)
  nt<-length(trajectories$time)
  nd<-length(trajectories$dimension_names)
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
    "outcome must contain finite scalar per training curve")
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=20&&n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer at least 20")
  maximum<-min(n-1L,nt*nd)
  for(value in list(residual_components,inference_components))
    .etr_assert(is.numeric(value)&&length(value)==1L&&
      is.finite(value)&&value==floor(value)&&
      value>=1L&&value<=maximum,
      "component counts must be positive integers within source maximum")
  k<-as.integer(residual_components);h<-as.integer(inference_components)
  .etr_assert(h>=k,"inference_components must be >= residual_components")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  .etr_assert(is.character(multiplier)&&length(multiplier)==1L&&
    !is.na(multiplier)&&multiplier%in%c("normal","mammen"),
    "multiplier must be normal or mammen")
  .etr_assert(is.numeric(confidence_level)&&
    length(confidence_level)==1L&&is.finite(confidence_level)&&
    confidence_level>0&&confidence_level<1,
    "confidence_level must lie in (0,1)")
  .etr_assert(is.null(independent_unit_column)||
    (is.character(independent_unit_column)&&
      length(independent_unit_column)==1L&&!is.na(independent_unit_column)&&
      independent_unit_column%in%names(trajectories$metadata)),
    "independent_unit_column must identify an existing metadata field")
  if(!is.null(independent_unit_column)){
    ids<-as.character(trajectories$metadata[[independent_unit_column]])
    .etr_assert(!anyNA(ids)&&!anyDuplicated(ids),
      "wild bootstrap requires independent curve rows; repeated unit IDs unsupported")
  }
  external<-!is.null(targets)
  if(!external)targets<-trajectories
  etr_validate(targets,require_complete=TRUE)
  .etr_assert(identical(targets$time,trajectories$time)&&
    identical(targets$dimension_names,trajectories$dimension_names)&&
    identical(targets$time_unit,trajectories$time_unit)&&
    identical(targets$coordinate_system,trajectories$coordinate_system)&&
    all(is.finite(targets$values)),
    "targets must match training time channel units geometry and be complete finite")
  B<-as.integer(n_bootstrap)
  if(is.null(multiplier_draws)){
    random_engine<-match.arg(random_engine,c("numpy","base_R"))
    mult<-.etr_wild_fpcr_multipliers(B,n,multiplier,random_state,random_engine)
  }else{
    mult<-multiplier_draws
    .etr_assert(is.matrix(mult)&&is.numeric(mult)&&
      identical(dim(mult),c(B,n))&&all(is.finite(mult)),
      "multiplier_draws must be finite B-by-training-curve source draws")
  }
  fit<-etr_fit_fpca(trajectories,n_components=as.integer(h),scaling=scaling)
  scores<-fit$scores[,seq_len(h),drop=FALSE]
  target_scores<-etr_transform_fpca(fit,targets)[,seq_len(h),drop=FALSE]
  .etr_assert(all(is.finite(scores))&&all(is.finite(target_scores)),
    "FPCA score geometry must be finite")
  fit_k<-.etr_wild_fpcr_prepared_fit(scores,k)
  fit_h<-.etr_wild_fpcr_prepared_fit(scores,h)
  fk<-fit_k(outcome)
  fh<-fit_h(outcome)
  tk<-target_scores[,seq_len(k),drop=FALSE]
  pseudo_truth<-as.vector(tk%*%fk$beta[-1L])
  reference<-as.vector(target_scores%*%fh$beta[-1L])
  reference_se<-.etr_wild_fpcr_hetero_se(scores,fk$residual,target_scores)
  nq<-nrow(target_scores)
  projections<-matrix(0,B,nq)
  ses<-matrix(0,B,nq)
  roots<-matrix(0,B,nq)
  tolerance<-100*.Machine$double.eps*max(1,abs(reference))
  for(i in seq_len(B)){
    pseudo_y<-fk$fitted+fk$residual*mult[i,]
    hs<-fit_h(pseudo_y)
    ks<-fit_k(pseudo_y)
    ps<-as.vector(target_scores%*%hs$beta[-1L])
    ss<-.etr_wild_fpcr_hetero_se(scores,ks$residual,target_scores)
    root<-ps-pseudo_truth
    stat<-numeric(nq)
    positive<-ss>.Machine$double.eps*max(1,ss)
    .etr_assert(!any(!positive & abs(root)>tolerance),
      paste0("wild bootstrap replicate ",i-1L,
        " zero SE with non-zero target projection root"))
    stat[positive]<-root[positive]/ss[positive]
    projections[i,]<-ps;ses[i,]<-ss;roots[i,]<-stat
  }
  absolute<-abs(roots)
  quantile_index<-as.integer(ceiling((B-1)*confidence_level)+1L)
  critical<-vapply(seq_len(nq),function(i)
    sort(absolute[,i])[quantile_index],numeric(1L))
  contract<-if(multiplier=="normal")
    list(mean=0,variance=1) else{
      sq<-sqrt(5);list(mean=0,variance=1,
        negative_support=-(sq-1)/2,positive_support=(sq+1)/2,
        negative_probability=(sq+1)/(2*sq))
    }
  provenance<-if(is.list(trajectories$provenance))
    trajectories$provenance else list()
  provenance$fpca_wild_bootstrap_projection<-list(
    method="fixed_regressor_studentized_multiplier_wild_bootstrap",
    family="gaussian",
    estimand="centered_projection_relative_to_training_functional_mean",
    n_bootstrap=B,residual_components_k=k,
    pseudo_truth_components_g=k,inference_components_h=h,
    g_equals_k=TRUE,h_at_least_g=TRUE,scaling=scaling,
    multiplier=multiplier,multiplier_contract=contract,
    studentization="bootstrap_level_heteroscedastic_score_covariance",
    interval="symmetrized_studentized_targetwise",
    confidence_level=confidence_level,fpca_basis_refit_in_bootstrap=FALSE,
    functional_regressors_fixed=TRUE,target_curves_fixed=TRUE,
    independence_assumption="independent_curve_rows",
    independent_unit_column=independent_unit_column,
    clustered_wild_bootstrap=FALSE,future_outcome_prediction_interval=FALSE,
    simultaneous_across_targets=FALSE,
    component_selection_uncertainty_included=FALSE,
    random_state=random_state,
    fixed_source_multiplier_draws_supplied=!is.null(multiplier_draws),
    seeded_normal_draws_match_numpy=is.null(multiplier_draws)&&
      !is.null(random_state)&&random_engine=="numpy"&&multiplier=="normal",
    seeded_mammen_draws_match_numpy=is.null(multiplier_draws)&&
      !is.null(random_state)&&random_engine=="numpy"&&multiplier=="mammen",
    source_full_contract_certified=FALSE)
  structure(list(reference_fpca=fit,
    target_curve_ids=targets$curve_ids,
    reference_projection=reference,pseudo_truth_projection=pseudo_truth,
    reference_se=reference_se,
    bootstrap_projections=projections,bootstrap_se=ses,
    studentized_roots=roots,critical_values=critical,
    lower=reference-critical*reference_se,
    upper=reference+critical*reference_se,
    residuals=fk$residual,confidence_level=confidence_level,
    residual_components=k,inference_components=h,scaling=scaling,
    multiplier=multiplier,target_source=if(external)"external" else "training",
    independent_unit_column=independent_unit_column,
    random_state=random_state,provenance=provenance),
    class="etr_fpca_wild_bootstrap_projection")
}
