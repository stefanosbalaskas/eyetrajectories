#!/usr/bin/env Rscript
# RESEARCH ONLY: independently reconcile a saved MCAR/MAR IPW point pilot.
# All paths are read-only except no outputs (prints PASS/FAIL only).
# Run from repo root:
#   source("scripts/audit_missing_gaze_ipw_pilot.R")
# Optionally set ET_OBS_IPW_AUDIT_DIR to the actual archived run.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from repository checkout.",call.=FALSE)
source("scripts/audit_missing_gaze_ipw_helpers.R",local=TRUE)
root <- file.path("artifacts","missing_gaze_ipw_pilot")
chosen <- Sys.getenv("ET_OBS_IPW_AUDIT_DIR",unset="")
if (!nzchar(chosen)) {
  dirs <- if(dir.exists(root)) list.dirs(root,recursive=FALSE,
                                         full.names=TRUE) else character()
  dirs <- dirs[file.exists(file.path(dirs,"ipw_trials.csv")) &
                 file.exists(file.path(dirs,"ipw_summary.csv"))]
  if(!length(dirs)) stop("No complete IPW study archive.",call.=FALSE)
  chosen <- dirs[order(basename(dirs),decreasing=TRUE)][1L]
}
chosen <- normalizePath(chosen,winslash="/",mustWork=TRUE)
trials <- utils::read.csv(file.path(chosen,"ipw_trials.csv"),
                          stringsAsFactors=FALSE)
summary <- utils::read.csv(file.path(chosen,"ipw_summary.csv"),
                           stringsAsFactors=FALSE)
keys <- c("family","mechanism","n_subjects","simulation",
          "generator_seed","mask_seed","severity","status")
if (!length(trials$family) || !nrow(summary) ||
    !all(keys %in% names(trials)))
  stop("Missing or empty archive keys.",call.=FALSE)
if (anyNA(trials[,keys]) ||
    anyDuplicated(paste(trials$family,trials$mechanism,trials$n_subjects,
                        trials$simulation,sep=":")) ||
    anyDuplicated(c(trials$generator_seed,trials$mask_seed)))
  stop("Invalid study key or duplicate generator/mask seed.",call.=FALSE)
if (!all(trials$mechanism %in%
         c("complete","mcar_gaze","mar_gaze","mar_dropout")) ||
    !all(trials$status %in%
         c("success","no_observation_support","numerical_failure")))
  stop("Undeclared mechanism/status in trial archive.",call.=FALSE)
fields <- c("mean_coordinate_support","observed_fraction",
            "observed_participants","naive_mean_rmse_supported",
            "ht_mean_rmse_supported","naive_contrast_rmse_supported",
            "ht_contrast_rmse_supported","ht_mean_signed_all_grid",
            "ht_contrast_signed_all_grid","ht_mean_rmse_all_grid",
            "ht_contrast_rmse_all_grid")
if (!all(fields %in% names(trials)))
  stop("Missing required point diagnostics.",call.=FALSE)
ok <- trials$status!="numerical_failure"
for(field in c("mean_coordinate_support","observed_fraction")){
  v <- trials[[field]][ok]
  if (anyNA(v)||any(!is.finite(v))||any(v<0|v>1))
    stop("Invalid fraction: ",field,call.=FALSE)
}
for(field in c("ht_mean_signed_all_grid","ht_contrast_signed_all_grid",
               "ht_mean_rmse_all_grid","ht_contrast_rmse_all_grid")){
  if(anyNA(trials[[field]][ok]) ||
     any(!is.finite(trials[[field]][ok])))
    stop("Undefined all-grid HT diagnostic: ",field,call.=FALSE)
}
if(any(trials$status=="success" &
       trials$mean_coordinate_support<1))
  stop("Full-grid success with incomplete minimum-group support.",
       call.=FALSE)
if(any(trials$status=="no_observation_support" &
       trials$mean_coordinate_support>=1))
  stop("Unsupported label with full support.",call.=FALSE)
group <- split(trials,interaction(trials$family,trials$mechanism,
                                  trials$n_subjects,drop=TRUE))
if (length(group)!=nrow(summary))
  stop("Summary condition count mismatches trials.",call.=FALSE)
# The trials name their metric 'observed_fraction'; the archived summary
# correctly names its aggregate 'mean_observed_fraction'. Reconcile using
# explicit named pairs, never a missing data.frame column that returns NULL.
measures <- et_ipw_summary_metric_map
if (!all(names(measures) %in% names(trials)) ||
    !all(unname(measures) %in% names(summary)))
  stop("Trial/summary metric schema mismatch; missing metric columns.",
       call.=FALSE)
for(z in group){
  r <- summary[summary$family==z$family[1L] &
                 summary$mechanism==z$mechanism[1L] &
                 summary$n_subjects==z$n_subjects[1L] &
                 summary$severity==z$severity[1L],,drop=FALSE]
  if(nrow(r)!=1L || r$requested_datasets!=nrow(z) ||
     r$full_grid_supported!=sum(z$status=="success") ||
     r$no_observation_support!=sum(z$status=="no_observation_support") ||
     r$numerical_failures!=sum(z$status=="numerical_failure"))
    stop("Failure-inclusive summary count mismatch.",call.=FALSE)
  k <- sum(z$status=="success")
  ci <- stats::binom.test(k,nrow(z))$conf.int
  if(max(abs(c(r$exact_95_lower,r$exact_95_upper)-ci))>1e-7 ||
     abs(r$support_rate-k/nrow(z))>1e-10)
    stop("Support-rate/MC-interval mismatch.",call.=FALSE)
  for (trial_field in names(measures)) {
    et_ipw_verify_metric(z, r, trial_field,
                         unname(measures[[trial_field]]))
  }
}
if(sum(summary$requested_datasets)!=nrow(trials))
  stop("Some requested datasets absent from summary.",call.=FALSE)
cat("DESIGN-KNOWN IPW ARCHIVE AUDIT PASS\n",
    "Independent studies: ",nrow(trials),"\n",
    "Cells: ",nrow(summary),"\n",
    "Supported: ",sum(trials$status=="success"),"\n",
    "No observation support: ",
    sum(trials$status=="no_observation_support"),"\n",
    "Numerical failures: ",
    sum(trials$status=="numerical_failure"),"\n",
    "No confidence bands or release qualification have been evaluated.\n",
    sep="")
