# Scientific parity development: evidence and release lanes

This project has **508 frozen Python 1.2 exports** (380 callable and 128 noncallable).
The current source-gap register is historical: there are 203 callable witnesses
and one noncallable witness. The current **active** count must always be read
from `scripts/source_gap_inventory.py`, never copied into a script as a
qualification target.

## Three different progress measures

1. **Actual scientific source cases with reproducible differential evidence.**
   Run `scripts/summarize_scientific_source_evidence.py` after the live
   `scripts/run_accelerated_scientific_wave.R` gate. The report joins real,
   exact-head case-level CSV output across the bounded numerical probes,
   generalized GEE fit/prediction, and the optional 100-replicate participant
   bootstrap in three scientific families. It writes SHA256-referenced unsigned
   developer evidence, grouped by exact Python export, under
   `artifacts/scientific_source_evidence/<R_SHA12>/`. Its totals are dynamic.
   A matched input or a passing finite example is **not** whole-contract parity.
2. **Open documented source gaps.** Only the authoritative source-gap ledger
   controls this count. An implementation or successful limited differential
   does not close an entire accepted-domain/exception/schema/backend gap.
   The bootstrap source-gap descriptions have been updated to distinguish
   new native joint likelihood paths from their older moments-only paths.
   Their open status remains intact pending full-domain review.
3. **Independently certified source contracts.** Only a real independent
   reviewer can adjudicate complete Python ↔ native R parity. SHA256 checks,
   author-conducted Python replays, passing RStudio tests and first-party
   review packets do not impersonate such an approval.

## Scientific development priorities

Continue coherent estimation/inference families in this order: mixed-effects
full likelihood and covariance structures; functional regression with
whole-participant refitting; sparse FPCA joint covariance/score prediction;
then functional FPCR predictive inference. Keep scientific source oracles on
the *frozen* Python commit `c1cd95ad718327550f7e55393ff38582872f7a94`,
while automatically recording the native Git commit and case-level results.

The new conditional **joint GLS bootstrap** is source-compared on selected
matched source-index cases. The **joint likelihood full-refit** performs actual Gaussian ML/REML
participant-case refits for the established iid random-intercept model, which
has passed local RStudio tests. An additional author-side implementation now
routes serial residual, random-slope, nested-trial and nested-slope structures
to their own likelihood estimators, retaining all estimated covariance fields.
The four expanded models have separate slow-gated optimizer tests
(`ET_RUN_SCIENTIFIC_SLOW=true`); they are not claimed to have passed until
the new source wave runs. Neither implementation is an independent certificate.

## Release separation

CRAN qualification is a separate packaging track. The fast scientific wave
must not run a CRAN check every time; the full or cran modes run a clean
snapshot check as available. A CRAN-compatible release may declare a
**restricted native scientific scope**, clearly label optional backends, and
exclude unsupported methods; a CRAN check is not evidence for all 508 Python
contracts. No release is implied by this document.

## Commands

```r
stopifnot(system("git pull --ff-only") == 0L)
Sys.setenv(
  ET_SCIENTIFIC_WAVE_MODE="fast",
  ET_RUN_BOOTSTRAP_SOURCE_DIFF="true",
  ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE="false"
)
source("scripts/run_accelerated_scientific_wave.R", encoding="UTF-8")
```

Then inspect the reported `SCIENTIFIC_SOURCE_EVIDENCE_` counts and
`developer_source_functions_UNSIGNED.csv`: they distinguish successful
bounded-source cases from actual gap closure and external certification.


## Native sparse PACE scientific family

A new Python-free native sparse FPCA algorithm now uses local-linear
Epanechnikov smoothing, off-diagonal within-curve covariance pairs,
quadrature-weighted PSD projection, a positive eigenspectrum rule, and PACE
scores conditioned on the full fitted covariance (not a truncated rank-k
approximation). Rotated 45-degree local-quadratic diagonal-difference noise
estimation is implemented alongside fixed known noise variance; all methods
remain research-only pending their direct frozen Python numerical replay.
`etr_sparse_fpca_score_uncertainty_native()` computes a conditional Gaussian
posterior given those retained population objects. The previously available
fdapace alternative has not been removed. The sparse workflow now accepts
explicit `backend="native_covariance"`, retains no-imputation provenance,
and labels the full Python workflow schema as unverified.

To include these numerical source comparisons in a single wave, use
`ET_RUN_SPARSE_SOURCE_DIFF=true` alongside the existing bootstrap
differential option. The dynamic case summary includes the optional sparse
report only when it is actually generated. Its presence never closes a
historical gap or grants independent review.
