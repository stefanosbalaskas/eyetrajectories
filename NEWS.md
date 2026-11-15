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
