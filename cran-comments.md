## eyetrajectories 0.4.4 — versioned release candidate, not yet submitted

This candidate is derived from the published v0.4.3 GitHub tag (`20e6db830d480b55456c2acf85e5fdb12cfa398f`). The optimization changes the strict native-R `etr_pairwise_l2()` path while retaining the published API, the original scalar boundary mode, and a numerically safe fallback. No changes from the divergent development `main` are incorporated.

**Prior qualification only:** the preceding `0.4.3.9000` commit `a435f2c3c36ebc7659cb43b4d0709d3b80f43f29` passed 12 CI jobs (four workflows on Windows, Linux and macOS). Those jobs included `R CMD check --as-cran` with 0 errors, 0 warnings and two environment/submission notes, plus exact-installed synthetic and public OneStop fixation-data comparisons. These results do NOT certify the new `0.4.4` archive.

**Version-specific gate:** rebuild `eyetrajectories_0.4.4.tar.gz`, record SHA-256, run its exact-archive CRAN-style matrix and independent numerical comparisons, inspect all notes/skips, and verify the source archive excludes benchmarks. Do not submit, tag or make a new Zenodo deposit before the version-specific gates pass.

**Scientific scope:** native R core with experimental advanced methods, separate optional Python interop, and restricted method-specific performance claims. Real OneStop repeated-reading fixation-level interpolation is not raw-sample validation of the 904-interface catalog.

---

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
