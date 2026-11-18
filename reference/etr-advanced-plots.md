# Experimental Phase 3 R methods: advanced plots

Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated
inference.

## Usage

``` r
etr_plot_functional_band(
  fit,
  dimension = 1L,
  interval = c("simultaneous", "pointwise"),
  ...
)

etr_plot_sparse_support(
  diagnostic,
  ...
)

etr_plot_transfer_surrogates(
  x,
  ...
)
```

## Arguments

- fit:

  A fitted native R model result of the expected class.

- dimension:

  One-based functional channel index.

- interval:

  Whether to display pointwise or simultaneous exploratory bands.

- ...:

  Additional base-R graphics parameters.

- diagnostic:

  Observed sparse-curve support diagnostic result.

- x:

  A native trajectory object, sparse collection, numeric sequence, or
  validated diagnostic according to the function.

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
