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

## November 2, second release-candidate run and remediation

Owner executed the exact development commit
`7d52d24ee4666cee1515fe0c23bf5509ea627d03` on Windows 11 /
R 4.6.1. The first malformed Rd source-build failure was genuinely
resolved: **93 manuals parsed; R CMD build PASS, installation PASS,
PDF manual PASS, and the native scientific smoke PASS**.

The full check nevertheless reported **1 ERROR, 4 WARNINGS and 4 NOTES**.
These are actual defects, not waived counts:

- R CMD check tests failed after `scripts/` was excluded from the
  built tarball, leaving five research-only test helpers inaccessible.
- Two scientific test cases invoked frozen Python fixtures
  (`_gm_band` and `_mc_family`) before their opt-in Python 1.2 setup;
  both failed in the offline and direct-source qualification modes.
- Five R source files contained literal non-ASCII multiplication/squared
  symbols; source text is now encoded with R Unicode escapes that
  preserve the same *runtime* strings.
- `etr_functional_mixed_effects_variance_decomposition` had two Rd
  aliases. The canonical dedicated manual is retained.
- Forty exported functions lacked a public help-page alias; three
  scientific-domain reference pages now index these export names.
  These concise umbrella references do not themselves certify full-domain
  scientific behavior; full API-specific documentation remains a
  publication-quality review task.
- Six public function argument lists were out of sync with their Rd
  usages. Five relevant flags and the two recurrence metric parameters
  have been reconciled in the R manuals.
- The package used `combn`, `head`, `tail` and `setNames` without
  NAMESPACE imports; their standard package imports are now explicit.
- Ten Rd usage sections contained overlong lines truncated in the PDF
  manual; each was wrapped to fit the documented width.
- Eight old private GitHub PR/issue links in README returned 404 to
  public URL checks; their development references now remain as text
  rather than broken public URLs.
- Source-independent research fixtures now live under
  `tests/testthat/fixtures/`. A new early preflight asserts that all
  five packaged files are byte-for-byte identical to their canonical
  scripts. Production scientific API and inference are unchanged.

The second run's frozen source suite failed only in the two named
Python initialization contexts visible in the shared log; this does
NOT imply those were the only possible unexecuted boundary conditions.
The source parity register and 508 scientific reviewer signatures
remain unchanged.

The CRAN incoming-feasibility NOTE for a first submission and current
`0.4.1.9000` development version remains expected and requires
publication-version review. No release tag, CRAN upload, independent
certification or cross-platform Actions PASS is asserted.

**Current exact branch HEAD remains unverified** until the owner reruns
both `scripts/preflight_rd_manuals.R` and
`scripts/qualify_experimental_candidate.R`. Never infer a green release
from committed repairs alone.

## November 2 — qualifying Python 1.2 parity work and CRAN 0.4.2 together

Keep the research checkout at its full, immutable Git HEAD (development
version \`0.4.1.9000\`) and use two **independent** evidence gates from the
same checkout, in this order:

\`\`\`r
system("git pull --ff-only")
stopifnot(system("git status --porcelain", intern = TRUE) |> length() == 0L)
source("scripts/capture_native_source_qualification_evidence.R")
source("scripts/stage_local_release_candidate.R")
\`\`\`

The first command records developer scientific test-case evidence, 508
contract reconciliation, and the 28-item unsigned review dispatch. Cases
with completed Python-mode literal references are now preferred for review,
but this is *not* a full scientific source-call replay or a certificate.

The second command creates a separate version \`0.4.2\` copy using
\`git archive\`, runs actual \`R CMD build\` and
\`R CMD check --as-cran\` **on the staged tarball**, and retains the
source-HEAD SHA in \`STAGING_MANIFEST.json\`. Its check verifier now also
requires installed \`testthat.R\` execution, help examples, the PDF manual
phase, and exactly one finished terminal verdict. An absent phase is FAIL,
not a 0-warning PASS. All staged results remain on publication HOLD until
manual NOTE review, external cross-platform checks, scoped scientific
claims, and maintainer submission approval.

For a *separate* full development-check report (in addition to staged
tarball validation), run
\`source("scripts/qualify_experimental_candidate.R")\`. It repeats the
scientific and CRAN qualification and is not required for the faster
two-gate sequence above.

The first-party staging regression tests can be run with
\`python scripts/tests/test_local_release_staging.py\`. Python test and
native scientific qualification need to be executed in the owner's
environment after each new Git HEAD; committed source alone is not a PASS.
GitHub Actions runner admission and genuine independent 508-contract
certification remain unresolved.
