# eyetrajectories 0.4.4 (release candidate; NOT yet published)

## Native R trajectory distance optimization

- Derived directly from the immutable published v0.4.3 source baseline. The development `main` history is not treated as the release source.
- Optimizes `etr_pairwise_l2()` for complete common-grid trajectories in strict native-R mode using centered, quadrature-weighted matrix geometry and `stats::dist`. Preserves the archived function signature, singleton behavior, numerical safety fallback and original scalar compatibility mode (`python_boundary_mode = TRUE`).
- Retains existing experimental-method caveats; does not claim scientific certification of the broader R/Python interfaces.

## Release qualification

- The preceding unversioned candidate `0.4.3.9000` passed three-platform regression, synthetic installed-package scaling, full CRAN-style and official OneStop fixation-level installed-package gates at SHA `a435f2c3c36ebc7659cb43b4d0709d3b80f43f29`.
- Version `0.4.4` must independently pass the same checks on its **own exact source tarball and commit**. Its results must not be inferred from the development candidate.
- OneStop evidence uses public repeated-reading fixation summaries on declared interpolated grids, not unprocessed 1000 Hz signals. Numerical parity for L² does not establish general inferential validity of experimental methods.
- Publication, tagging, CRAN submission and Zenodo deposit remain gated on the new version's qualification.

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
