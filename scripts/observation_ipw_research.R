# Research-only known-design inverse-probability-weighted (IPW) point estimates.
# NO released estimator changes; NO confidence bands, no inference claims.
# This file must only ever receive observed samples, baseline registry and
# the public design labels; it MUST NOT receive latent trajectories or mask
# probabilities that depend on unobserved gaze.
#
# Source: source("scripts/observation_ipw_research.R")
# Requires scripts/observation_process_fixture.R for matching generator API.
et_obs_public_retention_probability <- function(observed, severity="moderate") {
  rates <- c(mild=.80, moderate=.60, severe=.40)
  if (length(severity)!=1L || !severity %in% names(rates))
    stop("Invalid severity.",call.=FALSE)
  permitted <- c("complete","mcar_gaze","mar_gaze","mar_dropout")
  if (length(observed$mechanism)!=1L ||
      !observed$mechanism %in% permitted)
    stop("Unsupported mechanism for design-known IPW; MNAR is not identified.",
         call.=FALSE)
  z <- observed$samples
  r <- observed$registry
  if (!all(c("participant","group","Z") %in% names(r)) ||
      !all(c("participant","trial","time_index","channel","time",
              "Y","group","Z") %in% names(z)))
    stop("Observed-data fixture lacks mandatory fields.",call.=FALSE)
  if (!all(is.finite(r$Z)) ||
      any(!z$participant %in% r$participant) ||
      any(!is.finite(z$Y)))
    stop("Nonfinite observed value or unknown participant.",call.=FALSE)
  target <- unname(rates[[severity]])
  n <- nrow(z)
  # Never name a retention-probability vector 'pi': that would shadow
  # the mathematical constant in the MAR temporal cos(2*pi*time) term.
  retention_probability <- rep(1,n)
  if (observed$mechanism=="mcar_gaze") {
    retention_probability[] <- target
  } else if (observed$mechanism=="mar_gaze") {
    eta <- stats::qlogis(target)+.65*z$Z+
      .50*cos(2*base::pi*z$time)+.12*(z$channel=="y")
    retention_probability <- pmax(.05,pmin(.95,stats::plogis(eta)))
  } else if (observed$mechanism=="mar_dropout") {
    pS <- pmax(.05,pmin(.95,
      stats::plogis(stats::qlogis(target)+.70*r$Z)))
    retention_probability <- pS[match(z$participant,r$participant)]
  }
  if (anyNA(retention_probability) ||
      any(!is.finite(retention_probability)) ||
      any(retention_probability<=0) || any(retention_probability>1))
    stop("Invalid known design probabilities.",call.=FALSE)
  retention_probability
}

et_obs_ipw_point_diagnostics <- function(observed,truth_mean,truth_contrast,
                                         severity="moderate",
                                         min_per_group=2L) {
  if (!is.matrix(truth_mean) || !is.matrix(truth_contrast) ||
      !identical(dim(truth_mean),c(observed$n_time,2L)) ||
      !identical(dim(truth_contrast),dim(truth_mean)) ||
      any(!is.finite(c(truth_mean,truth_contrast))))
    stop("Expected finite (time x 2 channel) population truth.",call.=FALSE)
  if (length(min_per_group)!=1L ||
      min_per_group!=as.integer(min_per_group) ||
      min_per_group<1L)
    stop("Invalid minimum participant support.",call.=FALSE)
  registry <- observed$registry
  samples <- observed$samples
  if (anyDuplicated(registry$participant) ||
      !setequal(unique(registry$group),c(0L,1L)))
    stop("Unbalanced registry definition.",call.=FALSE)
  if (length(observed$n_trials)!=1L || observed$n_trials<1L)
    stop("Missing known number of scheduled trials.",call.=FALSE)
  N <- nrow(registry)
  J <- observed$n_trials
  n0 <- sum(registry$group==0L)
  n1 <- sum(registry$group==1L)
  pi <- et_obs_public_retention_probability(observed,severity)
  ncell <- observed$n_time*2L
  ch <- match(samples$channel,c("x","y"))
  if (anyNA(ch) || anyNA(samples$time_index) ||
      any(samples$time_index<1L |
            samples$time_index>observed$n_time))
    stop("Unrecognized observation coordinate.",call.=FALSE)
  cell <- (samples$time_index-1L)*2L+ch
  bucket <- samples$group*ncell+cell
  totals <- numeric(2L*ncell)
  if (length(bucket)) {
    sums <- rowsum(matrix(samples$Y/pi,ncol=1L),bucket,reorder=FALSE)
    totals[as.integer(rownames(sums))] <- as.numeric(sums[,1L])
  }
  group_sums <- matrix(totals,nrow=ncell,ncol=2L)
  g0 <- group_sums[,1L]/(n0*J)
  g1 <- group_sums[,2L]/(n1*J)
  # Horvitz-Thompson population scaling, NOT a rescaled observed mean.
  as_grid <- function(x) t(matrix(x,nrow=2L,ncol=observed$n_time))
  mean_ht <- as_grid((group_sums[,1L]+group_sums[,2L])/(N*J))
  contrast_ht <- as_grid(g1-g0)
  # This is participant support, never number of gaze points or trials.
  present <- unique(data.frame(bucket=bucket,
                               participant=samples$participant))
  counts <- tabulate(present$bucket,nbins=2L*ncell)
  group_counts <- matrix(counts,nrow=ncell,ncol=2L)
  common_support <- as_grid(as.integer(
    group_counts[,1L]>=min_per_group &
    group_counts[,2L]>=min_per_group))==1L
  naive <- et_obs_naive_diagnostic(observed,truth_mean,truth_contrast)
  measure <- function(est,truth,support) {
    if (!any(support)) return(c(signed_error=NA_real_,
                                 rmse=NA_real_))
    errors <- est[support]-truth[support]
    if (any(!is.finite(errors)))
      stop("Nonfinite estimate in a supported coordinate.",call.=FALSE)
    c(signed_error=mean(errors),rmse=sqrt(mean(errors^2)))
  }
  mn <- measure(naive$mean_estimate,truth_mean,common_support)
  cn <- measure(naive$contrast_estimate,truth_contrast,common_support)
  mh <- measure(mean_ht,truth_mean,common_support)
  ch <- measure(contrast_ht,truth_contrast,common_support)
  # HT is mathematically defined on the entire prespecified population grid
  # even where no gaze was seen. Expose those high-variance cells instead
  # of silently conditioning on support when checking unconditional MC bias.
  mha <- measure(mean_ht,truth_mean,matrix(TRUE,nrow=nrow(mean_ht),
                                           ncol=ncol(mean_ht)))
  cha <- measure(contrast_ht,truth_contrast,
                 matrix(TRUE,nrow=nrow(contrast_ht),
                        ncol=ncol(contrast_ht)))
  list(status=if(all(common_support)) "success" else
                      "no_observation_support",
       mean_coordinate_support=mean(common_support),
       minimum_group_participants_per_coordinate=min(group_counts),
       observed_fraction=naive$observed_fraction,
       observed_participants=naive$observed_participants,
       naive_mean_signed_supported=unname(mn[1L]),
       naive_mean_rmse_supported=unname(mn[2L]),
       naive_contrast_signed_supported=unname(cn[1L]),
       naive_contrast_rmse_supported=unname(cn[2L]),
       ht_mean_signed_supported=unname(mh[1L]),
       ht_mean_rmse_supported=unname(mh[2L]),
       ht_contrast_signed_supported=unname(ch[1L]),
       ht_contrast_rmse_supported=unname(ch[2L]),
       ht_mean_signed_all_grid=unname(mha[1L]),
       ht_mean_rmse_all_grid=unname(mha[2L]),
       ht_contrast_signed_all_grid=unname(cha[1L]),
       ht_contrast_rmse_all_grid=unname(cha[2L]),
       max_observed_ipw=if(length(pi)) max(1/pi) else NA_real_,
       mean_estimate=mean_ht,contrast_estimate=contrast_ht,
       common_support=common_support)
}
