# Native methods: mathematical implementation and interpretive limits

**Development version:** eyetrajectories 0.2.0.9000, Phase 2. All functions
prefixed etr_* operate in pure R. The Python-backed et_* methods remain
separate. These are a selected implementation surface, not a full translation
of the 380 Python public API functions.

## Continuous gaze representation

For n curves, M common observation times, and D channels, values form a
numeric array of shape n × M × D. Coordinate and time semantics are
explicit. Missing measurements are NA, never zero. Duplicate timestamps,
different time grids, or implicit extrapolation are rejected. Interpolation,
gap repair and smoothing are distinct opt-in calls.

## Quadrature-weighted FPCA

Let G_i(t_m) be curve i at time t_m. For trapezoidal weights w_m,
mean mu(t_m), and optional channel scale s_d, define

\[
Z_{i,m,d}=(G_{i,d}(t_m)-\hat{\mu}_d(t_m))\sqrt{w_m}/s_d.
\]

The native algorithm performs an SVD of Z flattened in the
time-then-channel order. Variances are squared singular values divided
by (n-1). The optional dimension_sd channel scales use population
mean-integrated variance (matching the Python 1.2.0 contract).
The fit rejects missing observations and constant-total-variance input.

FPCA eigenvector signs are not identified: parity comparisons must use
eigenvalues, reconstructed curves and score Gram matrices, not unaligned
signed loadings. No sparse PACE, uncertainty bands, or conditional
inference are part of the native Phase 2 FPCA implementation.

## Distances and kinematics

Integrated L2 is the quadrature-weighted Euclidean difference over
matching sample grids. Discrete Fréchet uses the monotone minimum-max
coupling of ordered points; DTW uses symmetric1 local-cost accumulation
without default normalization. Neither discrete distance uses recorded
timestamps, resampling, or coordinate standardization.

Velocity uses three-point nonuniform-grid numerical derivatives with
second-order endpoint rules. Acceleration differentiates twice.
Path length is the sum of Euclidean increments, not a continuous-speed
integral. Tortuosity is path length / end-to-end distance; zero
displacement is undefined (NA).

## Basic recurrence and RQA

Auto recurrence uses Euclidean distances <= an explicit fixed radius,
excluding self recurrence and all lags <= the sample-based Theiler
window. Recurrence rates use eligible unordered off-diagonal pairs.
Determinism is computed from qualifying upper-triangle diagonal
runs. Laminarity is computed from qualifying vertical runs over all
recurrence points. No automatic target-radius tuning, cross-lag
rescaling, interval estimates or long-record sparse implementation
is included.

Dense recurrence is limited to 2,500 samples per curve and dense
cross-recurrence and DTW/Fréchet dynamic-programming calculations have
explicit limits of approximately five million cells. Larger data
should use an appropriate sparse or chunked backend and require
separate performance qualification.

## Validation evidence

- R: tests/testthat/test-native-core.R
- Frozen mathematical targets: tests/testthat/fixtures/python_1_2_0_math_reference.csv
- Actual Python package check: scripts/check_python_native_reference.py
- Boundaries and delivery gates: docs/native-phase2.md

These tests make the basic mathematical contracts falsifiable.
Until successful CI runs, **do not describe Python parity, R CMD check
or scientific qualification as passed**.

## Related prior implementation guidance

- [Published Python project and scientific contracts](https://github.com/stefanosbalaskas/eyetrajectoriespy)
- [R multivariate FPCA package](https://github.com/ClaraHapp/MFPCA)
- [R Journal: recurrence quantification with crqa](https://journal.r-project.org/articles/RJ-2021-062/)
- [testthat numerical comparisons](https://testthat.r-lib.org/reference/expect_snapshot_value.html)
- [reticulate optional Python requirements](https://rstudio.github.io/reticulate/articles/python_packages.html)

The other R packages are methodological references, not source-code
dependencies for the native Phase 2 methods.
