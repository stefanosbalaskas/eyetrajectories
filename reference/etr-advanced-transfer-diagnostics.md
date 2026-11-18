# Experimental Phase 3 R methods: advanced transfer diagnostics

Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated
inference.

## Usage

``` r
etr_discretize_states(
  x,
  bins = 3L,
  method = c("quantile", "equal_width")
)

etr_effective_transfer_entropy(
  source,
  target,
  k_target = 1L,
  k_source = 1L,
  lag = 1L,
  conditioning = NULL,
  n_shuffles = 99L,
  seed = 1L
)

etr_simulate_te_null(
  n = 400L,
  persistence = 0.80,
  seed = 42L
)

etr_evaluate_te_null(
  simulations = 20L,
  n = 400L,
  persistence = .8,
  n_surrogates = 39L,
  seed = 100L,
  nominal = .05
)
```

## Arguments

- x:

  A native trajectory object, sparse collection, numeric sequence, or
  validated diagnostic according to the function.

- bins:

  Number of support bins or discrete-state bins, according to the
  function.

- method:

  Declared estimation, binning, or smoothing method.

- source:

  Discrete source sequence.

- target:

  Discrete target sequence.

- k_target:

  Target autoregressive history order.

- k_source:

  Source history order.

- lag:

  Source-to-response time lag in discrete samples.

- conditioning:

  Optional aligned discrete conditioning states.

- n_shuffles:

  Number of permuted-source TE bias-reference replicates.

- seed:

  Deterministic random seed.

- n:

  Number of time-series observations.

- persistence:

  Within-process Markov state persistence probability.

- simulations:

  Independent known-truth Monte Carlo dataset count.

- n_surrogates:

  Number of circular-source-shift surrogate replicates.

- nominal:

  Diagnostic flagging threshold, not a validated type-I error
  probability.

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
