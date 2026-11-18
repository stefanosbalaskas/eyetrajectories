# Plot actual within-trial functional mixed residual semivariance

Plots observed one-half mean squared within-trial residual differences
at each retained index lag. The native source stores exact mean/min/max
physical separations and does not silently aggregate an unrequested
trial or participant. The nonuniform-lag warning title and raw/whitened
residual scale follow frozen Python 1.2 scientific rendering semantics.

## Usage

``` r
etr_plot_functional_mixed_effects_residual_variogram(
    result, level = "overall", curve_id = NULL,
    participant_id = NULL, strict_source_record = FALSE)
```

## Arguments

- result:

  Native already-computed residual diagnostic scientific record. Strict
  mode requires genuine native Gaussian spline joint-likelihood
  provenance.

- level:

  Trial, participant or overall summary level.

- curve_id:

  Explicit curve for trial summary.

- participant_id:

  Explicit participant for participant summary.

- strict_source_record:

  Return source-ordered one-panel scientific line and axes geometry
  instead of default numerical R return. Does not construct Matplotlib
  Axes.

## Value

Physical-lag semivariance geometry for native Gaussian residual
diagnostics.
