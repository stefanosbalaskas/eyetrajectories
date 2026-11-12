# FDApy 1.0.x fixed-spectrum PACE numerical source-scientific contract

Frozen public source: `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/sparse.py::fit_sparse_fpca_fdapy`.

Upstream source audit: `StevenGolovkine/FDApy`, revision `6626ebc6a70a6496f3058c4abb0bb97f5bdb20be`, `FDApy/preprocessing/dim_reduction/ufpca.py` (`UFPCA.fit`, `transform`, `_transform_pace_irregular`, `_transform_pace_dense`) and `FDApy/representation/functional_data.py::IrregularFunctionalData.smooth`.

## New actual mathematical implementation

The opt-in `etr_fit_sparse_fpca_fdapy(trajectories,dimension,n_components,strict_source_record=TRUE,source_fit_snapshot=...)` computes the **deterministic FDApy PACE score and inverse-reconstruction stage conditional on a real frozen-source fitted UFPCA eigensystem**. It does not import Python. Default historic `backend="fdapace"` is preserved unchanged.

The prefit snapshot must explicitly supply the FDApy already-fitted arrays:

- `mean_grid`: prefit UFPCA mean as a length-m numeric vector on the **exact sorted pooled time grid** of the original irregular sample times
- `eigenfunctions`: k x m numerical matrix of the prefit UFPCA eigenfunctions, respecting actual source component signs and order
- `eigenvalues`: vector of the k source eigenvalues (not recomputed by native R)
- `noise_variance`: prefit `UFPCA._noise_variance` as estimated by the actual source
- `centered_observations`: list of per-curve observed values **already centered by the actual UFPCA preprocessing**, in exactly the original sampled observation time order
- optionally `backend_version`: actual upstream FDApy package version

**Important source correction:** Although the frozen public `fit_sparse_fpca_fdapy` docstring says no common-grid interpolation, the FDApy 1.0.x `_transform_pace_irregular` source actually invokes `data.smooth(method="interpolation")`. That in turn calls `np.interp` on the exact **sorted pooled observed time grid**, with constant endpoint values outside each curve's observed range. Native R therefore uses `stats::approx(...,rule=2)` on the **source-centered irregular values** to reproduce this actual internal operation.

FDApy UFPCA PACE uses the **spectrally reconstructed** covariance matrix, not the earlier raw smoothed covariance operator:

`C = Phi^T diag(lambda) Phi`.

The fixed-source score noise floor is `sigma2 = max(tol, fitted_noise_variance)`, applied **once** as `C + sigma2 I`.

`S = centered_grid pinv(C + sigma2 I) Phi^T diag(lambda)`.

The native Moore-Penrose pseudoinverse applies NumPy's ordinary double-precision relative singular cutoff `1e-15`, and the inverse reconstruction uses `Yhat = S Phi + mean_grid`, without an additional `weights` factor when `normalize=FALSE`.

The resulting typed native R `etr_fdapy_fixed_spectrum_pace_scientific_record` exposes the source-scientific `SparseFPCAResult` fields (`scores`, `eigenvalues`, `dimension`, `curve_ids`, `metadata`, `coordinate_system`, `time_unit`, `n_components`, `fit_method`, `fit_smoothing`, `score_method`, `score_smoothing`, `tolerance`, `normalize`, `provenance`) plus audit values, pooled interpolation matrix, source spectral covariance, noise floor, pseudoinverse and reconstructed R grid. All Python backend instance fields (`backend_object`, `backend_data`, `reconstructed_backend`) are `NULL` and are **not** represented as real FDApy objects.

## Strict qualification and exclusions

The native strict numerical scope accepts only `normalize=FALSE`, integer `1 <= n_components <= n_curves-1`, finite regular per-curve ordered times and the pinned exact pooled grid. `fit_smoothing` may be `PS`, `LP` or `NULL`, and `score_smoothing` `PS` or `LP`; these are **recorded controls**, but their actual smoothing and fitted eigensystem are **provided rather than estimated natively**. The source-normalized, ill-conditioned, arbitrary-smoothing or alternative-mode domains remain outside this deterministic scoring review.

**Not yet implemented:** FDApy `UFPCA.fit` mean PS/LP smoothing, irregular covariance PS/LP smoothing, source trapezoid-weighted eigendecomposition, source variance estimation, optional `kwargs_mean`/`kwargs_covariance`, full `normalize=TRUE`, backend object identity, Python failure modes and independent full source-contract parity.

The review is therefore **only a conditional-source-scoring scientific stage**, NOT a complete native implementation of the public `fit_sparse_fpca_fdapy` estimator. The source fitting stage remains explicitly recorded as open in `inst/extdata/native_scoped_fdapy_submethod_gaps_20261112.csv`.

Tests include exact source equation reconstruction, singular pseudoinverse with SVD cutoff, source pooled interpolation and endpoint semantics, noise floor once-only behavior, a required real prefit snapshot and invalid control rejection. An opt-in test uses the **real FDApy 1.0.3 `_transform_pace_irregular`** with actual `DenseArgvals`, `DenseValues`, `DenseFunctionalData`, `IrregularArgvals`, `IrregularValues` and `IrregularFunctionalData` objects, and the frozen public Python converter, on the same source spectrum, to compare scores, dense interpolation and reconstruction. CI must execute before qualification. These tests do not prove native PS/LP fitting.
