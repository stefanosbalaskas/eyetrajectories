# Frozen Python 1.2: complex NumPy coercion and nonfinite source arithmetic

Source pinned to `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`:
- `src/eyetrajectoriespy/fpca.py::functional_trapezoid_weights`
- `src/eyetrajectoriespy/analysis.py::functional_l2_distance`.

## Exact Python scientific code paths

The weight function first uses `np.asarray(time, dtype=float)`,
validates increasing time, then applies `if normalize:`.
In NumPy 2.3.5, a complex **ndarray** cast to a real dtype discards its
imaginary part with a `ComplexWarning`, while a Python *list of
complex scalar objects* fails the float cast. Python `bool(complex)`
is FALSE only when both components are zero, and TRUE for NaN/Inf
complex components, including signed-zero/nonfinite combinations.

The published integrated functional L2 estimator casts two point
matrices with `np.asarray(...,dtype=float)`, validates same 2D shape
and rejects `np.isnan` on point matrices; it **does not** reject
infinite point values. It uses the above time weights and optional
dimension weights converted through `np.asarray(dtype=float)`. Source
weight validation checks shape and negativity only, so positive Inf
and NaN weights flow into arithmetic (which may yield Inf or NaN).

## New bounded, opt-in native behavior

Both functions retain strict, finite native R behavior by default.
With `python_boundary_mode=TRUE`:

1. `etr_trapezoid_weights` accepts a complex atomic time vector,
   retains real coordinates only, and validates their strict monotonicity.
   Nonfinite complex normalization flags now follow Python truthiness;
   complex lists remain rejected, as they are not a NumPy complex ndarray.
2. `etr_l2_distance` accepts complex 2D point matrices and complex
   1D weights by converting to their real values, accepts +Inf/-Inf
   coordinates where source Python does, and rejects missing/NaN
   point coordinates. It now passes `python_boundary_mode` through
   to quadrature time weighting, thus supporting source complex time
   grids. Finite numerical calculations use unchanged L2 quadrature.
3. Source dimension weights may be Inf or explicitly NaN; negative
   values are still rejected. These may produce legitimate Inf/NaN
   source results. R `NA_real_` weights remain excluded because R
   missing-value provenance differs from explicit NumPy NaN.

The native source domain remains intentionally narrower than all Python
and SciPy input classes. Actual Python warnings, error exception classes
and arbitrary Python objects are not represented by native R.

## Source checks (request execution before integration)

- `tests/testthat/test-native-trapezoid-complex-source.R`:
  native strict/default and complex opt-in; Python 1.2 direct
  NumPy ndarray comparisons and nonfinite complex Boolean flags.
- `tests/testthat/test-native-functional-l2-complex-source.R`:
  complex curves, imaginary time/weight casting, Inf trajectories,
  NaN from Inf - Inf, NaN/Inf weights, zero-dimensional channel matrices;
  direct Python source export comparisons.
- Both new suites registered in required offline and
  `python_1_2_direct_source` qualification modes; source implementation,
  tests, manual and this document added to integrity manifest.

The first-party experiments performed against NumPy 2.3.5 found a
complex ndarray casting to real data with a warning, but a complex
Python list scalar sequence raising TypeError. The user-side R and
actual pinned Python 1.2 source tests have **not** yet been run at
this feature SHA.

No recorded source-gap row may be closed, and **0/508 independently
certified** remains unchanged until full-domain evidence is reviewed and
signed by a genuinely independent third party. This work only extends
specific Python source-boundary numerical cases.
