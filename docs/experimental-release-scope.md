# Experimental native R release candidate: explicit scope and gate

This document describes a scoped experimental 0.x release, NOT full frozen
Python 1.2 parity and NOT a completed CRAN submission.

## Native scientific scope

The package provides Python-free native R trajectories, validation,
explicit preprocessing, dense common-grid FPCA/MFPCA, distances,
kinematics, plots and bounded recurrence. Additional native estimators,
source-field workflow records and explicit alternate backends must retain
their documented scientific restrictions. The optional Python bridge
remains separate.

Native fixed-radius W4 recurrence now supports cityblock/L1,
euclidean/L2 and chebyshev/L-infinity. On approximately regular
observed grids, native delay embedding, recurrence, Rosenstein local
divergence and Kantz divergence support source-compatible physical-time
delays, Theiler windows and horizon conversions (seconds/milliseconds
and the frozen Python 1.2 aliases). These conversions never interpolate
or resample observations.

The 380 callable-name mapping inventory is not a claim of 380 fully
ported or scientific-equivalent native estimators. Scientific
conclusions require actual estimand- and inference-unit-specific tests.

## One owner-side qualification command (Windows RStudio)

From the working copy of the desired branch and exact commit:

    system("git pull --ff-only")
    install.packages(c("rcmdcheck","pkgload"))
    source("scripts/qualify_experimental_candidate.R")

This local gate executes two actual existing R qualification suites:

1. Full source-build R CMD check --as-cran (PDF manual included) and
   numerical/plot example through scripts/run_cran_qualification.R.
2. Native offline and frozen Python 1.2 direct-source scientific
   qualification through scripts/capture_native_source_qualification_evidence.R,
   including unsigned SHA256 reviewer evidence integrity tests.

Each existing runner retains its own detailed report and the exact Git
SHA. The candidate gate writes an additional exact-HEAD and package-version
record under artifacts/experimental_release_candidates. It does NOT
upload to CRAN, create a Git tag, publish a release, waive check NOTES,
change DESCRIPTION, or sign third-party scientific reviews.

## Two distinct release targets

**Experimental R 0.x**: Must have actual R CMD check 0 ERROR/0 WARNING,
a documented disposition for any NOTE, working installed examples,
complete local scientific qualification and a clear limited scope.
Review cross-platform compatibility, support claims, README, NEWS,
DESCRIPTION URLs/license, source tarball and external CI evidence before
publication. Current DESCRIPTION version 0.4.1.9000 is a DEVELOPMENT
version, not a release tag. Do not call it publication-ready automatically.

**Full Python 1.2 parity**: Requires stronger complete-domain source
contracts, boundary/input/output audits and genuine independent reviewer
replays; test passes or class field names alone do not grant certificates.

## GitHub Actions is an infrastructure dependency

GitHub issue #3 documents that a minimal echo-only private-repository
workflow failed with no allocated runner and no executed steps. Subsequent
runs exhibit the same problem. This does not prove R scientific code
failures, but it means there is no passing cross-platform CI evidence.

Owner should check repository Settings / Actions / General and account
Billing and licensing / Actions budgets, inspect workflow annotations,
then dispatch the existing Actions runner startup diagnostic. Only
after runner startup succeeds should the existing R CMD, Python bridge
and native scientific matrices be executed on hosted runners. Do not
weaken the tests or report a CI success without an actual executed job.

The branch remains DRAFT. This gate creates no public distribution.

## November 2 CRAN source-build blocker and repair

The first combined release-candidate run at development HEAD
`e97d7a17499ddf307f8a02c895e3fc73c5263687` stopped in
`R CMD build` before `R CMD check` could execute. The cause was
`man/etr_capture_environment.Rd`, whose manual control sequences had
accidentally been stored as double-backslash text (`\\\\name`,
`\\\\alias`, `\\\\title`, etc.) rather than valid Rd commands.
The native scientific smoke example independently PASSed; it does not
make the source build pass. The reported R CMD check ERROR/WARNING/NOTE
counts of `NA` therefore mean NOT EXECUTED, not zero failures.

The source Rd control sequences have now been corrected. A new
`scripts/preflight_rd_manuals.R` parses and validates all tracked Rd
files *before* the costly package build. The full qualification runner
now distinguishes build aborts from executed package checks, and the
combined experimental gate runs both CRAN-style and frozen Python 1.2
scientific qualification independently, preserving separate PASS/FAIL
results even when either one fails. This fix is not a new release or a
completed R CMD check: owner-side rerun at exact repaired SHA is required.
