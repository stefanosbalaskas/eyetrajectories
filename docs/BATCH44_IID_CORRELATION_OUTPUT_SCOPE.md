# Batch 44 — native IID residual-correlation output contract

Pinned source: Python `eyetrajectoriespy` **1.2.0**, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/functional_mixed_effects.py`. Python explicitly returns `residual_correlation_matrix = np.eye(n_time)` for IID residuals.

## Exactly what changes

Two already-qualified native estimators now return `residual_correlation_matrix = diag(1, n_time)` in their existing S3 lists:

- `etr_fit_joint_bspline_functional_mixed_effects()` (participant random intercept; IID)
- `etr_fit_joint_bspline_functional_random_slope()` (participant intercept and slope; IID)

The additional matrix is dimension `n_time × n_time`, symmetric positive definite, exactly 1 on the diagonal and zero elsewhere, with no time labels. Its presence does **not** change `nlme::lme` model fitting, optimizer control, design, likelihood, variance components, fixed/random coefficients, fitted values, or residuals. There is no added parameter to be estimated.

Two existing Rd manuals gain the return-field description; one R test file is added. No `NAMESPACE`, other source modules, Python code, or reviewer ledgers change. The installer enforces the exact Batch 39 commit and normalized-original SHA256 of the four existing files and refuses conflicting modifications. Original bytes are backed up under ignored `artifacts/` before patching.

## Evidence and limitations

The audited two missing Python fields were identified in Batch 41 as `IID_MATRIX_NOT_EXPORTED_BUT_PYTHON_IDENTITY`. This patch targets that **output-schema discrepancy only**. It does not close source-scientific discrepancies or establish independent full-contract certification. The two earlier missing fields should be retested on identical data after native installation and full qualification. R/CRAN verification must be run in the user's own R environment.
