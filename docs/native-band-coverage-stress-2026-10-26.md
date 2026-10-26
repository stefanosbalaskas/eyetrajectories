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
The owner **executed the negative seed-guard test successfully**: five
already-used seeds under the pilot offset were blocked with the expected
`BAND SEED COLLISION PRECHECK` error before fitting.

The expanded 200-study-per-participant-size study **completed** (see below).
No bootstrap estimator was changed. Qualification of
small-cluster simultaneous intervals remains blocked; do not
merge or release based on smoke-test pass counts.

## Owner-executed expanded 200-study / B=399 qualification (26 October 2026)

The author executed `scripts/stress_native_band_coverage.R` with
`ET_BAND_MC_REPS=200`, `ET_BAND_MC_B=399`,
`ET_BAND_MC_SEED_OFFSET=30000000` and explicit no-reuse mode.
The script reported **zero overlapping archived generating-study seeds**.
Its archive was
`artifacts/band_coverage_stress/run_20261026_205405_pid51684/`.
The prior negative seed-collision check passed.

There are **600 independently generated datasets** (200 at each N)
and **1,200 fitted estimator evaluations**, two using each generated
dataset, **zero fitting failures**. Reported exact Monte Carlo
confidence intervals and one-sided binomial tails:

| N participants | Estimator | Covered / 200 | Simultaneous coverage | Exact 95% MC interval | One-sided p against 90% | Mean pointwise coverage | Mean band width |
|---:|---|---:|---:|---|---:|---:|---:|
| 12 | Participant mean | 126 | **0.630** | [0.55905, 0.69703] | 2.1184e-24 | 0.834878 | 0.323027 |
| 12 | Two-group null contrast | 110 | **0.550** | [0.47825, 0.62025] | 3.5739e-37 | 0.835854 | 0.610305 |
| 24 | Participant mean | 151 | **0.755** | [0.68936, 0.81292] | 2.7691e-09 | 0.858232 | 0.233832 |
| 24 | Two-group null contrast | 152 | **0.760** | [0.69469, 0.81743] | 8.1410e-09 | 0.864512 | 0.456831 |
| 48 | Participant mean | 174 | 0.870 | [0.81535, 0.91329] | 0.100457 | 0.887317 | 0.170627 |
| 48 | Two-group null contrast | 167 | **0.835** | [0.77616, 0.88362] | 0.002916 | 0.879756 | 0.336803 |

The exact 95% MC intervals for **five of six** conditions have
upper endpoints below nominal 90%. The N=48 participant-mean
interval includes 90%, so nonrejection in that condition does
**not establish statistical calibration**. The two estimator
outcomes within a generating dataset are paired; the six
descriptive binomial tests are not jointly multiplicity-adjusted.
A complete pointwise-versus-simultaneous analysis and
distributional generalization require additional models.

The user's console output supports these six rows and their
zero-failure claims. The raw `band_coverage_trials.csv` from
the expanded study has **not** been uploaded to this chat for
independent record-by-record verification.

**Qualification decision: HOLD.** The fixed-SE participant
bootstrap produces material undercoverage for the known-truth
Gaussian hierarchical generator at modest cluster sizes.
No current native estimator was modified. A replacement must
first improve coverage *and* report the width trade-off in
an independently designed paired simulation; it cannot be
selected solely on optimistic outputs from the same design.

## Next research stage: paired simultaneous-interval candidates

The new research-only [`scripts/compare_native_band_intervals.R`](../scripts/compare_native_band_intervals.R)
places the existing fixed-SE participant-bootstrap intervals alongside
(1) a cluster-resampled **studentized bootstrap** with recalculated SE in each
resample and (2) a **Gaussian pooled-t/Bonferroni reference**. It uses the
same independently generated datasets for every method, for N=12/24/48
and for both the participant mean and equal-group null contrast.

**The Gaussian reference is assumption-restricted:** under the known-truth
normal, independent participant-mean generator and equal group variance,
the marginal Student t pivots combined with Bonferroni control achieve at
least the target familywise coverage (potentially with much wider bands).
It is not a general correction for non-Gaussian processes, missingness,
heteroskedastic group variance or dependent participants. The studentized
bootstrap is entirely exploratory; its coverage must be measured rather
than assumed. Both alternatives are implemented **only inside the research
script**; the existing R estimators and exports are unchanged.

Start with a small paired experiment on non-overlapping seeds:

```r
Sys.setenv(
  ET_BAND_COMPARE_REPS = "30",
  ET_BAND_COMPARE_B = "199",
  ET_BAND_COMPARE_SEED_OFFSET = "57000000"
)
source("scripts/compare_native_band_intervals.R")
```

Outputs appear under `artifacts/band_interval_comparison/run_*/`: 
`interval_comparison_trials.csv`, `interval_comparison_summary.csv`,
`interval_comparison_failures.csv`, a manifest and session details.
An archive seed-overlap guard prevents silently repeating datasets.
The design compares **both** simultaneous truth coverage and interval
width; fitting failures are retained. The script is committed and
statically reviewed but **has not yet been executed in RStudio**.
No inferential calibration claim follows from adding it.
