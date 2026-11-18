# Scientific sparse FPCA and multivariate PACE diagnostics in native R graphics

Plot the native sparse univariate and planar multivariate FPCA fitted
population objects and original irregular observations, retaining
scientific coordinate values from the frozen Python 1.2 source. No
estimator is refit.

## Plotting parameters

- result:

  Explicit native R-list fitted sparse FPCA or MFPCA record with grid,
  covariance, eigenfunctions, uncertainty and dimensions.

- component:

  Zero-based integer index of a retained component.

- sd_multiplier:

  Strictly positive multiple of the fitted component standard deviation
  used for the mean-plus/minus perturbation.

- source:

  One of `"used"` (fitted PSD-qualified covariance) or `"smoothed"`
  (pre-repair smoothing output).

- trajectories:

  Native irregular-trajectory R-list with per-curve times and observed
  coordinate matrices.

- dimension:

  Explicit dimension identifier from trajectories.

## Value

Base R plots on the active graphics device. In each case the
source-ordered numerical plot geometry is returned invisibly; unlike the
published Python 1.2 functions, no Matplotlib Axes object is returned.

## Details

Covariance heatmaps retain original directional XY and YX blocks,
component indices are zero-based as in Python, and values are not
automatically interpolated. Input, rendering and backend object
differences are documented source-contract gaps, not independently
certified one-to-one parity. Source: published eyetrajectoriespy 1.2.0,
pinned commit c1cd95ad718327550f7e55393ff38582872f7a94.
