# Unregistered SRVF FPCA or genuine native R elastic Karcher shape FPCA

The opt-in mathematical-source R path performs genuine nonidentity
elastic phase alignment of multivariate open curves through SRVF Karcher
mean, dynamic-programming time warping and tangent-geodesic shape PCA.
It reports fitted warps, aligned coordinates, PCA scores, a
ten-deformation principal-direction array, and mean curve in the same
scientific axis ordering as frozen Python 1.2 `fit_elastic_fpca`. The
unchanged default still returns the historical
unregistered/identity-warp native FPCA alternative.

## Usage

``` r
etr_fit_elastic_fpca(trajectories, n_components = 3L,
  rotation = FALSE, scale_curves = FALSE, lam = 0,
  method = "identity_only", strict_source_record = FALSE)
```

## Arguments

- trajectories:

  A complete finite numeric common-grid `etr_trajectory_set` with at
  least two measured dimensions. The native R elastic source requires at
  least three curves and five observation times.

- n_components:

  Positive integer number of principal directions. In native R elastic
  source mode, this cannot exceed `n_curves - 1`.

- rotation:

  Boolean. Source-scientific mode optionally aligns rigid rotations in
  true SRVF shape space. Legacy identity mode requires `FALSE`.

- scale_curves:

  Boolean. Source-scientific mode optionally normalizes SRVF curve shape
  scale. Legacy mode requires `FALSE`.

- lam:

  Nonnegative finite elastic reparameterization penalty; the legacy
  identity mode requires zero.

- method:

  `"identity_only"` by default, preserving the original native
  unregistered SRVF result. To perform genuine elastic source-
  scientific Karcher dynamic programming, explicitly specify
  `method="DP"` and `strict_source_record=TRUE`. R native mode does not
  implement Python `RBFGS`.

- strict_source_record:

  Boolean. `FALSE` returns historical native unregistered SRVF
  functional principal components with identity warping. `TRUE` calls
  the independent genuine native R `fdasrvf` (\>= 2.5.1) library for
  Karcher SRVF registration and geodesic tangent-space shape PCA, with
  no Python backend.

## Value

With default parameters, an `etr_unregistered_srvf_fpca` native R
scientific alternative retaining identity warping. With
`strict_source_record=TRUE, method="DP"`, a typed
`etr_native_elastic_karcher_pca_scientific_record` with `aligned` native
trajectory (curves x times x channels), `warping_functions` (curves x
times), `scores` (curves x components), `principal_directions` (channels
x times x components x 10), `mean_curve` (channels x times),
source-scientific provenance, and actual R `fdacurve` and `curve_pca`
under `native_backend_object` and `native_pca_object`.
`backend_object=NULL` deliberately does NOT fabricate a Python
`fdasrsf.fdacurve`.

## Details

The source-scientific native R algorithm uses the genuine `fdasrvf`
package, which is optional. This is NOT a numerical clone of Python
`fdasrsf`: Python starts Karcher iterations from the first curve and
executes a separate `srvf_align`, whereas the independent modern native
R implementation starts at a medoid and returns already aligned
reconstructions. The scientific SRVF/elastic-Karcher/geodesic-PCA
objective is implemented, but exact DP warps, eigenvector signs, backend
class identity, Python exceptions and optional RBFGS behavior remain
uncertified. See
`docs/native-elastic-fdasrvf-karcher-source-20261113.md` and
`inst/extdata/native_scoped_elastic_submethod_gaps_20261113.csv`.
