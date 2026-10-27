#!/usr/bin/env Rscript
# Research-only, read-only paired scientific analysis of the ALREADY SAVED
# 240-study design-known IPW archive. Does NOT rerun simulations or fit bands.
# From the repository root:
#   Sys.setenv(ET_OBS_IPW_AUDIT_DIR =
#     "artifacts/missing_gaze_ipw_pilot/run_20261027_103444_pid51684")
#   source("scripts/analyze_missing_gaze_ipw_results.R")
#   Sys.unsetenv("ET_OBS_IPW_AUDIT_DIR")
#
# Independent generating dataset = Monte Carlo unit. Within a dataset
# the naive and known-design HT point estimates are paired, not replicated.
# All analysis is exploratory (20 replicates/cell); no 90% coverage claim.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from the eyetrajectories repository checkout.",call.=FALSE)

# Reuse and re-run the independent, read-only audit on the selected archive.
# Audit's trials/summary/chosen live in the current source environment.
source("scripts/audit_missing_gaze_ipw_pilot.R",local=TRUE)
source("scripts/analyze_missing_gaze_ipw_helpers.R",local=TRUE)
if (!exists("trials",inherits=FALSE) || !exists("chosen",inherits=FALSE) ||
    !exists("summary",inherits=FALSE))
  stop("Saved archive audit did not expose reconciled input.",call.=FALSE)
if (sum(summary$requested_datasets)!=nrow(trials))
  stop("Audited archive no longer reconciles.",call.=FALSE)

B <- 1999L
group_key <- interaction(trials$family,trials$mechanism,
                         trials$n_subjects,trials$severity,drop=TRUE)
cells <- split(trials,group_key)
if (length(cells)!=nrow(summary))
  stop("Unexpected number of independent generating-study cells.",
       call.=FALSE)
orders <- order(vapply(cells,function(z) z$family[1L],character(1)),
                vapply(cells,function(z) z$mechanism[1L],character(1)),
                vapply(cells,function(z) z$n_subjects[1L],numeric(1)))
cells <- cells[orders]
paired_results <- vector("list",length(cells)*4L)
all_grid_results <- vector("list",length(cells)*2L)
k <- 0L; g <- 0L

for (i in seq_along(cells)) {
  z <- cells[[i]]
  labels <- z[1L,c("family","mechanism","n_subjects","severity"),
              drop=FALSE]
  for (estimand in c("mean","contrast")) {
    for (selection in c("available_coordinates","full_grid_only")) {
      k <- k+1L
      comparison <- et_ipw_paired_accuracy(
        z,estimand,selection,
        bootstrap_seed=as.integer(1900000000L+100L*i+3L*k),
        B=B)
      paired_results[[k]] <- cbind(labels,comparison)
    }
    # The HT Horvitz-Thompson estimator has an explicit entire-grid
    # definition on every generated dataset, even without full sample
    # support. Do not incorrectly restrict this diagnostic to successes.
    g <- g+1L
    rmse_field <- paste0("ht_",estimand,"_rmse_all_grid")
    signed_field <- paste0("ht_",estimand,"_signed_all_grid")
    if (!all(c(rmse_field,signed_field) %in% names(z)))
      stop("Absent all-grid HT result fields.",call.=FALSE)
    valid <- z$status!="numerical_failure"
    if (anyNA(z[[rmse_field]][valid]) ||
        anyNA(z[[signed_field]][valid]) ||
        any(!is.finite(z[[rmse_field]][valid])) ||
        any(!is.finite(z[[signed_field]][valid])))
      stop("Missing all-grid values among numerically valid studies.",
           call.=FALSE)
    if (any(z[[rmse_field]][valid]<0))
      stop("Negative entire-grid RMSE.",call.=FALSE)
    err <- z[[signed_field]][valid]
    estimate <- if(length(err)) mean(err) else NA_real_
    ci <- c(NA_real_,NA_real_)
    if(length(err)>=2L) {
      draws <- et_ipw_resample_seed(
        as.integer(1910000000L+100L*i+3L*g),
        function() replicate(B,mean(
          err[sample.int(length(err),length(err),replace=TRUE)])))
      ci <- as.numeric(stats::quantile(draws,c(.025,.975),
                                       names=FALSE,type=1))
    }
    all_grid_results[[g]] <- cbind(labels,data.frame(
      estimand=estimand,requested_datasets=nrow(z),
      observed_all_grid_results=sum(valid),
      unsupported_full_grid=sum(z$status=="no_observation_support"),
      numerical_failures=sum(z$status=="numerical_failure"),
      ht_mean_signed_error_all_grid=estimate,
      ht_signed_error_lower_95=ci[1L],
      ht_signed_error_upper_95=ci[2L],
      ht_mean_per_dataset_rmse_all_grid=if(any(valid))
        mean(z[[rmse_field]][valid]) else NA_real_
    ))
  }
}
paired_report <- do.call(rbind,paired_results)
all_grid_report <- do.call(rbind,all_grid_results)
rownames(paired_report) <- NULL
rownames(all_grid_report) <- NULL

# Every requested independent dataset contributes to four declared cells:
# two estimands x two analysis sets. No individual gaze point is counted as
# independent Monte Carlo replication.
if (nrow(paired_report)!=length(cells)*4L ||
    nrow(all_grid_report)!=length(cells)*2L ||
    sum(paired_report$requested_datasets)!=4L*nrow(trials) ||
    sum(all_grid_report$requested_datasets)!=2L*nrow(trials))
  stop("Reporting denominator reconciliation failed.",call.=FALSE)
if (any(paired_report$paired_datasets >
        paired_report$eligible_datasets) ||
    any(paired_report$eligible_datasets >
        paired_report$requested_datasets))
  stop("Invalid paired comparison denominator.",call.=FALSE)

root <- file.path("artifacts","missing_gaze_ipw_pair_analysis")
out <- file.path(root,paste0("review_",
   format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),
   "_pid",Sys.getpid()))
if(dir.exists(out)) stop("Refusing to overwrite prior analysis.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
if(!dir.exists(out)) stop("Could not create analysis output.",call.=FALSE)
utils::write.csv(paired_report,file.path(out,"paired_rmse_by_cell.csv"),
                 row.names=FALSE,na="")
utils::write.csv(all_grid_report,file.path(out,"ht_all_grid_by_cell.csv"),
                 row.names=FALSE,na="")
writeLines(c(
  "Exploratory known-design IPW point comparison (not interval calibration)",
  paste("source_archive:",chosen),
  paste("independent_datasets:",nrow(trials)),
  paste("independent_condition_cells:",length(cells)),
  paste("bootstrap_draws_per_cell:",B),
  "Bias = mean signed error across generated datasets; cancellation is possible.",
  "RMSE: average *within-dataset functional RMSE*, not pooled coordinate RMSE.",
  "Paired difference = HT RMSE minus naive RMSE, negative favors HT.",
  "Paired bootstrap resamples INDEPENDENT datasets; 95% percentile MC CI.",
  "available_coordinates: both methods on identical common-supported cells;",
  "  may retain datasets marked no_observation_support for partial support.",
  "full_grid_only: only datasets with >=2 observed participants per group",
  "  at EVERY time/channel coordinate; conditional success selection.",
  "ht_all_grid: unconditional-grid HT point errors across all numerically",
  "  valid datasets, including those with no observation at some coordinates.",
  "All-grid HT diagnostics have no comparable all-grid naive estimate.",
  "Across-mask mechanisms are independent studies, NOT paired comparisons.",
  "Monte Carlo n=20/cell; directional results are exploratory only.",
  "No confidence bands, nominal coverage, estimator replacement or release."
),file.path(out,"manifest.txt"))

cat("IPW PAIRED ESTIMATION ANALYSIS COMPLETE (RESEARCH ONLY)\n",
  "Source: ",chosen,"\n",
  "Output: ",normalizePath(out,winslash="/"),"\n",
  "Independent datasets: ",nrow(trials),"\n",
  "Paired comparison rows: ",nrow(paired_report),"\n",
  "All-grid HT rows: ",nrow(all_grid_report),"\n",
  "Full-grid-supported: ",sum(trials$status=="success"),"\n",
  "No support: ",sum(trials$status=="no_observation_support"),"\n",
  "Numerical failures: ",sum(trials$status=="numerical_failure"),"\n",
  sep="")
print(paired_report[
  paired_report$subset=="full_grid_only",
  c("mechanism","n_subjects","estimand","paired_datasets",
    "naive_mean_functional_rmse","ht_mean_functional_rmse",
    "mean_paired_rmse_difference","paired_difference_lower_95",
    "paired_difference_upper_95","ht_naive_mean_rmse_ratio")
],row.names=FALSE)
cat("All-grid HT signed-error/bias summaries are separately saved;",
    " no inferential band coverage evaluated.\n")
