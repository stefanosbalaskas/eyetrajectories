# Native functional trajectory registration, dynamics, and anomaly diagnostics

Narrow, explicitly specified native R methods for prespecified
piecewise-linear landmark registration, delay embeddings, threshold
return maps, binary recurrence-network summaries, and split-conformal
anomaly screening. An offline catalog identifies optional R package
backends. No Python is used.

## Usage

``` r
etr_register_landmarks(x, source_landmarks, target_landmarks)

etr_registration_warp_frame(registration)

etr_delay_embedding(series, dimension = 2L, delay = 1L)

etr_poincare_return_map(series, threshold = 0,
    direction = c("up", "down"), time = NULL)

etr_recurrence_network_nodes(network)

etr_split_conformal_threshold(calibration_scores, alpha = 0.10)

etr_fpca_reconstruction_scores(fit, x)

etr_split_conformal_fpca_anomalies(fit, calibration, test, alpha = 0.10)

etr_r_backend_catalog()
```

## Arguments

- x:

  Native common-grid trajectories; must match the FPCA fit when scoring.

- source_landmarks:

  Numeric source times, one row per curve, strictly ordered.

- target_landmarks:

  Prespecified, increasing interior target times.

- registration:

  Native landmark registration output.

- series:

  Complete finite numeric sampled series.

- dimension:

  Embedding dimension, positive integer.

- delay:

  Positive integer sample lag.

- threshold:

  Finite scalar crossing threshold.

- direction:

  Upward or downward threshold crossing.

- time:

  Optional finite strictly increasing measurement times.

- network:

  Native recurrence-network result.

- calibration_scores:

  Nonnegative scores from held-out calibration curves.

- alpha:

  Miscoverage fraction strictly between zero and one.

- fit:

  FPCA fitted only to independent training curves.

- calibration:

  Held-out complete calibration trajectory set.

- test:

  Independent complete test trajectory set.

## Details

The registration is a deterministic piecewise-linear inverse time map,
with endpoints fixed. It is not SRVF elastic registration or a Python
parity claim. The canonical recurrence network treats time samples as
graph vertices; `etr_recurrence_network_nodes()` is an explicitly legacy
R-only projection that uses one-based component identifiers and missing
clustering for nodes of degree less than two. It does not regard
recurrence nodes as independent research participants. Theiler
exclusions remain ineligible edges. Return maps are scalar
threshold-event maps, not Lyapunov or causal estimates.

Split-conformal calibration uses rank
`ceiling((n_calibration+1)*(1-alpha))`; when the rank exceeds the
calibration sample size, the cutoff is infinite. Marginal false-alarm
coverage requires a frozen training fit and exchangeable
calibration/test units. It does not give batch-wide or
participant-cluster coverage guarantees, and must not be used to claim
calibrated simultaneous functional bands. External R backends listed by
`etr_r_backend_catalog` are optional and have not been independently
validated for equivalence.

## Value

`etr_register_landmarks` returns a registration object;
`etr_registration_warp_frame` returns its tidy warp frame;
`etr_delay_embedding` returns a numeric matrix with sample indices;
`etr_poincare_return_map` returns crossing times and adjacent pairs;
`etr_recurrence_network` returns the canonical source-aligned graph; the
compatibility function below projects a legacy per-node table from it;
`etr_recurrence_network_nodes` returns per-node metrics;
`etr_split_conformal_threshold` returns threshold/rank metadata;
`etr_fpca_reconstruction_scores` returns residual scores per curve;
`etr_split_conformal_fpca_anomalies` returns scores, flags and
calibration; `etr_r_backend_catalog` returns a local optional-package
catalog.

## Examples

``` r
d <- etr_delay_embedding(1:6, dimension = 3L, delay = 2L)
stopifnot(nrow(d) == 2L, ncol(d) == 3L)
cut <- etr_split_conformal_threshold(1:9, alpha = .1)
stopifnot(cut$rank == 9L, cut$threshold == 9)
head(etr_r_backend_catalog(), 3)
```
