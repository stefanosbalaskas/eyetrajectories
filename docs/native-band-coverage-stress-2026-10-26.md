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

## Owner-executed 20-dataset band-stress pilot (26 October 2026)

The author executed `scripts/stress_native_band_coverage.R` from RStudio
with `ET_BAND_MC_REPS=20`, `ET_BAND_MC_B=99`, nominal .90, three
trials per participant, and `n_subjects` in 12/24/48.
Archive (author's Windows checkout):
`artifacts/band_coverage_stress/run_20261026_204746_pid51684/`.

**All 120 attempted estimator fits succeeded** across 60 independently
generated datasets (20 per participant-size condition). The participant
mean and group contrast reuse each generated dataset, so their six
summary cells are *not* 120 independent experiments.

| Participants | Method | Covered / 20 | Simultaneous coverage | Exact 95% MC interval | One-sided binomial p vs .90 | Mean pointwise coverage | Mean band width |
|---:|---|---:|---:|---|---:|---:|---:|
| 12 | Participant mean | 15 | .75 | [.50895, .91343] | .04317 | .84939 | .32940 |
| 12 | Two-group null contrast | 15 | .75 | [.50895, .91343] | .04317 | .82378 | .61743 |
| 24 | Participant mean | 18 | .90 | [.68302, .98765] | .60825 | .87012 | .23597 |
| 24 | Two-group null contrast | 13 | **.65** | **[.40781, .84609]** | **.002386** | .80061 | .46052 |
| 48 | Participant mean | 18 | .90 | [.68302, .98765] | .60825 | .87866 | .17694 |
| 48 | Two-group null contrast | 17 | .85 | [.62107, .96793] | .32307 | .92134 | .34700 |

The participant contrast at N=24 has a 95% exact MC interval entirely
below the nominal coverage level, giving clear evidence of poor coverage
**in this one simulation scenario**. The six tests are descriptive,
paired within N and not an independently confirmed family of
hypothesis tests; do not overinterpret their unadjusted p-values.
At N=12 the individual one-sided tail is below .05, but the two-sided
exact MC interval includes .90. The absence of failed fits cannot
validate coverage; notably the mean method's apparent .90 coverage at
N=24/48 rests on just 20 independent draws each.

The 20-study findings are supported by the owner's console output.
The raw CSVs were **not independently uploaded or row-wise inspected**
in this conversation. The higher-precision B=399 / 200-study stage
has not run.

## Research stress harness

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

The initial pilot used the default seed offset `12000000`. To
ensure the expanded study is **disjoint** rather than simply
reproducing its first 20 datasets per participant size, use a
different offset after pulling the latest research branch:

```r
Sys.setenv(
  ET_BAND_MC_REPS = "200",
  ET_BAND_MC_B = "399",
  ET_BAND_MC_SEED_OFFSET = "30000000",
  ET_BAND_MC_ALLOW_SEED_REUSE = "false"
)
source("scripts/stress_native_band_coverage.R")
```

The new **preflight seed-collision guard** scans completed
`band_coverage_trials.csv` archives for repeated
(`n_subjects`, `generator_seed`) pairs and refuses reuse
*before any fitting or output archive creation*, unless explicitly
permitted using `ET_BAND_MC_ALLOW_SEED_REUSE=true`.
That safeguard is committed but **has not yet been executed in the
author's R environment**; it needs acceptance testing.

The complete higher-precision study is still pending.
No bootstrap estimator was changed. Qualification of
small-cluster simultaneous intervals remains blocked; do not
merge or release based on smoke-test pass counts.
