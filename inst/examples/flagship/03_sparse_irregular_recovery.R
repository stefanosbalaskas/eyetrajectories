# FLAGSHIP 03 — Sparse and irregular functional observation support
# Synthetic known-truth model; optional R fdapace estimator, no Python.
stopifnot(requireNamespace("eyetrajectories",quietly=TRUE))
if(!requireNamespace("fdapace",quietly=TRUE))
  stop("This flagship requires R package fdapace; install.packages('fdapace').")
suppressPackageStartupMessages(library(eyetrajectories))
set.seed(20261120L)
n<-80L; latent<-stats::rnorm(n,sd=.75)
times<-lapply(seq_len(n),function(i)
  sort(stats::runif(sample(7:12,1L),0,1)))
true_fun<-function(t,a) 1+sin(pi*t)+a*cos(2*pi*t)
values<-lapply(seq_len(n),function(i)
  true_fun(times[[i]],latent[i])+
    stats::rnorm(length(times[[i]]),sd=.08))
names(times)<-NULL;names(values)<-NULL
sparse<-etr_sparse_curves(times,values,
  curve_ids=sprintf("synthetic_sparse_%03d",seq_len(n)),
  time_unit="normalized_trial")
fit<-etr_fit_sparse_pace(sparse,max_components=2L,fve=.95)
reconstruction<-etr_sparse_pace_fitted(fit)
scores<-etr_sparse_pace_scores(fit)
grid<-reconstruction$time
estimate<-reconstruction$fitted
stopifnot(is.matrix(estimate),nrow(estimate)==n,
          ncol(estimate)==length(grid),all(is.finite(estimate)))
truth<-t(vapply(seq_len(n),function(i)true_fun(grid,latent[i]),
             numeric(length(grid))))
mean_only<-matrix(rep(1+sin(pi*grid),each=n),nrow=n)
rmse<-sqrt(mean((estimate-truth)^2))
baseline_rmse<-sqrt(mean((mean_only-truth)^2))
corr<-abs(stats::cor(scores$FPC1,latent))
stopifnot(is.finite(rmse),is.finite(baseline_rmse),is.finite(corr))
out<-file.path(Sys.getenv("ET_FLAGSHIP_OUTPUT",
    file.path("artifacts","flagship-workflows")),"03-sparse")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
utils::write.csv(data.frame(metric=c("trajectories","minimum_observations",
  "median_observations","maximum_observations","noise_sd",
  "reconstruction_rmse","mean_only_rmse","abs_latent_score_cor"),
  value=c(n,min(lengths(times)),stats::median(lengths(times)),
          max(lengths(times)),.08,rmse,baseline_rmse,corr)),
  file.path(out,"known_truth_recovery.csv"),row.names=FALSE)
utils::write.csv(data.frame(curve_id=sparse$curve_ids,
  n_observed=lengths(times)),file.path(out,"observation_support.csv"),
  row.names=FALSE)
grDevices::pdf(file.path(out,"01_observation_support.pdf"),width=7,height=5)
graphics::plot(NA_real_,NA_real_,xlim=c(0,1),ylim=c(0,15),
  xlab="Normalized time",ylab="Curve index (first 15)",
  main="Sparse, irregular observation support")
for(i in seq_len(15L))graphics::points(times[[i]],
  rep(i,length(times[[i]])),pch=16,cex=.65,col="steelblue")
grDevices::dev.off()
grDevices::pdf(file.path(out,"02_sparse_known_truth.pdf"),width=7,height=5)
graphics::plot(grid,truth[1,],type="l",lwd=2,
  xlab="Normalized time",ylab="Synthetic signal",col="black",
  main="Sparse PACE reconstruction: first generated trajectory")
graphics::lines(grid,estimate[1,],lwd=2,col="steelblue",lty=2)
graphics::points(times[[1]],values[[1]],pch=16,col="tan3")
graphics::legend("topright",legend=c("Analytic truth","PACE fitted","Sparse observations"),
  col=c("black","steelblue","tan3"),lty=c(1,2,NA),pch=c(NA,NA,16),bty="n")
grDevices::dev.off()
grDevices::pdf(file.path(out,"03_recovery_diagnostics.pdf"),width=7,height=5)
graphics::barplot(c(PACE=rmse,Mean_only=baseline_rmse),
  col=c("steelblue","tan3"),ylab="Known-truth RMSE",
  main="Synthetic estimator recovery, not general validity")
grDevices::dev.off()
writeLines(c("# Workflow 03 — Sparse and irregular FDA","",
  "Known truth: 1 + sin(pi*t) + latent_i*cos(2*pi*t); latent_i ~ N(0,0.75^2).",
  "Irregular observed times and additive Gaussian measurement noise SD=0.08.",
  "Estimation: optional fdapace::FPCA via etr_fit_sparse_pace adapter.",
  sprintf("Synthetic reconstruction RMSE: %.5f; mean-only RMSE: %.5f.",rmse,baseline_rmse),
  sprintf("Sign-invariant correlation of first score with latent: %.5f.",corr),
  "One-factor synthetic recovery only. NOT an independent PACE implementation.",
  "A missingness process dependent on unobserved gaze is NOT simulated here.",
  "No human data, inference coverage, eye-tracker calibration or raw event truth."),
  file.path(out,"METHODS_AND_LIMITATIONS.md"))
writeLines(capture.output(utils::sessionInfo()),file.path(out,"sessionInfo.txt"))
stopifnot(length(list.files(out,pattern="\\.pdf$"))==3L)
cat("FLAGSHIP_03_SPARSE_SYNTHETIC_PASS=",normalizePath(out),"\n",sep="")
