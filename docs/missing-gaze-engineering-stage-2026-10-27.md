# Missing-gaze observation-process engineering handoff — 27 October 2026

**Research-only implementation, NOT an executed missing-gaze study, package estimator, inferential qualification, or release authorization.** Complements the [prespecified observation-process protocol](missing-gaze-observation-process-qualification-2026-10-27.md). The existing fixed-SE and studentized bands remain unqualified under missing gaze.

## Staged components

- `scripts/observation_process_fixture.R`: independent complete participant/trial/channel trajectories with 41 evaluation-grid points; fully observed baseline covariate Z, pre-mask full-population means and null contrast, and separate realized masks for complete data, MCAR, MAR, MNAR, MAR participant dropout, MNAR participant dropout, unequal density and sparse participant/trial-specific subsets of the common grid. Missing values are **never filled**.
- `scripts/run_missing_gaze_pilot.R`: seed-disjoint, failure-inclusive research pilot; defaults to Gaussian data, N=12/24/48, 20 independent generated datasets per mechanism/N (480 datasets across eight mechanisms), moderate severity. Outputs `missing_gaze_trials.csv`, `missing_gaze_summary.csv`, and `manifest.txt`. No package dependency beyond base/recommended R.
- `scripts/audit_missing_gaze_pilot.R`: independent read-only trial/summary reconciliation, distinct generator/mask seeds, status/denominator checks and missingness diagnostics.
- `tests/testthat/test-observation-process-fixture.R`: latent truth/observed-data separation, reproducibility, RNG restoration, MAR/MNAR distinction, participant dropout and unsupported grid tests.

## Initial owner-run verification

Run **from the repository root** after pulling `research/native-parity-stage1`:

```r
testthat::test_local(".", filter = "observation-process-fixture")
Sys.setenv(ET_OBS_REPS = "20",
           ET_OBS_SEVERITY = "moderate",
           ET_OBS_SEED_OFFSET = "125000000",
           ET_OBS_FAMILIES = "gaussian_baseline")
source("scripts/run_missing_gaze_pilot.R")
Sys.unsetenv(c("ET_OBS_REPS", "ET_OBS_SEVERITY",
               "ET_OBS_SEED_OFFSET", "ET_OBS_FAMILIES"))
source("scripts/audit_missing_gaze_pilot.R")
```

If an archive already exists, the preflight seed collision guard should halt and **must not be bypassed**; use a genuinely new seed offset only for an intended new replication. The audit defaults to the latest completed archive; to inspect a particular archive, set `ET_OBS_AUDIT_DIR` first. Preserve all failure/no-support rows.

## Interpretation boundaries

- The naive diagnostic averages trials **within participants**, then averages participants or group means, and compares these observed-data estimates to the generator's declared **unconditional full-population** truth. This exposes selection bias, not a demonstrated correction for it.
- RMSE and bias are **supported-coordinate only**, explicitly recorded alongside the supported fraction. A study missing sufficient participants at any time/channel receives `no_observation_support`.
- MCAR and observed-Z/time MAR generation expose known retention probabilities in the **sealed mask** for potential future identification diagnostics; no propensity-corrected estimator has been implemented or validated.
- For MNAR, latent Y/effects affect retention by construction. Internal mask probabilities are **infeasible oracles**, not observed-data information.
- Sparse asynchronous observation here means **irregular participant/trial-specific subsets of the 41-point grid**, not arbitrary off-grid timestamps. Continuous-time smoothing/interpolation requires a separately qualified stage.
- These scripts do not construct confidence bands. No 90% simultaneous coverage is reported, and no 90% coverage assertion is licensed by this engineering pilot.
- On the owner's Windows RStudio session the **fixture tests, pilot and original row/summary audit subsequently passed**; the assistant environment still cannot execute R or independently inspect the local raw CSVs. GitHub Actions runner admission failure remains tracked in issue #3.

## After the audit

Only after an executed PASS should the next research step add prespecified, separately labeled full-population and observed-cohort estimators, analyze identification under MCAR/MAR, and conduct a disjoint-seed 200-study-per-cell experiment across all four latent families and three severities. Candidate *confidence bands* require a distinct validity and interval-width gate. Do not merge research PR #6, replace native estimators, or submit to CRAN on the basis of these fixtures.


## Owner-executed pilot verification (27 October 2026)

- `testthat::test_local(".", filter="observation-process-fixture")`: **40 PASS / 0 FAIL / 0 WARN / 0 SKIP**.
- Pilot archive: `artifacts/missing_gaze_pilot/run_20261027_094753_pid51684/`. Exactly **480 generated datasets**, **24 cells**; **406 full-grid supported**, **74 no-observation-support**, **0 numerical failures**.
- Independent `scripts/audit_missing_gaze_pilot.R`: **PASS** on that archive, according to the owner's RStudio console. Raw CSVs are local to the owner and have not been independently inspected here.
- This is an **engineering gate**, not a calibrated inferential-coverage finding. The 74 unsupported datasets must remain in every denominator and be stratified before evaluating alternatives.

### Read-only next step: explain the 74 no-support datasets

From the repository checkout after pulling the research branch, run:

```r
Sys.setenv(
  ET_OBS_REPORT_DIR =
    "artifacts/missing_gaze_pilot/run_20261027_094753_pid51684"
)
source("scripts/report_missing_gaze_mechanisms.R")
Sys.unsetenv("ET_OBS_REPORT_DIR")
```

This does **not** create new simulated datasets. It verifies cell-level counts and independent seeds, reports support rates with exact simulation intervals for each mechanism and N, and saves separate `by_mechanism.csv` and `by_mechanism_N.csv` files under a **new** `artifacts/missing_gaze_mechanism_report/audit_...` directory. Signed bias and RMSE are *conditional on supported coordinates*; they must never be interpreted as unconditional performance or valid confidence-band coverage. Do not use the original default seed offset to rerun the same 480 datasets.
