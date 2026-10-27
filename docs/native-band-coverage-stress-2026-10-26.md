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

## Paired experimental interval comparison — author-run 30-study pilot

**Execution (26 October 2026):** The owner ran
`scripts/compare_native_band_intervals.R` with
`ET_BAND_COMPARE_REPS=30`, `ET_BAND_COMPARE_B=199` and
`ET_BAND_COMPARE_SEED_OFFSET=57000000`. Archive:
`artifacts/band_interval_comparison/run_20261026_210748_pid51684/`.
There were **90 independently generated datasets total** (30 for
each N=12/24/48), shared between the mean and null contrast
estimands. Each generating dataset supplied three methods for two
estimands, producing **540 candidate evaluations with zero fitting
failures**. Counting 540 results as independent would be pseudoreplication.

The methods are the existing fixed-SE participant-cluster bootstrap,
an experimental studentized cluster bootstrap (recalculating SE
inside each resampling draw), and a Gaussian/pooled-t Bonferroni
reference requiring Gaussian, independent, equal-variance clusters.

### Coverage results, nominal simultaneous coverage 90%

| Participants | Estimand | Existing (out of 30) | Studentized (out of 30) | Gaussian reference (out of 30) |
|---:|---|---:|---:|---:|
| 12 | Mean | 19 (.6333) | 29 (.9667) | 30 (1.000) |
| 12 | Null group contrast | 18 (.6000) | 29 (.9667) | 29 (.9667) |
| 24 | Mean | 24 (.8000) | 27 (.9000) | 29 (.9667) |
| 24 | Null group contrast | 23 (.7667) | 26 (.8667) | 30 (1.000) |
| 48 | Mean | 26 (.8667) | 28 (.9333) | 30 (1.000) |
| 48 | Null group contrast | 23 (.7667) | 25 (.8333) | 29 (.9667) |

The studentized candidate showed higher *observed* simultaneous
coverage than the existing method in all six conditions, but
the group contrasts at N=24 (26/30) and N=48 (25/30) remain
below nominal, and the Monte Carlo confidence intervals are wide.
These are **not** independent evidence of calibrated 90% coverage.
The high Gaussian Bonferroni proportions are expected to accompany
conservative intervals under this restricted generator; even 30/30
has an exact 95% Monte Carlo lower limit of approximately 88.4%,
which alone does not establish coverage of at least 90%.

### Interval-width trade-offs (averaged over all 30 datasets)

| Participants | Estimand | Existing width | Studentized width | Gaussian width | Studentized width increase |
|---:|---|---:|---:|---:|---:|
| 12 | Mean | .315390 | .485937 | .567577 | +54.1% |
| 12 | Null contrast | .593780 | 1.058628 | 1.160553 | +78.3% |
| 24 | Mean | .235366 | .273443 | .338887 | +16.2% |
| 24 | Null contrast | .455071 | .554732 | .684925 | +21.9% |
| 48 | Mean | .168019 | .181480 | .225789 | +8.0% |
| 48 | Null contrast | .332950 | .363565 | .452400 | +9.2% |

Thus the studentized method's apparent coverage gains are **not
free**: at N=12, mean bands widen by roughly 54% and contrast bands
by roughly 78%. The Gaussian reference produces still wider bands
in all six conditions, as expected from its conservative construction.

The raw `interval_comparison_trials.csv` has **not been uploaded to
this conversation for independent row-wise audit**. The table above
is sourced from the owner's RStudio console output, not independently
recomputed from raw trial records.

### Paired-data audit and next independent replication

A read-only script
[`scripts/audit_paired_band_candidates.R`](../scripts/audit_paired_band_candidates.R)
has been added to validate archived trial-summary counts, verify
the shared generating seed within all six method/estimand evaluations,
and compute exploratory **paired coverage gains**, coverage
discordance counts and mean-width ratios. It also computes
paired-bootstrap Monte Carlo intervals for those differences.
This audit is committed and statically checked but **not executed in
the owner's RStudio session**.

```r
source("scripts/audit_paired_band_candidates.R")
```

After that audit passes, an independently seeded 200-study-per-N,
B=399 confirmation should preserve the same three-method
comparison, 90% nominal target, failure-inclusive outputs,
and a **different generating seed offset**, for example:

```r
Sys.setenv(
  ET_BAND_COMPARE_REPS = "200",
  ET_BAND_COMPARE_B = "399",
  ET_BAND_COMPARE_SEED_OFFSET = "81000000"
)
source("scripts/compare_native_band_intervals.R")
```

The runner checks previous comparison archives for overlapping
(`n_subjects`, `generator_seed`) pairs. Do not choose a
replacement based solely on the pilot's observed improvement;
also require data-generating stress under heavy tails,
heteroskedasticity, and missing observation processes, plus
an independent participant-level qualification design.

**No published or release-facing estimator changed.**
Scientific simultaneous-band qualification and the release
decision remain **HOLD**.

## Independent expanded candidate comparison — author-run 200/N, B=399

The owner first ran the read-only paired audit on the earlier **30-study**
archive. It passed its trial-summary integrity checks with no missing pairs.
That audit pertains to the *pilot*, not the newer expanded study.

The owner then ran `scripts/compare_native_band_intervals.R` with
`ET_BAND_COMPARE_REPS=200`, `ET_BAND_COMPARE_B=399`,
`ET_BAND_COMPARE_SEED_OFFSET=81000000` and saved:
`artifacts/band_interval_comparison/run_20261026_212042_pid51684/`.
The experiment comprises **600 independently generated datasets**
(200 per N=12/24/48), each supplying six method/estimand evaluations:
**3,600 successful evaluations, no reported fitting failures**.
The seed-overlap precheck did not abort. Raw expanded trial records
have not been uploaded into this conversation, so independent
row-level validation of the expanded archive is still pending.

### Simultaneous population-mean and null-contrast coverage (nominal 90%)

| Participants | Estimand | Existing fixed-SE | Studentized | Gaussian Bonferroni-t |
|---:|---|---:|---:|---:|
| 12 | Mean | 146/200 = **.730** | 195/200 = **.975** | 196/200 = .980 |
| 12 | Null contrast | 125/200 = **.625** | 194/200 = **.970** | 195/200 = .975 |
| 24 | Mean | 160/200 = **.800** | 176/200 = .880 | 195/200 = .975 |
| 24 | Null contrast | 161/200 = **.805** | 182/200 = .910 | 196/200 = .980 |
| 48 | Mean | 165/200 = **.825** | 175/200 = .875 | 195/200 = .975 |
| 48 | Null contrast | 176/200 = .880 | 189/200 = .945 | 199/200 = .995 |

Studentization improved observed simultaneous coverage in all six cells.
However, N24 and N48 mean coverage remained .880 and .875, with exact
95% Monte Carlo intervals [.82673,.92158] and [.82103,.91745]. Both
intervals include nominal .90; this neither demonstrates calibrated
coverage nor conclusively establishes undercoverage in those two cells.
N12 studentized mean .975 has exact 95% CI [.94263,.99183], indicating
potential conservatism in the specified Gaussian generator.
Gaussian Bonferroni-t reference rates .975–.995 are expected to be
conservative under its independent Gaussian equal-variance assumptions,
not generally valid under other participant and observation processes.

### Mean simultaneous band width

| Participants | Estimand | Existing | Studentized | Gaussian | Studentized width increase |
|---:|---|---:|---:|---:|---:|
| 12 | Mean | .317734 | .477744 | .564829 | **+50.4%** |
| 12 | Null contrast | .600213 | 1.042275 | 1.159661 | **+73.7%** |
| 24 | Mean | .237065 | .275614 | .345269 | +16.3% |
| 24 | Null contrast | .462661 | .562379 | .694446 | +21.6% |
| 48 | Mean | .169745 | .181870 | .226777 | +7.1% |
| 48 | Null contrast | .335902 | .363291 | .453789 | +8.2% |

The observed improvements are accompanied by meaningful interval inflation,
most notably for 12-participant designs.

### Historical reporting-label correction

Code inspection found that the archived comparison fields
`average_pointwise_coverage` (trials) and `avg_pointwise_rate` (summary)
were computed by comparing truth to the **simultaneous band's** lower
and upper bounds. They therefore describe **mean coordinate inclusion
within the simultaneous band**, not separately constructed marginal
pointwise CI coverage. The research script's future output has been
renamed `coordinate_coverage_in_simultaneous_band` and
`avg_coordinate_coverage_in_simultaneous_band`. Original archives
are retained unchanged. **Simultaneous all-coordinate coverage counts
and band widths are unaffected.** Historical pointwise-labeled columns
must not be cited as pointwise confidence-interval calibration evidence.

### Next steps and qualification limits

The author has now **successfully run**
`scripts/audit_paired_band_candidates.R` on the 200-study archive,
verifying the saved trial-summary counts, all six-way paired records
and zero missing/failed fit pairs. The historical coordinate-level
reporting field was correctly identified as simultaneous-band
coordinate inclusion rather than true pointwise CI coverage.
The audit calculated exact discordance tests and paired-bootstrap
Monte Carlo intervals for differences in simultaneous coverage and
mean width ratios:

```r
Sys.setenv(
  ET_BAND_COMPARE_AUDIT_DIR =
    "artifacts/band_interval_comparison/run_20261026_212042_pid51684"
)
source("scripts/audit_paired_band_candidates.R")
```

The next independent qualification must vary participant-effect tails,
between-group variances, observation density and missingness while
preserving the failure-inclusive protocol. No published estimator
has been modified; inferential release status remains **HOLD**.

## Expanded 200-study paired audit — completed (26 October 2026)

**Author-run outcome:** `Archive summary/trial consistency: PASS`.
Archived trial source:
`artifacts/band_interval_comparison/run_20261026_212042_pid51684/`.
Derived audit:
`artifacts/band_interval_comparison_audit/audit_20261026_213928_pid51684/`.
All six generating-study blocks per independent dataset were present;
**600 distinct generating datasets, 3,600 method/estimand rows**,
zero reported failures or missing method pairs. Historical
`average_pointwise_coverage` was explicitly flagged as
coordinate inclusion within the simultaneous interval, NOT
separate pointwise confidence-interval coverage.

### Paired candidate coverage gains and width ratios

The reported Monte Carlo intervals for gains/ratios were constructed
with **2,000 paired generating-study bootstrap draws per condition**.

| Participants | Estimand | Candidate | Gain (percentage points) | Paired 95% MC interval (pp) | Recovered / lost baseline-covered studies | Mean width ratio |
|---:|---|---|---:|---|---:|---:|
| 12 | Mean | Studentized | +24.5 | [18.5,30.5] | 49 / 0 | 1.5036 |
| 12 | Mean | Gaussian Bonferroni-t | +25.0 | [19.0,31.5] | 50 / 0 | 1.7777 |
| 12 | Null contrast | Studentized | +34.5 | [28.0,41.0] | 69 / 0 | 1.7365 |
| 12 | Null contrast | Gaussian Bonferroni-t | +35.0 | [28.49,42.0] | 70 / 0 | 1.9321 |
| 24 | Mean | Studentized | +8.0 | [4.5,12.0] | 16 / 0 | 1.1626 |
| 24 | Mean | Gaussian Bonferroni-t | +17.5 | [12.0,22.5] | 35 / 0 | 1.4564 |
| 24 | Null contrast | Studentized | +10.5 | [6.5,14.51] | 21 / 0 | 1.2155 |
| 24 | Null contrast | Gaussian Bonferroni-t | +17.5 | [12.5,23.0] | 35 / 0 | 1.5010 |
| 48 | Mean | Studentized | +5.0 | [2.0,8.5] | 10 / 0 | 1.0714 |
| 48 | Mean | Gaussian Bonferroni-t | +15.0 | [10.5,20.0] | 30 / 0 | 1.3360 |
| 48 | Null contrast | Studentized | +6.5 | [3.5,10.0] | 13 / 0 | 1.0815 |
| 48 | Null contrast | Gaussian Bonferroni-t | +11.5 | [7.5,16.0] | 23 / 0 | 1.3510 |

**All 12 paired comparisons had zero observed baseline-covered/candidate-
missed datasets.** This is *not* a formal proof of algebraic band
nesting nor scientific coverage validity. In all 12 conditions the
candidate was **wider** than the baseline, so simple conservatism
explains at least part of the improvement. The descriptive exact
discordance sign tests therefore cannot establish that studentizing
provides a generally valid 90% interval. The gain confidence
intervals estimate Monte Carlo uncertainty under this same
prespecified Gaussian generator and do not cover DGP uncertainty,
multiplicity or model selection.

The expanded raw CSV was validated by the **owner's R execution**,
not independently uploaded to this conversation. Results remain
scientifically conditional on the generator and the author's
execution log. **No release-facing estimators were modified.**

## Distributional robustness experiment — 20-study author-run pilot

The new research-only script
[`scripts/stress_native_band_distributions.R`](../scripts/stress_native_band_distributions.R)
extends the paired interval comparison to four known-truth
**complete-data** participant-level generating processes:

1. `gaussian_baseline`: independent Gaussian participant effects;
2. `heavy_t3`: centered Student-t effects (3 degrees of freedom),
   rescaled to the same standard deviation as the Gaussian condition;
3. `heteroskedastic_groups`: independent Gaussian participant effects
   with between-group SDs .18 and .70, breaking equal-variance assumptions;
4. `skewed_lognormal`: centered, variance-standardized skewed
   lognormal participant effects.

All scenarios have known common functional population mean
`sin(2*pi*t), cos(2*pi*t)`, null group contrast zero, three
complete observed trials per participant, 41 time points, and
two functional channels. This deliberately isolates
**distributional robustness**; it does **not** test MCAR/MAR/MNAR
or participant dropout and must not be used to claim missingness
qualification.

The comparison retains existing fixed-SE bootstrap, experimental
studentized bootstrap and the Gaussian Bonferroni-t reference.
Only the Gaussian baseline satisfies the latter's normality/equal-
variance assumptions. The other three scenarios use that method
as an **assumption-violating sensitivity comparison**, not a
guaranteed-coverage procedure.

Per-run seed prechecks against prior robustness runs,
failure-inclusive trial/summary CSVs, known-truth coverage,
mean width and explicit simultaneous-band coordinate inclusion
are preserved. No native scientific estimator was changed.

Initial structural and performance smoke test (four DGPs,
three cluster sizes, 20 independent generated studies each):

```r
Sys.setenv(
  ET_BAND_ROBUST_REPS = "20",
  ET_BAND_ROBUST_B = "99",
  ET_BAND_ROBUST_SEED_OFFSET = "96000000"
)
source("scripts/stress_native_band_distributions.R")
```

Conditional on successful smoke and archive checks, a separate
200-study / B399 run needs a non-overlapping seed offset, e.g.
`43000000`. Do not reuse pilot seed offset. More complete
observation-process/missingness validation must follow as a
separate study with an explicitly defined target estimand.

**Status:** Author-run 20-study/condition distributional stress completed on 26 October 2026. See execution evidence below. The script remains research-only; raw CSV records were not supplied for an independent row-by-row audit.

### Author-executed pilot across four complete-data generators (26 October 2026)

The owner sourced `scripts/stress_native_band_distributions.R` under Windows R with **20 independently generated datasets for every scenario/N combination** and `B=99` bootstrap draws, producing archive:
`artifacts/band_robustness_stress/run_20261026_215536_pid51684/`.

There are **4 generating scenarios × 3 N levels × 20 datasets = 240 distinct generated datasets**. Each dataset supplies **two paired estimands and three paired methods**, for **1,440 successful method/estimand evaluations and zero reported failed fits**. Evaluations from the same generating dataset are *dependent*: 1,440 must not be reported as 1,440 independent generating studies. The following descriptive totals aggregate 60 generated studies and two estimands per scenario; **each denominator of 120 combines correlated outcomes and must not be used as an independent-binomial calibration test**.

| Complete-data DGP | Existing fixed-SE covered / 120 | Experimental studentized covered / 120 | Gaussian Bonferroni-t covered / 120 |
|---|---:|---:|---:|
| Independent Gaussian | 93 (77.5%) | 111 (92.5%) | 118 (98.3%) |
| Heavy-tailed Student-t(3) | 87 (72.5%) | 111 (92.5%) | 115 (95.8%) |
| Unequal group variances | 92 (76.7%) | 109 (90.8%) | 118 (98.3%) |
| Centered skewed lognormal | 78 (65.0%) | 107 (89.2%) | 114 (95.0%) |

The **strongest pilot warning** was skewed lognormal N=12: the existing fixed-SE band covered the true participant mean in only **9/20 (45%)** and the true-null group contrast in only **10/20 (50%)** generated datasets. The studentized candidate covered both targets in **19/20 and 20/20**, and the Bonferroni reference covered them in **19/20 and 20/20**, respectively. At N=24 and N=48 in the skewed participant-mean condition, the studentized candidate achieved only **16/20 (80%)**; in the N=24 heteroskedastic null-contrast condition, it achieved **17/20 (85%)**. These cell-wise counts are noisy and **cannot establish either general calibration or general failure to meet 90%** for the exploratory studentized candidate.

The author-reported width columns show wider experimental intervals alongside the apparent gains. For skewed lognormal N=12 mean, mean widths were **0.262890 fixed-SE / 0.481333 studentized / 0.470930 Bonferroni**. For skewed lognormal N=12 null contrast, they were **0.511245 fixed-SE / 0.979211 studentized / 0.964791 Bonferroni**. Larger coverage therefore cannot be separated from interval inflation. These widths are supported by the owner's console output and subsequent owner-executed archive-consistency audit. The raw `robustness_trials.csv` and `robustness_summary.csv` have not been uploaded to this conversation for independent reproduction.

The Bonferroni reference is assumption-matched **only** to the Gaussian generator. Its observed coverage under the heavy-tailed, unequal-variance and skewed generators is a sensitivity result, **not** a finite-sample coverage guarantee. `B=99` makes bootstrap cutoff estimation coarse; **20 independent studies per cell** gives very wide exact Monte Carlo coverage intervals (e.g., 9/20: [0.23058,0.68472]; 16/20: [0.56339,0.94267]). No MCAR/MAR/MNAR, subject dropout, asynchronous sampling, sparse-time-grid or unequal observation density was tested.

**Next gate:** Reconcile archived trial-level records with summaries and verify scenario/N/generator-seed uniqueness and complete six-way pairing, then run an independently seeded larger study (proposed `ET_BAND_ROBUST_REPS=200`, `ET_BAND_ROBUST_B=399`, `ET_BAND_ROBUST_SEED_OFFSET=43000000`) if computing cost permits. Report per-scenario/N/estimand simultaneous coverage, exact Monte Carlo uncertainty, paired candidate-only and baseline-only discordance counts, and width ratios. Follow with a *separate*, explicitly estimand-defined missingness/observation-process experiment. No estimator replacement, merge or release is authorized: **inference qualification remains HOLD**.

The owner has now **executed** the read-only `scripts/audit_native_band_distributions.R`. It checked each six-way study block, global generating-seed uniqueness, and the reconstruction of **all 72 archived summary cells**, including exact Monte Carlo intervals and average width/coordinate-inclusion means. It created a new audit folder without modifying source trial records. The RStudio console reported **`Robustness archive summary/trial consistency: PASS`**, 240 distinct generating datasets, 1,440 paired evaluations, **0 failures** and **0 incomplete candidate/baseline pairs**.

### Author-run read-only archive audit — PASS (26 October 2026)

Source: `artifacts/band_robustness_stress/run_20261026_215536_pid51684/`.
Audit: `artifacts/band_robustness_stress_audit/audit_20261026_220836_pid51684/`.

The 48 matched candidate/baseline cells arise from **4 DGPs × 3 participant counts × 2 estimands × 2 alternative methods**, each with 20 generating studies. The audit reports:

- **48/48 paired comparisons complete**, with no failed or unmatched studies; all 48 had **zero observed baseline-covered/candidate-missed datasets**.
- **47/48 comparisons showed a positive observed coverage gain**, while one (Gaussian N=48 null contrast, studentized vs baseline) had a 0-percentage-point gain. These are descriptive paired outcomes, not independent hypothesis tests.
- Studentized mean-width ratios ranged from **1.0661 to 2.3398** across conditions; Gaussian Bonferroni-t ratios ranged from **1.3206 to 1.9914**. All alternatives produced wider *average* bands than the corresponding baseline condition. The largest studentized width inflation was for the heavy-t(3) N=12 null contrast, 2.3398× baseline.
- Paired candidate-minus-baseline gains ranged from **0 to +50 percentage points** for studentized and **+10 to +50 pp** for the Gaussian reference. At skewed N=12, both candidate methods gained +50 pp for both estimands, but widths increased approximately 1.83×–1.92× (studentized), so improved observed coverage is partly attributable to conservatism.
- Exploratory 2,000-resample paired bootstrap intervals for gains/width ratios measure *within-DGP simulation variability only*. With just 20 generating datasets per cell and 48 comparisons, they do not address multiplicity, estimator selection or general DGP validity.

**No universal band nesting has been proved.** Zero observed candidate-only misses and higher mean width do not imply pointwise set inclusion for future datasets. The normal/pooled-t reference remains assumption-matched solely in `gaussian_baseline` despite high empirical coverage in other scenarios. The raw CSV files were not attached to this conversation; trial-level consistency is validated by the **owner-executed audit**, not independently reproduced in the assistant environment. The result still excludes missing observations, attrition and sparse asynchronous sampling.

**Next decision:** An independently seeded, substantially larger complete-data robustness study remains scientifically justified, followed by a separate missingness study with a declared full-population versus observed-data target. No native estimator change or release authorization follows from this pilot; scientific qualification remains **HOLD**.

```r
Sys.setenv(ET_BAND_ROBUST_AUDIT_DIR =
  "artifacts/band_robustness_stress/run_20261026_215536_pid51684")
source("scripts/audit_native_band_distributions.R")
Sys.unsetenv("ET_BAND_ROBUST_AUDIT_DIR")
```


## Independent 2,400-dataset four-DGP expansion — completed 27 October 2026

The owner executed the planned 200-dataset-per-scenario/N study with
`ET_BAND_ROBUST_B=399` and seed offset `43000000` under RStudio.
Across four DGPs and N=12/24/48, there were **2,400 independently
generated datasets**, evaluated for paired participant mean and null
group contrast by all three methods (**14,400 successful evaluations,
zero reported fitting failures**). Archive:
`artifacts/band_robustness_stress/run_20261027_005525_pid51684/`.

The new [expanded study report](native-band-robustness-expanded-2026-10-27.md)
contains **all 24 scenario/N/estimand coverage comparisons**, three
method rates, the studentized coverage gains and mean width ratios,
plus a warning against pooling correlated estimands as independent
Monte Carlo units.

**Main findings:** Baseline undercoverage persisted, particularly
heavy-t(3) N=12 null contrast **107/200 = 53.5%**. Studentized
intervals improved observed coverage in **24/24 cells** but mean
band widths were **1.063–2.036× the baseline**. Three candidate cells
had observed coverage below nominal 90% (Gaussian N24 contrast
89.5%; Gaussian N48 mean 89.0%; skewed N48 mean 88.5%); their separate
exact 95% Monte Carlo intervals include .90. Gaussian Bonferroni-t
is a restricted reference, not a general-purpose correction.

**The earlier 240-dataset pilot's read-only audit was PASS, but this
larger archive is NOT YET AUDITED at trial level.** Run
`scripts/audit_native_band_distributions.R` with
`ET_BAND_ROBUST_AUDIT_DIR` pointing to
`run_20261027_005525_pid51684` before considering the larger
study reproducibility-qualified. No estimator changed; release HOLD.
