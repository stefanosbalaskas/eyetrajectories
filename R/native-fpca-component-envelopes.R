# Matched-bootstrap descriptive FPC envelopes.
# Source: eyetrajectoriespy v1.2.0 stability.py, pinned c1cd95ad.
# Base-R generator is not bitwise equivalent to NumPy PCG64.

.etr_fpca_envelope_quantiles <- function(samples,level) {
  d<-dim(samples)
  .etr_assert(is.array(samples)&&length(d)==4L&&is.numeric(samples)&&
    d[1L]>=2L&&all(is.finite(samples)),
    "bootstrap component samples must be finite four-dimensional arrays")
  .etr_assert(is.numeric(level)&&length(level)==1L&&!is.na(level)&&
    is.finite(level)&&level>0&&level<1,
    "level must lie strictly between zero and one")
  alpha<-(1-level)/2
  dims<-as.integer(d[-1L])
  lower<-median<-upper<-array(NA_real_,dims)
  for(k in seq_len(dims[1L])) {
    for(t in seq_len(dims[2L])) {
      for(j in seq_len(dims[3L])) {
        q<-as.numeric(stats::quantile(samples[,k,t,j],
          probs=c(alpha,.5,1-alpha),names=FALSE,type=7L))
        lower[k,t,j]<-q[1L]
        median[k,t,j]<-q[2L]
        upper[k,t,j]<-q[3L]
      }
    }
  }
  list(lower=lower,median=median,upper=upper)
}

#' Native matched-bootstrap FPCA component shape envelopes
#'
#' @description A descriptive pointwise resampling summary, not a
#'   calibrated pointwise or simultaneous confidence band.
#' @param trajectories Complete common-grid native trajectories.
#' @param n_bootstrap At least two independent bootstrap draws.
#' @param n_components Positive number of retained FPCA components below
#'   the number of source trajectories.
#' @param scaling Explicit native channel scaling.
#' @param resample_unit Resample individual curves or whole participants.
#' @param participant_column Metadata column when resampling participants.
#' @param level Central pointwise quantile mass, strictly between zero and one.
#' @param random_state Base R seed, restored after completion.
#' @param bootstrap_unit_indices Optional list of zero-based whole-unit
#'   resampling index vectors, with one vector per bootstrap replicate.
#'   Curve mode indexes original curves; participant mode indexes groups
#'   in their first-observed order. Bypasses base R RNG for source replay.
#' @return Reference FPCA, pointwise descriptive lower, median and upper
#'   surfaces, matched component similarity and scientific provenance.
#' @export
etr_bootstrap_fpca_component_envelopes <- function(
    trajectories,n_bootstrap=200L,n_components=3L,scaling="none",
    resample_unit="curve",participant_column=NULL,level=.95,
    random_state=0L,bootstrap_unit_indices=NULL) {
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    !is.na(n_bootstrap)&&is.finite(n_bootstrap)&&
    n_bootstrap==floor(n_bootstrap)&&n_bootstrap>=2L &&
    n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer of at least two")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.na(n_components)&&is.finite(n_components)&&
    n_components==floor(n_components)&&n_components>=1L&&
    n_components<length(trajectories$curve_ids),
    "n_components must be positive and below source curve count")
  .etr_assert(is.numeric(level)&&length(level)==1L&&
    !is.na(level)&&is.finite(level)&&level>0&&level<1,
    "level must lie strictly between zero and one")
  .etr_fpca_stability_scope(trajectories,resample_unit,participant_column)
  k<-as.integer(n_components)
  b<-as.integer(n_bootstrap)
  nt<-length(trajectories$time)
  nd<-length(trajectories$dimension_names)
  .etr_fpca_stability_check_fixed_draws(trajectories,resample_unit,
    participant_column,bootstrap_unit_indices,b)
  reference<-.etr_fpca_stability_fit(trajectories,k,scaling)
  if(is.null(bootstrap_unit_indices)) {
    restore<-.etr_simulation_rng(random_state)
    on.exit(restore(),add=TRUE)
  }
  samples<-array(NA_real_,c(b,k,nt,nd))
  similarity<-matrix(NA_real_,b,k)
  for(i in seq_len(b)) {
    sample<-if(is.null(bootstrap_unit_indices))
      .etr_fpca_stability_boot(trajectories,resample_unit,
        participant_column)
      else .etr_fpca_stability_fixed_boot(trajectories,resample_unit,
        participant_column,bootstrap_unit_indices[[i]])
    .etr_assert(length(sample$curve_ids)>k,
      paste("bootstrap replicate",i-1L,
        "has insufficient sample rank"))
    candidate<-.etr_fpca_stability_fit(sample,k,scaling)
    matched<-etr_match_fpca_components(reference,candidate,
      n_components=k)
    similarity[i,]<-abs(matched$signed_similarity)
    for(j in seq_len(k)) {
      signed<-if(matched$signed_similarity[[j]]>=0)1 else -1
      index<-as.integer(matched$assignments[[j]])+1L
      .etr_assert(index>=1L&&index<=candidate$n_components,
        "matched bootstrap component index is invalid")
      samples[i,j,,]<-signed*matrix(
        candidate$components[index,,,drop=FALSE],
        nrow=nt,ncol=nd)
    }
  }
  q<-.etr_fpca_envelope_quantiles(samples,level)
  structure(list(reference=reference,
    lower=q$lower,median=q$median,upper=q$upper,
    similarities=similarity,level=level,
    resampling_unit=resample_unit,random_state=random_state,
    provenance=list(
      method="matched_sign_aligned_bootstrap_pointwise_envelope",
      n_bootstrap=b,n_components=k,scaling=scaling,
      participant_column=participant_column,
      coverage_claim="descriptive_pointwise_only",
      random_engine=if(is.null(bootstrap_unit_indices))
        "base_R_not_NumPy_PCG64" else "caller_supplied_fixed_unit_indices",
      fixed_draw_replay=!is.null(bootstrap_unit_indices),
      source_python_equivalent_stochastic_draws=FALSE,
      scientific_warning=paste(
        "Envelopes describe matched bootstrap component shape variation;",
        "they do not establish pointwise or simultaneous coverage"))),
    class="etr_fpca_component_envelope")
}
