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

**Execution status:** New R files passed *static* delimiter inspection, but R parser execution, tests, new Monte Carlo, and new archive audit have **not** yet run. Scientific acceptance and PR #6 merge/release remain blocked.

## 27 October 2026: MAR propensity bug identified and patched (retest required)

The owner's first execution of `testthat::test_local(".", filter="observation-ipw-research")` reported **29 PASS / 1 FAIL / 0 WARN / 0 SKIP**. The failing equality check compared the reconstructed observed-Z/time/channel MAR retention probabilities against the probabilities stored by the latent mask generator. The research point-estimator script had named its probability vector `pi`, unintentionally **shadowing R's mathematical constant** in `cos(2*pi*time)`. This changed the retained-sample propensity calculation and would bias the intended inverse-probability weights.

**Fix:** Rename the vector `retention_probability`, explicitly reference `base::pi` in the periodic MAR component, and add an independent deterministic analytic regression fixture at times 0, 0.25, and 0.5. The original generator-vs-reconstruction test is retained.

**Status:** The source correction and regression test are committed to the research branch but have **not been rerun under R here**. Do not run the 240-dataset Monte Carlo until the complete updated `observation-ipw-research` test filter passes. No pilot archive is known to have been produced by the failed test.
