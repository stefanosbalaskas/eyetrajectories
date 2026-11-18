# FLAGSHIP 02 — Descriptive multilevel functional variation
# Synthetic data only. Published eyetrajectories v0.4.3 API. No Python.
stopifnot(requireNamespace("eyetrajectories",quietly=TRUE))
suppressPackageStartupMessages(library(eyetrajectories))
set.seed(20261119L)
n_subjects<-30L; trials<-4L; nt<-61L; t<-seq(0,1,length.out=nt)
participant<-rep(seq_len(n_subjects),each=trials);n<-length(participant)
a<-stats::rnorm(n_subjects,sd=.32)
b<-stats::rnorm(n_subjects,sd=.22)
z<-array(0,c(n,nt,1L))
for(i in seq_len(n)){
 z[i,,1]<-1.5+.4*sin(2*pi*t)+a[participant[i]]*sin(pi*t)+
   b[participant[i]]*cos(pi*t)+stats::rnorm(1,sd=.1)*sin(4*pi*t)+
   stats::rnorm(nt,sd=.035)
}
ids<-sprintf("synthetic_%03d",seq_len(n))
x<-etr_trajectory_set(t,z,curve_ids=ids,
  dimension_names="synthetic_signal",
  coordinate_system="synthetic_arbitrary_units",time_unit="normalized_trial")
fit<-etr_fit_multilevel_fpca(x,participant=participant,n_between=2L,n_within=2L)
v<-etr_multilevel_variance(fit)
sc<-etr_multilevel_scores(fit)
stopifnot(nrow(v)==2L,all(is.finite(v$integrated_variance)),
          all(v$integrated_variance>=0),
          nrow(sc$between)==n_subjects,nrow(sc$within)==n)
out<-file.path(Sys.getenv("ET_FLAGSHIP_OUTPUT",
    file.path("artifacts","flagship-workflows")),"02-multilevel")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
utils::write.csv(v,file.path(out,"descriptive_variance_strata.csv"),row.names=FALSE)
utils::write.csv(sc$between,file.path(out,"between_fpca_scores.csv"),row.names=FALSE)
utils::write.csv(sc$within,file.path(out,"within_fpca_scores.csv"),row.names=FALSE)
utils::write.csv(data.frame(participants=n_subjects,trials_per_participant=trials,
                            total_curves=n,time_grid_points=nt),
                 file.path(out,"synthetic_design.csv"),row.names=FALSE)
grDevices::pdf(file.path(out,"01_repeated_curves.pdf"),width=7,height=5)
graphics::matplot(t,t(z[1:12,,1L]),type="l",lty=1,
  col=rep(c("steelblue","tan3","darkseagreen4"),each=4),
  xlab="Normalized trial time",ylab="Synthetic signal",
  main="Synthetic repeated trajectories: first three participants")
grDevices::dev.off()
grDevices::pdf(file.path(out,"02_descriptive_variance.pdf"),width=7,height=5)
graphics::barplot(v$integrated_variance,
  names.arg=c("Subject means","Within-subject residual"),
  ylab="Integrated descriptive variance",
  col=c("steelblue","tan3"),
  main="Distinct design strata, not additive population variance")
grDevices::dev.off()
grDevices::pdf(file.path(out,"03_component_scores.pdf"),width=7,height=5)
graphics::par(mfrow=c(1,2))
graphics::hist(sc$between$FPC1,main="Between participants FPC1",
  xlab="Descriptive score",col="steelblue")
graphics::hist(sc$within$FPC1,main="Within participants FPC1",
  xlab="Descriptive score",col="tan3")
grDevices::dev.off()
writeLines(c("# Workflow 02 — Descriptive multilevel FPCA","",
  sprintf("Synthetic participants: %d, trials each: %d, grid: %d.",
          n_subjects,trials,nt),
  "Two level scores are descriptive and have distinct variance normalizations.",
  "Not REML mixed model fitting or independently calibrated random-effect inference.",
  "No causal, statistical-significance or population variance-additivity claim.",
  "Entirely synthetic functional trajectories, not measured gaze."),
  file.path(out,"METHODS_AND_LIMITATIONS.md"))
writeLines(capture.output(utils::sessionInfo()),file.path(out,"sessionInfo.txt"))
stopifnot(length(list.files(out,pattern="\\.pdf$"))==3L)
cat("FLAGSHIP_02_MULTILEVEL_SYNTHETIC_PASS=",normalizePath(out),"\n",sep="")
