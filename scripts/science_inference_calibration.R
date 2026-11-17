# Known-truth Monte Carlo statistical inference calibration (R only).
# Compare participant-cluster functional bootstrap against naive trial IID
# bootstrap as a diagnostic, NOT an independent scientific certificate.
# Tests null false positives, pointwise and simultaneous coverage, and
# missingness MCAR / observed MAR / latent-subject MNAR.
# source(url("https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/science_inference_calibration.R"))
# ET_SCI_MC_REPS: 100 default; ET_SCI_MC_B: 199; ET_SCI_MC_N: 30.
# ET_SCI_MC_NO_AUTORUN=true to source definitions only.

.sci_ci <- function(successes,n,level=.95) {
  if(!n)return(c(NA_real_,NA_real_))
  as.numeric(stats::binom.test(successes,n,conf.level=level)$conf.int)
}
.sci_dgp <- function(seed,n_subjects=30L,trials=3L,scenario="complete"){
  set.seed(as.integer(seed))
  t<-seq(0,1,length.out=25L)
  subject<-rep(seq_len(n_subjects),each=trials)
  subj_latent<-stats::rnorm(n_subjects,sd=.7)
  subj_observed<-stats::rnorm(n_subjects)
  trial_effect<-stats::rnorm(length(subject),sd=.25)
  n<-length(subject)
  y<-array(NA_real_,c(n,length(t),1L))
  for(i in seq_len(n))
    y[i,,1]<-subj_latent[subject[i]]*sin(pi*t)+
      trial_effect[i]*cos(2*pi*t)+stats::rnorm(length(t),sd=.08)
  # The population mean is identically zero under the generator.
  p<-switch(scenario,
    complete=rep(0,n),mcar=rep(.20,n),
    mar=stats::plogis(-1.3+.8*subj_observed[subject]),
    mnar=stats::plogis(-1.3+1.3*subj_latent[subject]),
    stop("Unknown missingness scenario"))
  keep<-stats::runif(n)>p
  if(sum(keep)<10L || length(unique(subject[keep]))<5L)
    stop("Insufficient observed independent clusters")
  X<-eyetrajectories::etr_trajectory_set(t,y[keep,,,drop=FALSE],
    curve_ids=sprintf("s%03d_trial%02d",subject[keep],
        ave(seq_along(subject[keep]),subject[keep],FUN=seq_along)),
    dimension_names="gaze_feature",coordinate_system="normalized",
    time_unit="normalized_trial")
  list(x=X,subject=subject[keep],truth=rep(0,length(t)),
       observed_fraction=mean(keep),n_subjects=length(unique(subject[keep])),
       latent_subject_mean=mean(subj_latent[unique(subject[keep])]))
}
.sci_naive_band <- function(Y,B=199L,alpha=.05) {
  # Intentionally wrong reference: treats all trials as IID.
  # Used to reveal possible false confidence from repeated measurements.
  n<-nrow(Y)
  reps<-replicate(B,colMeans(Y[sample.int(n,n,replace=TRUE),,drop=FALSE]))
  reps<-matrix(reps,nrow=ncol(Y),ncol=B)
  lower<-apply(reps,1,stats::quantile,probs=alpha/2,names=FALSE)
  upper<-apply(reps,1,stats::quantile,probs=1-alpha/2,names=FALSE)
  list(lower=lower,upper=upper)
}
sci_calibrate_inference<-function(
  out=tempfile("SCIENCE_INFERENCE_CALIBRATION_"),
  repetitions=as.integer(Sys.getenv("ET_SCI_MC_REPS","100")),
  B=as.integer(Sys.getenv("ET_SCI_MC_B","199")),
  n_subjects=as.integer(Sys.getenv("ET_SCI_MC_N","30")),
  alpha=.05,seed=8102L){
  stopifnot(repetitions>=5L,repetitions<=500L,B>=39L,B<=20000L,
            n_subjects>=6L,alpha>0,alpha<1)
  if(!dir.create(out,recursive=TRUE))stop("Cannot create output folder")
  rows<-list();k<-0L
  scenarios<-c("complete","mcar","mar","mnar")
  for(sc in scenarios)for(i in seq_len(repetitions)){
    k<-k+1L;dat<-.sci_dgp(seed+10000L*match(sc,scenarios)+i,
                         n_subjects=n_subjects,scenario=sc)
    fit<-eyetrajectories::etr_bootstrap_mean_band(dat$x,dat$subject,
      B=B,alpha=alpha,seed=seed+50000L+k)
    truth<-dat$truth
    s_l<-as.vector(fit$simultaneous_lower)
    s_u<-as.vector(fit$simultaneous_upper)
    p_l<-as.vector(fit$pointwise_lower)
    p_u<-as.vector(fit$pointwise_upper)
    point<-ceiling(length(truth)/2)
    Y<-eyetrajectories::etr_dimension(dat$x,1L)
    set.seed(seed+75000L+k)
    naive<-.sci_naive_band(Y,B=B,alpha=alpha)
    rows[[k]]<-list(scenario=sc,replicate=i,
      independent_subjects=dat$n_subjects,
      observed_fraction=dat$observed_fraction,
      simultaneous_covered=as.integer(all(truth>=s_l & truth<=s_u)),
      pointwise_mid_covered=as.integer(truth[point]>=p_l[point] &&
                                        truth[point]<=p_u[point]),
      proportion_pointwise_covered=mean(truth>=p_l & truth<=p_u),
      naive_trial_mid_covered=as.integer(truth[point]>=naive$lower[point] &&
                                         truth[point]<=naive$upper[point]),
      mean_bias_at_midpoint=as.vector(fit$mean)[point]-truth[point],
      band_width_midpoint=s_u[point]-s_l[point])
    if(i%%25L==0L)message("CALIBRATION_SCENARIO=",sc," ",i,"/",repetitions)
  }
  raw<-do.call(rbind,lapply(rows,as.data.frame,
                           stringsAsFactors=FALSE,check.names=FALSE))
  utils::write.csv(raw,file.path(out,"monte_carlo_replicates.csv"),
                   row.names=FALSE)
  summ<-lapply(scenarios,function(sc){
    d<-raw[raw$scenario==sc,,drop=FALSE];n<-nrow(d)
    s<-sum(d$simultaneous_covered)
    p<-sum(d$pointwise_mid_covered)
    naive<-sum(d$naive_trial_mid_covered)
    ci<-.sci_ci(s,n)
    data.frame(scenario=sc,repetitions=n,n_subjects_target=n_subjects,
       B=B,alpha=alpha,
       simultaneous_coverage=s/n,simultaneous_low=ci[1L],
       simultaneous_high=ci[2L],
       null_fpr_simultaneous=1-s/n,
       pointwise_mid_coverage=p/n,
       naive_trial_iid_mid_coverage=naive/n,
       mean_observed_fraction=mean(d$observed_fraction),
       mean_midpoint_bias=mean(d$mean_bias_at_midpoint),
       sd_midpoint_bias=stats::sd(d$mean_bias_at_midpoint),
       mean_midpoint_band_width=mean(d$band_width_midpoint))
  })
  summary<-do.call(rbind,summ)
  utils::write.csv(summary,file.path(out,"coverage_calibration_summary.csv"),
                   row.names=FALSE)
  notes<-c("# Inferential calibration — known-truth Monte Carlo","",
    paste0("Executed: ",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z")),
    paste0("Repetitions per scenario: ",repetitions,
      "; bootstrap replicates: ",B,"; nominal coverage: ",1-alpha,"."),
    "",
    "Each simulation has independent participant random curves and repeated trials;",
    "truth is zero at every time. The bootstrap resamples participant means.",
    "Null false-positive rate = 1 - simultaneous truth-coverage for the",
    "entire trajectory (pointwise error rates are separately reported).",
    "The naive trial-IID bootstrap is an intentionally misspecified comparator;",
    "its performance is NOT a reference target or scientific certification.",
    "MCAR deletes independent random trials; MAR deletes using observed",
    "subject covariates; MNAR depends on latent, unobserved participant effects.",
    "Data deletion is explicit; the native package does not silently impute.",
    "Exact binomial intervals reflect Monte Carlo uncertainty; no fixed",
    "coverage target is certified when the interval is wide.",
    "",
    "A frequentist coverage statement requires a predeclared DGP family,",
    "adequate simulation repetitions, independent reviewer and evaluation",
    "of failure modes. Synthetic PASS must not imply validity on real gaze.")
  writeLines(notes,file.path(out,"INFERENCE_SCOPE.md"))
  writeLines(capture.output(utils::sessionInfo()),
             file.path(out,"R_session_info.txt"))
  message("INFERENCE_CALIBRATION_COMPLETED=",out)
  invisible(summary)
}
if(!identical(tolower(Sys.getenv("ET_SCI_MC_NO_AUTORUN")),"true"))
  sci_calibrate_inference()
