# Frozen Python 1.2 regression_inference.py:
# paired nonparametric bootstrap of FULL Gaussian FPCR refits, not
# future-outcome prediction and not calibrated simultaneous bands.
# Integer seeds and caller-supplied source indices support deterministic replay.

.etr_fpcr_bootstrap_fit <- function(x,y,k,scaling,targets) {
  fpca<-.etr_fpca_stability_fit(x,k,scaling)
  design<-cbind(1,fpca$scores[,seq_len(k),drop=FALSE])
  .etr_assert(qr(design)$rank==k+1L,
    "FPCR regression design is rank deficient")
  fit<-etr_fit_scalar_on_fpca(fpca,y,n_components=k)
  beta<-as.numeric(stats::coef(fit$model))
  .etr_assert(length(beta)==k+1L&&all(is.finite(beta)),
    "FPCR fitted coefficient vector is nonfinite or rank deficient")
  .etr_assert(length(fpca$scale)==length(fpca$dimension_names)&&
    all(is.finite(fpca$scale))&&all(fpca$scale>.Machine$double.eps),
    "FPCA scales must be strictly positive")
  nt<-length(fpca$time);nd<-length(fpca$dimension_names)
  slope<-matrix(0,nt,nd)
  for(j in seq_len(nd))for(t in seq_len(nt))
    slope[t,j]<-sum(beta[-1L]*fpca$components[,t,j])/
      fpca$scale[j]^2
  .etr_assert(all(is.finite(slope)),
    "reconstructed FPCR slope must be finite")
  score_target<-etr_transform_fpca(fpca,targets)
  predictions<-as.numeric(beta[1L]+
    score_target[,seq_len(k),drop=FALSE]%*%beta[-1L])
  .etr_assert(all(is.finite(predictions)),
    "FPCR conditional mean prediction must be finite")
  list(fpca=fpca,fit=fit,beta=beta,slope=slope,predictions=predictions)
}
.etr_fpcr_bootstrap_indices <- function(trajectories,unit,participant_column,rng) {
  n<-length(trajectories$curve_ids)
  draw<-function(size)if(is.null(rng))sample.int(size,size,replace=TRUE) else
    rng$integers(size,size)+1L
  if(unit=="curve")return(draw(n))
  groups<-as.character(trajectories$metadata[[participant_column]])
  labels<-unique(groups)
  selected<-labels[draw(length(labels))]
  unlist(lapply(selected,function(g)which(groups==g)),use.names=FALSE)
}
.etr_fpcr_bootstrap_sample <- function(x,index,b) {
  n<-length(index);shape<-dim(x$values)
  ids<-sprintf("bootstrap_%05d_%05d|%s",b-1L,seq_len(n)-1L,
    x$curve_ids[index])
  metadata<-x$metadata[index,,drop=FALSE]
  values<-array(x$values[index,,,drop=FALSE],
    c(n,shape[2L],shape[3L]))
  provenance<-x$provenance
  provenance$paired_regression_bootstrap<-list(
    replicate=b-1L,source_indices=as.integer(index-1L))
  etr_trajectory_set(x$time,values,ids,x$dimension_names,
    metadata=metadata,coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=provenance)
}

# Verify that an external zero-based source-row draw is the concatenation
# of exactly one complete original participant group per independent group draw.
# This preserves Python's _participant_bootstrap_indices sampling unit even
# when participants have unequal numbers of trajectories or are drawn twice.
.etr_fpcr_whole_participant_indices <- function(indices,participant){
  labels<-unique(as.character(participant))
  groups<-lapply(labels,function(label)
    as.integer(which(as.character(participant)==label)-1L))
  observed<-as.integer(indices)
  pos<-1L
  for(draw in seq_along(labels)){
    matched<-FALSE
    for(rows in groups){
      last<-pos+length(rows)-1L
      if(last<=length(observed)&&
        identical(observed[pos:last],rows)){
        pos<-last+1L;matched<-TRUE;break
      }
    }
    if(!matched)return(FALSE)
  }
  identical(pos-1L,length(observed))
}

#' Native paired-bootstrap Gaussian FPCR slope and conditional-mean uncertainty
#'
#' @description Refits the FPCA basis and Gaussian scalar score regression on
#'   each jointly resampled curve/outcome sample. Slope functions are restored
#'   in original channel units; fixed target predictions are conditional
#'   means, not future-outcome prediction intervals or simultaneous bands.
#' @param trajectories Complete common-grid training trajectory set.
#' @param outcome Finite scalar outcome aligned to training curves.
#' @param targets Optional fixed compatible target curves; NULL uses training.
#' @param n_bootstrap Integer count of at least 20 independent replicates.
#' @param n_components Positive integer FPCA score predictor count.
#' @param scaling "none" or "dimension_sd".
#' @param resample_unit "curve" or "participant".
#' @param participant_column Required complete group metadata for participant.
#' @param level Pointwise percentile central mass strictly between 0 and 1.
#' @param random_state Nonnegative integer for NumPy-compatible PCG64 draws,
#'   or NULL for unseeded native R draws.
#' @param bootstrap_indices Optional list of zero-based fixed source-curve
#'   index vectors from the pinned Python bootstrap for numerical replay.
#'   With `resample_unit="participant"`, each vector must concatenate exactly
#'   one *whole original participant* per sampled participant unit, retaining
#'   the observed order of that participant's curves. Repeated groups and
#'   unequal original group sizes are allowed.
#' @return Source-shaped Gaussian FPCR reference and bootstrap fields,
#'   source-invariant estimands, explicit RNG and coverage provenance.
#' @param python_boundary_mode If TRUE, emit exactly the source FPCARegressionUncertaintyResult
#'   outer fields and nested Gaussian regression scientific record, omitting
#'   R-only fixed-index replay fields and retaining source provenance. The
#'   underlying native R lm remains an R model, never a Python statsmodels object.
#' @export
etr_bootstrap_fpca_regression_uncertainty <- function(
    trajectories,outcome,targets=NULL,n_bootstrap=500L,
    n_components=3L,scaling="none",resample_unit="curve",
    participant_column=NULL,level=.95,random_state=0L,
    bootstrap_indices=NULL,python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  .etr_assert(!isTRUE(python_boundary_mode)||is.null(bootstrap_indices),
    "Python source mode does not accept caller-supplied bootstrap indices")
  etr_validate(trajectories,require_complete=TRUE)
  n<-length(trajectories$curve_ids)
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    length(outcome)==n&&all(is.finite(outcome)),
    "outcome must contain one finite scalar per training trajectory")
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=20L&&n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer of at least 20")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==floor(n_components)&&
    n_components>=1L&&n_components< n &&
    n_components<=length(trajectories$time)*
      length(trajectories$dimension_names),
    "n_components must be an admissible positive integer")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  .etr_assert(is.character(resample_unit)&&length(resample_unit)==1L&&
    !is.na(resample_unit)&&resample_unit%in%c("curve","participant"),
    "resample_unit must be curve or participant")
  if(resample_unit=="curve") {
    .etr_assert(is.null(participant_column),
      "participant_column must be NULL with curve resampling")
  } else {
    .etr_assert(is.character(participant_column)&&
      length(participant_column)==1L&&!is.na(participant_column)&&
      participant_column%in%names(trajectories$metadata)&&
      !anyNA(trajectories$metadata[[participant_column]])&&
      length(unique(trajectories$metadata[[participant_column]]))>=2L,
      "participant_column must define two or more complete groups")
  }
  .etr_assert(is.numeric(level)&&length(level)==1L&&
    is.finite(level)&&level>0&&level<1,
    "level must lie in (0, 1)")
  .etr_assert(is.null(random_state)||(is.numeric(random_state)&&length(random_state)==1L&&
    is.finite(random_state)&&random_state==floor(random_state)&&
    random_state>=0L&&random_state<2^53),
    "random_state must be NULL or an exactly represented nonnegative integer")
  if(is.null(targets)) {
    target<-trajectories;target_source<-"training"
  } else {
    etr_validate(targets,require_complete=TRUE)
    .etr_assert(identical(targets$time,trajectories$time)&&
      identical(targets$dimension_names,trajectories$dimension_names)&&
      identical(targets$coordinate_system,trajectories$coordinate_system)&&
      identical(targets$time_unit,trajectories$time_unit),
      "targets must match training time grid dimensions and units exactly")
    target<-targets;target_source<-"external"
  }
  b<-as.integer(n_bootstrap);k<-as.integer(n_components)
  if(!is.null(bootstrap_indices)){
    .etr_assert(is.list(bootstrap_indices)&&length(bootstrap_indices)==b,
      "fixed bootstrap_indices require one source-index vector per replicate")
    for(index in bootstrap_indices){
      .etr_assert(is.numeric(index)&&is.null(dim(index))&&
        length(index)>0L&&all(is.finite(index))&&
        all(index==floor(index))&&all(index>=0L & index<n),
        "fixed bootstrap_indices must use zero-based source curve indices")
      if(resample_unit=="curve"){
        .etr_assert(length(index)==n,
          "curve bootstrap_indices must select n source curves")
      }else{
        .etr_assert(.etr_fpcr_whole_participant_indices(index,
          trajectories$metadata[[participant_column]]),
          "participant bootstrap_indices must select whole-participant groups")
      }
    }
  }
  reference<-.etr_fpcr_bootstrap_fit(
    trajectories,outcome,k,scaling,target)
  rng<-if(is.null(bootstrap_indices)&&!is.null(random_state))
    .etr_numpy_pcg64(random_state) else NULL
  nt<-length(trajectories$time)
  nd<-length(trajectories$dimension_names)
  ntarget<-length(target$curve_ids)
  bslope<-array(NA_real_,c(b,nt,nd))
  bpred<-matrix(NA_real_,b,ntarget)
  bintercept<-numeric(b)
  indices_used<-vector("list",b)
  for(i in seq_len(b)){
    index<-if(is.null(bootstrap_indices))
      .etr_fpcr_bootstrap_indices(trajectories,resample_unit,
        participant_column,rng)
    else as.integer(bootstrap_indices[[i]])+1L
    .etr_assert(length(index)>k+2L,
      paste("bootstrap replicate",i,"has too few independent observations"))
    sample<-.etr_fpcr_bootstrap_sample(trajectories,index,i)
    result<-.etr_fpcr_bootstrap_fit(sample,outcome[index],k,
      scaling,target)
    bslope[i,,]<-result$slope
    bpred[i,]<-result$predictions
    bintercept[i]<-result$beta[1L]
    indices_used[[i]]<-as.integer(index-1L)
  }
  alpha<-(1-level)/2
  slope_q<-function(p)apply(bslope,c(2L,3L),
    stats::quantile,probs=p,names=FALSE,type=7L)
  pred_q<-function(p)as.numeric(apply(bpred,2L,
    stats::quantile,probs=p,names=FALSE,type=7L))
  reference_regression<-list(
    family="gaussian",
    predictions=as.numeric(stats::fitted(reference$fit$model)),
    coefficients=stats::coef(reference$fit$model),
    native_model=reference$fit)
  provenance<-trajectories$provenance
  provenance$fpca_regression_uncertainty<-list(
    method="paired_nonparametric_bootstrap_full_fpcr_refit",
    family="gaussian",n_bootstrap=b,n_components=k,
    component_count_fixed=TRUE,
    component_selection_uncertainty_included=FALSE,
    scaling=scaling,resample_unit=resample_unit,
    participant_column=participant_column,level=level,
    slope_interval="pointwise_percentile_bootstrap",
    prediction_interval="fixed_target_conditional_mean_percentile_bootstrap",
    future_outcome_prediction_interval=FALSE,
    target_source=target_source,target_curves_fixed=TRUE,
    fpc_label_matching_required=FALSE,
    operator_scaled_fpcr_test=FALSE,
    random_state=random_state,
    random_engine=if(is.null(bootstrap_indices))
      (if(is.null(rng))"base_R_unseeded"else"numpy_pcg64") else if(resample_unit=="participant")
      "externally_fixed_source_participant_indices" else
      "externally_fixed_source_curve_indices",
    source_schema_equivalent=FALSE)
  if(isTRUE(python_boundary_mode)) {
    # The Python FunctionalRegressionResult scientific fields are retained
    # in source order. The native lm is a model analogue, never a
    # Python statsmodels results wrapper.
    source_fit<-reference$fit
    # The R scalar-FPCA fit is an S3 regression record, not the frozen
    # FunctionalRegressionResult dataclass. Explicitly materialize the six
    # source-scientific fields instead of subsetting nonexistent list keys.
    source_coef<-as.numeric(stats::coef(source_fit$model))
    names(source_coef)<-c("const",paste0("FPC",seq_len(k)))
    reference_regression<-list(
      model=source_fit$model,
      component_indices=as.integer(seq_len(k)-1L),
      coefficients=source_coef,
      predictions=as.numeric(stats::fitted(source_fit$model)),
      family="gaussian",
      provenance=NULL)
    reference_regression$provenance<-list(
      method="scalar_on_function_via_fpca_scores",
      n_components=k,family="gaussian",covariates=list())
    provenance<-trajectories$provenance
    provenance$fpca_regression_uncertainty<-list(
      method="paired_nonparametric_bootstrap_full_fpcr_refit",
      family="gaussian",n_bootstrap=b,n_components=k,
      component_count_fixed=TRUE,
      component_selection_uncertainty_included=FALSE,
      scaling=scaling,resample_unit=resample_unit,
      participant_column=if(resample_unit=="participant")
        participant_column else NULL,
      level=level,slope_interval="pointwise_percentile_bootstrap",
      prediction_interval="fixed_target_conditional_mean_percentile_bootstrap",
      future_outcome_prediction_interval=FALSE,
      target_source=target_source,target_curves_fixed=TRUE,
      fpc_label_matching_required=FALSE,
      fpc_label_invariance_reason=
        "slope_and_mean_prediction_reconstructed_from_each_complete_refit",
      operator_scaled_fpcr_test=FALSE,random_state=random_state)
  }
  result<-structure(list(reference_fpca=reference$fpca,
    reference_regression=reference_regression,
    reference_slope=reference$slope,
    bootstrap_slopes=bslope,
    slope_lower=matrix(slope_q(alpha),nt,nd),
    slope_median=matrix(slope_q(.5),nt,nd),
    slope_upper=matrix(slope_q(1-alpha),nt,nd),
    slope_se=apply(bslope,c(2L,3L),stats::sd),
    reference_intercept=reference$beta[1L],
    bootstrap_intercepts=bintercept,
    target_curve_ids=target$curve_ids,
    reference_mean_predictions=reference$predictions,
    bootstrap_mean_predictions=bpred,
    prediction_lower=pred_q(alpha),
    prediction_median=pred_q(.5),
    prediction_upper=pred_q(1-alpha),
    prediction_se=apply(bpred,2L,stats::sd),
    level=level,n_components=k,scaling=scaling,
    resampling_unit=resample_unit,
    participant_column=if(resample_unit=="participant")
      participant_column else NULL,
    target_source=target_source,random_state=random_state,
    sampled_source_curve_indices=indices_used,
    provenance=provenance),
    class="etr_fpcr_bootstrap_uncertainty")
  if(isTRUE(python_boundary_mode))
    result$sampled_source_curve_indices<-NULL
  result
}
