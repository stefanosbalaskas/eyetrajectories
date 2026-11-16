# CRAN incoming pretest correction — eyetrajectories 0.4.2 (2026-11-16)

## Scope and provenance

This correction branch starts from the **exact source commit** of the original
CRAN submission: `948901e087c2176bd23e01845ba2747b2b602cd8`.

Original source archive SHA-256:
`20d31cab8930e4846968dc268e7a7c4737f7b12ad45c0d657519ddfd76822b28`.

The original tarball and `v0.4.2` GitHub stable release must remain immutable.
Any CRAN resubmission requires a freshly built `eyetrajectories_0.4.2.tar.gz`
from this correction branch, a **different SHA-256**, and a complete qualification.

## Incoming CRAN result

Automated CRAN pretest: `eyetrajectories_0.4.2_20261116_113731`.

- Windows R-devel: expected New submission incoming NOTE plus an additional
  overall checktime NOTE: **11 minutes > 10 minutes**.
- Debian R-devel: expected New submission NOTE plus Rd contents NOTE:
  **10 group documentation topics provide an `\\arguments` block without
  a `\\usage` block**.

The mailing list / CRAN response explicitly requests a corrected resubmission.

## Documentation correction

The 10 flagged group help topics were verified to be descriptive plotting
collection pages, not individual callable function manuals. Their common
parameter descriptions were moved from the inappropriate Rd top-level
`\\arguments` section into an ordinary
`\\section{Plotting parameters}{\\describe{...}}` section.

The documentation contents were preserved; no exported R function signatures
or statistical algorithm implementations were changed.

`scripts/preflight_rd_manuals.R` now explicitly rejects
`\\arguments` without `\\usage` and parses all Rd files.

## Runtime correction experiment

The original package contains hundreds of test files. An experiment uses
the supported testthat edition-3 option `Config/testthat/parallel: true`,
which normally runs test files with two workers instead of sequentially.
No tests have been removed or suppressed. This change MUST be validated on
all platforms, with particular attention to shared test fixtures and
inter-file state. If it fails or gives negligible benefit, revert it and
profile/optimize the actual slow tests.

Two GitHub Actions qualification runs provide a before/after comparison:

- Serial tests, corrected manuals: https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/43861031885
- Parallel experiment, corrected manuals: https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/43861459562

Each run rebuilds the exact tarball and checks Windows release and devel,
Linux release/oldrel-1/devel and macOS release. The stricter Rd incoming
setting `_R_CHECK_RD_CONTENTS_USAGE_=true` and
`_R_CHECK_TIMINGS_=0` are enabled.

The pretest problem is NOT resolved merely by a successful local
`R CMD check --as-cran`. We need a clean result on the external CRAN
incoming pretest after submitting the replacement archive.

## Resubmission gates

1. Confirm the 10 documentation NOTES are absent under strict Rd settings.
2. Confirm the complete package test suite still passes (including concurrent
   testing if retained).
3. Check the **total Windows R-devel elapsed checktime**, aiming comfortably
   below 10 minutes.
4. Confirm 0 errors, 0 warnings and no other unexpected NOTES in the complete
   six-platform matrix; inspect the check logs and artifact SHA-256.
5. Download the new exact source archive from the successful GitHub Actions
   qualification workflow; verify its SHA-256 locally.
6. Resubmit the **new archive** using the CRAN webform, with an optional comment
   referring to the resolved 2026-11-16 pretest issues.

**Status:** qualification in progress. Do not resubmit the original archived
source, do not assert that CRAN accepted the package, and do not change the
public release assets simply to make the old source resemble the new candidate.
