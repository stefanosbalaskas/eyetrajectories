# eyetrajectories 0.4.4

## Native R L² trajectory distances

- Retains the published v0.4.3 interface while accelerating `etr_pairwise_l2()` for complete common-grid trajectories in strict native-R mode.
- Uses centered, quadrature-weighted matrix geometry and `stats::dist` to compute pairwise distances. The original scalar compatibility mode (`python_boundary_mode = TRUE`), singleton handling and numerical safety fallback are preserved.
- Based on the frozen v0.4.3 source, rather than the divergent development `main` branch.

## Qualification and scientific scope

- The exact v0.4.4 source candidate passed 12/12 GitHub CI qualification jobs across Ubuntu, macOS and Windows: archived numerical contracts, exact-installed synthetic scaling, public OneStop real-data comparisons and full CRAN-style source checks (0 errors and 0 warnings).
- Local Windows R 4.6.1 source-archive qualification completed in 4m12.4s with 0 errors, 0 warnings and one expected first-submission NOTE. GitHub CRAN-style checks had two runner/tooling notes.
- Installed v0.4.4 was compared with v0.4.3 on six OneStop repeated-reading fixation-level inputs (250, 500 and 1000 trajectories; 64 and 128 normalized interpolated grid points), with three repetitions. The largest full-matrix numerical discrepancy was approximately 1.14e-12 against a tolerance of 1e-8; sampled independent trapezoidal comparisons also passed. The observed local Windows median speedup ranged from 95.49 to 245.43 times for these configurations.
- These findings concern this L² function, the selected common-grid input domain and specific runtimes. They do not independently validate arbitrary eye-tracker acquisition data, all 904 interfaces, experimental functional inference, or optional Python-backed methods.
- GitHub release publication, CRAN submission/acceptance and archival DOI registration have separate statuses; consult the official release and CRAN pages rather than inferring publication from passing CI. See the [version-specific publication checklist](https://github.com/stefanosbalaskas/eyetrajectories/issues/221).

# eyetrajectories 0.4.3 (CRAN incoming pretest correction candidate)

## First-submission pretest remediation

- Corrected ten group plotting documentation topics that incorrectly
  declared \\arguments without function \\usage. Parameter explanations
  remain available in descriptive \\section/\\describe structures.
- Added a stricter Rd-manual preflight mirroring the Debian incoming checks.
- Evaluating two-worker, third-edition testthat execution to lower elapsed
  Windows R-devel CRAN check time without dropping or skipping tests.
- Scientific model implementations, exported function names and numerical
  analysis algorithms are unchanged relative to the original 0.4.2
  submitted source.

Version 0.4.3 is a CRAN resubmission candidate; acceptance is not implied.

# eyetrajectories 0.4.2 (release candidate; not yet published to CRAN)

## Package scope and native analysis

- Native R support for time-indexed trajectories, explicit preprocessing,
  kinematics, trajectory distances, dense FPCA and multivariate FPCA,
  recurrence and documented scientific visualization.
- Experimental sparse PACE, functional regression, participant-level
  resampling, nonlinear analysis, elastic-registration and uncertainty
  diagnostics retain their stated data-domain and inference limitations.
- Optional Python 1.2 interface remains separate from native R methods.
  A mapped Python callable does not establish a native R numerical match.

## Packaging and reproducibility

- Cross-platform R release checks passed on Windows, macOS, Ubuntu and
  Ubuntu oldrel-1 at development-source commit fc8f05cd061aa0cd151d4bdd5ae29356cc6fa32f.
- Windows PDF-manual support was restored by installing an expanded TinyTeX
  bundle with the Courier font available.
- An isolated R 0.4.2 release-candidate workflow is being qualified on
  the source tarball; candidate check results must be inspected before
  any CRAN submission.
- Research-only source-contract ledgers and development files remain
  excluded from the CRAN source tarball by the existing build rules.

## Scientific qualifications

- The provisional 508-export source-contract ledger is not equivalent to
  508 independently certified mathematical or statistical methods.
- Experimental functional confidence bands, transfer entropy diagnostics,
  and uncertainty procedures require estimand-specific validation.
