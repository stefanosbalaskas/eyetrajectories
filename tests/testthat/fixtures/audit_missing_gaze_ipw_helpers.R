# Research-only helpers for reconciling IPW trial and summary metrics.
# Pure validation functions: do not read/write archives or use RNG.
et_ipw_summary_metric_map <- c(
  mean_coordinate_support="mean_coordinate_support",
  observed_fraction="mean_observed_fraction",
  naive_mean_rmse_supported="naive_mean_rmse_supported",
  ht_mean_rmse_supported="ht_mean_rmse_supported",
  naive_contrast_rmse_supported="naive_contrast_rmse_supported",
  ht_contrast_rmse_supported="ht_contrast_rmse_supported",
  ht_mean_signed_all_grid="ht_mean_signed_all_grid",
  ht_contrast_signed_all_grid="ht_contrast_signed_all_grid",
  ht_mean_rmse_all_grid="ht_mean_rmse_all_grid",
  ht_contrast_rmse_all_grid="ht_contrast_rmse_all_grid"
)

et_ipw_verify_metric <- function(trial_group, summary_row,
                                 trial_field, summary_field,
                                 tolerance=1e-9) {
  if (!is.data.frame(trial_group) || !nrow(trial_group) ||
      !is.data.frame(summary_row) || nrow(summary_row)!=1L)
    stop("Expected a nonempty trial group and one summary row.",
         call.=FALSE)
  if (!trial_field %in% names(trial_group))
    stop("Missing trial metric: ",trial_field,call.=FALSE)
  if (!summary_field %in% names(summary_row))
    stop("Missing summary metric: ",summary_field,call.=FALSE)
  vals <- trial_group[[trial_field]]
  actual <- summary_row[[summary_field]]
  if (!is.numeric(vals) || length(actual)!=1L ||
      (!is.numeric(actual) && !(is.logical(actual) && is.na(actual))))
    stop("Invalid metric type/dimension: ",trial_field,
         " -> ",summary_field,call.=FALSE)
  if (any(is.infinite(vals) | is.nan(vals)) ||
      is.infinite(actual) || is.nan(actual))
    stop("Nonfinite metric: ",trial_field,call.=FALSE)
  expected <- if (all(is.na(vals))) NA_real_ else mean(vals,na.rm=TRUE)
  if (is.na(expected) != is.na(actual) ||
      (!is.na(expected) && abs(expected-actual)>tolerance))
    stop("Metric mismatch: ",trial_field," -> ",summary_field,
         call.=FALSE)
  invisible(TRUE)
}
