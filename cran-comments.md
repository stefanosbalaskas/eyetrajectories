# CRAN submission comments — eyetrajectories 0.4.2 (DRAFT, NOT SUBMITTED)

## Release identity

- Package: `eyetrajectories`
- Proposed version: `0.4.2`
- Scope: limited experimental native R trajectory-analysis API; optional
  Python integration. No claim of 508/508 scientific parity.
- Source Git SHA: **TO RECORD after final review/merge**
- Validated `eyetrajectories_0.4.2.tar.gz` SHA256:
  **NOT YET GENERATED OR VERIFIED**
- Upload/submission date: **NOT SUBMITTED**

## Test environments and checks (fill only from executed reports)

- Windows 11 / R 4.6.1, development `0.4.1.9000` source,
  commit `7f1f2a8440ec049bd9104eeb93f5d0de3cfaaa5e`:
  `R CMD check --as-cran` **0 ERROR / 0 WARNING / 1 NOTE**.
  Both native offline and pinned Python 1.2 source scientific
  suites passed. **This is not a check of the submitted 0.4.2 tarball.**
- Windows `0.4.2` source tarball: **PENDING**.
- Linux (R release/R-devel): **PENDING**.
- macOS: **PENDING**.
- GitHub Actions: **BLOCKED at runner admission** (issue #3).
  Do not represent queued workflow runs as passing tests.

## NOTE review (do not copy the dev-version NOTE into an alleged 0.4.2 check)

Development check's single incoming-feasibility NOTE observed:

- New submission.
- Version contains large components (`0.4.1.9000`).

The proposed `0.4.2` version avoids the long development version
component, but the release candidate **must be rebuilt and checked**.
A new-submission NOTE may remain and needs an explanatory comment.
Record any additional actual release tarball NOTE text below before
submission; do not pre-approve or suppress it.

- Actual `0.4.2` NOTE(s): **PENDING SOURCE CHECK**.
- Maintainer disposition: **PENDING**.

## Scientific scope and external dependencies

- R-native operations can run without Python. Optional Python-backed
  operations require a separately installed/pinned Python backend.
- 380 Python callable name candidates observed, 128 Python nonfunction
  symbols inventoried. The native representation register has 32
  populated mappings and 96 empty entries; **not full Python parity**.
- Zero independently signed 508-contract full-domain certifications.
- All scientific limitations of the supported models remain in their
  respective help pages. Independently calibrated coverage is not
  inferred from `R CMD check`.

**DO NOT SUBMIT** before the candidate tarball, R-devel/platform
qualification, dependency and copyright review, and maintainer decision
have been completed. This is an internal draft for accurate CRAN submission
comments, not evidence that any action has taken place.
