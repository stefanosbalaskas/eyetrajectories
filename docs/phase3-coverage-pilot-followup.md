# Phase 3 known-truth pilot audit — 2026-10-25

## Evidence status

User-executed Windows 11 / R 4.6.1 audit of eyetrajectories 0.3.2.9000.
The uploaded local MANIFEST reports Git SHA as local-unverified.
Five generated studies per main design, B=49 bootstrap draws and 12 independent
participants were used; there was no sparse PACE recovery in this smoke run.
The four-panel PDF is a diagnostic visualization and does not itself demonstrate
nominal simultaneous confidence-band coverage.

## Descriptive findings

| Design | Simultaneous inclusion | Mean pointwise inclusion | Target |
|---|---:|---:|---:|
| Randomized group contrast | 3/5 (60%) | 71.22% | 90% |
| Participant mean band | 2/5 (40%) | 71.95% | 90% |

Exact two-sided 95% binomial uncertainty intervals for Monte Carlo coverage:
group contrast [0.1466, 0.9473]; participant mean [0.0527, 0.8534].
Group-contrast failures were simulations 2 (RMSE 0.3162) and 3 (RMSE 0.2150).
These outcomes warrant more replication and investigation of finite-cluster
bootstrap behavior, not a declaration of validated coverage.

The analytic between-participant variance truth was 0.131667, with mean estimate
0.133742, mean bias 0.002075 and Monte Carlo SE 0.010650 over five studies.
Descriptive multilevel mean-curve RMSE was 0.100351 over three runs.

For each of three independent Markov-chain transfer-entropy null designs
(persistence 0.55, 0.80, 0.95), no diagnostic false flags were seen across
five trials. A zero sample flag rate produces a zero plug-in MC SE, but its
two-sided exact 95% binomial upper bound remains 0.5218. The shift
diagnostic is not a calibrated hypothesis test.

## Independent local follow-up

Pull the newest main in GitHub Desktop. From the root of the cloned project
in RStudio, run:

```r
Sys.setenv(
  ET_PHASE3_GRID_SIMS = "100",
  ET_PHASE3_GRID_B = "399",
  ET_PHASE3_GRID_SUBJECTS = "12,24,48"
)
source("scripts/run_phase3_coverage_grid.R")
```

The grid runs independent known-truth group-contrast and participant-mean
evaluations at three participant sample sizes and reports all observed
simultaneous inclusions, exact 95% binomial intervals, mean pointwise rates
and, where available, contrast estimation RMSE. Failed designs are written
to a separate error table; they are never silently discarded.

Local output under artifacts/phase3_coverage_grid (Git-ignored):

- coverage_grid_summary.csv
- coverage_grid_trials.csv
- coverage_grid_failures.csv (only if execution fails)
- MANIFEST.txt

This is still exploratory Monte Carlo evaluation; results do not qualify
the fixed-SE max-standardized simultaneous bootstrap, sparse PACE, or
general transfer-entropy inference for published use.
