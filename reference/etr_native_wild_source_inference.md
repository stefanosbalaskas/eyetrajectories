# Native FPCA wild-bootstrap truncation selection and inference audit tables

One independent native selection algorithm and four source-aligned
read-only inference frames from published eyetrajectoriespy 1.2.0. The
stabilized-volatility selector requires `stability_run + 1` consecutive
stable width and center transitions and picks the earliest candidate
starting such a run for each fixed target. There is no fallback to a
largest candidate or automatic calibration.

## Usage

``` r
etr_select_fpca_wild_bootstrap_truncation(
  scan, width_threshold, center_threshold, stability_run,
  on_failure = "error"
)
etr_fpca_wild_bootstrap_projection_frame(result)
etr_fpca_wild_bootstrap_simultaneous_frame(result)
etr_fpca_wild_bootstrap_family_test_frame(result)
etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame(result)
```

## Arguments

- scan:

  Explicit R record of an already computed wild-bootstrap truncation
  scan with candidate components, target curve IDs and
  candidate-by-target center, width and interval-bound matrices.

- width_threshold:

  Strictly positive width transition threshold, including a finite
  decimal-text scalar.

- center_threshold:

  Strictly positive center transition threshold, including a finite
  decimal-text scalar.

- stability_run:

  Nonnegative whole-number r, requiring r+1 successive stable candidate
  transitions.

- on_failure:

  Whether targets with no qualifying run trigger an error, warning or
  ignored missing selection.

- result:

  Source-aligned realized projection, simultaneous interval,
  fixed-family test or Monte Carlo precision diagnostic record.

## Details

Published Python eyetrajectoriespy 1.2.0 source: `wild_selection.py`,
`wild_regression.py`, `wild_simultaneous.py` and `wild_testing.py`,
pinned at `c1cd95ad718327550f7e55393ff38582872f7a94`.

The selector preserves zero-based chosen candidate index in the result.
Target-specific missing selections use `NaN`, not an unreported
fallback. The four audit frames preserve the fixed-target row order,
family-adjusted p values, simultaneous interval bounds, and Monte
Carlo-sensitive decisions; they do not generate or re-estimate bootstrap
quantities. R named-list inputs and R data frame returns are not
equivalent to the Python frozen dataclass and pandas source types. This
boundary remains a documented unresolved full-contract gap.

## Value

Selection returns an explicit R record containing transition matrices,
selected source indices, selected values and provenance. Reporting
functions return native R data frames. No Python runtime is invoked.
