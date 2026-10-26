#!/usr/bin/env Rscript
# RESEARCH ONLY: paired, known-truth functional simultaneous band candidates.
# Native estimators are never modified. Gaussian Bonferroni-t is an
# assumption-restricted reference, not a general-purpose replacement.
#
# From checkout root after pulling research/native-parity-stage1:
#   Sys.setenv(ET_BAND_COMPARE_REPS="30", ET_BAND_COMPARE_B="199")
#   source("scripts/compare_native_band_intervals.R")
#
# Three paired methods per estimand and generating dataset:
#   1. Existing fixed-SE cluster bootstrap (package function).
#   2. Exploratory studentized cluster bootstrap (re-estimates SE per resample).
#   3. Gaussian equal-variance marginal t + Bonferroni simultaneous reference.
#
# Failure-inclusive, non-overwriting, one independent seed per dataset.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields="Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories repository checkout.", call.=FALSE)
if (!requireNamespace("pkgload",quietly=TRUE))
  stop("Install development dependency 'pkgload' first.", call.=FALSE)
pkgload::load_all(".",quiet=TRUE)

int_env <- function(key,default,min_val,max_val) {
  raw <- Sys.getenv(key,unset=as.character(default))
  x <- suppressWarnings(as.integer(raw))
  if (length(x)!=1L || is.na(x) || as.character(x)!=raw ||
      x<min_val || x>max_val)
    stop(key," must be an integer from ",min_val," to ",max_val,
         call.=FALSE)
  x
}
reps <- int_env("ET_BAND_COMPARE_REPS",30L,5L,1000L)
B <- int_env("ET_BAND_COMPARE_B",199L,39L,1999L)
offset <- int_env("ET_BAND_COMPARE_SEED_OFFSET",57000000L,0L,100000000L)
N <- c(12L,24L,48L)
nt <- 41L
alpha <- .10
n_trials <- 3L
root <- file.path("artifacts","band_interval_comparison")
keys <- do.call(rbind,lapply(seq_along(N),function(j)
  data.frame(n_subjects=N[j],
             generator_seed=as.integer(offset+1000000L*j+3L*seq_len(reps)))))
if (anyDuplicated(paste(keys$n_subjects,keys$generator_seed)))
  stop("Non-unique generating-study seeds within a planned run.",call.=FALSE)
existing_dirs <- if (dir.exists(root)) {
  list.dirs(root,recursive=FALSE,full.names=TRUE)
} else {
  character()
}
existing_csv <- file.path(existing_dirs,"interval_comparison_trials.csv")
existing_csv <- existing_csv[file.exists(existing_csv)]
for (path in existing_csv) {
  z <- utils::read.csv(path,stringsAsFactors=FALSE)
  if (!all(c("n_subjects","generator_seed") %in% names(z)))
    stop("Archive cannot be checked for seed reuse: ",path,call.=FALSE)
  n_overlap <- length(intersect(unique(paste(keys$n_subjects,keys$generator_seed)),
                                unique(paste(z$n_subjects,z$generator_seed))))
  if (n_overlap)
    stop("INTERVAL COMPARISON SEED COLLISION: ",n_overlap,
         " reused generating-study seeds in ",path,
         "; choose another ET_BAND_COMPARE_SEED_OFFSET.",
         call.=FALSE)
}
out <- file.path(root,paste0("run_",
  format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if (dir.exists(out)) stop("Same-name archive already exists.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)

seed_scope <- function(seed, fn) {
  had <- exists(".Random.seed",.GlobalEnv,inherits=FALSE)
  if (had) saved <- get(".Random.seed",.GlobalEnv,inherits=FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed",saved,.GlobalEnv)
    } else if (exists(".Random.seed",.GlobalEnv,inherits=FALSE)) {
      rm(".Random.seed",envir=.GlobalEnv)
    }
  },add=TRUE)
  set.seed(as.integer(seed))
  fn()
}
participant_matrix <- function(sim) {
  x <- sim$trajectories
  pid <- as.character(sim$participant)
  ids <- unique(pid)
  nt <- length(x$time)
  nd <- length(x$dimension_names)
  z <- matrix(NA_real_,length(ids),nt*nd)
  for (i in seq_along(ids)) {
    idx <- which(pid==ids[i])
    for (j in seq_len(nd)) for (t in seq_len(nt))
      z[i,(t-1L)*nd+j] <- mean(x$values[idx,t,j])
  }
  if (any(!is.finite(z)))
    stop("Participant curve means must be finite.",call.=FALSE)
  list(z=z,ids=ids,nt=nt,nd=nd)
}
data_for <- function(z,estimand) {
  n <- nrow(z)
  if (estimand=="participant_mean")
    return(list(est=colMeans(z),
                se=apply(z,2L,stats::sd)/sqrt(n),
                df=n-1L, a=z, b=NULL))
  a <- z[seq_len(n/2L),,drop=FALSE]
  b <- z[seq.int(n/2L+1L,n),,drop=FALSE]
  na <- nrow(a); nb <- nrow(b)
  se <- sqrt(apply(a,2L,stats::var)/na+
             apply(b,2L,stats::var)/nb)
  list(est=colMeans(b)-colMeans(a),se=se,df=n-2L,a=a,b=b)
}
# Exact marginal Student t pivots for the Gaussian, equal-variance
# participant-mean generator. Bonferroni union bound handles dependence
# across grid coordinates. Not valid without these assumptions.
gaussian_reference <- function(design) {
  p <- length(design$est)
  crit <- stats::qt(1-alpha/(2*p),df=design$df)
  if (is.null(design$b)) {
    se <- design$se
  } else {
    a <- design$a; b <- design$b
    na <- nrow(a); nb <- nrow(b)
    va <- apply(a,2L,stats::var)
    vb <- apply(b,2L,stats::var)
    pooled <- ((na-1L)*va+(nb-1L)*vb)/(na+nb-2L)
    se <- sqrt(pooled*(1/na+1/nb))
  }
  list(lo=design$est-crit*se,hi=design$est+crit*se,
       cutoff=crit,degenerate_replicates=0L)
}
# Paired studentized cluster bootstrap: every resample independently
# estimates its own SE. This is an EXPERIMENTAL interval candidate,
# not an asserted calibrated method.
studentized_cluster <- function(design,seed) {
  est <- design$est
  se <- design$se
  p <- length(est)
  stat <- seed_scope(seed,function(){
    vapply(seq_len(B),function(i){
      if (is.null(design$b)) {
        a <- design$a
        idx <- sample.int(nrow(a),nrow(a),replace=TRUE)
        aa <- a[idx,,drop=FALSE]
        estb <- colMeans(aa)
        seb <- apply(aa,2L,stats::sd)/sqrt(nrow(aa))
      } else {
        a <- design$a; b <- design$b
        aa <- a[sample.int(nrow(a),nrow(a),TRUE),,drop=FALSE]
        bb <- b[sample.int(nrow(b),nrow(b),TRUE),,drop=FALSE]
        estb <- colMeans(bb)-colMeans(aa)
        seb <- sqrt(apply(aa,2L,stats::var)/nrow(aa)+
                    apply(bb,2L,stats::var)/nrow(bb))
      }
      discrepancy <- abs(estb-est)
      # Zero resampled SE with nonzero deviation yields infinite
      # studentized statistic, which is explicitly recorded.
      ratio <- ifelse(seb>1e-12,discrepancy/seb,
                      ifelse(discrepancy<=1e-12,0,Inf))
      if (anyNA(ratio)) stop("Undefined studentized bootstrap statistic.")
      max(ratio)
    },numeric(1))
  })
  crit <- as.numeric(stats::quantile(stat,probs=1-alpha,
                                     type=1,names=FALSE))
  if (!is.finite(crit))
    stop("Studentized critical value infinite; degenerate resamples.",
         call.=FALSE)
  list(lo=est-crit*se,hi=est+crit*se,
       cutoff=crit,degenerate_replicates=sum(!is.finite(stat)))
}
existing_band <- function(sim,estimand,seed) {
  if (estimand=="participant_mean") {
    b <- etr_bootstrap_mean_band(
      sim$trajectories,sim$participant,B=B,alpha=alpha,seed=seed)
  } else {
    pid <- as.integer(sub("^p","",sim$participant))
    group <- ifelse(pid<=length(unique(pid))/2L,"control","treatment")
    b <- etr_bootstrap_group_contrast(
      sim$trajectories,sim$participant,group,
      B=B,alpha=alpha,seed=seed)
  }
  list(lo=as.vector(t(b$simultaneous_lower)),
       hi=as.vector(t(b$simultaneous_upper)),
       cutoff=if (estimand=="participant_mean") b$cutoff else b$critical,
       degenerate_replicates=NA_integer_)
}
evaluate <- function(interval,truth) {
  lo <- interval$lo; hi <- interval$hi
  if (length(lo)!=length(truth) || length(hi)!=length(truth) ||
      any(!is.finite(c(lo,hi))) || any(lo>hi))
    stop("Malformed/nonfinite candidate intervals.",call.=FALSE)
  list(covered=all(truth>=lo & truth<=hi),
       pointwise=mean(truth>=lo & truth<=hi),
       width=mean(hi-lo),cutoff=interval$cutoff,
       degenerate=interval$degenerate_replicates)
}
methods <- c("existing_fixed_se_bootstrap",
             "studentized_cluster_bootstrap",
             "gaussian_bonferroni_t")
estimands <- c("participant_mean","two_group_null_contrast")
rows <- vector("list",length(N)*reps*length(estimands)*length(methods))
k <- 0L
for (j in seq_along(N)) {
  n <- N[j]
  cat("Paired interval comparison, N=",n," participants; ",
      reps," generated studies; bootstrap B=",B,"\n",sep="")
  for (i in seq_len(reps)) {
    seed <- as.integer(offset+1000000L*j+3L*i)
    sim <- tryCatch(etr_simulate_hierarchical(
      n_subjects=n,trials_per_subject=n_trials,n_time=nt,
      subject_sd=.35,trial_sd=.15,noise_sd=.05,seed=seed),error=identity)
    design <- if (!inherits(sim,"error")) {
      tryCatch(participant_matrix(sim),error=identity)
    } else {
      sim
    }
    for (ei in seq_along(estimands)) {
      estimand <- estimands[ei]
      d <- if (!inherits(design,"error")) {
        tryCatch(data_for(design$z,estimand),error=identity)
      } else {
        design
      }
      truth <- if (estimand=="participant_mean" &&
                   !inherits(sim,"error")) {
        as.vector(t(sim$truth_mean))
      } else {
        rep(0,nt*2L)
      }
      for (mi in seq_along(methods)) {
        k <- k+1L
        fit_seed <- as.integer(seed+10L*ei+mi)
        result <- if (inherits(d,"error")) d else tryCatch({
          band <- switch(methods[mi],
            existing_fixed_se_bootstrap=existing_band(sim,estimand,fit_seed),
            studentized_cluster_bootstrap=studentized_cluster(d,fit_seed),
            gaussian_bonferroni_t=gaussian_reference(d))
          evaluate(band,truth)
        },error=identity)
        success <- !inherits(result,"error")
        rows[[k]] <- data.frame(
          n_subjects=n,simulation=i,generator_seed=seed,
          bootstrap_seed=fit_seed,estimand=estimand,method=methods[mi],
          n_grid_coordinates=nt*2L,B=B,nominal=1-alpha,
          success=success,
          simultaneous_covered=if(success) result$covered else NA,
          average_pointwise_coverage=if(success) result$pointwise else NA_real_,
          mean_simultaneous_width=if(success) result$width else NA_real_,
          cutoff=if(success) result$cutoff else NA_real_,
          degenerate_bootstrap_draws=if(success) result$degenerate else NA_integer_,
          error=if(success) NA_character_ else conditionMessage(result),
          stringsAsFactors=FALSE)
      }
    }
  }
}
trials <- do.call(rbind,rows)
rownames(trials) <- NULL
utils::write.csv(trials,file.path(out,"interval_comparison_trials.csv"),
                 row.names=FALSE)
failed <- trials[!trials$success,,drop=FALSE]
utils::write.csv(failed,file.path(out,"interval_comparison_failures.csv"),
                 row.names=FALSE)
cells <- split(trials,interaction(trials$n_subjects,trials$estimand,
                                  trials$method,drop=TRUE))
summ <- lapply(cells,function(z){
  ok <- z$success
  m <- sum(ok)
  cov <- sum(z$simultaneous_covered[ok])
  ci <- if(m) {
    stats::binom.test(cov,m)$conf.int
  } else {
    c(NA_real_,NA_real_)
  }
  data.frame(n_subjects=z$n_subjects[1L],
    estimand=z$estimand[1L],method=z$method[1L],
    requested_datasets=nrow(z),successful_fits=m,
    failed_fits=nrow(z)-m,covered=cov,
    simultaneous_rate=if(m)cov/m else NA_real_,
    exact_95_lower=ci[1L],exact_95_upper=ci[2L],
    avg_pointwise_rate=if(m)
      mean(z$average_pointwise_coverage[ok]) else NA_real_,
    avg_simultaneous_width=if(m)
      mean(z$mean_simultaneous_width[ok]) else NA_real_)
})
summary <- do.call(rbind,summ)
rownames(summary) <- NULL
summary <- summary[order(summary$n_subjects,summary$estimand,
                         summary$method),,drop=FALSE]
utils::write.csv(summary,file.path(out,"interval_comparison_summary.csv"),
                 row.names=FALSE)

git <- tryCatch(system2("git",c("rev-parse","HEAD"),
                        stdout=TRUE,stderr=FALSE),
                error=function(e)"unavailable")
if (!length(git)) git <- "unavailable"
capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
writeLines(c("RESEARCH-ONLY EXPERIMENTAL PAIRED SIMULTANEOUS INTERVAL COMPARISON",
  paste("Archive:",normalizePath(out,winslash="/")),
  paste("Git HEAD:",git[1L]),
  paste("UTC:",format(Sys.time(),tz="UTC",usetz=TRUE)),
  paste("Package:",unname(read.dcf("DESCRIPTION",fields="Version")[1L])),
  paste("Seed offset:",offset),
  paste("Independent generating studies per N:",reps),
  paste("Participants by condition:",paste(N,collapse=",")),
  paste("Bootstrap draws:",B),
  paste("Alpha:",alpha),
  paste("Grid coordinates:",nt*2L),
  "Same generated dataset used for ALL six estimator-method combinations.",
  "Gaussian Bonferroni-t reference requires independent Gaussian participant",
  "means, equal variance between groups and fixed common observation grid.",
  "Studentized cluster bootstrap is experimental and has no declared guarantee.",
  "All fit failures retained. Rates conditional on successful fits.",
  "No runtime estimator or CRAN package implementation was altered.",
  "Compare BOTH truth coverage and mean simultaneous interval width."
),file.path(out,"MANIFEST.txt"))
cat("Output: ",normalizePath(out,winslash="/"),"\n",sep="")
print(summary,row.names=FALSE)
if(nrow(failed)) stop(nrow(failed),
  " candidate interval fits failed; investigate failures CSV.",
  call.=FALSE)
cat("Experimental paired candidate comparison complete; no scientific ",
    "method has been certified by this one study.\n",sep="")
