# Generalized GEE score controls and conditioning

`etr_fit_generalized_function_on_scalar_regression(..., python_boundary_mode = TRUE)`
uses a native implementation of the frozen Python 1.2 working-independence
GEE fitting sequence. The source commit is
`c1cd95ad718327550f7e55393ff38582872f7a94`. The differential used
Statsmodels 0.15.0 and NumPy 2.3.5.

- Spline, scalar and expanded designs use the NumPy matrix-rank threshold
  `max(dim(x)) * .Machine$double.eps * max(svd(x)$d)`.
- The initial GLM uses weighted least squares for up to 100 iterations
  with an absolute deviance tolerance of `1e-8`. The source counts
  perfect-prediction or separation warnings during this fit.
- The requested `maxiter` and `ctol` govern the next GEE phase. It
  updates the coefficients and tests the Euclidean norm of the score
  used for that update. Grouped binomial uses success proportions and
  denominator weights. Poisson exposure enters as log exposure.
- The native robust sandwich uses the fitted independence information
  and whole-participant score contributions. A cross-product of cluster
  influence vectors gives the symmetric, positive-semidefinite sandwich.
  The information solve falls back to a pseudoinverse at numerical singularity.
- The fitted provenance records GLM initialization iterations, GEE
  iterations and the final tested score norm. The participant coefficient
  bootstrap refits use the same solver as the reference fit.

With the default `python_boundary_mode = FALSE`, fitting uses base R
`glm.fit` with its deviance iteration controls. Both modes use native R
numerical kernels. On the tested one-update Poisson fixture, the
source mode and Python converge after GLM initialization and one GEE
update. The default R solver exhausts its one-iteration IRLS limit.

Run the frozen-source comparisons with
`scripts/run_generalized_gee_source_differential.R` and
`scripts/run_generalized_gee_bootstrap_source_differential.R`.
Fixtures include grouped binomial denominators, complete separation,
an exposure-adjusted Poisson predictor scaled by `1e-8`, a numeric
curve-ID predictor, an exact duplicate intercept, a predictor scaled
below the rank threshold, all-zero counts, and a tight score
tolerance with one allowed update. The separated fixture includes
the warning strings and their multiplicity. The retained covariance
and coefficient comparisons specify a scaled absolute tolerance in
the evidence rows.

The native records have R classes and provenance. The Python
`model` attribute is a Statsmodels results wrapper. Its fitted
attributes serve as an oracle for the tested diagnostics. Extreme
ill-conditioning and near-threshold decisions may still depend on
the numerical backend. A direct inverse-information sandwich trial
failed the symmetry check at bootstrap replicate 22 on the Poisson
fixture with predictor scaling `1e-8`, varying exposure and seed
`20261109`. One transposed entry pair differed by `9.72e-7`
near `2210.87`. The native influence cross-product removes that
arithmetic asymmetry. Source covariance rejection due to floating-point
asymmetry can still be backend-sensitive. Warning behavior outside the
tested cases and the complete input and result domains remain open for review.
