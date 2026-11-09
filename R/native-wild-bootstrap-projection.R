# Source: eyetrajectoriespy 1.2.0 wild_regression.py, immutable
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Independent R FPCA/least squares/studentization; no Python backend.
# Optional fixed multiplier matrix replays frozen-source draws. R RNG
# does NOT reproduce NumPy PCG64 without supplied multipliers.

.etr_wild_fpcr_fixed_fit<-function(scores,y,k){
  n<-nrow(scores)
  design<-cbind(1,scores[,seq_len(k),drop=FALSE])
  .etr_assert(qr(design)$rank==k+1L,
    "FPCR score regression is rank deficient")
  beta<-as.numeric(qr.coef(qr(design),y))
  fit<-as.vector(design%*%beta)
  .etr_assert(all(is.finite(beta))&&all(is.finite(fit)),
    "FPCR score regression produced nonfinite values")
  list(beta=beta,fitted=fit,residual=y-fit)
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
#' @param random_state Native R seed. Not a NumPy-equivalent random stream.
#' @param multiplier_draws Optional finite B-by-n numeric matrix of fixed
#'   source draws; overrides R RNG and permits numerical oracle replay.
#' @return Native result reusing source schema numerical fields. Full-domain
#'   source accepted-type and dataclass contracts remain unsigned.
#' @export
etr_wild_bootstrap_fpca_projection<-function(
    trajectories,outcome,targets=NULL,n_bootstrap=1000L,
    residual_components=2L,inference_components=3L,
    scaling="none",multiplier="normal",
    confidence_level=.95,independent_unit_column=NULL,
    random_state=0L,multiplier_draws=NULL){
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
    .etr_assert(is.null(random_state)||
      (is.numeric(random_state)&&length(random_state)==1L&&
      is.finite(random_state)&&random_state==floor(random_state)&&
      random_state>=0&&random_state<=.Machine$integer.max),
      "random_state must be NULL or a native nonnegative integer")
    draw_mult<-function(){
      if(multiplier=="normal"){
        matrix(stats::rnorm(B*n),nrow=B,ncol=n,byrow=TRUE)
      }else{
        sq<-sqrt(5)
        negative<-(1-sq)/2
        positive<-(1+sq)/2
        pneg<-(sq+1)/(2*sq)
        u<-matrix(stats::runif(B*n),B,n,byrow=TRUE)
        ifelse(u<pneg,negative,positive)
      }
    }
    # NULL mirrors Python's accepted unseeded domain. Native R uses its
    # current RNG stream, not NumPy PCG64; seeded calls restore R RNG.
    mult<-if(is.null(random_state))draw_mult() else
      .etr_seed_scope(as.integer(random_state),draw_mult)
    mult<-matrix(mult,nrow=B,ncol=n)
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
  fk<-.etr_wild_fpcr_fixed_fit(scores,outcome,k)
  fh<-.etr_wild_fpcr_fixed_fit(scores,outcome,h)
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
    hs<-.etr_wild_fpcr_fixed_fit(scores,pseudo_y,h)
    ks<-.etr_wild_fpcr_fixed_fit(scores,pseudo_y,k)
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
