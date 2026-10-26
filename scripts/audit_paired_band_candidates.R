#!/usr/bin/env Rscript
# Read-only paired Monte Carlo audit of the research interval comparison.
# Preserves all source outputs; never modifies package estimators.
# Pull research/native-parity-stage1, then:
#   source("scripts/audit_paired_band_candidates.R")
# Optionally set ET_BAND_COMPARE_AUDIT_DIR to a specific archived run.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L]) != "eyetrajectories") {
  stop("Run from the eyetrajectories repository checkout.",call.=FALSE)
}
root <- file.path("artifacts","band_interval_comparison")
chosen <- Sys.getenv("ET_BAND_COMPARE_AUDIT_DIR",unset="")
if (!nzchar(chosen)) {
  dirs <- if (dir.exists(root)) {
    list.dirs(root,recursive=FALSE,full.names=TRUE)
  } else {
    character()
  }
  dirs <- dirs[grepl("^run_[0-9]{8}_[0-9]{6}_pid[0-9]+$",basename(dirs))]
  dirs <- dirs[file.exists(file.path(dirs,"interval_comparison_trials.csv")) &
               file.exists(file.path(dirs,"interval_comparison_summary.csv"))]
  if (!length(dirs)) stop("No complete candidate comparison archive.",call.=FALSE)
  chosen <- dirs[order(basename(dirs),decreasing=TRUE)][1L]
}
chosen <- normalizePath(chosen,winslash="/",mustWork=TRUE)
trials <- utils::read.csv(file.path(chosen,"interval_comparison_trials.csv"),
                          stringsAsFactors=FALSE)
reported <- utils::read.csv(file.path(chosen,"interval_comparison_summary.csv"),
                            stringsAsFactors=FALSE)
required <- c("n_subjects","simulation","generator_seed","estimand","method",
              "success","simultaneous_covered","average_pointwise_coverage",
              "mean_simultaneous_width","error")
if (!all(required %in% names(trials))) {
  stop("Trial archive lacks required audit columns.",call.=FALSE)
}
if (!all(c("n_subjects","estimand","method","requested_datasets",
           "successful_fits","failed_fits","covered",
           "simultaneous_rate","avg_simultaneous_width") %in% names(reported))) {
  stop("Summary archive lacks required audit columns.",call.=FALSE)
}
baseline <- "existing_fixed_se_bootstrap"
candidates <- c("studentized_cluster_bootstrap","gaussian_bonferroni_t")
methods <- c(baseline,candidates)
estimands <- c("participant_mean","two_group_null_contrast")
if (!identical(sort(unique(trials$method)),sort(methods)) ||
    !identical(sort(unique(trials$estimand)),sort(estimands))) {
  stop("Unexpected method/estimand coverage; inspect source archive.",
       call.=FALSE)
}
study_key <- paste(trials$n_subjects,trials$simulation,sep=":")
pair_key <- paste(study_key,trials$estimand,trials$method,sep=":")
if (anyDuplicated(pair_key)) {
  stop("Duplicated method evaluations on the same generating dataset.",
       call.=FALSE)
}
study_groups <- split(trials,study_key)
for (key in names(study_groups)) {
  z <- study_groups[[key]]
  if (nrow(z)!=length(methods)*length(estimands) ||
      length(unique(z$generator_seed))!=1L) {
    stop("Incomplete or nonpaired generating-study records: ",key,
         call.=FALSE)
  }
}
# The archived six-cell summaries must reconstruct exactly from the trials.
archive_cells <- split(trials,interaction(trials$n_subjects,
                                          trials$estimand,trials$method,
                                          drop=TRUE))
if (length(archive_cells)!=nrow(reported)) {
  stop("Number of trial/summary cells differs.",call.=FALSE)
}
for (z in archive_cells) {
  sm <- reported[reported$n_subjects==z$n_subjects[1L] &
      reported$estimand==z$estimand[1L] &
      reported$method==z$method[1L],,drop=FALSE]
  if (nrow(sm)!=1L) stop("Missing/duplicate summary cell.",call.=FALSE)
  ok <- z$success
  if (anyNA(ok)) stop("Undefined fit statuses in archive.",call.=FALSE)
  n <- sum(ok)
  if (nrow(z)!=sm$requested_datasets ||
      n!=sm$successful_fits ||
      sum(!ok)!=sm$failed_fits ||
      sum(z$simultaneous_covered[ok])!=sm$covered) {
    stop("Counts do not reproduce the archived summary.",call.=FALSE)
  }
  if (n && (abs(mean(z$simultaneous_covered[ok])-
                 sm$simultaneous_rate)>1e-10 ||
            abs(mean(z$mean_simultaneous_width[ok])-
                 sm$avg_simultaneous_width)>1e-9)) {
    stop("Rates or width means differ from archived summary.",call.=FALSE)
  }
}
# Use a fresh, explicit seed for uncertainty in derived Monte Carlo
# comparisons. Restore the owner's RNG state on function exit.
rng_scoped <- function(seed,operation) {
  had <- exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  if (had) old <- get(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed",old,envir=.GlobalEnv)
    } else if (exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)) {
      rm(".Random.seed",envir=.GlobalEnv)
    }
  },add=TRUE)
  set.seed(seed)
  operation()
}
comparison_rows <- list()
index <- 0L
for (n in sort(unique(trials$n_subjects))) {
  for (estimand in estimands) {
    source <- trials[trials$n_subjects==n &
                     trials$estimand==estimand,,drop=FALSE]
    b <- source[source$method==baseline,
                c("simulation","generator_seed","success",
                  "simultaneous_covered","mean_simultaneous_width"),
                drop=FALSE]
    for (candidate in candidates) {
      z <- source[source$method==candidate,
                  c("simulation","generator_seed","success",
                    "simultaneous_covered","mean_simultaneous_width"),
                  drop=FALSE]
      paired <- merge(b,z,by=c("simulation","generator_seed"),
                      suffixes=c("_base","_candidate"),
                      sort=TRUE,all=TRUE)
      valid <- with(paired,success_base & success_candidate)
      valid[is.na(valid)] <- FALSE
      p <- paired[valid,,drop=FALSE]
      m <- nrow(p)
      if (m>0L) {
        original <- as.logical(p$simultaneous_covered_base)
        proposed <- as.logical(p$simultaneous_covered_candidate)
        newly_covered <- sum(!original & proposed)
        lost_covered <- sum(original & !proposed)
        discord <- newly_covered+lost_covered
        sign_p <- if (discord>0L) {
          stats::binom.test(newly_covered,discord,p=.5)$p.value
        } else {
          1
        }
        rate_diff <- mean(as.integer(proposed)-as.integer(original))
        width_ratio <- mean(p$mean_simultaneous_width_candidate)/
                       mean(p$mean_simultaneous_width_base)
        boot <- rng_scoped(as.integer(78000000L+n+match(estimand,estimands)*10L+
                                     match(candidate,candidates)),function(){
          draws <- replicate(2000L,{
            ix <- sample.int(m,m,replace=TRUE)
            c(gain=mean(as.integer(proposed[ix])-as.integer(original[ix])),
              ratio=mean(p$mean_simultaneous_width_candidate[ix])/
                    mean(p$mean_simultaneous_width_base[ix]))
          })
          rbind(
            stats::quantile(draws["gain",],c(.025,.975),names=FALSE),
            stats::quantile(draws["ratio",],c(.025,.975),names=FALSE))
        })
      } else {
        newly_covered <- lost_covered <- discord <- 0L
        sign_p <- rate_diff <- width_ratio <- NA_real_
        boot <- matrix(NA_real_,2L,2L)
      }
      index <- index+1L
      comparison_rows[[index]] <- data.frame(
        n_subjects=n,estimand=estimand,candidate=candidate,
        recorded_datasets=nrow(paired),both_successful=m,
        paired_failed_or_missing=nrow(paired)-m,
        baseline_coverage_rate=if(m)mean(original) else NA_real_,
        candidate_coverage_rate=if(m)mean(proposed) else NA_real_,
        coverage_gain_pp=100*rate_diff,
        gain_pp_boot_95_lower=100*boot[1L,1L],
        gain_pp_boot_95_upper=100*boot[1L,2L],
        baseline_missed_candidate_covered=newly_covered,
        baseline_covered_candidate_missed=lost_covered,
        exact_discordant_sign_p=sign_p,
        width_ratio=width_ratio,
        width_ratio_boot_95_lower=boot[2L,1L],
        width_ratio_boot_95_upper=boot[2L,2L])
    }
  }
}
paired_summary <- do.call(rbind,comparison_rows)
rownames(paired_summary) <- NULL
audit_root <- file.path("artifacts","band_interval_comparison_audit")
out <- file.path(audit_root,paste0("audit_",
  format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if (dir.exists(out)) stop("Same-name audit archive exists.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
utils::write.csv(paired_summary,
  file.path(out,"paired_candidate_comparisons.csv"),row.names=FALSE)
writeLines(c(
  "RESEARCH-ONLY PAIRED COMPARISON OF ARCHIVED BAND CANDIDATES",
  paste("Source archive:",chosen),
  paste("Output:",normalizePath(out,winslash="/")),
  paste("Archive trial rows:",nrow(trials)),
  paste("Unique generating studies:",length(study_groups)),
  "Paired gain = candidate coverage minus baseline coverage (percentage points).",
  "Width ratio = average candidate band width / average baseline band width.",
  "Uncertainty: 2000 paired Monte Carlo bootstrap resamples per condition.",
  "Exact sign p-values are descriptive discordance tests, not multiplicity adjusted.",
  "Six estimand-by-N comparisons and two candidate families are exploratory.",
  "Only jointly successful fits inform paired effects; failures counted separately.",
  "The candidate methods are NOT scientifically certified by this audit."
),file.path(out,"MANIFEST.txt"))
cat("Source archive: ",chosen,"\n",sep="")
cat("Output: ",normalizePath(out,winslash="/"),"\n",sep="")
cat("Archive summary/trial consistency: PASS\n")
print(paired_summary,row.names=FALSE)
cat("Paired read-only audit finished. No estimator or source trial modified.\n")
