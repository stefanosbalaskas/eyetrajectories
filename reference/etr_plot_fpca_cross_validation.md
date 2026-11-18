# Native held-out FPCA reconstruction cross-validation source errorbar geometry

Uses the actual native fold-level cross-validation result and native
fold-level standard-error summary. This is descriptive held-out
reconstruction error, not a validated model-selection claim or an
inferential confidence interval. Source Matplotlib marker `"o"` and
capsize 3 and scientific arrays are retained; Python rendering backend
and Axes runtime identity are not.

## Usage

``` r
etr_plot_fpca_cross_validation(
    result, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Actual native FPCA reconstruction cross-validation result with
  observed fold errors by retained number of principal components.

- strict_source_record:

  Return original held-out reconstruction-error mean, fold-level
  standard error, matched lower/upper limits and frozen Python 1.2
  source errorbar marker and capsize in native R scientific geometry.
  Not a live Matplotlib `Axes`.

- ...:

  Additional base-R drawing arguments.

## Value

Default invisible component-wise held-out reconstruction RMSE summary.
Strict mode returns native one-panel source-scientific errorbar artist
metadata with exact component counts, means, SEs, and errorbar
endpoints.
