# Native scikit-fda Fourier and B-spline basis projection source contract

Frozen eyetrajectoriespy public oracle: `eyetrajectoriespy==1.2.0` at `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/backends.py::to_skfda_basis`.

Mathematical backend source inspected: GAA-UAM/scikit-fda Git commit `9e21b2a0bf7674ebea906851f48883c3f4c0c375`, `skfda/representation/grid.py::FDataGrid.to_basis`, `skfda/preprocessing/smoothing/_basis.py::BasisSmoother`, `skfda/representation/basis/_bspline_basis.py::BSplineBasis` and `_fourier_basis.py::FourierBasis`. CI targets a real version-pinned scikit-fda installation and the frozen public eyetrajectoriespy function.

## Key scientific correction

The Python source `grid.to_basis(basis_object)` uses `BasisSmoother(return_basis=True)` with sampled **unweighted least squares**. It does **not** use an independent continuous-integral projection as previously suspected. Given the source basis design matrix `Phi[t,j]` and observed data `Y[i,t]`, the estimand is:

`C = argmin_C ||Y - C Phi^T||_F^2`; equivalently for full-rank `Phi`, `C^T = (Phi^T Phi)^-1 Phi^T Y^T`.

The native strict mode solves the same *sampled LS* mathematical problem using `qr.solve(Phi, t(Y))` (full-rank QR). It is not smoothing, penalized regression, interpolation, time quadrature, or an independent change to the scientific estimand. Source scikit-fda defaults may use an SVD solver; numerical differences at nearly rank-deficient designs are excluded from this bounded contract.

## Fourier basis

The scikit-fda basis contains an orthonormal constant `1/sqrt(T)`, followed by alternating `sqrt(2/T) sin(2 pi k t/T)` and `sqrt(2/T) cos(2 pi k t/T)` for `k>=1`, where `T=tmax-tmin`. The basis evaluates the actual physical observation times `t`, not a recentered phase. **An even requested `n_basis` is increased by one** inside `FourierBasis`; the Python source result's `n_basis` field nevertheless records the original requested value. Strict R now preserves both, including exact coefficient matrix width.

## B-spline basis

The source `BSplineBasis(domain_range=(tmin,tmax), n_basis=n_basis, order=order)` uses `n_basis-order+2` equally spaced base knot positions including endpoints, and an additional `order-1` repeated copies of each endpoint for the evaluation-knot sequence. R `splines::splineDesign` is used with the same knot sequence. Because the endpoint-inclusion convention differs from scipy's `BSpline` right boundary, the final row is set to the last basis function (1); all other final-row basis entries are zero. The design has exactly `n_basis` columns.

## Native interface and return

`etr_to_skfda_basis(trajectories, dimension, basis="bspline", n_basis=15L, order=4L, strict_source_record=TRUE)` returns `etr_skfda_basis_scientific_record`. It includes exact source basis values on the observed grid, coefficients, reconstructed observations, full-rank source geometry and a native R list of the frozen `BasisProjectionResult` scientific fields, with explicit `backend_object=NULL`. The provenance stores the source `backend="scikit-fda"`, family, requested basis count and order (NULL for Fourier). Input observations are never modified.

The legacy `strict_source_record=FALSE` native R basis continues unchanged, including its historical non-normalized Fourier convention.

## Limits and independent verification

The strict mode requires complete finite input and **at least as many sample times as actual basis functions**, and rejects rank-deficient bases. These are deliberate full-rank numerical qualification bounds. Source scikit-fda has broader or distinct handling of underspecified/underdetermined cases, its real `FDataBasis` Python instance, arbitrary optional backend acceptance, exceptions and equality semantics. The R list and QR solver are not a replacement for those objects.

A native R regression suite verifies normalized basis values, even-to-odd expansion, B-spline endpoint and knots, exact coefficient recovery, legacy invariance, original observation immutability and exclusion domains. An opt-in Python test calls the **real** `eyetrajectoriespy==1.2.0` public `to_skfda_basis` function and compares actual real scikit-fda `FDataBasis` evaluated basis values, coefficients, reconstruction and requested vs expanded basis counts.

The tests are **authored** at this stage; until exact-head CI executes successfully, runtime numerical/source parity is not witnessed. This represents **provisional scoped author-reviewed source scientific projection**, not independent full Python object/domain certification or CRAN release readiness.
