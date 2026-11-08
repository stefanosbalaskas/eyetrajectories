# Batch 38 — Nested participant/trial functional random intercepts

Pinned Python scientific reference: `eyetrajectoriespy` 1.2.0,
`src/eyetrajectoriespy/functional_mixed_effects_nested.py`, frozen commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.

## Implemented

`etr_fit_joint_bspline_functional_nested_trial()` is a **native-R** Gaussian
joint model using `nlme::lme` with a clamped B-spline fixed-effects design and
independent **unstructured participant and trial coefficient covariance**
matrices. The nested trial random intercept is a *function*, not a scalar
nuisance intercept. Trials are nested within participants, and each
participant/trial pair has one complete observed source curve, as required by
the frozen Python 0.48/0.49 one-curve-per-trial contract.

Three residual families are explicit: independent, discrete index-step AR(1)
(requires equally spaced time), and exponential physical-time correlation (on
irregular grids). Residual correlations never bridge source trials. Marginal
covariances and posterior random-effect coefficients are reconstructed from
participant and trial covariance components using Gaussian block GLS/BLUP
algebra. The fitted random-effect covariances are estimated jointly by nlme;
zero covariances *between* participant and trial random effects are part of the
hierarchical model, not a simplification inside either unstructured block.

## Boundaries

- This is a **different optimizer, parameterization, convergence path, error
  contract, and returned object** from Python's SciPy profiled-likelihood
  estimator. Numerical equality on every source domain is not claimed.
- The function does not support random functional slopes or extra crossed
  effects in the *same* nested fit; these remain separate native estimators.
- Distinct participants must have >=2 trials; every participant/trial pair must
  be unique. Complete common-grid trajectories are required.
- This batch adds a native estimator and scientific numerical tests. It closes
  **zero** of the recorded 204 Python source-gap exports; independent full-
  domain certifications remain **0/508**.

## Direct scientific checks

The R suite independently constructs each participant's marginal covariance

\[
V_g = Z_{pg}G_p Z_{pg}^{\mathsf T} +
\sum_{t\in g} Z_{tg}G_tZ_{tg}^{\mathsf T} + R_g,
\]

with `R_g` block diagonal across observed curves. It recomputes marginal GLS
fixed coefficients and covariance, tests nested BLUP reconstructions, and
rejects duplicated trial identifiers, invalid grouping and irregular AR(1)
grids. Python offline reference tests validate the same covariance algebra,
but do not execute the native R model.

## Verification sequence

1. Guarded install and complete targeted R tests.
2. Commit exact paths listed in `README.md`.
3. Run `scripts/capture_native_source_qualification_evidence.R` in both modes.
4. Run `scripts/run_batch32_cran_gate.R` and inspect the actual `00check.log`.
