# Experimental Phase 3 R methods: advanced contrast

Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated
inference.

## Usage

``` r
etr_bootstrap_group_contrast(
  x,
  participant,
  group,
  B = 399L,
  alpha = 0.05,
  seed = 3L
)

etr_multilevel_reconstruct(
  fit,
  n_between = NULL,
  n_within = NULL
)

etr_multilevel_diagnostics(
  fit
)
```

## Arguments

- x:

  A native trajectory object, sparse collection, numeric sequence, or
  validated diagnostic according to the function.

- participant:

  Participant identifiers by curve, or a metadata-column name.

- group:

  Exactly two group labels, each constant within participant.

- B:

  Number of participant-level bootstrap draws, at least 39.

- alpha:

  Target nominal miscoverage in (0,1); calibration not guaranteed.

- seed:

  Deterministic random seed.

- fit:

  A fitted native R model result of the expected class.

- n_between:

  Number of between-participant components.

- n_within:

  Number of within-participant components.

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
