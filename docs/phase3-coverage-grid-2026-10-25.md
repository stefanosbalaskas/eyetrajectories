# Phase 3 finite-sample coverage grid — local Windows evidence (25 October 2026)

**Evidence provenance:** Console output supplied by the package author from
Windows 11 / R 4.6.1. The local Phase 3 grid source is
`scripts/run_phase3_coverage_grid.R`; no attached trials CSV was independently
audited at the time this summary was written.

**Design:** 100 independent synthetic datasets per cell; B=399
participant-cluster bootstrap draws; nominal target simultaneous coverage
90%; six configurations, 600 total datasets, **zero fitted-design failures**.
Group-contrast assignment has equal arms, hence 6, 12 and 24 participants
per arm for N=12, 24 and 48 respectively. The bootstrap method remains
fixed-original-standard-error max-standardized, experimental.

| Method | Participants | Fits | Contained truth | Coverage | Exact 95% interval | Mean pointwise |
|---|---:|---:|---:|---:|---:|---:|
| Group contrast | 12 | 100 | 65 | 0.65 | [0.5482, 0.7427] | 0.8287 |
| Group contrast | 24 | 100 | 79 | 0.79 | [0.6971, 0.8651] | 0.8459 |
| Group contrast | 48 | 100 | 84 | 0.84 | [0.7532, 0.9057] | 0.8729 |
| Participant mean | 12 | 100 | 63 | 0.63 | [0.5276, 0.7244] | 0.8106 |
| Participant mean | 24 | 100 | 89 | 0.89 | [0.8117, 0.9438] | 0.8854 |
| Participant mean | 48 | 100 | 86 | 0.86 | [0.7763, 0.9213] | 0.9012 |

## Interpretation and decision

The strong undercoverage seen at N=12 persists after increasing Monte Carlo
replication and the bootstrap draw count. At N=24, the group-contrast
exact Monte Carlo interval remains below the nominal 90% benchmark.
Group contrast improves with N in this design but the N=48 result does
not establish nominal simultaneous coverage. Mean-band coverage is
non-monotonic (0.63, 0.89, 0.86), with insufficient precision to
confirm qualification at N=24 or 48.

Zero failed fits indicates that operational reliability of the six runs
was good. It does not imply scientifically adequate confidence bands.
Exact intervals characterize Monte Carlo estimation precision; they are
not confidence intervals for an observed real-data effect.

**Scientific status: HOLD.** No calibrated 90% coverage claim, no
general-purpose inferential recommendation, and no CRAN submission
based on these pilot/grid outcomes. Reconsider the fixed-SE max
calibration, percentile intervals, participant-level studentization,
small-cluster corrections and independent oracle comparisons.
Repeat experiments under multiple seeds, heteroskedasticity,
cross-channel dependence, informative observation processes and
alternative participant designs. Retain all failure-inclusive trial files.

See also `docs/phase3-coverage-pilot-followup.md` and GitHub Issue #5.
