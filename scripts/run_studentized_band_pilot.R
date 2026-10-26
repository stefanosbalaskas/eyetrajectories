#!/usr/bin/env Rscript
# RESEARCH ONLY: paired confidence-band pilot on independent generated datasets.
# Compares existing fixed-SE cluster max-t bootstrap against a candidate
# bootstrap-specific-SE studentized max-t method. These are NOT calibrated
# estimators. No native R package function is replaced or exported.
# From R repository root:
#   source("scripts/run_studentized_band_pilot.R")
#   Sys.setenv(ET_STUDENT_SIMS="100", ET_STUDENT_B="399")
#   source("scripts/run_studentized_band_pilot.R")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from eyetrajectories source repository root.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install the development dependency pkgload.", call. = FALSE)
pkgload::load_all(".", quiet = TRUE)
get_int <- function(key, default, low, high) {
  txt <- Sys.getenv(key, unset = as.character(default))
  n <- suppressWarnings(as.integer(txt))
  if (length(n) != 1L || is.na(n) || as.character(n) != txt ||
      n < low || n > high)
    stop(key, " must be an integer in [", low, ",", high, "].")
  n
}
nsim <- get_int("ET_STUDENT_SIMS", 30L, 5L, 5000L)
B <- get_int("ET_STUDENT_B", 199L, 39L, 20000L)
sizes <- suppressWarnings(as.integer(strsplit(
  Sys.getenv("ET_STUDENT_SUBJECTS", unset = "12,24,48"),
  ",", fixed = TRUE)[[1L]]))
if (!length(sizes) || anyNA(sizes) ||
    any(sizes < 8L) || any(sizes %% 2L != 0L) ||
    anyDuplicated(sizes))
  stop("ET_STUDENT_SUBJECTS must be distinct even integers >= 8.")
alpha <- .10
out <- file.path("artifacts", "studentized_band_pilot",
                 paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S", tz="UTC"),
                        "_pid", Sys.getpid()))
if (dir.exists(out)) stop("Archive name collision. Retry in another second.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(out)) stop("Cannot create output archive.")

preserve_rng <- function(seed, fn) {
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) prev <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (had) assign(".Random.seed", prev, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed)
  fn()
}
# Independent participant means, respecting the original participant labels.
# Columns use array order (all grid samples of channel 1, then channel 2),
# consistent with as.vector() of known-truth and native fitted R band matrices.
subject_matrix <- function(sample) {
  v <- sample$trajectories$values
  ids <- unique(as.character(sample$participant))
  obs <- matrix(v, nrow = dim(v)[1L])
  z <- t(vapply(ids, function(id)
    colMeans(obs[as.character(sample$participant) == id, , drop=FALSE]),
    numeric(ncol(obs))))
  list(z=z, ids=ids)
}
get_design <- function(sample, design) {
  part <- subject_matrix(sample)
  if (design == "participant_mean") {
    return(list(z=part$z, a=NULL, b=NULL, truth=as.vector(sample$truth_mean)))
  }
  g <- as.character(sample$treatment[match(part$ids, sample$participant)])
  a <- part$z[g=="control", , drop=FALSE]
  b <- part$z[g=="treatment", , drop=FALSE]
  if (nrow(a) < 3L || nrow(b) < 3L) stop("Insufficient group participants.")
  list(z=NULL, a=a, b=b, truth=as.vector(sample$true_contrast))
}
point_and_se <- function(d) {
  if (!is.null(d$z)) {
    n <- nrow(d$z)
    list(point=colMeans(d$z), se=apply(d$z,2L,stats::sd)/sqrt(n))
  } else {
    a <- d$a; b <- d$b
    list(point=colMeans(b)-colMeans(a),
         se=sqrt(apply(a,2L,stats::var)/nrow(a) +
                 apply(b,2L,stats::var)/nrow(b)))
  }
}
# Studentized max statistic uses bootstrap-specific pointwise SEs.
# This differs fundamentally from the existing fixed-original-SE
# approach. It must NOT be represented as a qualified replacement.
studentized <- function(d, B, alpha, seed) {
  original <- point_and_se(d)
  estimate <- original$point
  se <- original$se
  active <- which(is.finite(se) & se > .Machine$double.eps)
  if (!length(active) || any(!is.finite(estimate)))
    stop("Degenerate observed standard errors or estimate.")
  draws <- preserve_rng(seed, function() {
    vapply(seq_len(B), function(i) {
      if (!is.null(d$z)) {
        n <- nrow(d$z)
        sample_d <- list(z=d$z[sample.int(n,n,TRUE),,drop=FALSE],
                         a=NULL,b=NULL)
      } else {
        na <- nrow(d$a); nb <- nrow(d$b)
        sample_d <- list(z=NULL,
                         a=d$a[sample.int(na,na,TRUE),,drop=FALSE],
                         b=d$b[sample.int(nb,nb,TRUE),,drop=FALSE])
      }
      bootstrap <- point_and_se(sample_d)
      star_se <- bootstrap$se[active]
      if (any(!is.finite(star_se) | star_se <= .Machine$double.eps))
        return(NA_real_)
      max(abs((bootstrap$point[active]-estimate[active])/star_se))
    }, numeric(1))
  })
  if (anyNA(draws) || any(!is.finite(draws)))
    stop("One or more studentized bootstrap SEs degenerated.")
  critical <- unname(stats::quantile(draws, probs=1-alpha, type=1,
                                     names=FALSE))
  lower <- estimate - critical*se
  upper <- estimate + critical*se
  if (any(!is.finite(c(lower,upper))) ||
      length(lower) != length(d$truth))
    stop("Non-finite or incompatible candidate interval.")
  list(inside=all(d$truth >= lower & d$truth <= upper),
       mean_width=mean(upper-lower), critical=critical)
}
baseline <- function(sample, design, B, alpha, seed) {
  d <- get_design(sample, design)
  fit <- if (design == "participant_mean") {
    etr_bootstrap_mean_band(sample$trajectories, sample$participant,
                            B=B, alpha=alpha, seed=seed)
  } else {
    etr_bootstrap_group_contrast(sample$trajectories, sample$participant,
                                 sample$treatment, B=B, alpha=alpha,
                                 seed=seed)
  }
  lo <- as.vector(fit$simultaneous_lower)
  hi <- as.vector(fit$simultaneous_upper)
  if (any(!is.finite(c(lo,hi))) || length(lo) != length(d$truth))
    stop("Non-finite baseline functional band.")
  list(inside=all(d$truth >= lo & d$truth <= hi),
       mean_width=mean(hi-lo),
       critical=if (design=="participant_mean") fit$cutoff else fit$critical)
}
one_row <- function(method, design, n, i, seed, fit) {
  if (inherits(fit, "error")) {
    return(data.frame(method=method, design=design,
      n_subjects=n, simulation=i, seed=seed, alpha=alpha, B=B,
      status="failed", contains_truth=NA, mean_width=NA_real_,
      critical=NA_real_, error=conditionMessage(fit)))
  }
  data.frame(method=method, design=design, n_subjects=n,
    simulation=i, seed=seed, alpha=alpha, B=B,
    status="ok", contains_truth=isTRUE(fit$inside),
    mean_width=fit$mean_width, critical=fit$critical,
    error=NA_character_)
}
trials <- list()
for (design in c("group_contrast", "participant_mean")) for (n in sizes) {
  cat("Paired fixed-SE and studentized mean/contrast bands: ",
      design, " N=", n, " studies=", nsim, " B=", B, "\n", sep="")
  for (i in seq_len(nsim)) {
    seed <- as.integer(520000L + 2000L*n + 3L*i +
      if (design=="participant_mean") 100000L else 0L)
    sample <- tryCatch({
      if (design=="participant_mean") {
        etr_simulate_hierarchical(n_subjects=n, n_time=41L, seed=seed)
      } else {
        etr_simulate_group_contrast(n_subjects=n, n_time=41L, seed=seed)
      }
    }, error=function(e)e)
    if (inherits(sample,"error")) {
      fit_old <- fit_new <- sample
    } else {
      fit_old <- tryCatch(baseline(sample,design,B,alpha,seed+1L),
                          error=function(e)e)
      fit_new <- tryCatch(studentized(get_design(sample,design),B,alpha,
                                      seed+2L),
                          error=function(e)e)
    }
    trials[[length(trials)+1L]] <- one_row(
      "fixed_original_se_max",design,n,i,seed,fit_old)
    trials[[length(trials)+1L]] <- one_row(
      "bootstrap_studentized_max",design,n,i,seed,fit_new)
  }
}
cases <- do.call(rbind,trials)
rownames(cases) <- NULL
utils::write.csv(cases,file.path(out,"studentized_trials.csv"),
                 row.names=FALSE)
failed <- cases[cases$status!="ok",,drop=FALSE]
if (nrow(failed))
  utils::write.csv(failed,file.path(out,"studentized_failures.csv"),
                   row.names=FALSE)
grouped <- split(cases,interaction(cases$method,cases$design,
                                  cases$n_subjects,drop=TRUE))
summaries <- lapply(grouped,function(x){
  ok <- x$status=="ok"
  fitted <- sum(ok); covered <- sum(x$contains_truth[ok])
  ci <- if (fitted) {
    as.numeric(stats::binom.test(covered,fitted)$conf.int)
  } else {
    c(NA_real_,NA_real_)
  }
  data.frame(method=x$method[1L],design=x$design[1L],
    n_subjects=x$n_subjects[1L],alpha=x$alpha[1L],
    requested=nrow(x),fitted=fitted,failed=nrow(x)-fitted,
    covered=covered,conditional_coverage=if (fitted) covered/fitted else NA_real_,
    exact_95_lower=ci[1L],exact_95_upper=ci[2L],
    operational_coverage=covered/nrow(x),
    mean_width=if (fitted) mean(x$mean_width[ok]) else NA_real_,
    mean_critical=if (fitted) mean(x$critical[ok]) else NA_real_,
    nominal_reference=1-alpha)
})
summary <- do.call(rbind,summaries)
rownames(summary) <- NULL
utils::write.csv(summary,file.path(out,"studentized_summary.csv"),
                 row.names=FALSE)
plot_file <- file.path(out,"studentized_coverage_width.pdf")
grDevices::pdf(plot_file,width=8.5,height=5.5)
tryCatch({
  for (design in c("group_contrast","participant_mean")) {
    dat <- summary[summary$design==design,,drop=FALSE]
    x <- sort(unique(dat$n_subjects))
    methods <- c("fixed_original_se_max","bootstrap_studentized_max")
    linecols <- c("#356B87","#B35F3C")
    for (measure in c("conditional_coverage","mean_width")) {
      yvals <- dat[[measure]]
      ylim <- if (measure=="conditional_coverage") c(0,1) else
        range(c(0,yvals),finite=TRUE)
      graphics::plot(range(x),ylim,type="n",xlab="Independent participants",
                     ylab=measure, main=paste(design,measure),xaxt="n")
      graphics::axis(1,at=x)
      for (j in seq_along(methods)) {
        sub <- dat[dat$method==methods[j],,drop=FALSE]
        sub <- sub[order(sub$n_subjects),,drop=FALSE]
        graphics::lines(sub$n_subjects,sub[[measure]],type="b",
                        pch=16,col=linecols[j],lwd=2)
      }
      if (measure=="conditional_coverage")
        graphics::abline(h=1-alpha,lty=2,col="grey50")
      graphics::legend("topright",legend=methods,col=linecols,
                       lwd=2,pch=16,bty="n",cex=.8)
    }
  }
},finally=grDevices::dev.off())
sha <- tryCatch(system2("git",c("rev-parse","HEAD"),stdout=TRUE,
                        stderr=FALSE),error=function(e)"unavailable")
if (!length(sha)) sha <- "unavailable"
capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
writeLines(c(
 "Research pilot ONLY: paired bootstrap studentization vs fixed-SE bands",
 paste("UTC:",format(Sys.time(),tz="UTC",usetz=TRUE)),
 paste("Source HEAD:",sha[1L]),
 paste("R:",R.version.string),
 paste("Source version:",unname(read.dcf("DESCRIPTION",fields="Version")[1L])),
 paste("B:",B),paste("Independent studies per design:",nsim),
 paste("Participant sample sizes:",paste(sizes,collapse=",")),
 "Full 41x2 grid; alpha=.10, simultaneous target=.90.",
 "Current production R confidence bands UNCHANGED.",
 "Studentized SE refitted within each bootstrap sample.",
 "Bootstrap-specific zero/invalid SE marks entire design fit as failed.",
 "Original point/SE and studentized max-T are separate estimators.",
 "No missingness, unequal trials, heterogeneous noise, or skew in this pilot.",
 "One native research fit unit is one generated independent participant cluster.",
 "Conditional fit-success coverage + failures + operational coverage all reported.",
 "A higher empirical coverage from wider bands is not release qualification.",
 "Known fixed-SE undercoverage remains an open research blocker."
),file.path(out,"MANIFEST.txt"))
print(summary,row.names=FALSE)
cat("Saved studentized pilot in: ",
    normalizePath(out,winslash="/"),"\n",sep="")
if(nrow(failed))stop("One or more fits failed; inspect archived failure records.")
cat("Pilot completed. No coverage calibration claim is authorized.\n")
