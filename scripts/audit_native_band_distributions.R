#!/usr/bin/env Rscript
# Research-only, read-only audit of saved distributional band stress results.
# Does not alter source trial archives, native R estimators or exports.
#
# From the repository checkout after pulling research/native-parity-stage1:
#   source("scripts/audit_native_band_distributions.R")
# Optionally select one archive:
#   Sys.setenv(ET_BAND_ROBUST_AUDIT_DIR =
#     "artifacts/band_robustness_stress/run_20261026_215536_pid51684")
#   source("scripts/audit_native_band_distributions.R")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields="Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories repository checkout.", call.=FALSE)

root <- file.path("artifacts", "band_robustness_stress")
chosen <- Sys.getenv("ET_BAND_ROBUST_AUDIT_DIR", unset="")
if (!nzchar(chosen)) {
  dirs <- if (dir.exists(root))
    list.dirs(root, recursive=FALSE, full.names=TRUE) else character()
  dirs <- dirs[grepl("^run_[0-9]{8}_[0-9]{6}_pid[0-9]+$", basename(dirs))]
  dirs <- dirs[file.exists(file.path(dirs, "robustness_trials.csv")) &
               file.exists(file.path(dirs, "robustness_summary.csv"))]
  if (!length(dirs))
    stop("No completed robustness trial/summary archive found.", call.=FALSE)
  chosen <- dirs[order(basename(dirs), decreasing=TRUE)][1L]
}
chosen <- normalizePath(chosen, winslash="/", mustWork=TRUE)
trials <- utils::read.csv(file.path(chosen, "robustness_trials.csv"),
                          stringsAsFactors=FALSE)
reported <- utils::read.csv(file.path(chosen, "robustness_summary.csv"),
                            stringsAsFactors=FALSE)

keys <- c("scenario", "n_subjects", "simulation", "generator_seed",
          "estimand", "method")
fields <- c(keys, "success", "simultaneous_covered",
            "mean_simultaneous_width",
            "coordinate_coverage_in_simultaneous_band", "error")
if (!all(fields %in% names(trials)))
  stop("Trial archive lacks required audit fields.", call.=FALSE)
summary_fields <- c("scenario", "n_subjects", "estimand", "method",
                    "requested_datasets", "successful_fits", "failed_fits",
                    "covered", "simultaneous_rate", "exact_95_lower",
                    "exact_95_upper",
                    "avg_coordinate_coverage_in_simultaneous_band",
                    "avg_simultaneous_width")
if (!all(summary_fields %in% names(reported)))
  stop("Summary archive lacks required audit fields.", call.=FALSE)
if (!nrow(trials) || !nrow(reported) || anyNA(trials[, keys]))
  stop("Empty/incomplete trial archive or missing study keys.", call.=FALSE)
if (anyNA(trials$success) || anyNA(trials$mean_simultaneous_width[trials$success]) ||
    anyNA(trials$simultaneous_covered[trials$success]) ||
    anyNA(trials$coordinate_coverage_in_simultaneous_band[trials$success]))
  stop("Undefined status or successful-fit outputs.", call.=FALSE)
if (any(trials$mean_simultaneous_width[trials$success] < 0) ||
    any(!is.finite(trials$mean_simultaneous_width[trials$success])))
  stop("Invalid successful-fit widths.", call.=FALSE)

scenarios <- c("gaussian_baseline", "heavy_t3", "heteroskedastic_groups",
               "skewed_lognormal")
ns <- c(12L, 24L, 48L)
estimands <- c("participant_mean", "two_group_null_contrast")
baseline <- "existing_fixed_se_bootstrap"
candidates <- c("studentized_cluster_bootstrap", "gaussian_bonferroni_t")
methods <- c(baseline, candidates)
if (!identical(sort(unique(trials$scenario)), sort(scenarios)) ||
    !identical(sort(unique(trials$n_subjects)), sort(ns)) ||
    !identical(sort(unique(trials$estimand)), sort(estimands)) ||
    !identical(sort(unique(trials$method)), sort(methods)))
  stop("Unexpected scenario/N/estimand/method coverage.", call.=FALSE)

study_key <- paste(trials$scenario, trials$n_subjects, trials$simulation, sep=":")
eval_key <- paste(study_key, trials$estimand, trials$method, sep=":")
if (anyDuplicated(eval_key))
  stop("Duplicate evaluation rows for one generating study.", call.=FALSE)
study_groups <- split(trials, study_key)
study_seeds <- vapply(study_groups, function(z) {
  if (nrow(z) != length(estimands)*length(methods) ||
      length(unique(z$generator_seed)) != 1L ||
      length(unique(z$simulation)) != 1L ||
      !setequal(z$estimand, estimands) ||
      !setequal(z$method, methods))
    stop("Incomplete/unpaired six-way study: ",
         paste(unique(z$scenario), unique(z$n_subjects),
               unique(z$simulation), collapse=":"), call.=FALSE)
  as.numeric(z$generator_seed[1L])
}, numeric(1L))
if (anyDuplicated(study_seeds))
  stop("Generator seeds reused across distinct scenario/N/study keys.",
       call.=FALSE)

cells <- split(trials, interaction(trials$scenario, trials$n_subjects,
                                   trials$estimand, trials$method, drop=TRUE))
if (length(cells) != nrow(reported))
  stop("Archive summary count differs from trial condition count.",
       call.=FALSE)
for (z in cells) {
  sm <- reported[reported$scenario==z$scenario[1L] &
                 reported$n_subjects==z$n_subjects[1L] &
                 reported$estimand==z$estimand[1L] &
                 reported$method==z$method[1L], , drop=FALSE]
  if (nrow(sm) != 1L) stop("Missing or duplicate reported cell.", call.=FALSE)
  ok <- z$success
  m <- sum(ok)
  covered <- sum(z$simultaneous_covered[ok])
  if (sm$requested_datasets != nrow(z) ||
      sm$successful_fits != m || sm$failed_fits != sum(!ok) ||
      sm$covered != covered)
    stop("Archived summary trial/fit/coverage counts disagree.", call.=FALSE)
  if (m) {
    ci <- stats::binom.test(covered, m)$conf.int
    if (abs(sm$simultaneous_rate-covered/m)>1e-10 ||
        max(abs(c(sm$exact_95_lower, sm$exact_95_upper)-ci))>1e-7 ||
        abs(sm$avg_simultaneous_width-
            mean(z$mean_simultaneous_width[ok]))>1e-9 ||
        abs(sm$avg_coordinate_coverage_in_simultaneous_band-
            mean(z$coordinate_coverage_in_simultaneous_band[ok]))>1e-9)
      stop("Archived rates, exact CI, or width/coordinate means disagree.",
           call.=FALSE)
  }
}

scoped_seed <- function(seed, operation) {
  had <- exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE)
  if (had) old <- get(".Random.seed", envir=.GlobalEnv, inherits=FALSE)
  on.exit({
    if (had) assign(".Random.seed", old, envir=.GlobalEnv)
    else if (exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE))
      rm(".Random.seed", envir=.GlobalEnv)
  }, add=TRUE)
  set.seed(seed)
  operation()
}
output <- list()
k <- 0L
for (scenario in scenarios) for (n in ns) for (estimand in estimands) {
  z <- trials[trials$scenario==scenario & trials$n_subjects==n &
              trials$estimand==estimand, , drop=FALSE]
  b <- z[z$method==baseline,
         c("simulation", "generator_seed", "success",
           "simultaneous_covered", "mean_simultaneous_width"), drop=FALSE]
  for (candidate in candidates) {
    cand_rows <- z[z$method==candidate,
           c("simulation", "generator_seed", "success",
             "simultaneous_covered", "mean_simultaneous_width"), drop=FALSE]
    p <- merge(b, cand_rows, by=c("simulation", "generator_seed"),
               suffixes=c("_base", "_candidate"), all=TRUE, sort=TRUE)
    valid <- p$success_base & p$success_candidate
    valid[is.na(valid)] <- FALSE
    paired <- p[valid, , drop=FALSE]
    m <- nrow(paired)
    old <- as.logical(paired$simultaneous_covered_base)
    new <- as.logical(paired$simultaneous_covered_candidate)
    gain <- if (m) 100 * mean(as.integer(new)-as.integer(old)) else NA_real_
    width_ratio <- if (m) mean(paired$mean_simultaneous_width_candidate)/
                           mean(paired$mean_simultaneous_width_base) else NA_real_
    newly <- if (m) sum(!old & new) else 0L
    lost <- if (m) sum(old & !new) else 0L
    if (m) {
      seed <- as.integer(68000000L + 100000L*match(scenario,scenarios) +
                         1000L*n + 100L*match(estimand,estimands) +
                         10L*match(candidate,candidates))
      draws <- scoped_seed(seed, function() replicate(2000L, {
        idx <- sample.int(m, m, replace=TRUE)
        c(gain=100*mean(as.integer(new[idx])-as.integer(old[idx])),
          width_ratio=mean(paired$mean_simultaneous_width_candidate[idx])/
                      mean(paired$mean_simultaneous_width_base[idx]))
      }))
      gains_ci <- stats::quantile(draws["gain", ], c(.025,.975), names=FALSE)
      widths_ci <- stats::quantile(draws["width_ratio", ], c(.025,.975),
                                  names=FALSE)
    } else {
      gains_ci <- widths_ci <- c(NA_real_, NA_real_)
    }
    k <- k+1L
    output[[k]] <- data.frame(
      scenario=scenario, n_subjects=n, estimand=estimand,
      candidate=candidate, recorded_datasets=nrow(p),
      both_successful=m, failed_or_unpaired=nrow(p)-m,
      baseline_coverage_rate=if(m)mean(old) else NA_real_,
      candidate_coverage_rate=if(m)mean(new) else NA_real_,
      coverage_gain_pp=gain,
      gain_pp_boot_95_lower=gains_ci[1L],
      gain_pp_boot_95_upper=gains_ci[2L],
      baseline_missed_candidate_covered=newly,
      baseline_covered_candidate_missed=lost,
      width_ratio=width_ratio,
      width_ratio_boot_95_lower=widths_ci[1L],
      width_ratio_boot_95_upper=widths_ci[2L])
  }
}
paired_summary <- do.call(rbind, output)
rownames(paired_summary) <- NULL
audit_root <- file.path("artifacts", "band_robustness_stress_audit")
out <- file.path(audit_root, paste0("audit_",
  format(Sys.time(), "%Y%m%d_%H%M%S", tz="UTC"),
  "_pid", Sys.getpid()))
if (dir.exists(out))
  stop("Same-name robustness audit archive exists.", call.=FALSE)
if (!dir.create(out, recursive=TRUE, showWarnings=FALSE))
  stop("Cannot create robustness audit output directory.", call.=FALSE)
utils::write.csv(paired_summary, file.path(out, "paired_robustness_audit.csv"),
                 row.names=FALSE)
writeLines(c(
  "READ-ONLY COMPLETE-DATA SIMULTANEOUS-BAND ROBUSTNESS AUDIT",
  paste("Source archive:", chosen),
  paste("Audit output:", normalizePath(out,winslash="/")),
  paste("Distinct generated datasets:", length(study_groups)),
  paste("Recorded method/estimand evaluations:", nrow(trials)),
  paste("Evaluation failures:", sum(!trials$success)),
  "Archive trial/summary reconciliation: PASS",
  "Each study must contain 2 estimands x 3 methods using the same seed.",
  "Descriptive paired-bootstrap intervals use 2000 resamples per condition.",
  "Bootstrap intervals quantify Monte Carlo uncertainty under each fixed DGP.",
  "These intervals do NOT account for model uncertainty or multiplicity.",
  "Coordinate inclusion means truth within simultaneous bands, not pointwise CIs.",
  "Normal Bonferroni-t is assumption-matched only to gaussian_baseline.",
  "No MCAR/MAR/MNAR, dropout, or sparse-observation process is tested.",
  "No source data or package estimator was modified; qualification HOLD."
), file.path(out, "MANIFEST.txt"))
cat("Source archive: ", chosen, "\n", sep="")
cat("Output: ", normalizePath(out,winslash="/"), "\n", sep="")
cat("Generating datasets: ", length(study_groups), "; evaluations: ",
    nrow(trials), "; failed: ", sum(!trials$success), "\n", sep="")
cat("Robustness archive summary/trial consistency: PASS\n")
print(paired_summary, row.names=FALSE)
cat("Read-only paired robustness audit complete; no scientific ",
    "method certified.\n", sep="")
