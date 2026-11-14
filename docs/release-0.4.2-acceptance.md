# EyeTrajectories 0.4.2 — release acceptance record

**Status: HOLD / release preparation only.** This is a candidate process for
the limited, documented native R research API, not a claim of all-508 Python
contract parity or a CRAN acceptance decision. No tag, GitHub Release or
CRAN submission has been made.

## Exact-head baseline: what has actually passed

- Scientific source commit: `7f1f2a8440ec049bd9104eeb93f5d0de3cfaaa5e`
  (draft PR #178, source branch `fix/package-wide-qualification-20261113`).
- Maintainer local platform: Windows 11 x64, R 4.6.1, reticulate-managed
  Python 3.12.14 and frozen `eyetrajectoriespy==1.2.0`.
- `R CMD check --as-cran`: **0 ERROR / 0 WARNING / 1 NOTE**
  for development version `0.4.1.9000`. The NOTE includes first
  submission and oversized development version components; it must be
  re-examined on the candidate `0.4.2` tarball.
- Installed native example and both scientific qualification modes:
  **PASS**. The patch smoke ran 1,483 successful expectations.
- Source evidence/reviewer packet integrity: **author PASS**; developer
  508 reconciliation **PASS**; 508 frozen export interfaces descriptively
  enumerated. Historical author-reviewed source gaps: **0 currently open**.
- Remaining limits: **0/508 independently certified** scientific
  contracts; 19 alternative-backend/estimand cases; 96 of 128
  nonfunction symbols do not have an explicit native-R representation
  entry; an observed field mapping or function signature is not
  numerical or scientific equivalence.
- Evidence root (owner-local, not this repository):
  `artifacts/native_source_contract_evidence/qualification_20261115T003943`.
  Review packet:
  `artifacts/native_independent_review_packets/qualification_20261115T003943`.

**A later source commit is a NEW HEAD.** None of the earlier check PASS
claims carry over automatically to a changed source archive, including
README, DESCRIPTION, NEWS, tests, documentation or release scripts.

## Required gates for the limited experimental R 0.4.2 release

| Gate | At this stage | Acceptance evidence |
| --- | --- | --- |
| Git HEAD provenance and clean source | Prior development HEAD qualified | Clean release branch and exact SHA, no untracked source |
| Native R and Python 1.2 author scientific suites | PASS only at baseline above | PASS at final candidate source, frozen Python 1.2, complete source logs |
| R CMD build and check on **0.4.2 source tarball** | **NOT EXECUTED at current release head** | Actual `R CMD check --as-cran`: 0 ERROR, 0 WARNING; all NOTEs reviewed |
| Windows R 4.6.x | Baseline development check PASS with NOTE | Candidate tarball check and installed examples PASS |
| Linux R release or R-devel | **NOT VERIFIED** | Genuine full `R CMD check` transcript, including compiled native LAPACK bridge |
| macOS | **NOT VERIFIED** | Genuine check, or a documented reason for unsupported platform in release decision; do not infer PASS |
| GitHub Actions runner admission | **BLOCKED**, issue #3 | Executed, conclusively green jobs with exact commit, or a documented genuinely executed alternative CI/test platform |
| CRAN metadata / URLs / copyright / dependency audit | **PENDING** | Reviewed DESCRIPTION, LICENSE, README, NEWS, citations, runtime no-network behavior |
| CRAN NOTE disposition | **PENDING on 0.4.2 tarball** | Record exact NOTE text and reason in `cran-comments.md`; no suppression or unverified waiver |
| Independent full 508-export parity | **0 independently certified** | **Not a gate for limited native R release**, but FULL PARITY may not be advertised |

The package has an `Imports` requirement on `reticulate`; optional Python
methods may need additional Python packages. Native R examples, tests,
package load and installation must not download Python or require any
Python interpreter. A test that merely skips the Python oracle is not
evidence that those optional methods work.

## Reproducible owner-side execution (RStudio, repository root)

In a **fresh** R session and a clean exact-head checkout:

```r
source("scripts/verify_qualification_managed_python_20261113.R")
source("scripts/qualify_experimental_candidate.R")
```

The full source qualification must produce
`LOCAL_TESTS_PASSED; NOT READY FOR PUBLICATION` in its generated
`local_candidate_<SHA>.txt` receipt. Do not mistake that exact string
for release approval.

Then execute the isolated **candidate tarball** build/check:

```r
source("scripts/stage_local_release_candidate.R")
```

This calls `scripts/stage_local_release_candidate.py` with
`--version 0.4.2 --build-check`; it stages a clean `git archive` outside
Git, edits only staged metadata and runs real `R CMD build` /
`R CMD check --as-cran` on the changed source. Inspect
`STAGING_MANIFEST.json`, `STAGED_R_CMD_CHECK.log`,
`eyetrajectories.Rcheck/00check.log`, the tarball SHA256, all NOTES
and the installed test results. The staging script does not publish.

To run the separate local platform matrix:

```r
source("scripts/run_local_release_matrix.R")      # Windows host
# When WSL2 and Linux dependencies are genuinely provisioned:
Sys.setenv(ET_LOCAL_TARGETS="host,wsl", ET_LOCAL_WSL_DISTRO="Ubuntu")
source("scripts/run_local_release_matrix.R")
```

A missing requested target must be `BLOCKED_NOT_EXECUTED`, never PASS.
Reset `ET_LOCAL_TARGETS` after the matrix. For R-devel and macOS use
an actually executed independent platform run or an equivalent external
builder, and retain exact logs and source-tarball identity. If CI
cannot start any job, investigate repository/account Actions settings and
billing/runner admission; do not change scientific assertions to obtain
a green status.

Python-only release-tooling regressions (not R science or CRAN checks):

```sh
py -3 -m unittest discover -s scripts/tests -p "test_local_release_*.py" -v
```

## Decision and publication controls

1. Document final release scope and what each exported function can do.
   Neither 380 mapped callable names nor 508 descriptors equal
   independently validated native numerical parity.
2. Require a checked final `0.4.2` tarball; preserve its SHA256 and
   source-Git SHA. Check the **same** tarball submitted to CRAN.
3. Review exact candidate NOTE(s), portability, copyright, source
   dependencies, URL accessibility and CRAN policies. Complete the
   maintainer's release checklist and record the deliberate decision.
4. Obtain green, executed platform evidence. GitHub Actions queued jobs
   are not a substitute for executed tests.
5. Only after all gates: merge approved work, regenerate/check the
   release artifact if the merged source differs, create the matching
   Git tag/GitHub release, and optionally submit the validated source
   tarball through https://cran.r-project.org/submit.html. CRAN requires
   email confirmation for submission.
6. **Never** convert author test results, local reconciliation or
   source-name mapping into independent full-domain certification.

See [CRAN submission checklist](https://cran.r-project.org/web/packages/submission_checklist.html)
and [CRAN repository policy](https://cran.r-project.org/web/packages/policies.html).
