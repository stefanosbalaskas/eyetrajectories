# Plot joint-PACE score conditioning and explicit failed/nonfinite cases

Plots the real per-curve joint-PACE system condition number against
paired native observations, preserving explicit failure states. A
missing/NaN/Inf condition creates the source's empty-marker legend
representation and is not silently treated as a successful finite solve;
all-nonfinite and empty sources are plotted without raising on absent
finite points. Python runtime plotting object identity remains
unimplemented.

## Usage

``` r
etr_plot_sparse_mfpca_score_diagnostics(
    result, strict_source_record = FALSE)
```

## Arguments

- result:

  Genuine native sparse multivariate fitted PACE result containing
  `score_diagnostics` with `n_time_points`, `condition_number` and
  `status_code`.

- strict_source_record:

  If TRUE, return native source-scientific Matplotlib scatter-artist
  data for finite successful, finite flagged and non-finite failed
  observations. No Python `Axes` object is returned.

## Value

Invisible finite diagnostics and counts in default mode; a
source-scientific one-panel native R scatter-geometry record with finite
and nonfinite source collections in strict mode.
