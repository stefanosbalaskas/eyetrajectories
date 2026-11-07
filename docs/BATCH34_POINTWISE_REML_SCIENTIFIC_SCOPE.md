# Batch 34: native Gaussian functional random-intercept REML

This batch advances the **native R scientific method** track. It does not claim
full source parity or close any 508-export Python 1.2 gap.

## Estimand and method

For each observed time point `t` separately, fit

`y_i(t) = x_i^T beta(t) + b_{g(i)}(t) + epsilon_i(t)`;

`Var[b_g(t)] = tau2(t)` and `Var[epsilon_i(t)] = sigma2(t)`, with independent
participants and curves conditional on group intercepts. The one-dimensional
profile-REML search covers the nonnegative variance ratio `lambda=tau2/sigma2`
including the exact zero-variance boundary. The objective includes
`log|X^T W^{-1} X|` and is optimized separately at each time; Sherman-Morrison
identities avoid assembling dense covariance matrices in production code.

## Scientific limitations

- This is **pointwise REML**, not the Python 1.2 jointly optimized B-spline
  functional mixed model with optional random slope, nested trial covariance,
  or within-trial time correlation. No cross-time covariance is estimated.
- The fixed-effect intervals use **normal-Wald pointwise** standard errors;
  they are neither simultaneous nor small-sample adjusted.
- The model requires three or more participants and replication in at least
  one participant. Inference assumes independent participant groups.
- Profile optimization occurs inside user-specified positive variance-ratio
  bounds plus an explicit lambda=0 candidate. `at_search_boundary` identifies
  cases where the selected solution is on a supplied boundary.
- No independent scientific certificate, frozen Python joint-model equivalence,
  or source-gap closure is granted by these tests.

## Validation

The R suite checks fitted output shapes, finite variance components, inverse
reconstruction, exact low-rank vs dense covariance GLS-REML identities at each
estimated variance ratio, and invalid scientific input rejection.

An independently constructed Python NumPy/SciPy oracle checks the profile
objective against dense linear algebra and its optimized values against a
statsmodels Gaussian random-intercept MixedLM REML fit. This is **method-level
numerical validation**, not parity with the package's Python joint B-spline
estimator.

## CRAN

No additional Imports or Suggests packages are required. A release readiness
check should inspect the formal `00check.log` status; this additive batch does
not change the package's `Version` or the historic source-gap ledger.
