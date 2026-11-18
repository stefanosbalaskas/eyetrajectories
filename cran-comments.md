## eyetrajectories 0.4.4 — CRAN release-submission evidence

### Source provenance and scope

The proposed source is based on published v0.4.3 (`20e6db830d480b55456c2acf85e5fdb12cfa398f`), with an optimized strict native-R `etr_pairwise_l2()` implementation and original API/compatibility-mode behavior retained. The divergent development `main` branch is not included. Sparse, multilevel, regression and uncertainty functions retain their documented experimental scope; the 904-interface catalog is not an independently certified statistical-method library.

### Version-specific checks

The `0.4.4` source candidate at `4869d8c8ab24b273365559c8e6e3b670407bbc87` passed 12/12 qualification jobs across Windows, macOS and Ubuntu: frozen API and mathematical contracts, synthetic installed-source scaling, official OneStop fixation-level numerical comparisons, and source-tarball `R CMD check --as-cran` (0 errors, 0 warnings; two environment/new-submission notes). Local Windows R 4.6.1 produced 0 errors, 0 warnings and one NOTE ("New submission"), with PDF/HTML help checks passing and elapsed check time 4m12.4s. Release metadata-only changes must be checked anew on the final source archive.

The earlier pretest reported ten plotting-group Rd `\\arguments` without `\\usage` (corrected in v0.4.3) and approximately 11-minute Windows check elapsed time. No scientific model-generalization claim is made from the distance benchmark.

### Submission gate

Before uploading, verify there is no unresolved earlier submission awaiting CRAN response. Build the exact intended `eyetrajectories_0.4.4.tar.gz` from the final qualified release commit, verify its SHA-256, run `R CMD check --as-cran` on that exact file and explain any expected incoming NOTE in the submission comment. The official CRAN acceptance decision remains independent of GitHub checks.

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
