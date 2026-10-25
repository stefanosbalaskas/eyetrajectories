# Phase 3 qualification and remaining work — 25 October 2026

**Version:** 0.4.0.9000 (private, unreleased, not on CRAN).
**Native and original bridge exports:** 88 native R, 14 original Python-backed bridge names.
**Python API expansion:** 380 explicit Python-backed wrappers and 3 catalog/verification utilities; 508 upstream Python symbols documented.
**Engineering qualification:** Windows 11 / R 4.6.1 passed locally; hosted CI remains unavailable.
**Scientific release status:** inference not qualified, no CRAN publication.


## P0 — Windows 11 qualification evidence for R 0.4.0.9000

**User-executed on 25 October 2026**, R 4.6.1 (ucrt), Windows 11 x64.
The console output shows `source("scripts/local_qualification.R")` with
`ET_RUN_PYTHON_TESTS=true` and `MPLBACKEND=Agg`: `testthat: PASS`,
R CMD check **0 errors, 0 warnings, 0 notes**; package building,
installation, loading, examples, Rd documentation and tests succeeded.
Opt-in Python bridge tests and the generated-wrapper test file ran without
failure. The informational `refund::pffr` note about a default sandwich
covariance mode did not generate an R CMD check warning or note.

The author also confirmed the installed `eyetrajectories` version
`0.4.0.9000`, `nrow(etpy_catalog()) == 380`,
`etpy_verify_api(strict=TRUE)` completed without error, and the
installed-Python availability census returned `TRUE = 380`. The strict
check also tests callability. This is a **structural runtime check**,
not a functional exercise of each of the 380 Python functions.

The independent R-native inventory remains **88 native scientific functions**
and **14 original bridge functions**, plus 380 explicit Python-backed
wrappers and three new Python API catalog/verification utilities. The
upstream Python source snapshot lists 362 root callables and 18 workflow
callables (and 128 nonfunction symbols across both namespaces). Generated
wrappers are delegated Python calls, **not native R translations**.

**Scope limits:** This is local Windows qualification and an upstream API
interface census. It does not qualify scientific uncertainty coverage,
estimate inference, full per-function behavioral parity, sparse-joint
inference, cross-platform portability, or CRAN readiness. Main's
GitHub Actions workflows remain manually dispatchable but blocked at
runner admission; see issue #3.

**Independent known-truth Monte Carlo evidence:** Across 100 simulated
datasets at each of 12, 24 and 48 participants and 399 bootstrap draws
per dataset, group-contrast simultaneous coverage was 65%, 79%, 84%;
participant-mean coverage 63%, 89%, 86%, respectively, against a nominal
90% target, with zero fit failures in all 600 datasets. Uncertainty
calibration therefore remains **HOLD**; see
[coverage grid evidence](phase3-coverage-grid-2026-10-25.md).

## P0.1 — Full CRAN-style local check (2026-10-25)

The owner executed `source("scripts/run_cran_qualification.R")` against
`eyetrajectories` 0.4.0.9000 on Windows 11 x64 / R 4.6.1. Result:
**0 ERROR, 0 WARNING, 1 NOTE** under `R CMD check --as-cran`.
All tests and Rd examples passed; the full PDF and HTML manuals built;
the standalone native example produced both its CSV and three-page PDF.
The sole CRAN incoming feasibility NOTE reported `New submission` and
`Version contains large components (0.4.0.9000)`. These do not constitute
an executed scientific qualification or CRAN acceptance. A subsequent
runner change reports this status as **PASS WITH NOTES - REVIEW REQUIRED**,
without ignoring NOTE messages, and has not yet been run locally.

The provided CSV records eight synthetic curves on a 31-point grid,
two MFPCA components, recurrence rate 0.00689655172413793 under the
illustrative sparse radius, 12 participants in a diagnostic mean-band
bootstrap and the structural catalog count of 380 Python callables.
The plotted trajectories, cumulative FPCA variance and sparse recurrence
are synthetic demonstration graphics; they do not establish coverage.

See [full CRAN runbook](cran-qualification-runbook.md). Cross-platform,
CRAN incoming release conditions and scientific calibration remain open.

## P1 — Follow-up engineering work, committed but unverified

- `scripts/run_native_worked_gallery.R`: reproducible five-figure native
  demo across multilevel FPCA, two experimental functional bands,
  sparse support and transfer-entropy shift diagnostics.
- `scripts/run_phase3_interval_comparison.R`: failure-inclusive paired
  coverage and mean-width comparison to a Gaussian pooled/one-sample
  Bonferroni Student-t reference; **not** a new qualified estimator.
- `.github/workflows/R-cross-platform-manual.yaml`: offline CRAN-style
  package checks on release R for Ubuntu, Windows and macOS, plus an
  Ubuntu previous-R-version case. Manual dispatch only; no runner
  admission/CI results yet.

The author **executed both scripts successfully** on Windows 11 / R 4.6.1
(25 October 2026) and supplied per-replicate CSVs, numerical summaries and
the five-page native PDF. The native gallery found 20 independent participants,
60 curves, descriptive reconstruction RMSE 0.04711, 12 participants per
randomized arm, 35 sparse curves and a minimum time-bin support fraction
0.48571. The observed TE was 0.48658 bits; circular-shift descriptive
diagnostic p=0.02 is NOT a causal or calibrated significance claim.

In the paired interval comparison (30 matched generated datasets in each
of six method/design cells; B=199), all 360 method-dataset calculations
completed without fit errors. Current fixed-SE group contrast band coverage
at N=12/24/48 was 0.60/0.70/0.80 and participant-mean band coverage
0.6667/0.7667/0.8333 versus the 0.90 target. Gaussian Student-t Bonferroni
reference coverage on those **same datasets** was 0.9667/0.9667/1.0000
(group) and 1.0000/0.9333/1.0000 (mean); the reference intervals were
substantially wider. These exploratory results do NOT justify substituting
the reference for a general estimator: homoskedastic Gaussian participant
assumptions, missingness and multiplicity remain limitations.

The owner **executed the optional ggplot2 gallery successfully** on
Windows with ggplot2 4.0.3 (UTC 2026-10-25 22:12:14) and provided the
five resulting PNGs, five-page PDF, summary CSV and manifest. All
five figures use the native R-generated datasets and estimators, not
Python. The first figure has no clipped category labels; the final
figure explicitly states observed TE 0.486580 bits versus maximum
surrogate 0.027734 bits. As the observed statistic lies far beyond
the surrogate histogram, the display is intentionally limited to
surrogate counts, with the out-of-range statistic in its subtitle.
The diagnostic p-value is descriptive and is not a calibrated test.
The plotting upgrade does not change numerical methods.
None of the native `etr_*` estimator implementations was changed.
Scientific simultaneous-band inference and CRAN release remain on HOLD.
## P1.1 — Native versus delegated Python capability audit

Current Python main SHA (2026-10-26):
`22da0659c7934b5a075701b7be0b7173f4c81f18`.
Both public `__all__` sequences match the R's stored Python inventory
**exactly**, including the order of all 458 root and 50 workflow symbols.
The R API has 380 explicit named Python function wrappers, 3 catalog
utilities, 88 separate native-R `etr_*` exports and 14 original
Python bridge names. Availability and numeric parity are not equivalent.

New [capability matrix](r-python-capability-parity.md) documents
limited or missing native implementations in sparse asynchronous
multivariate modelling, functional mixed-effects covariance/inference,
generalized regression/wild bootstrap, registration/elastic/phase models,
nonlinear recurrence/surrogates and prediction/inference tools.
A reproducible static function census is now available under
`scripts/report_python_r_capabilities.R` and writes to
`artifacts/capability_parity/`. The new script is committed but has
**not yet been executed** on local RStudio.

## What exists

| Component | Source | R tests successfully executed |
| --- | --- | --- |
| Dense FPCA, distances, recurrence | Yes | Yes — local Windows tests; scientific validity pending |
| Univariate fdapace sparse PACE and marginal channel PACE | Yes | Yes — local Windows tests; scientific validity pending |
| Two-level descriptive FPCA | Yes | Yes — local Windows tests; scientific validity pending |
| Optional refund mixed-response model | Yes | Yes — local Windows tests; scientific validity pending |
| Cluster bootstrap bands, contrasts and eigenvalue spectra | Yes | Yes — local Windows tests; scientific validity pending |
| Transfer entropy, shuffle bias and autocorrelated null audits | Yes | Yes — local Windows tests; scientific validity pending |
| Scalar-on-FPCA regression with participant-grouped CV | Yes | Yes — local Windows tests; scientific validity pending |
| Known-truth simulations and native figure scripts | Yes | Yes — local Windows tests; scientific validity pending |

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

- R CMD check and testthat: completed successfully on Windows 11 / R 4.6.1 with opt-in Python integration; independent oracle scripts and cross-platform checks remain to be completed separately.
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
