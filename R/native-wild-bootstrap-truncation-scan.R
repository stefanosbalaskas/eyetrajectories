# Frozen eyetrajectoriespy 1.2.0 wild_selection.py:
# One fixed FPCA basis at maximum h, shared multiplier rows across h.
# Competing inference truncations are never selected automatically.

#' Native shared-draw FPCR wild-bootstrap truncation scan
#' @param trajectories Complete native functional training curves.
#' @param outcome Finite per-curve Gaussian scalar outcomes.
#' @param candidate_components Strictly consecutive increasing h values.
#' @param targets Optional same-grid independent target curves.
#' @param n_bootstrap Number of multiplier draws (>=20).
#' @param residual_components Fixed residual and pseudo-truth k.
#' @param scaling, multiplier Explicit FPCA scaling and wild law.
#' @param confidence_level Fixed coverage probability.
#' @param independent_unit_column Optional unique independent curve ID field.
#' @param random_state Nonnegative integer seed below 2^53 for NumPy-compatible
#'   PCG64 normal or Mammen draws. NULL uses the current R RNG stream.
#' @param multiplier_draws Optional B-by-n frozen source multiplier matrix.
#' @param random_engine Seeded multiplier RNG. Use `"base_R"` to replay
#'   previous native normal multipliers, or `"numpy"` for source draws.
#' @return Native source-shape scan record, without automatic h selection.
#' @export
etr_scan_wild_bootstrap_fpca_truncations<-function(
    trajectories,outcome,candidate_components,targets=NULL,
    n_bootstrap=1000L,residual_components=2L,
    scaling="none",multiplier="normal",confidence_level=.95,
    independent_unit_column=NULL,random_state=0L,multiplier_draws=NULL,
    random_engine="numpy"){
  .etr_assert(is.numeric(candidate_components)&&
    length(candidate_components)>=2L&&
    all(is.finite(candidate_components))&&
    all(candidate_components==floor(candidate_components))&&
    all(diff(candidate_components)==1L),
    "candidate_components must be at least two consecutive increasing integers")
  .etr_assert(is.numeric(residual_components)&&
    length(residual_components)==1L&&is.finite(residual_components)&&
    residual_components==floor(residual_components)&&
    residual_components>=1L&&candidate_components[1L]>=residual_components,
    "all candidate h must be at least residual_components")
  maximum<-min(length(trajectories$curve_ids)-1L,
    length(trajectories$time)*length(trajectories$dimension_names))
  .etr_assert(all(candidate_components<=maximum),
    "candidate_components exceed source supported FPCA rank bound")
  # Fail-closed shared seed domain and matrix layout; never generate a
  # separate independent wild draw for any candidate h.
  B<-as.integer(n_bootstrap);n<-length(trajectories$curve_ids)
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=20&&n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer >=20")
  .etr_assert(is.character(multiplier)&&length(multiplier)==1L&&
    !is.na(multiplier)&&multiplier%in%c("normal","mammen"),
    "multiplier must be normal or mammen")
  if(is.null(multiplier_draws)){
    random_engine<-match.arg(random_engine,c("numpy","base_R"))
    mult<-.etr_wild_fpcr_multipliers(B,n,multiplier,random_state,random_engine)
  }else{
    mult<-multiplier_draws
    .etr_assert(is.matrix(mult)&&is.numeric(mult)&&
      identical(dim(mult),c(B,n))&&all(is.finite(mult)),
      "multiplier_draws must be finite B-by-n fixed source draws")
  }
  # The old scan first ran a complete h=max bootstrap merely to obtain
  # reference_fpca, then repeated every bootstrap replicate during the scan.
  # Fit the shared FPCA basis directly; this avoids a redundant B-replicate
  # wild bootstrap without changing the fixed-basis source estimand.
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(all(is.finite(trajectories$values)),
    "training trajectories must be complete finite")
  outcome<-.etr_fpcr_numeric_outcome(outcome,n,"gaussian",
    "outcome must contain finite scalar per training curve")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  .etr_assert(is.numeric(confidence_level)&&length(confidence_level)==1L&&
    is.finite(confidence_level)&&confidence_level>0&&
    confidence_level<1,
    "confidence_level must lie in (0,1)")
  .etr_assert(is.null(independent_unit_column)||
    (is.character(independent_unit_column)&&
      length(independent_unit_column)==1L&&!is.na(independent_unit_column)&&
      independent_unit_column%in%names(trajectories$metadata)),
    "independent_unit_column must identify existing metadata")
  if(!is.null(independent_unit_column)){
    ids<-as.character(trajectories$metadata[[independent_unit_column]])
    .etr_assert(!anyNA(ids)&&!anyDuplicated(ids),
      "wild bootstrap requires independent curve rows; repeated unit IDs unsupported")
  }
  target_source<-if(is.null(targets))"training" else "external"
  if(is.null(targets))targets<-trajectories
  etr_validate(targets,require_complete=TRUE)
  .etr_assert(identical(targets$time,trajectories$time)&&
    identical(targets$dimension_names,trajectories$dimension_names)&&
    identical(targets$time_unit,trajectories$time_unit)&&
    identical(targets$coordinate_system,trajectories$coordinate_system)&&
    all(is.finite(targets$values)),
    "targets must match training time channel units geometry and be complete finite")
  fit<-etr_fit_fpca(trajectories,
    n_components=as.integer(tail(candidate_components,1L)),scaling=scaling)
  scores<-fit$scores
  target_scores<-etr_transform_fpca(fit,targets)
  .etr_assert(all(is.finite(scores))&&all(is.finite(target_scores)),
    "FPCA score geometry must be finite")
  k<-as.integer(residual_components)
  fit_k<-.etr_wild_fpcr_prepared_fit(scores,k)
  fk<-fit_k(outcome)
  nk<-length(candidate_components);nq<-length(targets$curve_ids)
  pseudo_truth<-as.vector(
    target_scores[,seq_len(k),drop=FALSE]%*%fk$beta[-1L])
  pseudo_y<-matrix(0,B,n)
  residual_k<-matrix(0,B,n)
  for(i in seq_len(B)){
    pseudo_y[i,]<-fk$fitted+fk$residual*mult[i,]
    residual_k[i,]<-fit_k(pseudo_y[i,])$residual
  }
  projections<-matrix(0,nk,nq)
  ses<-matrix(0,nk,nq)
  crit<-matrix(0,nk,nq)
  lower<-matrix(0,nk,nq)
  upper<-matrix(0,nk,nq)
  roots<-array(0,c(nk,B,nq))
  critical_index<-as.integer(ceiling((B-1)*confidence_level)+1L)
  for(j in seq_along(candidate_components)){
    h<-as.integer(candidate_components[j])
    score_h<-scores[,seq_len(h),drop=FALSE]
    target_h<-target_scores[,seq_len(h),drop=FALSE]
    fit_h<-.etr_wild_fpcr_prepared_fit(scores,h)
    f_h<-fit_h(outcome)
    ref<-as.vector(target_h%*%f_h$beta[-1L])
    infer_se<-.etr_wild_fpcr_prepared_se(score_h,target_h)
    se<-infer_se(fk$residual)
    projections[j,]<-ref;ses[j,]<-se
    tolerance<-100*.Machine$double.eps*max(1,abs(ref))
    for(i in seq_len(B)){
      fs<-fit_h(pseudo_y[i,])
      ps<-as.vector(target_h%*%fs$beta[-1L])
      ss<-infer_se(residual_k[i,])
      delta<-ps-pseudo_truth
      pos<-ss>.Machine$double.eps*max(1,ss)
      .etr_assert(!any(!pos&abs(delta)>tolerance),
        paste0("wild scan replicate ",i-1L,
          " zero SE with nonzero projection root"))
      vals<-numeric(nq)
      vals[pos]<-delta[pos]/ss[pos]
      roots[j,i,]<-vals
    }
    for(t in seq_len(nq))
      crit[j,t]<-sort(abs(roots[j,,t]))[critical_index]
    lower[j,]<-ref-crit[j,]*se
    upper[j,]<-ref+crit[j,]*se
  }
  provenance<-if(is.list(trajectories$provenance))
    trajectories$provenance else list()
  provenance$fpca_wild_bootstrap_truncation_scan<-list(
    method="shared_multiplier_wild_bootstrap_truncation_scan",
    family="gaussian",residual_components_k=k,
    pseudo_truth_components_g=k,
    candidate_inference_components_h=as.integer(candidate_components),
    g_equals_k=TRUE,all_h_at_least_g=TRUE,
    shared_multiplier_draws_across_h=TRUE,
    n_bootstrap=B,confidence_level=confidence_level,scaling=scaling,
    multiplier=multiplier,
    interval="symmetrized_studentized_targetwise",
    functional_regressors_fixed=TRUE,
    fpca_basis_refit_in_bootstrap=FALSE,target_curves_fixed=TRUE,
    independence_assumption="independent_curve_rows",
    independent_unit_column=independent_unit_column,
    simultaneous_across_targets=FALSE,random_state=random_state,
    seeded_normal_draws_match_numpy=is.null(multiplier_draws)&&
      !is.null(random_state)&&random_engine=="numpy"&&multiplier=="normal",
    seeded_mammen_draws_match_numpy=is.null(multiplier_draws)&&
      !is.null(random_state)&&random_engine=="numpy"&&multiplier=="mammen",
    source_full_contract_certified=FALSE)
  structure(list(reference_fpca=fit,
    target_curve_ids=targets$curve_ids,
    candidate_components=as.integer(candidate_components),
    residual_components=k,pseudo_truth_projection=pseudo_truth,
    reference_projections=projections,reference_se=ses,
    critical_values=crit,lower=lower,upper=upper,
    centers=(lower+upper)/2,widths=upper-lower,
    studentized_roots=roots,confidence_level=confidence_level,
    scaling=scaling,multiplier=multiplier,
    target_source=target_source,
    independent_unit_column=independent_unit_column,
    random_state=random_state,provenance=provenance),
    class="etr_fpca_wild_bootstrap_truncation_scan")
}
