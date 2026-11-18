# FLAGSHIP 04 — Participant-level uncertainty for repeated observations
# Synthetic two-condition paired contrasts; NOT calibrated general inference.
stopifnot(requireNamespace("eyetrajectories",quietly=TRUE))
suppressPackageStartupMessages(library(eyetrajectories))
set.seed(20261121L)
n_part<-32L;repeats<-3L;nt<-51L;t<-seq(0,1,length.out=nt)
truth<-0.14*sin(2*pi*t)
subject_effect<-stats::rnorm(n_part,sd=.15)
A<-array(0,c(n_part,repeats,nt))
B<-array(0,c(n_part,repeats,nt))
for(i in seq_len(n_part))for(r in seq_len(repeats)){
  common<-subject_effect[i]*cos(pi*t)
  A[i,r,]<-.55+.2*sin(pi*t)+common+
    stats::rnorm(nt,sd=.09)
  B[i,r,]<-.55+.2*sin(pi*t)+common+truth+
    stats::rnorm(nt,sd=.09)
}
subject_difference<-array(0,c(n_part,nt,1L))
for(i in seq_len(n_part))
  subject_difference[i,,1]<-colMeans(B[i,,])-colMeans(A[i,,])
ids<-sprintf("synthetic_subject_%03d",seq_len(n_part))
diffs<-etr_trajectory_set(t,subject_difference,
  curve_ids=ids,dimension_names="paired_condition_difference",
  coordinate_system="synthetic_arbitrary_units",time_unit="normalized_trial")
# Every bootstrap row is one independent participant's paired trial-average.
fit<-etr_bootstrap_mean_band(diffs,participant=seq_len(n_part),
                            B=399L,alpha=.05,seed=20261122L)
mu<-as.numeric(fit$mean[,1L])
pwlo<-as.numeric(fit$pointwise_lower[,1L])
pwhi<-as.numeric(fit$pointwise_upper[,1L])
slo<-as.numeric(fit$simultaneous_lower[,1L])
shi<-as.numeric(fit$simultaneous_upper[,1L])
stopifnot(all(is.finite(c(mu,pwlo,pwhi,slo,shi))),
          all(pwlo<=pwhi),all(slo<=shi),
          identical(fit$resampling_unit,"participant"))
out<-file.path(Sys.getenv("ET_FLAGSHIP_OUTPUT",
    file.path("artifacts","flagship-workflows")),"04-uncertainty")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
utils::write.csv(data.frame(time=t,known_truth=truth,estimated=mu,
  pointwise_lower=pwlo,pointwise_upper=pwhi,
  simultaneous_lower=slo,simultaneous_upper=shi),
  file.path(out,"simulated_paired_contrast_bands.csv"),row.names=FALSE)
utils::write.csv(data.frame(n_independent_participants=n_part,
   trials_per_condition=repeats,bootstrap_draws=399L,
   nominal_level=.95,
   whole_curve_truth_covered=all(truth>=slo & truth<=shi),
   midpoint_truth_covered=truth[26]>=pwlo[26] && truth[26]<=pwhi[26]),
 file.path(out,"diagnostics.csv"),row.names=FALSE)
grDevices::pdf(file.path(out,"01_paired_difference_bands.pdf"),width=7,height=5)
graphics::plot(t,mu,type="n",ylim=range(c(slo,shi,truth)),
 xlab="Normalized time",ylab="Condition B minus A",
 main="Synthetic paired participant contrast with 95% bands")
graphics::polygon(c(t,rev(t)),c(slo,rev(shi)),
 col=grDevices::adjustcolor("steelblue",alpha.f=.25),border=NA)
graphics::lines(t,pwlo,col="steelblue",lty=2)
graphics::lines(t,pwhi,col="steelblue",lty=2)
graphics::lines(t,mu,lwd=2,col="steelblue4")
graphics::lines(t,truth,lwd=2,lty=3,col="black")
graphics::legend("topright",legend=c("Estimated contrast","Known truth",
 "Simultaneous envelope","Pointwise envelope"),
 col=c("steelblue4","black","steelblue","steelblue"),
 lty=c(1,3,1,2),bty="n")
grDevices::dev.off()
grDevices::pdf(file.path(out,"02_paired_participant_contrasts.pdf"),width=7,height=5)
graphics::matplot(t,t(subject_difference[1:15,,1L]),type="l",
 col=grDevices::adjustcolor("grey45",alpha.f=.4),lty=1,
 xlab="Normalized time",ylab="Paired trial-mean difference",
 main="Independent participant contrast curves (15 shown)")
graphics::lines(t,truth,col="black",lwd=2,lty=3)
grDevices::dev.off()
grDevices::pdf(file.path(out,"03_uncertainty_width.pdf"),width=7,height=5)
graphics::plot(t,shi-slo,type="l",lwd=2,col="steelblue",
 xlab="Normalized time",ylab="Full interval width",
 main="Simultaneous envelope versus pointwise interval")
graphics::lines(t,pwhi-pwlo,lty=2,col="tan3",lwd=2)
graphics::legend("topright",legend=c("Simultaneous","Pointwise"),
 col=c("steelblue","tan3"),lty=c(1,2),bty="n")
grDevices::dev.off()
writeLines(c("# Workflow 04 — Paired participant contrast uncertainty","",
 sprintf("SYNTHETIC paired design: %d participants, %d trials per condition.",n_part,repeats),
 "Estimand: population mean participant-level paired condition difference.",
 "Resampling unit: participant-averaged B-A functional contrast; not individual trials.",
 "Native etr_bootstrap_mean_band uses fixed-empirical-SE max standardized bands.",
 "A single simulated outcome cannot establish coverage or Type I error.",
 "Prior separate 400-simulation assessment found missingness-sensitive coverage.",
 "No real gazes, clinical findings, causal claims, or universally valid intervals."),
 file.path(out,"METHODS_AND_LIMITATIONS.md"))
writeLines(capture.output(utils::sessionInfo()),file.path(out,"sessionInfo.txt"))
stopifnot(length(list.files(out,pattern="\\.pdf$"))==3L)
cat("FLAGSHIP_04_UNCERTAINTY_SYNTHETIC_PASS=",normalizePath(out),"\n",sep="")
