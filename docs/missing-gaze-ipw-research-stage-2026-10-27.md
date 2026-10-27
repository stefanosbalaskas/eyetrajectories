# Missing-gaze research: independent MCAR/MAR point-estimator pilot (27 October 2026)

**Research-only. Not yet executed. Not calibrated 90% confidence bands, not a deployable missingness correction, not a CRAN release.**

## Engineering evidence from the prior pilot

The owner executed 40/40 passing `testthat` assertions, 480 generating studies, a 24-cell row/summary archive audit (PASS), and a new read-only mechanism audit (PASS). The first-stage archive is `artifacts/missing_gaze_pilot/run_20261027_094753_pid51684/`; the derived read-only report is `artifacts/missing_gaze_mechanism_report/audit_20261027_100550_pid51684/`. These are owner-local archives, not independently inspected raw CSVs in this session.

Of 74 no-full-grid-support datasets, **37** arise from `sparse_asynchronous`, **30** from `unequal_density`, **4** from `mar_dropout`, and **3** from `mnar_dropout`. Each mechanism had 60 independently generated studies across N=12,24,48. All 180 gaze-thinning studies under MCAR/MAR/MNAR met the strict full-grid requirement in this pilot. Despite 37/60 and 30/60 whole-curve support failures in the sparse and unequal-density mechanisms, mean contrast-coordinate support remained 99.39% and 99.21%, respectively. This distinction reflects a stringent requirement for **at least two observed participants per group at every coordinate**, not absence of almost all the observed curve.

## Stage 2 experiment: point-estimation proof of concept

New code:

- `scripts/observation_ipw_research.R` — public-design propensity reconstruction and **Horvitz–Thompson** (HT) point estimators using only observed gaze and fully observed participant baseline registry; never receives latent masked gaze or an infeasible MNAR oracle.
- `scripts/run_missing_gaze_ipw_pilot.R` — independently seeded, nonoverwriting, failure-inclusive comparison between the existing participant-balanced observed-data naive mean and the known-design HT estimator. Defaults to Gaussian generating family; complete, MCAR gaze, observed-`Z`/time MAR gaze, and observed-`Z` MAR participant dropout; N=12/24/48; 20 study replicates/cell (**240 independent datasets**, 12 cells). Uses seed offset 330000000 and prevents reuse of prior IPW and first-stage archives.
- `scripts/audit_missing_gaze_ipw_pilot.R` — independent, read-only trial/summary count, support fraction, exact Monte Carlo CI, seed and diagnostic consistency checks.
- `tests/testthat/test-observation-ipw-research.R` — design-propensity equivalence tests, complete-data equality, no masked-value leakage, MNAR/unsupported input refusal, and all-grid-vs-conditional-support reporting.

Both methods operate on **the same observed dataset within each generated study**, making each naive-vs-HT contrast paired. Across mechanisms, generating seeds are independent; do **not** treat MCAR/MAR mechanism comparisons as paired. The 240 point-estimate method outputs are not independent additional datasets.

### Target, estimator, and limitations

Primary truth remains the **unconditional participant-balanced full-population mean**, with null full-population two-group contrast. For each time and channel with `N` eligible participants and `J` scheduled trials, HT divides weighted observed outcomes by **N × J** (or **N_group × J** in each group) rather than dividing by the observed number of samples. Under the prespecified MCAR/MAR response law and known inclusion probabilities this is a design-unbiased estimator of the finite-sample full-data trajectory, conditional on the complete data; the Monte Carlo simulation also assesses error against the population generating truth. The known probabilities are fixed by the simulation rules; uncertainty from **estimating** propensity scores is not represented.

The full-grid HT output is reported even when no observation is available in a coordinate (its empty weighted sum is zero); this is inherent in the prespecified HT formula, **not observed gaze or imputation**. Such high-variance coordinates must remain explicit. For like-for-like comparisons with the naive estimator, signed error and RMSE are also reported *only on the common, sufficiently supported coordinates*, with support rates and `no_observation_support` status retained. Conditional-on-support metrics alone cannot establish unconditional unbiasedness. The all-grid HT errors are reported separately without excluding unsupported studies.

**Do not** transfer these design-known point results to MNAR, estimated propensity scores, arbitrary off-grid sparse trajectories or uncertainty bands. Under MNAR the full-population mean remains nonidentified without sensitivity assumptions. No confidence interval, standard error or 90% simultaneous-band coverage is constructed here.

## Execute the engineering pilot in the owner's RStudio

Pull the latest `research/native-parity-stage1` branch, run from the repository root:

```r
testthat::test_local(".", filter = "observation-ipw-research")

Sys.setenv(
  ET_OBS_IPW_REPS = "20",
  ET_OBS_IPW_SEED_OFFSET = "330000000",
  ET_OBS_IPW_SEVERITY = "moderate",
  ET_OBS_IPW_FAMILIES = "gaussian_baseline"
)
source("scripts/run_missing_gaze_ipw_pilot.R")
Sys.unsetenv(c("ET_OBS_IPW_REPS", "ET_OBS_IPW_SEED_OFFSET",
               "ET_OBS_IPW_SEVERITY", "ET_OBS_IPW_FAMILIES"))

source("scripts/audit_missing_gaze_ipw_pilot.R")
```

The runner writes `ipw_trials.csv`, `ipw_summary.csv`, and a manifest in a newly timestamped `artifacts/missing_gaze_ipw_pilot/run_.../` directory. If a seed collision is detected, stop and choose a genuinely new offset rather than bypassing the safeguard. Preserve all unsupported and error rows.

**Execution status updated below:** The corrected estimator tests and 240-dataset pilot have run in the owner's Windows RStudio. The original archive audit failed due to a summary-field lookup error; its correction still requires an R rerun. Scientific acceptance and PR #6 merge/release remain blocked.

## 27 October 2026: MAR propensity bug identified and patched (retest required)

The owner's first execution of `testthat::test_local(".", filter="observation-ipw-research")` reported **29 PASS / 1 FAIL / 0 WARN / 0 SKIP**. The failing equality check compared the reconstructed observed-Z/time/channel MAR retention probabilities against the probabilities stored by the latent mask generator. The research point-estimator script had named its probability vector `pi`, unintentionally **shadowing R's mathematical constant** in `cos(2*pi*time)`. This changed the retained-sample propensity calculation and would bias the intended inverse-probability weights.

**Fix:** Rename the vector `retention_probability`, explicitly reference `base::pi` in the periodic MAR component, and add an independent deterministic analytic regression fixture at times 0, 0.25, and 0.5. The original generator-vs-reconstruction test is retained.

**Status:** The source correction and regression test are committed to the research branch but have **not been rerun under R here**. Do not run the 240-dataset Monte Carlo until the complete updated `observation-ipw-research` test filter passes. No pilot archive is known to have been produced by the failed test.

## 27 October 2026: 240-study pilot completed; initial archive audit defect isolated

**Owner execution:** The corrected `testthat::test_local(".", filter="observation-ipw-research")` reported **31 PASS, zero failures/warnings/skips**. The independent known-design IPW point-estimation pilot ran **240/240 generating studies** (4 mechanisms × 3 N values × 20 per cell), reporting **235 full-grid-supported**, **5 no-observation-support**, **0 numerical failures**. Owner-local archive: `artifacts/missing_gaze_ipw_pilot/run_20261027_103444_pid51684/`. Its raw trial and summary CSVs have not been independently inspected here.

**Audit bug and fix:** The first `source("scripts/audit_missing_gaze_ipw_pilot.R")` stopped with `missing value where TRUE/FALSE needed`, not a quantitative archive inconsistency. The runner writes a trial column `observed_fraction` and correctly summarizes it as `mean_observed_fraction`. The auditor was erroneously looking up `summary[["observed_fraction"]]`, which returns `NULL`; the subsequent Boolean comparison was invalid. The research branch now contains a named metric mapping, a strict missing-column check, and `et_ipw_verify_metric()` with explicit NA, finite-value, and dimension handling in `scripts/audit_missing_gaze_ipw_helpers.R`. The auditor now sources those helpers. Regression tests were added in `tests/testthat/test-observation-ipw-audit.R`.

**Re-run only the corrected tests and read-only audit on the existing archive**, after pulling the updated research branch:

```r
testthat::test_local(".", filter="observation-ipw-audit")
Sys.setenv(
  ET_OBS_IPW_AUDIT_DIR =
    "artifacts/missing_gaze_ipw_pilot/run_20261027_103444_pid51684"
)
source("scripts/audit_missing_gaze_ipw_pilot.R")
Sys.unsetenv("ET_OBS_IPW_AUDIT_DIR")
```

**Historical gate at the first audit failure:** archive consistency was pending. The owner subsequently passed the corrected audit; see the newer milestone below. No IPW weighting benefit or confidence-band validity has yet been demonstrated. PR #6 remains unmerged and CRAN release blocked.

## 27 October 2026: IPW engineering archive certified; paired error review staged

**Owner execution evidence:** The audit-helper regression tests passed **8/8** (`FAIL 0, WARN 0, SKIP 0`). The corrected `source("scripts/audit_missing_gaze_ipw_pilot.R")` reported **DESIGN-KNOWN IPW ARCHIVE AUDIT PASS**: **240 independent studies**, **12 cells**, **235 full-grid supported**, **5 no-observation-support**, **0 numerical failures**. This supersedes the historical audit failure above. The archive remains local to the owner; no copied trial-level dataset has been independently examined in this session.

**New read-only scientific analysis:** `scripts/analyze_missing_gaze_ipw_results.R` plus `scripts/analyze_missing_gaze_ipw_helpers.R` and independent regression tests `tests/testthat/test-observation-ipw-paired-analysis.R` were added to PR #6. They **have not been executed under R**. The analysis re-runs the existing independent archive audit first, then produces two research tables (no new trajectories or masks generated):

- `paired_rmse_by_cell.csv`: naive vs design-known Horvitz–Thompson (HT) within the **same dataset** and common supported coordinates, separately for mean and two-group contrast and N=12/24/48. Reports average *within-dataset functional RMSE*, paired HT-minus-naive RMSE, ratio of those means, mean signed error, how many paired datasets contribute, and a 1,999-draw paired-dataset bootstrap percentile interval for the **Monte Carlo performance difference**. Includes both partial-support and strict full-grid-supported-only comparisons with explicitly distinct denominators. **These are not trajectory confidence bands**.
- `ht_all_grid_by_cell.csv`: HT-only entire-grid signed error and per-dataset RMSE, **including** the five unsupported studies (unless a study genuinely failed numerically), with dataset-bootstrap interval on the mean signed error. A comparable unconditional all-grid naive estimator is not available for all studies, so none is fabricated.

Run from the updated research checkout:

```r
testthat::test_local(".", filter = "observation-ipw-paired-analysis")
Sys.setenv(
  ET_OBS_IPW_AUDIT_DIR =
    "artifacts/missing_gaze_ipw_pilot/run_20261027_103444_pid51684"
)
source("scripts/analyze_missing_gaze_ipw_results.R")
Sys.unsetenv("ET_OBS_IPW_AUDIT_DIR")
```

A new non-overwriting research directory `artifacts/missing_gaze_ipw_pair_analysis/review_...` receives the outputs. The **exact original input archive is unchanged**. Conditional-on-full-grid comparisons are selected-sample performance, and coordinate-supported comparisons can depend on selection; neither by itself demonstrates unconditional unbiasedness. 20 repetitions per mechanism/sample-size cell are exploratory. Do not characterize dataset-bootstrap Monte Carlo intervals as 90% functional confidence bands or as final publication-quality calibration.

**Gate:** raw data integrity PASS as reported by the owner; actual naive-vs-HT performance **unknown until paired analysis executes**. No release, no native estimator replacement, no claims of calibrated 90% simultaneous coverage.
