#!/usr/bin/env Rscript
# Research-only failure-inclusive native R split-conformal Monte Carlo.
# Run at repository root on research/native-parity-stage1:
#   source("scripts/run_conformal_monte_carlo.R")
# Optional: Sys.setenv(ET_CONFORMAL_REPS = "1000")
# No Python, network calls, extra R dependencies, or changes to estimators.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories source repository root.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install the development dependency: install.packages('pkgload')")
pkgload::load_all(".", quiet = TRUE)
int_env <- function(key, default, min, max) {
  raw <- Sys.getenv(key, unset = as.character(default))
  val <- suppressWarnings(as.integer(raw))
  if (length(val) != 1L || is.na(val) || as.character(val) != raw ||
      val < min || val > max)
    stop(key, " must be a whole number between ", min, " and ", max)
  val
}
reps <- int_env("ET_CONFORMAL_REPS", 200L, 5L, 10000L)
# A nonzero offset makes a larger study an independent seeded replication
# rather than silently reusing the first 200 generated pilot datasets.
seed_offset <- int_env("ET_CONFORMAL_SEED_OFFSET", 0L, 0L, 100000000L)
n_train <- int_env("ET_CONFORMAL_TRAIN", 24L, 8L, 100L)
n_cal <- int_env("ET_CONFORMAL_CALIBRATION", 19L, 9L, 200L)
raw_alphas <- strsplit(Sys.getenv("ET_CONFORMAL_ALPHAS",
                                 unset = "0.05,0.10"), ",", fixed = TRUE)[[1L]]
alphas <- suppressWarnings(as.numeric(raw_alphas))
if (!length(alphas) || anyNA(alphas) || any(!is.finite(alphas)) ||
    any(alphas <= 0 | alphas >= 1) || anyDuplicated(alphas))
  stop("ET_CONFORMAL_ALPHAS must be distinct numeric values in (0,1).")
shift_amplitude <- suppressWarnings(as.numeric(
  Sys.getenv("ET_CONFORMAL_SHIFT", unset = "0.6")))
if (length(shift_amplitude) != 1L || !is.finite(shift_amplitude) ||
    shift_amplitude <= 0 || shift_amplitude > 5)
  stop("ET_CONFORMAL_SHIFT must be finite and in (0,5].")
test_noise_multiplier <- 3
base_noise <- 0.06
time <- seq(0, 1, length.out = 41L)
scenarios <- c("iid_exchangeable", "test_noise_shift", "dependent_calibration")
# Archive each pilot / high-replication run separately. Never overwrite
# previously archived failure-inclusive Monte Carlo evidence.
base_out <- file.path("artifacts", "conformal_monte_carlo")
run_name <- paste0(
  "run_", format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC"),
  "_pid", Sys.getpid())
out <- file.path(base_out, run_name)
if (dir.exists(out)) {
  stop("Archive collision; previous conformal outputs must not be overwritten.")
}
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(out)) stop("Could not create output archive.", call. = FALSE)

# Isolate each independent Monte Carlo dataset from the caller's global RNG.
with_seed <- function(seed, expression) {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed)
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit(if (had_seed) {
    assign(".Random.seed", old_seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed)
  force(expression)
}

# Independent per-curve latent coefficients under the inlier law.
# For dependent_calibration, distinct curves share some latent coefficients,
# but retain separately generated measurement errors.
sample_curves <- function(ids, noise_sd = base_noise, latent = NULL) {
  n <- length(ids)
  if (is.null(latent)) {
    latent <- cbind(stats::rnorm(n, sd = 0.25),
                    stats::rnorm(n, sd = 0.16))
  }
  stopifnot(is.matrix(latent), identical(dim(latent), c(n, 2L)))
  z <- array(NA_real_, c(n, length(time), 1L))
  for (j in seq_len(n)) {
    z[j, , 1L] <- sin(2*pi*time) +
      latent[j, 1L] * cos(2*pi*time) +
      latent[j, 2L] * sin(4*pi*time) +
      stats::rnorm(length(time), sd = noise_sd)
  }
  etr_trajectory_set(time, z, ids, "x",
                     coordinate_system = "synthetic",
                     time_unit = "normalized")
}
sample_calibration <- function(scenario, seed_tag) {
  ids <- paste0("cal_", seed_tag, "_", seq_len(n_cal))
  if (scenario != "dependent_calibration") return(sample_curves(ids))
  n_subjects <- ceiling(n_cal/2)
  latent_subject <- cbind(stats::rnorm(n_subjects, sd = .25),
                          stats::rnorm(n_subjects, sd = .16))
  participant <- rep(seq_len(n_subjects), each = 2L, length.out = n_cal)
  sample_curves(ids, latent = latent_subject[participant, , drop = FALSE])
}
simulate_once <- function(scenario, sim, seed) {
  with_seed(seed, {
    train <- sample_curves(paste0("train_", seed, "_", seq_len(n_train)))
    cal <- sample_calibration(scenario, seed)
    noise <- if (scenario == "test_noise_shift")
      base_noise * test_noise_multiplier else base_noise
    inlier <- sample_curves(paste0("null_", seed), noise_sd = noise)
    alt <- inlier$values[1L, , 1L] +
      shift_amplitude * sin(6*pi*time)
    candidate_values <- array(0, c(2L, length(time), 1L))
    candidate_values[1L, , 1L] <- inlier$values[1L, , 1L]
    candidate_values[2L, , 1L] <- alt
    candidates <- etr_trajectory_set(
      time, candidate_values,
      c(paste0("null_", seed), paste0("shifted_", seed)), "x",
      coordinate_system = "synthetic", time_unit = "normalized")
    # Strict frozen training: no calibration/test observations enter FPCA.
    fit <- etr_fit_fpca(train, n_components = 1L)
    lapply(alphas, function(alpha) {
      result <- etr_split_conformal_fpca_anomalies(
        fit, cal, candidates, alpha = alpha)
      flags <- result$test$is_anomaly
      score <- result$test$score
      if (length(flags) != 2L || anyNA(flags) ||
          any(!is.finite(score)) ||
          any(!is.finite(result$calibration$score)))
        stop("Missing or non-finite conformal scoring outcome.")
      data.frame(
        scenario = scenario, simulation = sim, seed = seed,
        alpha = alpha, n_train = n_train, n_calibration = n_cal,
        n_calibration_independent_subjects =
          if (scenario == "dependent_calibration") {
            ceiling(n_cal / 2)
          } else {
            n_cal
          },
        quantile_rank = result$cutoff$rank,
        threshold = result$cutoff$threshold,
        null_score = score[1L], shifted_score = score[2L],
        null_flag = flags[1L], shifted_flag = flags[2L],
        status = "ok", error = NA_character_,
        stringsAsFactors = FALSE)
    })
  })
}
failure_rows <- function(scenario, sim, seed, message) {
  do.call(rbind, lapply(alphas, function(alpha) data.frame(
    scenario = scenario, simulation = sim, seed = seed,
    alpha = alpha, n_train = n_train, n_calibration = n_cal,
    n_calibration_independent_subjects =
      if (scenario == "dependent_calibration") ceiling(n_cal/2) else n_cal,
    quantile_rank = NA_integer_, threshold = NA_real_,
    null_score = NA_real_, shifted_score = NA_real_,
    null_flag = NA, shifted_flag = NA, status = "failed",
    error = message, stringsAsFactors = FALSE)))
}
rows <- vector("list", reps * length(scenarios))
pos <- 0L
for (j in seq_along(scenarios)) {
  scenario <- scenarios[j]
  cat("Simulating ", scenario, ": ", reps, " independent datasets\n", sep = "")
  for (i in seq_len(reps)) {
    pos <- pos + 1L
    seed <- as.integer(260000L + j * 100000L + i * 31L +
                       seed_offset)
    result <- tryCatch(simulate_once(scenario, i, seed),
                       error = function(e) e)
    rows[[pos]] <- if (inherits(result, "error")) {
      failure_rows(scenario, i, seed, conditionMessage(result))
    } else {
      do.call(rbind, result)
    }
  }
}
trials <- do.call(rbind, rows)
rownames(trials) <- NULL
stopifnot(nrow(trials) == reps * length(scenarios) * length(alphas))
utils::write.csv(trials, file.path(out, "conformal_trials.csv"),
                 row.names = FALSE)
failed <- trials[trials$status != "ok", , drop = FALSE]
failed_file <- file.path(out, "conformal_failures.csv")
if (nrow(failed)) {
  utils::write.csv(failed, failed_file, row.names = FALSE)
} else if (file.exists(failed_file)) {
  unlink(failed_file)
}

# Exact binomial intervals describe finite Monte Carlo precision, not
# uncertainty about a scientific treatment effect or conditional coverage.
summarize_cell <- function(d) {
  success <- d$status == "ok"
  n <- sum(success)
  false_alarms <- sum(d$null_flag[success])
  detections <- sum(d$shifted_flag[success])
  null_rate <- if (n) false_alarms/n else NA_real_
  det_rate <- if (n) detections/n else NA_real_
  exact <- function(k) if (n) {
    as.numeric(stats::binom.test(k, n, conf.level = .95)$conf.int)
  } else {
    c(NA_real_, NA_real_)
  }
  ci_null <- exact(false_alarms)
  ci_det <- exact(detections)
  rank <- ceiling((n_cal + 1) * (1-d$alpha[1L]))
  continuous_exact <- if (rank <= n_cal) {
    (n_cal + 1 - rank)/(n_cal + 1)
  } else {
    0
  }
  is_iid <- identical(d$scenario[1L], "iid_exchangeable")
  data.frame(
    scenario = d$scenario[1L], alpha = d$alpha[1L],
    n_train = n_train, n_calibration = n_cal,
    requested_datasets = nrow(d), successful_datasets = n,
    failed_datasets = nrow(d)-n,
    observed_false_alarms = false_alarms,
    false_alarm_rate = null_rate,
    false_alarm_mc_se = if (n) sqrt(null_rate*(1-null_rate)/n) else NA_real_,
    false_alarm_exact_95_lower = ci_null[1L],
    false_alarm_exact_95_upper = ci_null[2L],
    observed_shifted_detections = detections,
    shifted_detection_rate = det_rate,
    shifted_exact_95_lower = ci_det[1L],
    shifted_exact_95_upper = ci_det[2L],
    continuous_rank_reference = if (is_iid) continuous_exact else NA_real_,
    reference_in_mc_95_ci = if (is_iid && n > 0L) {
      ci_null[1L] <= continuous_exact && continuous_exact <= ci_null[2L]
    } else {
      NA
    },
    deviation_from_rank_reference = if (is_iid && n > 0L) {
      null_rate - continuous_exact
    } else {
      NA_real_
    },
    nominal_alpha = d$alpha[1L],
    mean_threshold = if (n) mean(d$threshold[success]) else NA_real_,
    mean_null_score = if (n) mean(d$null_score[success]) else NA_real_,
    mean_shifted_score = if (n) mean(d$shifted_score[success]) else NA_real_
  )
}
groups <- split(trials,
                interaction(trials$scenario, trials$alpha, drop = TRUE))
summary <- do.call(rbind, lapply(groups, summarize_cell))
rownames(summary) <- NULL
utils::write.csv(summary, file.path(out, "conformal_summary.csv"),
                 row.names = FALSE)

# Pure base R visualization, with confidence intervals and target displayed.
plot_file <- file.path(out, "conformal_monte_carlo_figures.pdf")
grDevices::pdf(plot_file, width = 9, height = 5.8)
plot_error <- NULL
tryCatch({
  for (alpha in alphas) {
    cell <- summary[abs(summary$alpha-alpha) < 1e-12, , drop = FALSE]
    if (!all(is.finite(cell$false_alarm_rate))) next
    loc <- seq_len(nrow(cell))
    labels <- gsub("_", "\n", cell$scenario, fixed = TRUE)
    graphics::plot(loc, cell$false_alarm_rate, ylim = c(0, 1),
                   xlim = c(.7, length(loc)+.3), xaxt = "n",
                   xlab = "Simulation design", ylab = "Observed false-alarm rate",
                   main = sprintf("Frozen FPCA split-conformal: alpha = %.2f", alpha),
                   pch = 19, cex = 1.4, col = "#25638B")
    graphics::axis(1, at = loc, labels = labels, cex.axis = .8)
    graphics::arrows(loc, cell$false_alarm_exact_95_lower,
                     loc, cell$false_alarm_exact_95_upper,
                     angle = 90, code = 3, length = .05)
    graphics::abline(h = alpha, lty = 2L, col = "firebrick", lwd = 2L)
    graphics::mtext("Dashed line: nominal alpha (guaranteed only for exchangeable curves)",
                    side = 1L, line = 4L, cex = .73)
    graphics::plot(loc, cell$shifted_detection_rate, ylim = c(0, 1),
                   xlim = c(.7, length(loc)+.3), xaxt = "n",
                   xlab = "Simulation design",
                   ylab = "Detection frequency (constructed shift)",
                   main = sprintf("Shifted-curve detection: alpha = %.2f", alpha),
                   pch = 19, cex = 1.4, col = "#25638B")
    graphics::axis(1, at = loc, labels = labels, cex.axis = .8)
    graphics::arrows(loc, cell$shifted_exact_95_lower,
                     loc, cell$shifted_exact_95_upper,
                     angle = 90, code = 3, length = .05)
    graphics::mtext("Paired shifted curves; not a general power estimate",
                    side = 1L, line = 4L, cex = .73)
  }
}, error = function(e) plot_error <<- conditionMessage(e),
finally = grDevices::dev.off())
if (!is.null(plot_error))
  writeLines(plot_error, file.path(out, "plot_ERROR.txt"))
git_sha <- tryCatch(system2("git", c("rev-parse", "HEAD"),
                            stdout = TRUE, stderr = FALSE),
                    error = function(e) "unavailable")
if (!length(git_sha)) git_sha <- "unavailable"
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
writeLines(c(
  "RESEARCH ONLY: split-conformal frozen FPCA, failure-inclusive simulations",
  paste("Archive:", normalizePath(out, winslash = "/")),
  "Each execution creates a unique archive; no overwrite of earlier runs.",
  paste("UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Git HEAD:", git_sha[1L]),
  paste("R version:", R.version.string),
  paste("Source package version:",
        unname(read.dcf("DESCRIPTION", fields = "Version")[1L])),
  paste("Independent generated datasets PER SCENARIO:", reps),
  paste("Independent seed offset:", seed_offset),
  "The seed offset should change when running a new independent replication.",
  "The original 2026-10-26 pilot used the default offset zero.",
  paste("Training independent curves:", n_train),
  paste("Calibration curves:", n_cal),
  paste("Alpha values:", paste(alphas, collapse = ",")),
  paste("Base observation noise SD:", base_noise),
  paste("Test-only noise multiplier in shift condition:", test_noise_multiplier),
  paste("Constructed waveform shift:", shift_amplitude),
  "One paired ordinary and deliberately shifted test curve per generated study.",
  "Curves from distinct studies are independent; alpha results are paired.",
  "Primary null: independent identically distributed train/calibration/test.",
  "Test noise shift: breaks calibration/test score exchangeability.",
  "Repeated calibration: latent coefficients shared by ~2 calibration curves",
  "per participant; marginal calibration and test may match but joint exchangeability fails.",
  "Finite sample rank reference only for independent exchangeable no-ties null.",
  "Exact binomial intervals quantify Monte Carlo error among successful fits.",
  "All failed datasets are retained; no false-negative/positive imputation.",
  "Not participant-wise, conditional, simultaneous, or batch-wide coverage.",
  "Not a remedy for separate functional confidence-band undercoverage.",
  "No estimator source changed; do not release based solely on this experiment."
), file.path(out, "MANIFEST.txt"))
print(summary, row.names = FALSE)
cat("Results: ", normalizePath(out, winslash = "/"), "\n", sep = "")
cat("Summary CSV: ",
    normalizePath(file.path(out, "conformal_summary.csv"),
                  winslash = "/", mustWork = TRUE), "\n", sep = "")
cat("Trials CSV: ",
    normalizePath(file.path(out, "conformal_trials.csv"),
                  winslash = "/", mustWork = TRUE), "\n", sep = "")
cat("For the most recent archived results: ",
    "source(\"scripts/read_conformal_results.R\")\n", sep = "")
if (nrow(failed))
  stop("One or more independent conformal simulations failed; inspect ",
       failed_file, call. = FALSE)
if (!is.null(plot_error))
  stop("Monte Carlo results saved but plotting failed: ", plot_error,
       call. = FALSE)
cat("Exploratory conformal Monte Carlo complete; scientific qualification still OPEN.\n")
