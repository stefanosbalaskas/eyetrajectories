# Pure, research-only dataset-paired comparison helpers.
# No gaze imputation, interval estimation or released estimator changes.
et_ipw_resample_seed <- function(seed, operation) {
  if (length(seed)!=1L || is.na(seed) || !is.finite(seed) ||
      seed!=as.integer(seed) || seed<1L)
    stop("Invalid resampling seed.",call.=FALSE)
  existed <- exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  if (existed) previous <- get(".Random.seed",envir=.GlobalEnv,
                                inherits=FALSE)
  on.exit({
    if (existed) assign(".Random.seed",previous,envir=.GlobalEnv)
    else if (exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
      rm(".Random.seed",envir=.GlobalEnv)
  },add=TRUE)
  set.seed(as.integer(seed))
  operation()
}

et_ipw_paired_accuracy <- function(z, estimand, subset_label,
                                    bootstrap_seed, B=1999L) {
  if (!estimand %in% c("mean","contrast"))
    stop("Unknown scientific estimand.",call.=FALSE)
  if (!subset_label %in% c("available_coordinates","full_grid_only"))
    stop("Unknown support restriction.",call.=FALSE)
  if (!is.data.frame(z) || !nrow(z))
    stop("Expected nonempty independent-study cell.",call.=FALSE)
  if (length(B)!=1L || is.na(B) || B!=as.integer(B) || B<49L)
    stop("B must be an integer >=49.",call.=FALSE)
  fields <- c("generator_seed","mask_seed","status",
    paste0("naive_",estimand,"_rmse_supported"),
    paste0("ht_",estimand,"_rmse_supported"),
    paste0("naive_",estimand,"_signed_supported"),
    paste0("ht_",estimand,"_signed_supported"))
  if (!all(fields %in% names(z)))
    stop("Missing paired study fields: ",
         paste(setdiff(fields,names(z)),collapse=", "),call.=FALSE)
  if (anyDuplicated(z$generator_seed) || anyDuplicated(z$mask_seed) ||
      anyNA(z[,c("generator_seed","mask_seed","status")]))
    stop("Duplicate seed or missing study key.",call.=FALSE)
  if (!all(z$status %in%
           c("success","no_observation_support","numerical_failure")))
    stop("Unexpected study status.",call.=FALSE)
  n_requested <- nrow(z)
  failures <- sum(z$status=="numerical_failure")
  unsupported <- sum(z$status=="no_observation_support")
  eligible <- z$status!="numerical_failure"
  if (subset_label=="full_grid_only") eligible <- z$status=="success"
  na_rmse <- z[[paste0("naive_",estimand,"_rmse_supported")]]
  ht_rmse <- z[[paste0("ht_",estimand,"_rmse_supported")]]
  na_signed <- z[[paste0("naive_",estimand,"_signed_supported")]]
  ht_signed <- z[[paste0("ht_",estimand,"_signed_supported")]]
  paired <- eligible & is.finite(na_rmse) & is.finite(ht_rmse) &
    is.finite(na_signed) & is.finite(ht_signed)
  n_eligible <- sum(eligible)
  n_paired <- sum(paired)
  if (any(na_rmse[paired]<0 | ht_rmse[paired]<0))
    stop("Negative RMSE.",call.=FALSE)
  base <- data.frame(estimand=estimand,subset=subset_label,
    requested_datasets=n_requested,numerical_failures=failures,
    unsupported_full_grid=unsupported,
    eligible_datasets=n_eligible,paired_datasets=n_paired,
    excluded_from_pair=n_requested-n_paired,
    naive_mean_functional_rmse=NA_real_,
    ht_mean_functional_rmse=NA_real_,mean_paired_rmse_difference=NA_real_,
    paired_difference_lower_95=NA_real_,
    paired_difference_upper_95=NA_real_,
    ht_naive_mean_rmse_ratio=NA_real_,
    ratio_lower_95=NA_real_,ratio_upper_95=NA_real_,
    ht_better_dataset_fraction=NA_real_,
    naive_mean_signed_error=NA_real_,
    ht_mean_signed_error=NA_real_,
    mean_signed_error_difference=NA_real_,
    stringsAsFactors=FALSE)
  if (!n_paired) return(base)
  a <- na_rmse[paired]; b <- ht_rmse[paired]
  signed_a <- na_signed[paired]; signed_b <- ht_signed[paired]
  delta <- b-a
  base$naive_mean_functional_rmse <- mean(a)
  base$ht_mean_functional_rmse <- mean(b)
  base$mean_paired_rmse_difference <- mean(delta)
  base$ht_naive_mean_rmse_ratio <- if(mean(a)>0) mean(b)/mean(a) else NA_real_
  base$ht_better_dataset_fraction <- mean(delta < -1e-12)
  base$naive_mean_signed_error <- mean(signed_a)
  base$ht_mean_signed_error <- mean(signed_b)
  base$mean_signed_error_difference <- mean(signed_b-signed_a)
  # Bootstrap independent generating studies, keeping naive/HT jointly
  # sampled. No resampling of participants, trials or gaze time cells.
  if (n_paired>=2L) {
    boot <- et_ipw_resample_seed(bootstrap_seed,function() {
      replicate(as.integer(B),{
        idx <- sample.int(n_paired,n_paired,replace=TRUE)
        ba <- mean(a[idx]); bb <- mean(b[idx])
        c(diff=mean(delta[idx]),
          ratio=if(ba>0) bb/ba else NA_real_)
      })
    })
    ci <- stats::quantile(boot["diff",],c(.025,.975),names=FALSE,
                          na.rm=FALSE,type=1)
    base$paired_difference_lower_95 <- ci[1L]
    base$paired_difference_upper_95 <- ci[2L]
    ratios <- boot["ratio",]
    if (all(is.finite(ratios))) {
      q <- stats::quantile(ratios,c(.025,.975),names=FALSE,type=1)
      base$ratio_lower_95 <- q[1L]
      base$ratio_upper_95 <- q[2L]
    }
  }
  base
}
