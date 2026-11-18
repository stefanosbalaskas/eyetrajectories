# Plot direct-source conformal FPCA marginal anomaly p-values

Frozen Python eyetrajectoriespy 1.2.0 source-scientific plot geometry,
while preserving original native R scientific estimators and default
base R return values.

## Usage

``` r
etr_plot_conformal_fpca_anomaly(result, max_targets = 50L,
  strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Default mode accepts a native split-conformal calibration/test score
  record and reconstructs conservative p-values. Strict source mode
  instead requires an explicit source-shaped list with target_curve_ids,
  original marginal p_values and alpha, optionally review_flags.

- max_targets:

  Positive integer maximum number of displayed target trajectories;
  strict mode requires an R integer matching the Python domain.

- strict_source_record:

  TRUE selects direct frozen Python p-values, never recomputing them
  from calibration scores, and returns a typed R scatter/reference
  source artist with rotated source target labels and alpha legend.

- ...:

  Additional legacy base R plotting options.

## Value

Default invisible original native conservative score-calibrated p-value
data frame. Strict mode accepts explicit source p-values only, displays
the original ordered scatter and alpha cutoff on \[0,1\], and returns
typed native scientific artist geometry; marginal interpretation only.
No Python Matplotlib Axes object, source p-values fabricated from
scores, independent full contract or calibration-conditional guarantee.

## Details

Bounded native source-scientific artist parity only: no Python dataclass
or pandas runtime protocol, injected Axes identity, pixel rendering
equivalence, exception subclass identity, exact-head executable
qualification or independent full-source contract certification.
