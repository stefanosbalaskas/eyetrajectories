# RESEARCH ONLY: design-known, participant-normalized (Hájek-style)
# missing-gaze point estimator. No confidence bands or production exports.
# All estimator inputs are OBSERVED data and the fully observed Z registry.
# A group's eligible population size remains fixed in the combined mean.
# Participant-cluster contribution is normalized over observed trials,
# then inverse inclusion probability 1/q_i is normalized over participants.
# It is not finite-sample design unbiased and has no valid MNAR target.

et_obs_public_participant_inclusion <- function(observed,time,channel,
                                                 severity="moderate") {
  rates <- c(mild=.80,moderate=.60,severe=.40)
  if (length(severity)!=1L || !severity %in% names(rates))
    stop("Invalid severity.",call.=FALSE)
  if (length(time)!=1L || !is.finite(time) ||
      length(channel)!=1L || !channel %in% c("x","y"))
    stop("Invalid time/channel.",call.=FALSE)
  mechanism <- observed$mechanism
  if (!mechanism %in% c("complete","mcar_gaze","mar_gaze","mar_dropout"))
    stop("Unknown/unsupported mechanism; MNAR is not identifiable.",
         call.=FALSE)
  registry <- observed$registry
  if (!is.data.frame(registry) ||
      !all(c("participant","group","Z") %in% names(registry)) ||
      anyDuplicated(registry$participant) || any(!is.finite(registry$Z)) ||
      length(observed$n_trials)!=1L ||
      !is.finite(observed$n_trials) || observed$n_trials<1L)
    stop("Invalid complete baseline registry or trial schedule.",call.=FALSE)
  target <- unname(rates[[severity]])
  if (mechanism=="complete") {
    inclusion <- rep(1,nrow(registry))
  } else if (mechanism=="mcar_gaze") {
    inclusion <- rep(1-(1-target)^observed$n_trials,nrow(registry))
  } else if (mechanism=="mar_gaze") {
    eta <- stats::qlogis(target)+.65*registry$Z+
      .50*cos(2*base::pi*time)+.12*(channel=="y")
    p <- pmax(.05,pmin(.95,stats::plogis(eta)))
    # Probability >=1 trial observed in THIS participant/time/channel.
    # In the prespecified design, all J trial Bernoulli masks are
    # independent and have the same p at the selected coordinate.
    inclusion <- 1-(1-p)^observed$n_trials
  } else {
    # Entire-participant MAR dropout; do NOT apply J independent masks.
    inclusion <- pmax(.05,pmin(.95,
      stats::plogis(stats::qlogis(target)+.70*registry$Z)))
  }
  if(anyNA(inclusion) || any(!is.finite(inclusion)) ||
     any(inclusion<=0 | inclusion>1))
    stop("Invalid participant inclusion probability.",call.=FALSE)
  inclusion
}

et_obs_participant_hajek <- function(observed,severity="moderate",
                                     min_per_group=2L) {
  if (!is.list(observed) || !is.data.frame(observed$samples) ||
      !is.data.frame(observed$registry) ||
      !all(c("participant","trial","time_index","channel",
              "time","Y","group","Z") %in% names(observed$samples)) ||
      length(observed$n_time)!=1L ||
      !is.finite(observed$n_time) || observed$n_time<1L ||
      length(observed$time)!=observed$n_time)
    stop("Invalid observed-only input.",call.=FALSE)
  if(length(min_per_group)!=1L || is.na(min_per_group) ||
     min_per_group!=as.integer(min_per_group) || min_per_group<1L)
    stop("Invalid group support minimum.",call.=FALSE)
  # Reject MNAR and unqualified uneven-density mechanisms even when
  # there are no observed samples in a particular coordinate.
  et_obs_public_participant_inclusion(observed,observed$time[1L],
                                       "x",severity)
  pi_observed <- et_obs_public_retention_probability(observed,severity)
  registry <- observed$registry
  z <- observed$samples
  N <- nrow(registry)
  n0 <- sum(registry$group==0L)
  n1 <- sum(registry$group==1L)
  if(!n0 || !n1 || n0+n1!=N)
    stop("Both eligibility groups are required.",call.=FALSE)
  T <- as.integer(observed$n_time)
  mean_est <- matrix(NA_real_,T,2L)
  contrast_est <- matrix(NA_real_,T,2L)
  ng0 <- matrix(0L,T,2L)
  ng1 <- matrix(0L,T,2L)
  for (channel_index in seq_len(2L)) for (tt in seq_len(T)) {
    channel <- c("x","y")[channel_index]
    q <- et_obs_public_participant_inclusion(
      observed,observed$time[tt],channel,severity)
    index <- which(z$channel==channel & z$time_index==tt)
    if(!length(index)) next
    cell <- z[index,,drop=FALSE]
    individual_p <- pi_observed[index]
    ids <- unique(cell$participant)
    means <- numeric(length(ids))
    for (k in seq_along(ids)) {
      hit <- which(cell$participant==ids[k])
      inverse_trial_weights <- 1/individual_p[hit]
      means[k] <- sum(cell$Y[hit]*inverse_trial_weights) /
        sum(inverse_trial_weights)
    }
    registration <- match(ids,registry$participant)
    if(anyNA(registration))
      stop("Observed participant not in eligible registry.",call.=FALSE)
    gr <- registry$group[registration]
    weights <- 1/q[registration]
    g0 <- which(gr==0L)
    g1 <- which(gr==1L)
    ng0[tt,channel_index] <- length(g0)
    ng1[tt,channel_index] <- length(g1)
    # No observed participants => explicitly undefined, NOT zero.
    if(!length(g0) || !length(g1)) next
    mu0 <- sum(weights[g0]*means[g0])/sum(weights[g0])
    mu1 <- sum(weights[g1]*means[g1])/sum(weights[g1])
    mean_est[tt,channel_index] <- (n0*mu0+n1*mu1)/N
    contrast_est[tt,channel_index] <- mu1-mu0
  }
  supported <- ng0>=min_per_group & ng1>=min_per_group
  list(mean_estimate=mean_est,contrast_estimate=contrast_est,
       support=supported,
       fraction_supported=mean(supported),
       status=if(all(supported)) "success" else "no_observation_support",
       minimum_group_participants_per_coordinate=min(c(ng0,ng1)),
       observed_group0=ng0,observed_group1=ng1,
       # Undefined grid cells are distinct from HT's numerical zeros.
       undefined_coordinates=sum(!is.finite(mean_est) |
                                 !is.finite(contrast_est)))
}
