# Conformal FPCA anomaly screening: independent Monte Carlo audit

**Status: newly committed research script, not yet executed in R.**
Version `0.4.1.9000` on `research/native-parity-stage1`. The existing
native R estimator `etr_split_conformal_fpca_anomalies()` remains unchanged.
No PyPI or CRAN release is authorized by this audit.

## The theoretical claim being audited

A model fitted independently of the calibration/test data defines a
nonconformity score (here, the root integrated FPCA reconstruction
residual). For `n` calibration scores, the script calls the package's
existing split-conformal threshold at order-statistic rank

`k = ceiling((n + 1) * (1 - alpha))`.

If k is greater than n, the threshold is infinite. With independent,
exchangeable calibration/test curves and continuous/no-ties scores, the
marginal one-future-curve false-alarm probability is exactly
`(n + 1 - k)/(n + 1)` (or zero for the infinite threshold), never
above alpha. With n=19, the exact rank reference is 0.05 when
alpha=0.05 and 0.10 when alpha=0.10. This is NOT conditional validity,
batch-wise false-alarm control or a familywise functional confidence band.

Reference methodology: [Conformal prediction with conditional guarantees]
(https://academic.oup.com/jrsssb/article/87/4/1100/8058684), describing
the classical split-conformal exchangeability rank argument.
Related R functionality: [CRAN conformalInference.fd]
(https://CRAN.R-project.org/package=conformalInference.fd), which targets
functional prediction regions, a different estimand from anomaly
screening via an FPCA reconstruction score.

## Designs — independent generating studies

Each study draws one independent FPCA training dataset, a disjoint
calibration dataset, one ordinary held-out test curve, and a deliberately
shifted version of the **same** test curve. A new frozen rank-one native
FPCA model is fitted in each generating study. The alternative test
contains a fixed sinusoidal waveform perturbation; its detection rate
is descriptive, not a universal statistical power claim.

| Condition | Training/calibration | Ordinary held-out test | Guaranteed reference? |
|---|---|---|---|
| `iid_exchangeable` | Independent curves with the same latent coefficient/noise law | Same law | Yes, under exchangeability, frozen fit and continuity |
| `test_noise_shift` | Independent curves from baseline noise law | Threefold test-only measurement noise | **No:** calibration/test exchangeability deliberately fails |
| `dependent_calibration` | Calibration curves share participant-level latent coefficients in pairs | A new independent participant's curve | **No:** calibration scores dependent, joint exchangeability not established |

The three scenarios must never be pooled into one conformal coverage
estimate. Multiple alpha settings on the same generated study are
paired. Ordinary/shifted test curves are paired too. Each scenario
has one *independent generating dataset* per Monte Carlo repetition.

## Run in RStudio, from the checked-out research branch

```r
# A pilot with independent training/calibration/test cohorts
Sys.setenv(
  ET_CONFORMAL_REPS = "200",
  ET_CONFORMAL_TRAIN = "24",
  ET_CONFORMAL_CALIBRATION = "19",
  ET_CONFORMAL_ALPHAS = "0.05,0.10",
  ET_CONFORMAL_SHIFT = "0.6"
)
source("scripts/run_conformal_monte_carlo.R")
```

The owner executed the initial 200-study-per-scenario pilot on
26 October 2026 with zero failures. Its exact coverage intervals, stress
results and limitations are recorded in
[the first conformal pilot results](conformal-pilot-results-2026-10-26.md).

For a higher-precision *qualification candidate*, set
`ET_CONFORMAL_REPS='2000'`. Each run now creates its own
`run_YYYYMMDD_HHMMSS_pidNNNN/` archive: previous outputs are retained
rather than overwritten. If alpha=0.10, 2,000 independent generating
studies give an approximate binomial Monte Carlo SE of 0.0067 under
the exact 10% reference. More studies may be required to investigate
small deviations or multiple conditions. This script is a **diagnostic**
and does not formally certify real-world conditional, cluster-wise,
or cross-platform conformal validity.

## Outputs and interpretation

Under a timestamped run-specific subdirectory of
`artifacts/conformal_monte_carlo/` (ignored by Git):

- `conformal_trials.csv`: every scenario/dataset/alpha, seeds,
  calibration rank/threshold, held-out null/shifted scores and flags,
  and fit status or exception message
- `conformal_summary.csv`: success/failure counts, false-alarm rate and
  exact 95% binomial Monte Carlo interval, shifted detection rate and
  interval, mean thresholds, and the exact rank reference for **only**
  the exchangeable design
- `conformal_failures.csv`: present only when fits fail
- `conformal_monte_carlo_figures.pdf`: false-alarm and detection plots
  with uncertainty bars for every alpha
- `MANIFEST.txt`: seed structure, environment, assumptions and Git HEAD

Failures are never silently discarded or coded as nonflags. The
conditional-on-success Monte Carlo rate and the number of failed
datasets must be reported together. A successful software run and
theoretical rank calculation are not proof of a calibrated score model
under missingness, repeat measurements, informative observation
processes, or shifted subject populations.

## Before considering a method qualified

1. Execute and debug this pilot, including all 3 exchangeability designs.
2. Independently repeat at 2,000+ datasets for the exchangeable null,
   verify false-alarm estimates and uncertainty around rank targets,
   inspect ties and finite/infinite thresholds, and report all fit failures.
3. Repeat across alternative training sizes, calibration sizes,
   measurement noise, outlier magnitude, rank selection and missingness.
4. Develop genuine **participant-level** conformal analysis when
   there are multiple curves per participant; naïve curve-level
   exchangeability cannot be assumed.
5. Separately qualify the already-known under-covering functional
   bootstrap confidence bands. An anomaly screen does not solve
   simultaneous mean/contrast coverage.
6. Obtain Linux/macOS, old-release R and optional dependency checks
   before any merge/release review.

## Independent small mathematical tests

The new offline R fixture
`tests/testthat/test-native-parity-conformal-qualification.R`
enumerates all 20 possible held-out ranks (n=19) for alpha
0.05/0.10/0.20, checks calibration order invariance and ties,
and exercises frozen-model scoring with disjoint curve IDs.
These tests are fast; they do not substitute for the Monte Carlo study.

### Read an archived run

```r
# After pulling the research branch:
source("scripts/read_conformal_results.R")

# Or a specific archive, without rerunning the simulation:
Sys.setenv(ET_CONFORMAL_RUN_DIR =
  "artifacts/conformal_monte_carlo/run_20261026_103751_pid51684")
source("scripts/read_conformal_results.R")
Sys.unsetenv("ET_CONFORMAL_RUN_DIR")
```

The helper verifies per-scenario trial and summary counts. The runner prints
its exact summary and trials paths after a run. No flat
`artifacts/conformal_monte_carlo/conformal_summary.csv` file is created.

### Independent high-replication seed scheme

The first 200-study pilot used `ET_CONFORMAL_SEED_OFFSET=0`. Increasing
`ET_CONFORMAL_REPS` alone repeats its initial seeds and would not constitute
an entirely independent replication. To generate 2,000 *new* studies per
scenario, set:

```r
Sys.setenv(ET_CONFORMAL_REPS = "2000",
           ET_CONFORMAL_SEED_OFFSET = "1000000")
source("scripts/run_conformal_monte_carlo.R")
source("scripts/read_conformal_results.R")
```

The seed offset is recorded in the run manifest. All studies retain their
individual seeds and separate, non-overwriting timestamped output directories.
The high-replication stage is **not yet executed**.

## Expanded independent replication

The author reported a 2,000-independent-generating-dataset-per-scenario run
with zero fitting failures and exchangeable false alarms of .055/.098,
consistent with .05/.10 continuous rank references. The full six-cell
numerical report, exact intervals and provenance limitations are recorded
in [conformal replication evidence](conformal-replication-results-2026-10-26.md).
The uploaded raw trial CSV corresponds to the 200-study pilot only.
Run `source('scripts/audit_conformal_replication.R')` on the synchronized
research branch to compare both archived runs, validate summary counts,
and reject overlapping seeds. Higher experimental precision by itself
does not establish real-world robustness, participant-level validity, or
calibrated simultaneous functional confidence bands.
