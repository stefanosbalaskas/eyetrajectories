# Source known-truth univariate sparse FPCA recovery

Compares fitted modes with simulation truth on the exact grid.
Covariance error uses the directly estimated covariance. Score errors
use finite paired scores and reconstruction error uses finite whole
curves.

## Usage

``` r
etr_evaluate_sparse_fpca_recovery(result, truth)
```

## Arguments

- result:

  Source-shaped fitted univariate sparse FPCA/PACE with retained
  functional components and an estimated covariance matrix.

- truth:

  Frozen functional simulator truth including latent source curves and
  measurement-noise covariance.

## Value

Source-shaped population recovery values, optional score diagnostics,
PSD repair metrics, measurement-noise error and explicit provenance.
