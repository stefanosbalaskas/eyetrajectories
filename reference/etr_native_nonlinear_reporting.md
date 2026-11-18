# Python-free nonlinear scientific reporting

Independent R reporting and source-oriented structured-result adapters
for published eyetrajectoriespy 1.2.0 nonlinear outputs. These functions
do not run nonlinear estimators or import Python.

## Usage

``` r
etr_joint_recurrence_reporting_text(result, metrics = NULL)
etr_recurrence_network_reporting_text(result)
etr_recurrence_radius_profile_reporting_text(result)
etr_rqa_reporting_text(recurrence, metrics)
etr_rqa_metric_mean_bootstrap_reporting_text(result)
etr_windowed_rqa_reporting_text(result)
etr_windowed_rqa_functional_reporting_text(result)
etr_windowed_rqa_sensitivity_reporting_text(result)
etr_windowed_rqa_mean_band_reporting_text(result)
etr_rqa_parameter_sensitivity_reporting_text(result)
etr_kantz_parameter_sensitivity_reporting_text(result)
etr_lyapunov_parameter_sensitivity_reporting_text(result)
etr_largest_lyapunov_reporting_text(result)
etr_surrogate_nonlinearity_reporting_text(result)
etr_return_map_stability_reporting_text(fit, result)
```

## Arguments

- result:

  A compatible native nonlinear-result object, or a fully specified R
  result structure with the fields required by the selected report.

- metrics:

  Optional explicit RQA line metrics for joint recurrence or required
  RQA metrics for basic RQA reporting.

- recurrence:

  Native R recurrence result whose radius, metric and Theiler
  specification are recorded.

- fit:

  Explicit local return-map fit carrying declared neighborhood and
  source provenance.

## Value

A single descriptive character string; no fitted estimator, new
uncertainty interval, or automatic inference is produced.

## Details

Reports require declared source information, including recurrence
radius, line thresholds, window or bootstrap unit definitions, where
applicable. Some report-only source schemas have no native estimator
yet. No reporting statement should be taken as source-contract
certification, causal coupling, deterministic chaos, or inferential
validity.
