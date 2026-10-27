#!/usr/bin/env Rscript
# Research-only, READ-ONLY mechanism-level analysis of an already audited pilot.
# Does not generate data, fit intervals or change the original archive.
# Usage (from repository root):
#   Sys.setenv(ET_OBS_REPORT_DIR="artifacts/missing_gaze_pilot/run_20261027_094753_pid51684")
#   source("scripts/report_missing_gaze_mechanisms.R")
#   Sys.unsetenv("ET_OBS_REPORT_DIR")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories checkout.", call. = FALSE)

root <- file.path("artifacts", "missing_gaze_pilot")
chosen <- Sys.getenv("ET_OBS_REPORT_DIR", unset = "")
if (!nzchar(chosen)) {
  dirs <- if (dir.exists(root)) list.dirs(root, recursive=FALSE,
                                         full.names=TRUE) else character()
  dirs <- dirs[file.exists(file.path(dirs, "missing_gaze_trials.csv")) &
                 file.exists(file.path(dirs, "missing_gaze_summary.csv"))]
  if (!length(dirs)) stop("No completed missing-gaze archive.", call.=FALSE)
  chosen <- dirs[order(basename(dirs), decreasing=TRUE)][1L]
}
chosen <- normalizePath(chosen, winslash="/", mustWork=TRUE)
trials <- utils::read.csv(file.path(chosen,"missing_gaze_trials.csv"),
                          stringsAsFactors=FALSE)
reported <- utils::read.csv(file.path(chosen,"missing_gaze_summary.csv"),
                            stringsAsFactors=FALSE)
required <- c("family","mechanism","n_subjects","simulation",
              "generator_seed","mask_seed","severity","status",
              "observed_participants","observed_fraction",
              "mean_supported_fraction","contrast_supported_fraction",
              "minimum_group_participants_per_coordinate",
              "mean_bias_supported","mean_rmse_supported",
              "contrast_bias_supported","contrast_rmse_supported")
if (!all(required %in% names(trials)))
  stop("Missing columns in trial archive; do not infer unknown metrics.",
       call.=FALSE)
if (!nrow(trials) || !nrow(reported))
  stop("Empty archive.",call.=FALSE)
if (anyDuplicated(paste(trials$family,trials$mechanism,trials$n_subjects,
                        trials$severity,trials$simulation,sep=":")) ||
    anyDuplicated(c(trials$generator_seed,trials$mask_seed)))
  stop("Non-unique study keys/seeds.",call.=FALSE)
if (anyNA(trials$status) ||
    !all(trials$status %in% c("success","no_observation_support",
                              "numerical_failure")))
  stop("Unknown or missing failure status.",call.=FALSE)
# Reconcile row-count/status counts against archived cell summaries again.
keys <- c("family","mechanism","n_subjects","severity")
cells <- split(trials, interaction(trials$family,trials$mechanism,
                                   trials$n_subjects,trials$severity,drop=TRUE))
if (length(cells)!=nrow(reported)) stop("Unexpected cell count.",call.=FALSE)
for (z in cells) {
  r <- reported[reported$family==z$family[1L] &
                reported$mechanism==z$mechanism[1L] &
                reported$n_subjects==z$n_subjects[1L] &
                reported$severity==z$severity[1L], , drop=FALSE]
  if (nrow(r)!=1L || r$requested_datasets!=nrow(z) ||
      r$full_grid_supported!=sum(z$status=="success") ||
      r$no_observation_support!=sum(z$status=="no_observation_support") ||
      r$numerical_failures!=sum(z$status=="numerical_failure"))
    stop("Archive/summary reconciliation failed.",call.=FALSE)
}
safe_mean <- function(x) {
  if (!length(x) || all(is.na(x))) return(NA_real_)
  mean(x,na.rm=TRUE)
}
cell_report <- do.call(rbind, lapply(cells,function(z) {
  k <- sum(z$status=="success")
  n <- nrow(z)
  ci <- stats::binom.test(k,n)$conf.int
  data.frame(family=z$family[1L],mechanism=z$mechanism[1L],
    n_subjects=z$n_subjects[1L],severity=z$severity[1L],
    requested=n,full_grid_supported=k,
    no_observation_support=sum(z$status=="no_observation_support"),
    numerical_failure=sum(z$status=="numerical_failure"),
    support_rate=k/n,support_95_lower=ci[1L],
    support_95_upper=ci[2L],
    mean_observed_fraction=safe_mean(z$observed_fraction),
    mean_participants_observed=safe_mean(z$observed_participants),
    mean_coordinate_support=safe_mean(z$mean_supported_fraction),
    contrast_coordinate_support=safe_mean(z$contrast_supported_fraction),
    mean_min_group_support=safe_mean(
      z$minimum_group_participants_per_coordinate),
    naive_signed_mean_error_supported=safe_mean(z$mean_bias_supported),
    naive_mean_rmse_supported=safe_mean(z$mean_rmse_supported),
    naive_signed_contrast_error_supported=safe_mean(z$contrast_bias_supported),
    naive_contrast_rmse_supported=safe_mean(z$contrast_rmse_supported))
}))
rownames(cell_report) <- NULL
cell_report <- cell_report[order(cell_report$mechanism,
                                 cell_report$n_subjects),]
# Across N=12/24/48: descriptive aggregation only. The exact intervals below
# treat each independently seeded generated dataset as the Bernoulli unit, NOT
# individual gaze points, repeated trials, method comparisons or contrasts.
mechanism_groups <- split(trials,trials$mechanism)
mechanism_report <- do.call(rbind,lapply(mechanism_groups,function(z) {
  n <- nrow(z); k <- sum(z$status=="success")
  ci <- stats::binom.test(k,n)$conf.int
  data.frame(mechanism=z$mechanism[1L],datasets=n,
    supported=k,unsupported=sum(z$status=="no_observation_support"),
    numerical_failure=sum(z$status=="numerical_failure"),
    full_grid_support_rate=k/n,
    exact_95_lower=ci[1L],exact_95_upper=ci[2L],
    mean_observed_fraction=safe_mean(z$observed_fraction),
    mean_contrast_coordinate_support=safe_mean(
      z$contrast_supported_fraction),
    naive_mean_rmse_supported=safe_mean(z$mean_rmse_supported),
    naive_contrast_rmse_supported=safe_mean(z$contrast_rmse_supported))
}))
rownames(mechanism_report) <- NULL
mechanism_report <- mechanism_report[order(mechanism_report$mechanism),]
if (sum(mechanism_report$datasets)!=nrow(trials) ||
    sum(mechanism_report$unsupported)!=
      sum(trials$status=="no_observation_support"))
  stop("Mechanism totals do not reconcile.",call.=FALSE)
# Save only a new non-overwriting analysis directory; source archive untouched.
dest_root <- file.path("artifacts","missing_gaze_mechanism_report")
dest <- file.path(dest_root,paste0("audit_",
  format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if (dir.exists(dest)) stop("Refuse to overwrite prior audit.",call.=FALSE)
dir.create(dest,recursive=TRUE,showWarnings=FALSE)
if (!dir.exists(dest)) stop("Unable to create audit output.",call.=FALSE)
utils::write.csv(cell_report,file.path(dest,"by_mechanism_N.csv"),
                 row.names=FALSE,na="")
utils::write.csv(mechanism_report,file.path(dest,"by_mechanism.csv"),
                 row.names=FALSE,na="")
writeLines(c(
  "Missing-gaze mechanism audit — READ ONLY, NOT band calibration",
  paste("source_archive:",chosen),
  paste("reported_trials:",nrow(trials)),
  paste("supported:",sum(trials$status=="success")),
  paste("unsupported:",sum(trials$status=="no_observation_support")),
  paste("numerical_failures:",sum(trials$status=="numerical_failure")),
  "CI unit: independent generated datasets; descriptive across N.",
  "RMSE and signed error: supported coordinates only, conditional-on-support.",
  "Do not infer bias correction or nominal coverage from these summaries.",
  "No original archive, estimator or CRAN release was modified."
),file.path(dest,"README.txt"))
cat("MISSING-GAZE MECHANISM AUDIT PASS\n",
    "Source archive: ",chosen,"\n",
    "Output (new, not overwritten): ",normalizePath(dest,winslash="/"),"\n",
    "Datasets: ",nrow(trials),"\n",
    "Supported: ",sum(trials$status=="success"),"\n",
    "Unsupported: ",sum(trials$status=="no_observation_support"),"\n",
    "Numerical failures: ",sum(trials$status=="numerical_failure"),"\n",
    sep="")
print(mechanism_report[,c("mechanism","datasets","supported",
  "unsupported","full_grid_support_rate","exact_95_lower",
  "exact_95_upper","mean_observed_fraction",
  "mean_contrast_coordinate_support")],row.names=FALSE)
cat("Supported-coordinate RMSE is diagnostic, not a calibrated interval.\n")
