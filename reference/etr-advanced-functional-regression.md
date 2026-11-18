# Experimental Phase 3 R methods: advanced functional regression

Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated
inference.

## Usage

``` r
etr_fit_functional_mixed(
  x,
  participant = NULL,
  method = "REML",
  basis_k = 10L
)

etr_functional_mixed_fitted(
  fit
)

etr_fit_scalar_on_fpca(
  fit,
  outcome,
  n_components = NULL,
  family = "gaussian",
  covariates = NULL,
  python_boundary_mode = FALSE
)

etr_predict_scalar_on_fpca(
  fit,
  x,
  covariates = NULL
)
```

## Arguments

- x:

  A native trajectory object, sparse collection, numeric sequence, or
  validated diagnostic according to the function.

- participant:

  Participant identifiers by curve, or a metadata-column name.

- method:

  Declared estimation, binning, or smoothing method.

- basis_k:

  Spline basis dimension for the smooth functional intercept.

- fit:

  A fitted native R model result of the expected class.

- outcome:

  Finite numeric outcome for each curve.

- n_components:

  Fixed number of native FPCA components. In Python source mode, Boolean
  TRUE may select one score, while floating-point slice indices are
  deliberately disallowed.

- family:

  Gaussian linear or binomial logistic family. The binomial source
  analogue requires explicit Python source-compatibility mode.

- covariates:

  Optional curve-aligned finite numeric data.frame. Accepted only in
  explicit source mode and required for external predictions from a
  model fitted with covariates.

- python_boundary_mode:

  Logical, FALSE preserves the previous Gaussian-only native fit. TRUE
  enables the bounded Python 1.2 Gaussian/binomial and covariate source
  contract without invoking Python or certifying whole-domain
  equivalence.

## Details

These methods have explicitly limited scientific scope. Sparse
estimation uses fdapace when requested; functional mixed models use
optional refund. Marginal sparse fits do not estimate joint
cross-channel covariance. Cluster bootstrap resamples participants, not
trials. Transfer entropy describes discrete predictive information, not
causality, and its diagnostic p-values are not generally calibrated. See
docs/phase3-expansion-methods.md for independent simulation contracts.

## Value

A typed native model, diagnostic, Monte Carlo audit, or base R plot;
returned components are documented in the Phase 3 methods article.
