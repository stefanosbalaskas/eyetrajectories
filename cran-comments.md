## eyetrajectories 0.4.3 — first-submission CRAN pretest resubmission

**Status:** revised source is undergoing six-platform CRAN-style validation.
This is NOT a declaration of CRAN acceptance. Do not submit before final
qualification and SHA-256 verification.

### Response to CRAN pretest feedback on 0.4.2 (2026-11-16)

The automated pretest reported:
- Debian r-devel: ten plotting group help topics had \\arguments
  without \\usage.
- Windows r-devel: overall checktime 11 minutes (CRAN's target is below
  10 minutes).
- "New submission" is an expected first-submission incoming NOTE.

The ten plotting topic documentation sections have been revised into
descriptive \\section{Plotting parameters}{\\describe{...}} sections,
retaining their parameter descriptions. Their individual exported plotting
functions continue to have separate help topics. No numerical estimators
were changed.

The testthat edition-3 suite is being evaluated with two-worker parallel
execution to reduce Windows R-devel elapsed checktime. All existing tests
remain in place. Only validated changes will be retained.

Version increased to 0.4.3 in accordance with CRAN's preference to increase
the package version on each resubmission, even where the first submission
was not published.

### Scientific scope

Native R trajectory and functional-analysis methods; optional Python
interoperability. No claim of complete numerical equivalence to the
published Python package's 508-symbol public inventory.

### Qualification evidence

Use the latest exact-archive matrix results on this branch and the
external CRAN pretest before describing the submission as fully qualified.
Do not rely on older 0.4.2 GitHub release artifacts or checks.
