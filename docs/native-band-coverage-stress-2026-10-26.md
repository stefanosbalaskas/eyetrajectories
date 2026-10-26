# Native participant-bootstrap bands — known-truth stress evidence

**Status: undercoverage observed; inference not qualified; release HOLD.**
Branch `research/native-parity-stage1`, package 0.4.1.9000.

## Owner-executed engineering stress (26 October 2026)

The user ran an ad hoc comprehensive native R stress harness under Windows
11, R 4.6.1, Git HEAD `58fe617e126cc33014a0ed4c263b7f5114c01c12`.
The archived result listed **31 passes, 1 failure**. All 26 native
functional/estimator smoke checks passed and 5 small performance loops
passed. The single failed harness test was an indexing/scoping mistake
in the *harness's* scientific result recorder:
`scientific_results[[length(scientific_results) + 1L]] <<- ...`.
This was not evidence of a failure in the estimator; it prevented the
scientific diagnostic from being recorded in the output CSV.
The Python bridge and full testthat suite were deliberately disabled.

The user independently reran the known-truth diagnostic directly:

```r
coverage <- etr_evaluate_mean_band_coverage(
  simulations = 30L, B = 99L, alpha = .10,
  n_subjects = 12L, seed = 5000L
)
```

Owner-observed values:

| Metric | Value |
|---|---:|
| Simultaneous coverage | 19/30 = 0.6333333 |
| Monte Carlo standard error | 0.08798148 |
| Average pointwise coverage | 0.8414634 |
| Nominal simultaneous target | 0.90 |
| Independent generating datasets | 30 |
| Independent participant clusters per dataset | 12 |
| Bootstrap resamples per fit | 99 |

Exact two-sided 95% binomial Monte Carlo interval for 19/30:
approximately **[0.43856, 0.80070]**. The one-sided binomial tail
probability under a putative 0.90 coverage rate is about **0.0000891**.
This quantifies the diagnostic under its particular known-truth generator
with independent generated datasets; it is not a broad theorem about
all underlying distributions and requires more simulations and
additional generating designs before scientific method qualification.

This result is consistent with earlier observed small-participant
simultaneous-band undercoverage. It concerns the existing **fixed-SE
participant-cluster max-standardized bootstrap** and is unrelated to
the separate split-conformal one-curve anomaly screen.

## Newly staged research stress harness

`scripts/stress_native_band_coverage.R` independently simulates 12, 24
and 48 participant clusters with 3 trials per participant and a known
two-channel population mean. It evaluates **both** the participant mean
and a true-null two-group contrast in each generated dataset.

- Prespecified nominal 90% simultaneous coverage; fixed-SE bootstrap.
- Default 200 independent generating datasets per cluster size and B=399.
- Records trial-level pointwise and simultaneous truth coverage and widths.
- Records all fit failures instead of coding them as uncovered.
- Computes exact 95% binomial intervals and one-sided Monte Carlo tails.
- Generates timestamped non-overwriting CSV archives and a manifest.
- Uses a separate seeded research design without modifying any estimator.

Start with a smaller execution to check runtime and data shapes:

```r
Sys.setenv(ET_BAND_MC_REPS = '20', ET_BAND_MC_B = '99')
source('scripts/stress_native_band_coverage.R')
```

Then evaluate the higher-precision candidate:

```r
Sys.setenv(ET_BAND_MC_REPS = '200', ET_BAND_MC_B = '399',
           ET_BAND_MC_SEED_OFFSET = '12000000')
source('scripts/stress_native_band_coverage.R')
```

The code has been committed and statically checked but **not executed
in RStudio**. Avoid reporting its designed outputs as observed results
until the owner runs and verifies its actual CSVs. No bootstrap
estimator was changed. Qualification of small-cluster simultaneous
intervals remains blocked; do not merge or release based on
smoke-test pass counts.
