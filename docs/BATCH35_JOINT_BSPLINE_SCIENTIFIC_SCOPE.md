# Batch 35 — Basic joint functional B-spline mixed model

Frozen source reference: `eyetrajectoriespy` 1.2.0, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`, file
`src/eyetrajectoriespy/functional_mixed_effects.py`.

## What is new

`etr_fit_joint_bspline_functional_mixed_effects()` fits **one joint model over
all observed time points**, not separate regressions at each time point:

\[
 y_{igt}=\sum_{j=0}^p x_{igj}\sum_{k=1}^{K_f} B_{fk}(t)\beta_{jk}
     +\sum_{h=1}^{K_r}B_{rh}(t)b_{gh}+\varepsilon_{igt},
 \quad b_g\sim N(0,G),\ \varepsilon_{igt}\sim N(0,\sigma^2).
\]

The participant random-effect coefficient covariance **G is unstructured**,
not a scalar diagonal restriction. The implementation fits it with `nlme::lme`
in the R ecosystem. Fixed effects are B-spline coefficient functions,
with pointwise Wald standard errors. The optimization is deterministic;
no Python bridge or random-state manipulation is needed.

## Supported scope

- Strictly increasing common time grid, complete finite observations.
- One explicitly selected numeric response dimension.
- Numeric, finite, full-rank curve-level fixed covariates and functional intercept.
- Participant-level random-intercept function, `nlme::pdSymm` unstructured
  covariance of B-spline coefficients, independent Gaussian residual errors.
- ML and REML, positive-variance result, participant BLUP functions and
  pointwise fixed-coefficient Wald intervals.
- Equally spaced clamped interior knots on the observed time range, as in the
  pinned Python `_bspline_basis` implementation; no adaptive quantile knots.

## Not supported / do not claim

This does **not** implement the frozen Python API's random slopes, nested
trial-level effects, AR(1), physical-time exponential residual correlation,
its exact `statsmodels.MixedLM` optimizer trajectories or Python typed result
objects. Those remain genuine unclosed source-contract differences.

The comparison test uses a small deterministic synthetic fixture and an
independent dense Gaussian GLS calculation. Other optimizers can produce
slightly different variance components even for the same likelihood model.
This is a new native scientific implementation, **not** an independent
full-domain certificate or an automatic closure in the 204-row source ledger.

`nlme` is a recommended R package but is optional for `eyetrajectories`;
it is listed in `Suggests`. The spline basis relies on `splines`, declared
in `Imports`.

## Interpretation

These are observational joint model outputs, not causally identified effects.
Participant-level random effects condition on the fitted model; fixed-effect
confidence bands are **pointwise**, not simultaneous and do not substitute
for independent-unit bootstrap inference.
