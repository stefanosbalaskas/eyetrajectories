# Native audit adapters for Python 1.2 functional simulation truth.
# Scientific source: eyetrajectoriespy==1.2.0 reporting.py,
# pinned c1cd95ad718327550f7e55393ff38582872f7a94.
# This requires an explicit realized truth record; it does NOT simulate data.

.etr_simulation_audit_fields <- function(result) {
  .etr_assert(is.list(result) && is.list(result$truth) &&
    is.list(result$observations),
    "result must contain native truth and observations records")
  truth<-result$truth
  ids<-result$observations$curve_ids
  n<-length(ids)
  .etr_assert(is.character(ids)&&n>=1L&&!anyNA(ids)&&
    all(nzchar(ids))&&!anyDuplicated(ids),
    "observations$curve_ids must be unique nonempty curve IDs")
  meta<-truth$metadata
  .etr_assert(is.data.frame(meta)&&nrow(meta)==n,
    "truth$metadata must contain one row per curve")
  grid<-truth$truth_grid
  .etr_assert(is.numeric(grid)&&length(grid)>=3L&&
    all(is.finite(grid))&&all(diff(grid)>0),
    "truth$truth_grid must be finite and strictly increasing")
  pre<-truth$pre_missing_observation_times
  times<-truth$observation_times
  masks<-truth$missingness_mask
  .etr_assert(is.list(pre)&&is.list(times)&&is.list(masks)&&
    length(pre)==n&&length(times)==n&&length(masks)==n,
    "truth observation schedules and missingness masks must match curve count")
  .etr_assert(all(vapply(pre,function(x)is.numeric(x)&&
    all(is.finite(x)),logical(1L)))&&
    all(vapply(times,function(x)is.numeric(x)&&
    all(is.finite(x)),logical(1L)))&&
    all(vapply(masks,function(x)is.logical(x)&&!anyNA(x),logical(1L))),
    "truth observation schedules must be finite and masks complete logical")
  .etr_assert(all(vapply(seq_len(n),function(i)
    length(masks[[i]])==length(pre[[i]]),logical(1L))),
    "truth missingness masks must match pre-missing sample counts")
  warp<-truth$phase_warps_on_truth_grid
  .etr_assert(is.matrix(warp)&&is.numeric(warp)&&
    identical(dim(warp),c(as.integer(n),as.integer(length(grid))))&&
    all(is.finite(warp)),
    "truth phase warps must be an n_curves-by-truth_grid finite matrix")
  eigen<-truth$eigenvalues
  k<-length(eigen)
  .etr_assert(is.numeric(eigen)&&k>=1L&&
    all(is.finite(eigen))&&all(eigen>0),
    "truth$eigenvalues must contain positive finite component variances")
  for(name in c("scores","curve_scores","trial_scores")){
    a<-truth[[name]]
    .etr_assert(is.matrix(a)&&is.numeric(a)&&
      identical(dim(a),c(as.integer(n),as.integer(k)))&&
      all(is.finite(a)),
      paste0("truth$",name," must be an n_curves-by-components finite matrix"))
  }
  if("participant_id"%in%names(meta)){
    .etr_assert(!anyNA(meta$participant_id),
      "participant_id must contain no missing values in the native subset")
    group<-match(as.character(meta$participant_id),
      unique(as.character(meta$participant_id)))
    ps<-truth$participant_scores
    .etr_assert(is.matrix(ps)&&is.numeric(ps)&&
      identical(dim(ps),c(as.integer(max(group)),as.integer(k)))&&
      all(is.finite(ps)),
      "truth$participant_scores must match first-seen participant groups")
  }else group<-NULL
  list(truth=truth,ids=ids,n=n,metadata=meta,grid=grid,
    pre=pre,times=times,masks=masks,warp=warp,eigen=eigen,k=k,
    participant=group)
}

#' Return one row per realized functional simulation curve and score source
#' @param result Named native list with observations$curve_ids and explicit
#'   realized truth fields from a source-compatible simulation archive.
#' @return Native R data frame with source-ordered time, missingness,
#'   phase-displacement, curve/trial/participant score audit columns.
#' @details This is a read-only audit adapter, not a simulation.
#'   Python pandas and frozen dataclass identities are not asserted in R.
#' @export
etr_functional_simulation_truth_frame <- function(result) {
  x<-.etr_simulation_audit_fields(result)
  truth<-x$truth;n<-x$n
  frame<-data.frame(curve_id=x$ids,x$metadata,
    check.names=FALSE,stringsAsFactors=FALSE)
  pre_counts<-as.integer(lengths(x$pre))
  output_counts<-as.integer(lengths(x$times))
  missing_counts<-as.integer(vapply(x$masks,sum,integer(1L)))
  frame$n_pre_missing_samples<-pre_counts
  frame$n_output_schedule_samples<-output_counts
  frame$n_observed_samples<-pre_counts-missing_counts
  frame$n_missing_by_design<-missing_counts
  frame$max_phase_displacement<-apply(abs(x$warp-
    matrix(x$grid,nrow=n,ncol=length(x$grid),byrow=TRUE)),1L,max)
  for(j in seq_len(x$k)){
    suffix<-as.character(j)
    frame[[paste0("score_total_",suffix)]]<-truth$scores[,j]
    frame[[paste0("score_curve_",suffix)]]<-truth$curve_scores[,j]
    frame[[paste0("score_trial_",suffix)]]<-truth$trial_scores[,j]
    if(!is.null(x$participant))
      frame[[paste0("score_participant_",suffix)]]<-
        truth$participant_scores[x$participant,j]
  }
  rownames(frame)<-NULL
  frame
}

#' Describe one realized source-compatible functional simulation
#' @param result Explicit native simulation observations and truth records.
#' @param digits Positive whole number of significant digits, including zero.
#' @return One source-aligned descriptive manuscript paragraph.
#' @details The returned text does not imply source statistical calibration or
#'   that the simulated observations were generated by native R.
#' @export
etr_functional_simulation_reporting_text <- function(result,digits=3L) {
  x<-.etr_simulation_audit_fields(result)
  .etr_assert(is.numeric(digits)&&length(digits)==1L&&
    !is.na(digits)&&is.finite(digits)&&digits>=0&&
    digits==floor(digits)&&digits<=16,
    "digits must be a non-negative integer no greater than 16")
  truth<-x$truth
  .etr_assert(is.character(truth$dimension_names)&&
    length(truth$dimension_names)>=1L&&
    is.character(truth$score_distribution)&&
    length(truth$score_distribution)==1L&&
    is.character(truth$observation_design)&&
    length(truth$observation_design)==1L,
    "truth requires dimensions, score distribution and observation design")
  .etr_assert(is.numeric(truth$participant_eigenvalues)&&
    is.numeric(truth$trial_eigenvalues)&&
    is.matrix(truth$measurement_noise_covariance)&&
    all(is.finite(truth$measurement_noise_covariance))&&
    nrow(truth$measurement_noise_covariance)==
    length(truth$dimension_names)&&
    ncol(truth$measurement_noise_covariance)==
    length(truth$dimension_names),
    "truth must declare participant/trial variances and noise covariance")
  .etr_assert(is.list(truth$provenance),
    "truth must retain source simulation provenance")
  fmt<-function(v)paste(sprintf(paste0("%.",digits,"g"),v),collapse=", ")
  counts<-as.integer(lengths(x$pre))-
    as.integer(vapply(x$masks,sum,integer(1L)))
  missing<-sum(vapply(x$masks,sum,integer(1L)))
  pr<-truth$provenance
  p_kind<-if(is.null(pr$phase_variation_kind))"none"
    else pr$phase_variation_kind
  m_kind<-if(is.null(pr$missingness_kind))"none"
    else pr$missingness_kind
  pyrepr<-function(v){
    if(is.null(v))return("None")
    if(is.character(v))return(paste0("'",v,"'"))
    if(is.logical(v))return(if(v)"True" else "False")
    if(is.numeric(v)&&length(v)==1L&&is.finite(v)&&v==floor(v))
      return(sprintf("%.0f",if(v==0)0 else v))
    as.character(v)
  }
  distribution<-truth$score_distribution
  if(identical(distribution,"student_t")){
    df<-truth$score_distribution_parameters$df
    .etr_assert(is.numeric(df)&&length(df)==1L&&
      is.finite(df)&&df>2,
      "student_t requires finite score distribution df above two")
    distribution<-paste0(distribution," (df=",fmt(df),")")
  }
  interpolated<-identical(pr$raw_dense_to_irregular_interpolation_performed,FALSE)
  paste0(
    "Functional data were generated natively for ",x$n," curves ",
    "across ",length(truth$dimension_names)," dimension(s) ",
    "(",paste(truth$dimension_names,collapse=", "),") using ",
    x$k," declared orthonormal functional mode(s) with ",
    "curve-level variances [",fmt(x$eigen),"]. Curve-level component scores ",
    "followed ",distribution,"; declared participant-level variances were ",
    "[",fmt(truth$participant_eigenvalues),"] and trial-level variances were [",
    fmt(truth$trial_eigenvalues),"]. The observation design was ",
    pyrepr(truth$observation_design),", with ",min(counts),"\u2013",max(counts),
    " retained samples per curve after the declared missingness mechanism (",
    pyrepr(m_kind),"; ",missing," samples removed in total). ",
    "Phase variation used ",pyrepr(p_kind),
    ". Measurement-noise marginal variances were [",
    fmt(diag(truth$measurement_noise_covariance)),
    "], with the full covariance retained in the truth object. ",
    "The random state was ",pyrepr(truth$random_state),".",
    if(interpolated)
      " No dense-to-irregular raw-trajectory interpolation was performed."
    else "",
    " Exact latent curves, score sources, phase warps, pre-missing ",
    "observations, missingness masks, and measurement noise were retained ",
    "for audit and estimator-recovery analysis."
  )
}
