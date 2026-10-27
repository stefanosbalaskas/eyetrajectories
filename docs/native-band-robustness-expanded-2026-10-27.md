# Native simultaneous-band robustness: expanded independent four-DGP evaluation

**27 October 2026 — expanded simulation complete and author-run read-only archive audit PASS; inference and release status HOLD.**

**Research branch:** `research/native-parity-stage1`, R package `eyetrajectories`. This is a *research-only complete-trajectory simulation*, not a result from actual eye-tracking participants. Exported/native interval estimators were not changed.

## Design and provenance

- Author's RStudio execution: `source("scripts/stress_native_band_distributions.R")` with `ET_BAND_ROBUST_REPS=200`, `ET_BAND_ROBUST_B=399`, `ET_BAND_ROBUST_SEED_OFFSET=43000000`.
- Output archive: `artifacts/band_robustness_stress/run_20261027_005525_pid51684/` (local Windows checkout).
- Four scenarios: `gaussian_baseline`, `heavy_t3`, `heteroskedastic_groups`, `skewed_lognormal`; three participant sizes: 12, 24 and 48; **200 independently generated datasets per scenario/size**.
- Each dataset supplied two paired estimands (participant functional mean, equal-group null contrast) and three paired interval candidates (existing fixed-SE bootstrap, studentized cluster bootstrap, Gaussian pooled-t Bonferroni reference). **2,400 independent datasets**, **14,400 successful method/estimand evaluations**, **zero reported fitting failures**.
- Nominal truth-in-simultaneous-band target: **90%**; 41 timestamps × two channels. Different seed offset from initial 20-dataset pilot (`96000000`); the run did not report a seed-overlap error.
- The results below were **parsed from the owner's complete simulation console** and subsequently **validated by the owner's separate read-only trial/summary archive audit**, which reconstructed all 72 cells and all 48 paired candidate/baseline contrasts from the saved trial rows. The raw CSV was not provided for independent row-by-row verification in this conversation.

## Per-cell results: 200 independent datasets each

| DGP | Participants | Estimand | Existing fixed-SE | Studentized cluster | Gaussian Bonferroni-t | Studentized gain | Studentized/baseline mean width |
|---|---:|---|---:|---:|---:|---:|---:|
| gaussian_baseline | 12 | mean | 136/200 = 68.0% | 192/200 = 96.0% | 197/200 = 98.5% | +28.0 pp | 1.498x |
| gaussian_baseline | 12 | contrast | 125/200 = 62.5% | 195/200 = 97.5% | 196/200 = 98.0% | +35.0 pp | 1.776x |
| gaussian_baseline | 24 | mean | 162/200 = 81.0% | 184/200 = 92.0% | 195/200 = 97.5% | +11.0 pp | 1.167x |
| gaussian_baseline | 24 | contrast | 144/200 = 72.0% | 179/200 = 89.5% | 195/200 = 97.5% | +17.5 pp | 1.215x |
| gaussian_baseline | 48 | mean | 166/200 = 83.0% | 178/200 = 89.0% | 197/200 = 98.5% | +6.0 pp | 1.063x |
| gaussian_baseline | 48 | contrast | 170/200 = 85.0% | 181/200 = 90.5% | 198/200 = 99.0% | +5.5 pp | 1.083x |
| heavy_t3 | 12 | mean | 137/200 = 68.5% | 195/200 = 97.5% | 198/200 = 99.0% | +29.0 pp | 1.730x |
| heavy_t3 | 12 | contrast | 107/200 = 53.5% | 196/200 = 98.0% | 199/200 = 99.5% | +44.5 pp | 2.036x |
| heavy_t3 | 24 | mean | 155/200 = 77.5% | 188/200 = 94.0% | 197/200 = 98.5% | +16.5 pp | 1.285x |
| heavy_t3 | 24 | contrast | 158/200 = 79.0% | 188/200 = 94.0% | 197/200 = 98.5% | +15.0 pp | 1.324x |
| heavy_t3 | 48 | mean | 174/200 = 87.0% | 185/200 = 92.5% | 198/200 = 99.0% | +5.5 pp | 1.222x |
| heavy_t3 | 48 | contrast | 169/200 = 84.5% | 185/200 = 92.5% | 199/200 = 99.5% | +8.0 pp | 1.230x |
| heteroskedastic_groups | 12 | mean | 145/200 = 72.5% | 194/200 = 97.0% | 198/200 = 99.0% | +24.5 pp | 1.596x |
| heteroskedastic_groups | 12 | contrast | 117/200 = 58.5% | 196/200 = 98.0% | 197/200 = 98.5% | +39.5 pp | 2.018x |
| heteroskedastic_groups | 24 | mean | 167/200 = 83.5% | 187/200 = 93.5% | 199/200 = 99.5% | +10.0 pp | 1.176x |
| heteroskedastic_groups | 24 | contrast | 164/200 = 82.0% | 191/200 = 95.5% | 197/200 = 98.5% | +13.5 pp | 1.249x |
| heteroskedastic_groups | 48 | mean | 175/200 = 87.5% | 187/200 = 93.5% | 197/200 = 98.5% | +6.0 pp | 1.071x |
| heteroskedastic_groups | 48 | contrast | 172/200 = 86.0% | 182/200 = 91.0% | 198/200 = 99.0% | +5.0 pp | 1.102x |
| skewed_lognormal | 12 | mean | 123/200 = 61.5% | 185/200 = 92.5% | 184/200 = 92.0% | +31.0 pp | 1.878x |
| skewed_lognormal | 12 | contrast | 110/200 = 55.0% | 197/200 = 98.5% | 198/200 = 99.0% | +43.5 pp | 2.021x |
| skewed_lognormal | 24 | mean | 143/200 = 71.5% | 181/200 = 90.5% | 190/200 = 95.0% | +19.0 pp | 1.289x |
| skewed_lognormal | 24 | contrast | 160/200 = 80.0% | 192/200 = 96.0% | 197/200 = 98.5% | +16.0 pp | 1.281x |
| skewed_lognormal | 48 | mean | 160/200 = 80.0% | 177/200 = 88.5% | 192/200 = 96.0% | +8.5 pp | 1.145x |
| skewed_lognormal | 48 | contrast | 172/200 = 86.0% | 187/200 = 93.5% | 199/200 = 99.5% | +7.5 pp | 1.124x |

The **studentized candidate has higher observed truth coverage than fixed-SE in all 24 cells**, with descriptive gains of **+5.0 to +44.5 percentage points**. All 24 studentized **mean band-width ratios are greater than one**, ranging **1.063x–2.036x**; high coverage may largely reflect conservative interval inflation. No candidate can be judged on coverage without this width trade-off.

The **three** studentized cells whose observed coverage falls below 90% are: Gaussian N=24 null contrast **179/200 (89.5%)**; Gaussian N=48 mean **178/200 (89.0%)**; and skewed-lognormal N=48 mean **177/200 (88.5%)**. Their separate exact 95% Monte Carlo intervals include 90% (approx. **[84.4,93.4]%**, **[83.8,93.0]%** and **[83.2,92.6]%**, respectively), so these estimates neither prove calibrated coverage nor conclusively demonstrate undercoverage in those individual cells. Small-N overcoverage is evident for some candidate designs, e.g. heavy-t(3) N=12 contrast **196/200 (98%)** at **2.036x** baseline mean width.

### Descriptive scenario totals — NOT independent-binomial calibration tests

| Generator | Existing fixed-SE | Studentized cluster | Gaussian Bonferroni-t |
|---|---:|---:|---:|
| gaussian_baseline | 903/1,200 (75.3%) | 1109/1,200 (92.4%) | 1178/1,200 (98.2%) |
| heavy_t3 | 900/1,200 (75.0%) | 1137/1,200 (94.8%) | 1188/1,200 (99.0%) |
| heteroskedastic_groups | 940/1,200 (78.3%) | 1137/1,200 (94.8%) | 1186/1,200 (98.8%) |
| skewed_lognormal | 868/1,200 (72.3%) | 1119/1,200 (93.3%) | 1160/1,200 (96.7%) |

Each 1,200 denominator aggregates **correlated mean and contrast evaluations generated from only 600 independent datasets per scenario** (200 per N). Do not compute binomial confidence intervals or formal coverage claims on the pooled denominators. Use **200** independent generating datasets in each separately defined DGP/N/estimand cell.

## Scientific limitations and interpretation

1. **Existing fixed-SE undercoverage:** Especially severe in N=12 null contrasts, including heavy t(3) **107/200 = 53.5%**, skewed lognormal **110/200 = 55.0%**, and unequal group variances **117/200 = 58.5%**. That is a genuine *specific-generator* inferential concern despite 100% fitting success.
2. **Studentization improves observed coverage but may be overly conservative:** It achieves **92.5–98.5%** in many cells while increasing mean band width; at N=12, widths rise by around 50–104% across the tested generator/estimand combinations. No general target-calibration guarantee follows.
3. **Gaussian/pooled-t Bonferroni-t is only assumption-matched in the independent Gaussian, equal-variance condition.** Its high coverage elsewhere is an empirical sensitivity result, not a valid theorem for heavy tails, skewness or unequal group variances.
4. **All evaluations are paired by generating dataset.** Counts are not 14,400 independent studies. The script currently reports aggregate truth coverage and width, not per-dataset array-wise nesting of confidence bands.
5. **Missingness and observation-process robustness not tested:** no MCAR/MAR/MNAR, participant dropout, sparse/asynchronous trajectories, gaze-dependent observation probability, or full-population-versus-observed-target distinction.
6. **Evidence limitations:** The owner's **read-only large-archive audit PASSED**, including full six-way pairing, summary reconstruction, seed uniqueness, zero fit failures, and candidate recoveries/losses. The source CSV itself has **not** been independently rerun or inspected row-by-row in this assistant environment.

## Reproducibility gate: expanded archive audit PASSED

The owner **executed** the read-only script on the larger archive. The exact reproducing command is preserved here:

```r
Sys.setenv(
  ET_BAND_ROBUST_AUDIT_DIR =
    "artifacts/band_robustness_stress/run_20261027_005525_pid51684"
)
source("scripts/audit_native_band_distributions.R")
Sys.unsetenv("ET_BAND_ROBUST_AUDIT_DIR")
```

**Observed and verified in the author's RStudio audit:** 2,400 unique generating studies, 14,400 trial rows, zero failed evaluations, 72 consistent summary cells and 48 complete candidate-versus-baseline paired comparisons of 200 studies each. **All 48 pairs had zero observed baseline-covered/candidate-missed datasets**, with studentized average width ratios **1.062766–2.036074** and Gaussian reference ratios **1.326512–1.982138**. This is an empirical finite-simulation inclusion pattern, *not* a theorem of set nesting or evidence of general calibration.

The next-stage [missing-gaze and observation-process qualification protocol](missing-gaze-observation-process-qualification-2026-10-27.md) now prespecifies distinct full-population, selected-participant and observed-sample estimands, and differentiates MCAR, MAR, MNAR, dropout and asynchronous sampling. **It is a protocol only: no missingness simulations have run.**

**Development decision:** Research HOLD. Reassess method calibration against prespecified operating tolerances, wider intervals and independent observation-process/missingness scenarios before considering any estimator replacement. PR #6 remains unmerged and no CRAN release is approved.

## Separate expanded archive audit — executed 27 October 2026

Source: `artifacts/band_robustness_stress/run_20261027_005525_pid51684/`.
New read-only audit archive:
`artifacts/band_robustness_stress_audit/audit_20261027_013922_pid51684/`.

The owner's output explicitly states
`Robustness archive summary/trial consistency: PASS`, with
**2,400 generating datasets, 14,400 successful evaluations, zero failures**.
The script compared all **72** source summary cells against the
saved trial records, verified the unique generator seed and complete
six-way pairing for each generating study, and produced **48**
candidate-versus-baseline paired comparisons with **200 jointly
successful datasets per comparison**.

### Paired gains versus the fixed-SE bootstrap

Across **24** studentized comparisons, the candidate recovered
previously uncovered studies in every condition; the reported
coverage improvement ranged from **+5.0 to +44.5 percentage points**.
Across the **24** Gaussian Bonferroni-t comparisons, observed gains
ranged from **+11.0 to +46.0 percentage points**. Both candidate
families had **0 observed baseline-covered/candidate-missed**
studies in all 48 comparisons. This is not proof that each
candidate band contains the original band on every dataset.

The average candidate-to-baseline width ratios were:

- Studentized cluster bootstrap: **1.062766–2.036074**.
- Gaussian Bonferroni-t reference: **1.326512–1.982138**.

The separate audit produced 2,000-draw paired Monte Carlo bootstrap
intervals for coverage gains and width ratios. Those intervals
measure simulation uncertainty **conditional on each fixed DGP**;
they do not adjust for the 48 exploratory comparisons, the selection
of candidates, model misspecification or missingness.

Examples of precisely paired studentized improvements:

| DGP / participants / estimand | Coverage gain | 95% paired MC interval | Previously missed now covered | Previously covered now missed | Width ratio |
|---|---:|---|---:|---:|---:|
| Gaussian N12 mean | +28.0 pp | [+22.0,+34.5] | 56 | 0 | 1.497996 |
| Gaussian N12 null contrast | +35.0 pp | [+28.5,+41.5] | 70 | 0 | 1.775993 |
| Heavy-t(3) N12 null contrast | **+44.5 pp** | [+37.5,+51.5] | 89 | 0 | **2.036074** |
| Unequal-variance N12 null contrast | +39.5 pp | [+32.5,+46.5] | 79 | 0 | 2.017869 |
| Skewed-lognormal N12 mean | +31.0 pp | [+24.5,+37.5] | 62 | 0 | 1.878190 |
| Skewed-lognormal N48 mean | +8.5 pp | [+5.0,+12.5] | 17 | 0 | 1.144927 |

As expected, wider intervals commonly cover more true curves.
The gain–width trade-off is essential; neither good
computational reliability nor increased empirical coverage alone
justifies replacing the released estimator.

**Status: archive reproducibility gate PASS. Scientific validity,
missing-gaze processes, population estimands and release gates
remain OPEN. The package's native estimators were not changed.**
