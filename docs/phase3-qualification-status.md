# Phase 3 qualification and remaining work — 25 October 2026

**Version:** 0.3.2.9000 (private, unreleased, not on CRAN).
**Exports:** 102 total, 88 native R, 14 Python-backed bridge names.
**Scientific release status:** not qualified; code committed to main.

## What exists

| Component | Source | R tests successfully executed |
| --- | --- | --- |
| Dense FPCA, distances, recurrence | Yes | No |
| Univariate fdapace sparse PACE and marginal channel PACE | Yes | No |
| Two-level descriptive FPCA | Yes | No |
| Optional refund mixed-response model | Yes | No |
| Cluster bootstrap bands, contrasts and eigenvalue spectra | Yes | No |
| Transfer entropy, shuffle bias and autocorrelated null audits | Yes | No |
| Scalar-on-FPCA regression with participant-grouped CV | Yes | No |
| Known-truth simulations and native figure scripts | Yes | No |

## Independent mathematical checks (NOT R-package test results)

Python/Numpy generator (seed 20261025): 1,200 independent datasets,
24 participants, three trials per participant, 41 grid points, subject
SD 0.35, trial SD 0.15, sample noise SD 0.05.
Analytic integrated between-participant variance: 0.13166666666666663.
Simulated mean: 0.1318144250600696. MC SE: 0.0007755936732624886.
Absolute discrepancy: about 0.19 MC SE.
Reproduction: scripts/check_phase3_analytic_variance.py.

Independent discrete Shannon CMI calculation using deterministic 401-state
LCG series: source-to-lagged-response 0.9880521049342745 bits;
reverse 0.0008023573926947414 bits; unrelated source to target
0.001245743252896503 bits. Reproduction:
scripts/check_phase3_discrete_oracle.py, with frozen R CSV contract.
These are mathematical checks, not causal or inferential calibration.

## P0 — GitHub Actions runner startup

Even the minimal echo-only workflow failed with zero execution steps:
https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40188285732
Check repository Settings / Actions / General and account billing and
Actions budgets for the private repository. If settings are healthy,
request investigation from GitHub Support citing the exact run ID.
No specific cause is confirmed by the available logs.
https://github.com/stefanosbalaskas/eyetrajectories/issues/3

## P1 — Mandatory scientific qualification

- Execute complete R CMD check, testthat and independent oracle scripts.
- Sparse PACE: observed-device fixtures, convergence, data-density and
  smoothing sensitivity, missingness and cross-channel covariance.
- Functional mixed effects: REML fit diagnostics, nested/unbalanced trial
  data, covariance consistency and independent oracle comparison.
- Uncertainty: sufficient Monte Carlo repetitions for pointwise and
  whole-function coverage with Monte Carlo error, heteroskedasticity,
  heavy tails, small participant counts and informative missingness.
- Transfer entropy: source autocorrelation, lag/history selection,
  discretization, common causes, null false-signal rates and sensitivity
  of surrogate schemes; never interpret direction as causal proof.
- Grouped prediction: nested participant holdouts and external fixtures.
- Validate numerical rank, time-grid irregularity and resource limits.
https://github.com/stefanosbalaskas/eyetrajectories/issues/5

## P2 — Still unimplemented or incomplete scientifically

- Truly joint sparse asynchronous MFPCA with cross-channel covariance.
- Qualified functional mixed-effect inference and simultaneous bands.
- Continuous/conditional high-dimensional transfer entropy estimators.
- Direct GP3 / gp3tools / eyeprocess import adapters with measured data.
- Full cross-language parity and larger genuine eye-tracking fixtures.
https://github.com/stefanosbalaskas/eyetrajectories/issues/4

## P3 — Packaging, documentation and CRAN release

- Linux, Windows and macOS R version checks after runners work.
- Independent method/code review, all-function Rd examples and API freeze.
- Actually render scientific articles and figures for documentation site.
- Run CRAN policy checks; only then consider release approval.

Presence on main is not test success, empirical evidence,
nominal interval calibration, Python parity or CRAN approval.
