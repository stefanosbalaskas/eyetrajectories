# Batch 37: Participant B-spline mixed effects with serial residual covariance

**Scientific target:** A likelihood-fitted Gaussian participant random-function model with independent source curves conditional on random effects. The random functions use an unstructured B-spline coefficient covariance, while *within each source curve* the remaining residual is either AR(1) over index steps or exponentially correlated over physical time. The two sources of dependence are estimated jointly with `nlme::lme`.

`etr_fit_joint_bspline_functional_correlated()` is a new native R function; Batch 35 random-intercept and Batch 36 random-slope functions remain untouched. It provides a real statistical estimator, not a text-only compatibility adapter.

## Distinction from Python 1.2

Pinned source: `src/eyetrajectoriespy/functional_mixed_effects_nested.py`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`. That implementation fits a profiled Gaussian likelihood using a custom covariance backend and supports optional nested trial random functions and participant random slopes. The new native R method supports a participant B-spline random intercept and independently correlated *within-source-curve residuals*, using `nlme` optimizer and R-native S3 output. These are matching bounded Gaussian covariance families, **not proof of identical optimizer behavior, error boundaries, output classes, or 508-contract certification**.

- AR(1): the time grid must be effectively equally spaced, with \(C_{ij}=\rho^{|i-j|}\); negative correlation is permitted.
- Exponential: arbitrary finite strictly increasing grid; \(C_{ij}=\exp(-|t_i-t_j|/\phi)\). `phi` is reported in the original time units, even though the backend uses a scaled time coordinate internally.
- Within each participant, random B-spline effects induce dependence across source curves. Residual correlation **does not** cross curve/trial boundaries.
- Requires optional `nlme`, already declared by Batch 35 in `Suggests`; no new package dependency is added.
- A preliminary iid joint fit is used to validate and reuse the trusted design. The final fit estimates the correlated model, including the residual correlation parameter.
- Fitted Gaussian covariance is \(V=ZGZ^\top+\sigma^2 R\), with `R` block diagonal by source curve. This is independently rebuilt in R tests to check GLS fixed estimates and their covariance.
- No automatic model selection and no unsupported nested-trial or random-slope fallback. For those use explicitly separate methods.

## Verification, counting, and release

The installer only adds one source file, one test file, this document, one Rd file and an `NAMESPACE` export; it does not modify preexisting scientific code or the Python API-gap ledger. Until the user executes RStudio tests, native R convergence is **unverified**. Even after regression tests pass, zero new full-domain certified source contracts are asserted. Commit, both complete qualification modes, and CRAN checks remain separate gates.
