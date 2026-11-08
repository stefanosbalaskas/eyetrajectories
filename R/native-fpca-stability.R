# Stage 14: Python-free source-oriented FPCA influence, component and
# eigenspace stability, and explicit empirical outlier diagnostics.
# Source inspected: eyetrajectoriespy==1.2.0 outliers.py,
# stability.py, subspace.py. Robust MCD outlier covariance is NOT
# implemented; this unsupported mode always fails closed.

.etr_fpca_stability_fit <- function(x,k,scaling="none") {
  etr_validate(x,require_complete=TRUE)
  .etr_assert(is.numeric(k)&&length(k)==1L&&is.finite(k)&&
    k==as.integer(k)&&k>=1L&&k<length(x$curve_ids),
    "retained component count must be below number of curves")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    scaling%in%c("none","dimension_sd"),
    "scaling must be 'none' or 'dimension_sd'")
  if(length(x$dimension_names)>1L)
    etr_fit_mfpca(x,n_components=as.integer(k),scaling=scaling)
  else etr_fit_fpca(x,n_components=as.integer(k),scaling=scaling)
}

.etr_fpca_stability_boot <- function(x,unit,participant_column=NULL) {
  n<-length(x$curve_ids)
  if(unit=="curve"){
    selected<-sample.int(n,n,replace=TRUE)
    label<-sprintf("bootstrap_curve_%05d|%s",
      seq_len(n)-1L,x$curve_ids[selected])
    metadata<-x$metadata[selected,,drop=FALSE]
  }else{
    .etr_assert(is.character(participant_column)&&
      length(participant_column)==1L &&
      participant_column%in%names(x$metadata),
      "participant_column must exist for participant resampling")
    g<-x$metadata[[participant_column]]
    .etr_assert(length(g)==n&&!anyNA(g),
      "participant_column must be complete")
    g<-as.character(g);groups<-unique(g)
    .etr_assert(length(groups)>=2L,
      "participant bootstrap requires at least two participants")
    picked<-sample(groups,length(groups),replace=TRUE)
    selected<-integer();group_labels<-character()
    for(i in seq_along(picked)){
      ids<-which(g==picked[i])
      selected<-c(selected,ids)
      group_labels<-c(group_labels,
        rep(sprintf("%s#bootstrap%04d",picked[i],i-1L),length(ids)))
    }
    label<-sprintf("bootstrap_%05d|%s",
      seq_along(selected)-1L,x$curve_ids[selected])
    metadata<-x$metadata[selected,,drop=FALSE]
    metadata[[participant_column]]<-group_labels
  }
  d<-dim(x$values)
  vals<-array(x$values[selected,,,drop=FALSE],
    c(length(selected),d[2L],d[3L]))
  provenance<-x$provenance
  provenance$bootstrap<-list(unit=unit,n_draws=if(unit=="curve")n
    else length(unique(as.character(x$metadata[[participant_column]]))))
  etr_trajectory_set(x$time,vals,label,x$dimension_names,
    metadata=metadata,coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=provenance)
}

.etr_fpca_stability_scope <- function(x,unit,participant_column) {
  .etr_assert(is.character(unit)&&length(unit)==1L&&
    unit%in%c("curve","participant"),
    "resample_unit must be curve or participant")
  if(unit=="participant")
    .etr_assert(is.character(participant_column)&&
      length(participant_column)==1L&&
      participant_column%in%names(x$metadata) &&
      !anyNA(x$metadata[[participant_column]]),
      "participant_column required and complete for participant bootstrap")
}

.etr_fpca_stability_block <- function(fit,start,stop) {
  .etr_fpca_fitted_check(fit)
  nt<-length(fit$time);nd<-length(fit$dimension_names)
  out<-matrix(0,stop-start,nt*nd)
  for(k in seq.int(start+1L,stop)){
    component<-matrix(fit$components[k,,,drop=FALSE],
      nrow=nt,ncol=nd)
    standardized<-sweep(component,2L,fit$scale,"/")
    standardized<-sweep(standardized,1L,sqrt(fit$weights),"*")
    out[k-start,]<-as.vector(standardized)
  }
  gram<-tcrossprod(out)
  .etr_assert(isTRUE(all.equal(unname(gram),
    diag(stop-start),tolerance=1e-7,check.attributes=FALSE)),
    "selected components are not orthonormal in functional geometry")
  out
}

#' Signed/rotation-invariant comparison of weighted FPCA eigenspaces
#' @param reference,candidate Native FPCA fits with same grid and channels.
#' @param start_component Zero-based start index for contiguous FPC block.
#' @param n_components Positive number of FPCs in the block.
#' @export
etr_compare_fpca_subspaces <- function(reference,candidate,
    start_component=0L,n_components=2L) {
  .etr_fpca_fitted_check(reference);.etr_fpca_fitted_check(candidate)
  .etr_assert(is.numeric(start_component)&&length(start_component)==1L&&
    is.finite(start_component)&&start_component==as.integer(start_component)&&
    start_component>=0L,
    "start_component must be nonnegative integer")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==as.integer(n_components)&&
    n_components>=1L,
    "n_components must be positive integer")
  start<-as.integer(start_component);k<-as.integer(n_components)
  stop<-start+k
  .etr_assert(stop<=reference$n_components&&
    stop<=candidate$n_components,
    "requested subspace is outside the common fitted range")
  .etr_assert(identical(reference$time,candidate$time),
    "FPCA results must use same time grid")
  .etr_assert(identical(reference$dimension_names,candidate$dimension_names),
    "FPCA results must use same dimensions")
  .etr_assert(identical(reference$coordinate_system,candidate$coordinate_system)&&
    identical(reference$time_unit,candidate$time_unit),
    "FPCA coordinate and time-unit semantics must agree")
  .etr_assert(isTRUE(all.equal(reference$weights,candidate$weights,
    tolerance=1e-8,check.attributes=FALSE)),
    "quadrature weights differ")
  a<-.etr_fpca_stability_block(reference,start,stop)
  b<-.etr_fpca_stability_block(candidate,start,stop)
  # Identical standardized bases span exactly the same subspace.
  # SVD may return 1 - machine epsilon for their self-Gram matrix;
  # acos/sqrt magnifies that harmless roundoff to about 1e-8.
  # Handle exact equality only: never snap genuinely distinct bases.
  cos<-if(identical(a,b))rep(1,k) else
    svd(a%*%t(b),nu=0L,nv=0L)$d
  cos<-pmax(0,pmin(1,cos))
  ang<-acos(cos)*180/pi
  frob<-sqrt(2*sum(pmax(0,1-cos^2)))
  structure(list(reference=reference,candidate=candidate,
    component_indices=as.integer(start:(stop-1L)),
    principal_cosines=cos,principal_angles_degrees=ang,
    projector_distance_frobenius=frob,
    normalized_projector_distance=frob/sqrt(2*k),
    provenance=list(method="principal_angles_weighted_functional_subspace",
      start_component_zero_based=start,n_components=k,
      standardization="fit_specific_dimension_scale",
      rotation_invariant_within_selected_subspace=TRUE)),
    class="etr_fpca_subspace_comparison")
}

#' Bootstrap native principal-angle eigenspace stability
#' @param trajectories Complete common-grid sample.
#' @param n_bootstrap Number of independent resampling replicates (>=2).
#' @param scaling Native channel scaling mode.
#' @param resample_unit Curve or whole participant resampling.
#' @param participant_column Participant metadata column when requested.
#' @param random_state Scoped R seed (not NumPy bitwise equivalent).
#' @inheritParams etr_compare_fpca_subspaces
#' @export
etr_bootstrap_fpca_subspace_stability <- function(trajectories,
    start_component=0L,n_components=2L,n_bootstrap=200L,
    scaling="none",resample_unit="curve",
    participant_column=NULL,random_state=0L) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(start_component)&&length(start_component)==1L&&
    is.finite(start_component)&&start_component==as.integer(start_component)&&
    start_component>=0L,"start_component must be a nonnegative integer")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==as.integer(n_components)&&
    n_components>=1L,"n_components must be a positive integer")
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==as.integer(n_bootstrap)&&
    n_bootstrap>=2L,"n_bootstrap must be integer >=2")
  .etr_fpca_stability_scope(trajectories,resample_unit,participant_column)
  stop<-as.integer(start_component+n_components)
  .etr_assert(stop<length(trajectories$curve_ids),
    "requested subspace exceeds nonzero sample FPCA rank")
  ref<-.etr_fpca_stability_fit(trajectories,stop,scaling)
  restore<-.etr_simulation_rng(random_state);on.exit(restore(),add=TRUE)
  b<-as.integer(n_bootstrap);k<-as.integer(n_components)
  cos<-ang<-matrix(0,b,k)
  distances<-normed<-numeric(b)
  for(i in seq_len(b)){
    s<-.etr_fpca_stability_boot(trajectories,resample_unit,participant_column)
    .etr_assert(stop<length(s$curve_ids),
      "bootstrap replicate has insufficient nonzero sample rank")
    fit<-.etr_fpca_stability_fit(s,stop,scaling)
    comp<-etr_compare_fpca_subspaces(ref,fit,start_component,k)
    cos[i,]<-comp$principal_cosines
    ang[i,]<-comp$principal_angles_degrees
    distances[i]<-comp$projector_distance_frobenius
    normed[i]<-comp$normalized_projector_distance
  }
  structure(list(reference=ref,
    component_indices=as.integer(start_component:(stop-1L)),
    principal_cosines=cos,principal_angles_degrees=ang,
    projector_distance_frobenius=distances,
    normalized_projector_distance=normed,
    resampling_unit=resample_unit,random_state=as.integer(random_state),
    provenance=list(method="bootstrap_principal_angle_subspace_stability",
      n_bootstrap=b,start_component_zero_based=as.integer(start_component),
      n_components=k,scaling=scaling,
      participant_column=participant_column,
      random_engine="base_R_not_NumPy",
      scientific_warning="Descriptive stability, not FPC identifiability or interval coverage")),
    class="etr_fpca_subspace_stability")
}

#' Summarize principal-angle bootstrap results without inference claims
#' @param result Native FPCA subspace stability result.
#' @param interval Two declared quantile probabilities [0,1].
#' @export
etr_summarise_fpca_subspace_stability <- function(result,
    interval=c(.025,.975)) {
  .etr_assert(inherits(result,"etr_fpca_subspace_stability"),
    "result must be native FPCA subspace stability")
  .etr_assert(is.numeric(interval)&&length(interval)==2L&&
    all(is.finite(interval))&&interval[1L]>=0&&
    interval[2L]<=1&&interval[1L]<interval[2L],
    "interval must satisfy 0 <= low < high <= 1")
  minimum<-apply(result$principal_cosines,1L,min)
  maximum<-apply(result$principal_angles_degrees,1L,max)
  distance<-result$normalized_projector_distance
  q<-function(x,p)as.numeric(stats::quantile(x,p,names=FALSE,type=7L))
  ix<-result$component_indices
  data.frame(component_start=as.integer(ix[1L]+1L),
    component_end=as.integer(tail(ix,1L)+1L),
    n_components=as.integer(length(ix)),
    median_min_principal_cosine=stats::median(minimum),
    min_principal_cosine_interval_low=q(minimum,interval[1L]),
    min_principal_cosine_interval_high=q(minimum,interval[2L]),
    median_max_principal_angle_degrees=stats::median(maximum),
    max_principal_angle_interval_low=q(maximum,interval[1L]),
    max_principal_angle_interval_high=q(maximum,interval[2L]),
    median_normalized_projector_distance=stats::median(distance),
    normalized_projector_distance_interval_low=q(distance,interval[1L]),
    normalized_projector_distance_interval_high=q(distance,interval[2L]))
}

#' Leave-one-curve/participant-group-out FPCA influence by component matching
#' @inheritParams etr_bootstrap_fpca_subspace_stability
#' @param group_column Optional curve metadata group identifier.
#' @export
etr_leave_one_group_out_fpca_influence <- function(trajectories,
    group_column=NULL,n_components=3L,scaling="none") {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==as.integer(n_components)&&
    n_components>=1L&&n_components<length(trajectories$curve_ids),
    "n_components must be below number of source trajectories")
  k<-as.integer(n_components)
  if(is.null(group_column)){
    g<-trajectories$curve_ids
  }else{
    .etr_assert(is.character(group_column)&&length(group_column)==1L&&
      group_column%in%names(trajectories$metadata),
      "group_column must exist in metadata")
    g<-trajectories$metadata[[group_column]]
    .etr_assert(!anyNA(g),"group_column contains missing values")
    g<-as.character(g)
  }
  groups<-unique(g)
  ref<-.etr_fpca_stability_fit(trajectories,k,scaling)
  summary_rows<-vector("list",length(groups))
  component_rows<-vector("list",length(groups))
  for(i in seq_along(groups)){
    omitted<-which(g==groups[i])
    remain<-which(g!=groups[i])
    .etr_assert(length(remain)>k,
      paste("Removing group",groups[i],"leaves too few curves for FPCA"))
    cand<-.etr_fpca_stability_fit(.etr_cv_subset(trajectories,remain),k,scaling)
    match<-etr_match_fpca_components(ref,cand,n_components=k)
    ab<-abs(match$signed_similarity)
    dr<-cand$explained_variance_ratio[match$assignments+1L]-
      ref$explained_variance_ratio[seq_len(k)]
    summary_rows[[i]]<-data.frame(group=groups[i],
      omitted_n_curves=length(omitted),
      remaining_n_curves=length(remain),
      min_abs_component_similarity=min(ab),
      mean_abs_component_similarity=mean(ab),
      max_abs_explained_variance_change=max(abs(dr)),
      mean_abs_explained_variance_change=mean(abs(dr)),
      influence_score=1-min(ab))
    component_rows[[i]]<-data.frame(group=rep(groups[i],k),
      reference_component=seq_len(k),
      matched_component=match$assignments+1L,
      signed_similarity=match$signed_similarity,
      absolute_similarity=ab,explained_variance_change=dr)
  }
  structure(list(reference=ref,summary=do.call(rbind,summary_rows),
    components=do.call(rbind,component_rows),
    group_column=group_column,n_components=k,
    provenance=list(method="leave_one_group_out_fpca",
      group_column=group_column,scaling=scaling,
      scientific_warning="Influence is descriptive, not an automatic exclusion criterion")),
    class="etr_fpca_influence")
}

.etr_fpca_stability_fixed_boot <- function(x,unit,participant_column,
    draws) {
  # Source-equivalent indexing is zero-based. Do not perform any random
  # resampling here: the caller supplies the entire bootstrap unit draw.
  n<-length(x$curve_ids)
  if(unit=="curve") {
    .etr_assert(is.numeric(draws)&&is.null(dim(draws))&&
      length(draws)==n&&all(is.finite(draws))&&
      all(draws==floor(draws))&&all(draws>=0L & draws<n),
      "bootstrap_unit_indices require valid zero-based curve draws")
    selected<-as.integer(draws)+1L
    label<-sprintf("bootstrap_curve_%05d|%s",
      seq_len(n)-1L,x$curve_ids[selected])
    metadata<-x$metadata[selected,,drop=FALSE]
    n_draws<-n
  } else {
    group<-as.character(x$metadata[[participant_column]])
    unique_group<-unique(group)
    ng<-length(unique_group)
    .etr_assert(is.numeric(draws)&&is.null(dim(draws))&&
      length(draws)==ng&&all(is.finite(draws))&&
      all(draws==floor(draws))&&all(draws>=0L & draws<ng),
      "bootstrap_unit_indices require valid zero-based participant draws")
    picked<-unique_group[as.integer(draws)+1L]
    selected<-integer();group_labels<-character()
    for(j in seq_along(picked)) {
      src<-which(group==picked[j])
      selected<-c(selected,src)
      group_labels<-c(group_labels,rep(sprintf("%s#bootstrap%04d",
        picked[j],j-1L),length(src)))
    }
    label<-sprintf("bootstrap_%05d|%s",
      seq_along(selected)-1L,x$curve_ids[selected])
    metadata<-x$metadata[selected,,drop=FALSE]
    metadata[[participant_column]]<-group_labels
    n_draws<-ng
  }
  shape<-dim(x$values)
  values<-array(x$values[selected,,,drop=FALSE],
    c(length(selected),shape[2L],shape[3L]))
  provenance<-x$provenance
  provenance$bootstrap<-list(unit=unit,n_draws=n_draws,
    fixed_source_unit_indices=TRUE)
  etr_trajectory_set(x$time,values,label,x$dimension_names,
    metadata=metadata,coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=provenance)
}

.etr_fpca_stability_check_fixed_draws <- function(x,unit,
    participant_column,draws,b) {
  if(is.null(draws))return(invisible(NULL))
  .etr_assert(is.list(draws)&&length(draws)==b,
    "bootstrap_unit_indices must be a list of n_bootstrap replicate draws")
  for(indices in draws) {
    if(unit=="curve")n<-length(x$curve_ids) else
      n<-length(unique(as.character(x$metadata[[participant_column]])))
    .etr_assert(is.numeric(indices)&&is.null(dim(indices))&&
      length(indices)==n&&all(is.finite(indices))&&
      all(indices==floor(indices))&&all(indices>=0L & indices<n),
      "bootstrap_unit_indices must contain valid zero-based source unit indices")
  }
  invisible(NULL)
}

#' Descriptive nonparametric bootstrap of individually matched FPCs
#' @inheritParams etr_bootstrap_fpca_subspace_stability
#' @param bootstrap_unit_indices Optional list of zero-based unit-index
#'   draws, one numeric vector per replicate. Curve mode indexes source
#'   curves; participant mode indexes first-observed participant groups.
#'   This native replay extension bypasses the R RNG but does not add a
#'   parameter to the frozen Python public API.
#' @export
etr_bootstrap_fpca_stability <- function(trajectories,
    n_bootstrap=200L,n_components=3L,scaling="none",
    resample_unit="curve",participant_column=NULL,random_state=0L,
    bootstrap_unit_indices=NULL) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==as.integer(n_bootstrap)&&
    n_bootstrap>=2L,"n_bootstrap must be an integer >=2")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==as.integer(n_components)&&
    n_components>=1L&&n_components<length(trajectories$curve_ids),
    "n_components must be below source curve count")
  .etr_fpca_stability_scope(trajectories,resample_unit,participant_column)
  k<-as.integer(n_components);b<-as.integer(n_bootstrap)
  .etr_fpca_stability_check_fixed_draws(trajectories,resample_unit,
    participant_column,bootstrap_unit_indices,b)
  ref<-.etr_fpca_stability_fit(trajectories,k,scaling)
  if(is.null(bootstrap_unit_indices)) {
    restore<-.etr_simulation_rng(random_state)
    on.exit(restore(),add=TRUE)
  }
  sim<-signed<-explained<-matrix(0,b,k)
  assignments<-matrix(0L,b,k)
  sizes<-integer(b)
  for(i in seq_len(b)){
    sample<-if(is.null(bootstrap_unit_indices))
      .etr_fpca_stability_boot(trajectories,resample_unit,participant_column)
      else .etr_fpca_stability_fixed_boot(trajectories,resample_unit,
        participant_column,bootstrap_unit_indices[[i]])
    .etr_assert(length(sample$curve_ids)>k,
      "bootstrap replicate has insufficient fitted sample rank")
    cand<-.etr_fpca_stability_fit(sample,k,scaling)
    matched<-etr_match_fpca_components(ref,cand,n_components=k)
    assignments[i,]<-matched$assignments
    signed[i,]<-matched$signed_similarity
    sim[i,]<-abs(matched$signed_similarity)
    explained[i,]<-cand$explained_variance_ratio[matched$assignments+1L]
    sizes[i]<-length(sample$curve_ids)
  }
  structure(list(reference=ref,similarities=sim,
    signed_similarities=signed,assignments=assignments,
    explained_variance_ratio=explained,
    bootstrap_curve_counts=sizes,resampling_unit=resample_unit,
    random_state=as.integer(random_state),
    provenance=list(method="nonparametric_bootstrap_component_matching",
      n_bootstrap=b,n_components=k,scaling=scaling,
      participant_column=participant_column,
      random_engine=if(is.null(bootstrap_unit_indices))
        "base_R_not_NumPy" else "caller_supplied_fixed_unit_indices",
      fixed_draw_replay=!is.null(bootstrap_unit_indices),
      scientific_warning="Component stability is descriptive, not probability of truth")),
    class="etr_fpca_stability")
}

#' Summarize matched individual-FPC bootstrap stability
#' @param result Native FPCA stability result.
#' @param similarity_threshold Explicit descriptive cosine threshold.
#' @param interval Two quantiles within [0,1].
#' @export
etr_summarise_fpca_stability <- function(result,
    similarity_threshold=.80,interval=c(.025,.975)){
  .etr_assert(inherits(result,"etr_fpca_stability"),
    "result must be native FPCA component stability")
  .etr_assert(is.numeric(similarity_threshold)&&
    length(similarity_threshold)==1L&&is.finite(similarity_threshold)&&
    similarity_threshold>=0&&similarity_threshold<=1,
    "similarity_threshold must lie in [0,1]")
  .etr_assert(is.numeric(interval)&&length(interval)==2L&&
    all(is.finite(interval))&&interval[1L]>=0&&interval[2L]<=1&&
    interval[1L]<interval[2L],
    "interval must satisfy 0 <= low < high <= 1")
  k<-result$reference$n_components
  q<-function(x,p)as.numeric(stats::quantile(x,p,names=FALSE,type=7L))
  do.call(rbind,lapply(seq_len(k),function(j){
    v<-result$similarities[,j];ev<-result$explained_variance_ratio[,j]
    data.frame(component=as.integer(j),
      median_abs_similarity=stats::median(v),
      similarity_interval_low=q(v,interval[1L]),
      similarity_interval_high=q(v,interval[2L]),
      fraction_at_or_above_threshold=mean(v>=similarity_threshold),
      similarity_threshold=similarity_threshold,
      median_explained_variance_ratio=stats::median(ev))
  }))
}

#' Explicit empirical-score-covariance functional outlier review diagnostics
#' @param result Native fitted FPCA.
#' @param trajectories Exact fitted curve sample in same ID order.
#' @param n_components Retained fitted components (NULL all).
#' @param reconstruction_z_threshold Positive robust-MAD review cutoff.
#' @param score_alpha Chi-squared score-distance quantile.
#' @param score_covariance "empirical" supported; robust MCD fails closed.
#' @param random_state Source provenance only (unused for empirical).
#' @export
etr_diagnose_fpca_outliers <- function(result,trajectories,
    n_components=NULL,reconstruction_z_threshold=3.5,
    score_alpha=.99,score_covariance="robust",random_state=0L) {
  .etr_fpca_compatible_sample(result,trajectories)
  .etr_assert(identical(score_covariance,"empirical"),
    "robust MinCovDet covariance is not ported; explicitly select score_covariance='empirical'")
  k<-.etr_fpca_component_count(result$n_components,n_components)
  .etr_assert(is.numeric(reconstruction_z_threshold)&&
    length(reconstruction_z_threshold)==1L&&
    is.finite(reconstruction_z_threshold)&&reconstruction_z_threshold>0,
    "reconstruction_z_threshold must be positive finite")
  .etr_assert(is.numeric(score_alpha)&&length(score_alpha)==1L&&
    is.finite(score_alpha)&&score_alpha>0&&score_alpha<1,
    "score_alpha must lie in (0,1)")
  .etr_assert(length(trajectories$curve_ids)>k,
    "empirical covariance requires more curves than components")
  errors<-etr_reconstruction_error_by_curve(result,trajectories,k)$integrated_rmse
  med<-stats::median(errors)
  mad<-stats::median(abs(errors-med))
  if(mad<=.Machine$double.eps){
    .etr_assert(all(abs(errors-med)<=1e-8),
      "zero reconstruction-error MAD prevents robust review threshold")
    robust_z<-rep(0,length(errors))
  }else robust_z<-0.6744897501960817*(errors-med)/mad
  scores<-result$scores[,seq_len(k),drop=FALSE]
  centered<-sweep(scores,2L,colMeans(scores),"-")
  cov<-crossprod(centered)/nrow(scores) # sklearn EmpiricalCovariance: ddof=0
  .etr_assert(qr(cov)$rank==k && all(is.finite(cov)),
    "empirical score covariance is singular")
  mahal<-rowSums((centered%*%solve(cov))*centered)
  cutoff<-stats::qchisq(score_alpha,df=k)
  rflag<-robust_z>reconstruction_z_threshold
  sflag<-mahal>cutoff
  diagnostics<-data.frame(curve_id=trajectories$curve_ids,
    reconstruction_rmse=errors,reconstruction_robust_z=robust_z,
    score_mahalanobis_sq=mahal,score_cutoff=rep(cutoff,length(errors)),
    reconstruction_flag=rflag,score_flag=sflag,
    review_flag=rflag|sflag)
  structure(list(diagnostics=diagnostics,
    method="fpca_reconstruction_and_score_space",reference=result,
    provenance=list(n_components=k,
      reconstruction_z_threshold=reconstruction_z_threshold,
      score_alpha=score_alpha,score_covariance=score_covariance,
      random_state=random_state,
      scientific_warning="Review flags are diagnostic only; never automatic exclusions")),
    class="etr_fpca_outliers")
}
