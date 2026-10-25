# Phase 2 — Native R core (qualification pending)

The 38 exported etr_* functions run in R with **no Python interpreter**.
The prior Phase 1 et_* reticulate bridge remains available for features
that have not yet been ported.

## Scientific scope

| Area | Native API | Status |
|---|---|---|
| Trajectories | 7 functions | Common-grid only; strictly defined arrays and identifiers |
| Preprocessing | 6 functions | Explicit interpolation, missing-gap policy, time and coordinate transformations |
| Kinematics | 7 functions | Edge-aware derivatives and sampled planar geometry |
| Distances | 5 functions | Weighted integrated L2, discrete Fréchet, symmetric1 DTW |
| Dense FPCA/MFPCA | 7 functions | Quadrature weighted SVD; optional dimension_sd |
| Recurrence | 3 functions | Dense fixed-radius recurrence and basic line RQA |
| Visualizations | 3 functions | Base graphics, not matplotlib |

## Cross-language reference

- Fixture: tests/testthat/fixtures/python_1_2_0_math_reference.csv
- Python upstream check: scripts/check_python_native_reference.py
- R regression suite: tests/testthat/test-native-core.R

The frozen CSV contains analytically tractable targets for the exact mathematical
contracts of Python 1.2.0. It is deliberately **sign invariant** for PCA.
The separate Python script checks the target values by executing the published
`eyetrajectoriespy==1.2.0` package; it is not a substitute for that
execution to simply compare algebraic identities. **Do not claim upstream
Python parity verified until that CI job actually passes.**

No automated parity coverage exists yet for the entire 38-function surface.
Cross-language validation is **initial and narrow**; the rest of the native
functions have native unit tests or require further qualification.

## Scope limitations

1. Dense common-grid FPCA only; no native PACE or sparse/asynchronous joint FPCA.
2. Recurrent matrices are dense O(T^2) and have no memory guard in Phase 2.
3. Fixed Euclidean radius and sample-based Theiler window only.
4. No inferential calibration claims for RQA, mixed-effects uncertainty or W3.
5. No claim of full API parity; only the selected 38 independent native functions.
6. Scientific comparisons use eigenvalues, reconstruction and score Gram matrices,
   not arbitrary eigenvector signs.
7. The underlying Python 1.2.0 backend remains optional and scientifically
   qualified only to its published scope.

## CI gates for promotion

- Offline R CMD check and full testthat suite.
- Python 3.12 installed pinned backend verifying fixture with a second process.
- Controlled R↔Python parity on deterministic scenarios and edge cases.
- Memory/runtime stress for long recurrence paths.
- Windows/macOS + Linux R-version matrix.
- Documentation generated/checked, CRAN policy review and formal release decision.

Not ready to merge, publish, or submit to CRAN without these checks.
