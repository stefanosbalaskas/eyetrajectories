#!/usr/bin/env Rscript
# Research-only, failure-inclusive stress study for previously under-covering
# fixed-SE participant-cluster functional confidence bands.
# Run at checkout root on research/native-parity-stage1:
#   Sys.setenv(ET_BAND_MC_REPS="200", ET_BAND_MC_B="399")
#   source("scripts/stress_native_band_coverage.R")
#
# No estimator modification, no external packages except pkgload (development).
# Every run archives raw studies, failures, summary and manifest.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields="Package")[1L]) != "eyetrajectories") {
  stop("Run from the eyetrajectories source checkout.", call.=FALSE)
}
if (!requireNamespace("pkgload", quietly=TRUE))
  stop("Install the development dependency 'pkgload'.", call.=FALSE)
pkgload::load_all(".", quiet=TRUE)

strict_int <- function(name, default, minimum, maximum) {
  raw <- Sys.getenv(name, unset=as.character(default))
  x <- suppressWarnings(as.integer(raw))
  if (length(x) != 1L || is.na(x) || as.character(x) != raw ||
      x < minimum || x > maximum)
    stop(name, " must be an integer from ", minimum, " to ", maximum,
         call.=FALSE)
  x
}
reps <- strict_int("ET_BAND_MC_REPS", 200L, 5L, 1000L)
B <- strict_int("ET_BAND_MC_B", 399L, 39L, 1999L)
seed_offset <- strict_int("ET_BAND_MC_SEED_OFFSET", 12000000L, 0L, 100000000L)
nominal <- .90
alpha <- 1 - nominal
group_sizes <- c(12L, 24L, 48L)
trials_per_subject <- 3L
n_time <- 41L
root <- file.path("artifacts", "band_coverage_stress")
out <- file.path(root,
                 paste0("run_",format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),
                        "_pid", Sys.getpid()))
if (dir.exists(out)) stop("An identically named archive exists.")
dir.create(out, recursive=TRUE, showWarnings=FALSE)
if (!dir.exists(out)) stop("Unable to create audit output directory.")

score_band <- function(band, truth, lower, upper) {
  lo <- band[[lower]]
  hi <- band[[upper]]
  if (!is.matrix(lo) || !is.matrix(hi) ||
      !identical(dim(lo), dim(truth)) ||
      !identical(dim(hi), dim(truth)) ||
      any(!is.finite(c(lo,hi,truth))) ||
      any(lo > hi))
    stop("Nonfinite or malformed functional confidence band.")
  list(covered=all(truth >= lo & truth <= hi),
       pointwise=mean(truth >= lo & truth <= hi),
       mean_width=mean(hi-lo))
}
once <- function(n_subjects, index, scenario_index) {
  generator_seed <- as.integer(seed_offset + 1000000L*scenario_index +
                                 3L*index)
  simulated <- tryCatch(etr_simulate_hierarchical(
    n_subjects=n_subjects, trials_per_subject=trials_per_subject,
    n_time=n_time, subject_sd=.35, trial_sd=.15, noise_sd=.05,
    seed=generator_seed), error=identity)
  # Record BOTH independent estimands even if generation fails.
  methods <- c("participant_mean", "two_group_null_contrast")
  lapply(seq_along(methods), function(mi) {
    seed_fit <- as.integer(generator_seed + mi)
    error_message <- NA_character_
    ans <- NULL
    if (inherits(simulated, "error")) {
      error_message <- conditionMessage(simulated)
    } else {
      ans <- tryCatch({
        if (mi == 1L) {
          b <- etr_bootstrap_mean_band(
            simulated$trajectories, simulated$participant,
            B=B, alpha=alpha, seed=seed_fit)
          truth <- simulated$truth_mean
          obs <- score_band(b, truth,
                            "simultaneous_lower", "simultaneous_upper")
          pt <- score_band(b, truth,
                           "pointwise_lower", "pointwise_upper")
        } else {
          pid <- as.integer(sub("^p", "", simulated$participant))
          gr <- ifelse(pid <= n_subjects/2L, "control", "treatment")
          b <- etr_bootstrap_group_contrast(
            simulated$trajectories, simulated$participant, gr,
            B=B, alpha=alpha, seed=seed_fit)
          truth <- matrix(0, n_time, 2L)
          obs <- score_band(b, truth,
                            "simultaneous_lower", "simultaneous_upper")
          pt <- score_band(b, truth,
                           "pointwise_lower", "pointwise_upper")
        }
        list(simultaneous=obs$covered,
             pointwise=pt$pointwise,
             mean_width=obs$mean_width)
      }, error=identity)
      if (inherits(ans, "error")) {
        error_message <- conditionMessage(ans)
        ans <- NULL
      }
    }
    data.frame(n_subjects=n_subjects, simulation=index,
               method=methods[mi], generator_seed=generator_seed,
               bootstrap_seed=seed_fit, B=B, nominal=nominal,
               success=!is.null(ans),
               simultaneous_covered=if (is.null(ans)) NA else ans$simultaneous,
               average_pointwise_coverage=if (is.null(ans))
                 NA_real_ else ans$pointwise,
               mean_simultaneous_width=if (is.null(ans))
                 NA_real_ else ans$mean_width,
               error=error_message, stringsAsFactors=FALSE)
  })
}
all_rows <- vector("list", length(group_sizes) * reps)
i <- 0L
for (scenario_index in seq_along(group_sizes)) {
  n <- group_sizes[scenario_index]
  cat("n_subjects=",n,", generating datasets=",reps,
      ", bootstrap B=",B,"\n",sep="")
  for (run in seq_len(reps)) {
    i <- i + 1L
    all_rows[[i]] <- do.call(rbind, once(n, run, scenario_index))
  }
}
trials <- do.call(rbind, all_rows)
rownames(trials) <- NULL
trials_csv <- file.path(out, "band_coverage_trials.csv")
utils::write.csv(trials, trials_csv, row.names=FALSE)
failures <- trials[!trials$success, ,drop=FALSE]
utils::write.csv(failures, file.path(out, "band_coverage_failures.csv"),
                 row.names=FALSE)

cells <- split(trials, interaction(trials$n_subjects, trials$method,
                                   drop=TRUE))
summarize <- function(z) {
  success <- z$success
  n <- sum(success)
  k <- sum(z$simultaneous_covered[success])
  ci <- if (n) stats::binom.test(k, n)$conf.int else c(NA_real_,NA_real_)
  p_less <- if (n) stats::binom.test(k,n,p=nominal,
                                   alternative="less")$p.value else NA_real_
  data.frame(method=z$method[1L], n_subjects=z$n_subjects[1L],
             requested_datasets=nrow(z), successful_datasets=n,
             failed_datasets=nrow(z)-n, nominal=nominal,
             simultaneous_covered=k,
             simultaneous_rate=if (n) k/n else NA_real_,
             exact_95_lower=ci[1L], exact_95_upper=ci[2L],
             nominal_above_mc_95_upper=if (n)
               ci[2L] < nominal else NA,
             one_sided_binomial_p=p_less,
             average_pointwise_rate=if (n)
               mean(z$average_pointwise_coverage[success]) else NA_real_,
             mean_simultaneous_width=if (n)
               mean(z$mean_simultaneous_width[success]) else NA_real_)
}
s <- do.call(rbind, lapply(cells,summarize))
rownames(s) <- NULL
s <- s[order(s$n_subjects, s$method),,drop=FALSE]
utils::write.csv(s,file.path(out,"band_coverage_summary.csv"),
                 row.names=FALSE)

# Raw and summarized results are deliberately archived even if fits fail.
git <- tryCatch(system2("git", c("rev-parse","HEAD"),
                        stdout=TRUE,stderr=FALSE),
                error=function(e) "unavailable")
if (!length(git)) git <- "unavailable"
capture.output(sessionInfo(), file=file.path(out,"sessionInfo.txt"))
writeLines(c(
  "RESEARCH-ONLY FAILURE-INCLUSIVE NATIVE FUNCTIONAL BAND STRESS AUDIT",
  paste("Archive:",normalizePath(out,winslash="/")),
  paste("UTC:",format(Sys.time(),tz="UTC",usetz=TRUE)),
  paste("Git HEAD:",git[1L]),
  paste("R:",R.version.string),
  paste("Package:",unname(read.dcf("DESCRIPTION", fields="Version")[1L])),
  paste("Seed offset:",seed_offset),
  paste("Independent generating datasets per n_subjects:",reps),
  paste("Independent clusters:",paste(group_sizes,collapse=",")),
  paste("Trials per participant:",trials_per_subject),
  paste("Grid observations:",n_time),
  paste("Bootstrap draws per fit:",B),
  paste("Nominal simultaneous coverage:",nominal),
  "Generating population means are known: sin(2*pi*t),cos(2*pi*t).",
  "Two-group contrast has known truth zero under balanced random clusters.",
  "For each simulated dataset the mean and contrast methods share data.",
  "Do not count mean/contrast rows as independent generated datasets.",
  "All fit failures retained; rates conditional on successful fits.",
  "p-values are Monte Carlo diagnostics of the specified generator only.",
  "No automatic claim of general asymptotic or finite-sample validity.",
  "Existing estimators were NOT modified."
),file.path(out,"MANIFEST.txt"))

cat("Output:",normalizePath(out,winslash="/"),"\n")
print(s,row.names=FALSE)
if (nrow(failures))
  stop(nrow(failures)," estimator fits failed; inspect the failures CSV.",
       call.=FALSE)
cat("Completed synthetic diagnostic. A run without errors is NOT ",
    "a scientific coverage guarantee.\n",sep="")
