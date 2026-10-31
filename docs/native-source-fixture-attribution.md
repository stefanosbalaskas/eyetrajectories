# Source-contract fixture attribution and independent-review boundaries

Frozen source: `eyetrajectoriespy==1.2.0` at Python commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.

The 508 public Python exports (380 functions and 128 nonfunctions) are
inventoried separately from the 111 selected, **unsigned** source-oracle
candidate functions. Passing native R and pinned Python source test suites
is a necessary development qualification, **not** independent certification.

## New evidence captured on each exact R commit

Run in the R package root:

```r
source("scripts/qualify_native_current_contracts.R")
source("scripts/capture_native_source_qualification_evidence.R")
```

In `artifacts/native_source_contract_evidence/qualification_<timestamp>/`:
- `native_r_offline.txt` and `python_1_2_direct_source.txt`: complete
  testthat logs, plus their aggregate verdicts.
- `test_selection_regex.txt`: the exact testthat filename filter used by
  both captured test modes. Reviewers must not assume all package tests ran.
- `unsigned_contract_fixture_evidence.csv`: 111 candidate rows, all
  noncertifying with independent per-contract approval flags FALSE.
- `file_integrity_manifest.csv`: source and test file checksums.

In `artifacts/native_independent_review_packets/qualification_<timestamp>/`:
- `selected_111_fixture_static_attribution.csv`: one row per selected
  candidate with the source-fixture file's MD5, the recorded filter's
  MD5, whether the fixture filename was selected by the captured test
  filter, the number of **all** declared `test_that` cases in that file,
  and whether its parsed R syntax contains a direct literal call
  `etpy_get_export("<this-python-export>")`. The last two are
  **file-level static evidence**, not the executed number of cases for
  the named Python export. A FALSE literal-reference field may mean an
  indirect source oracle; it is not proof that no oracle exists.
- `all_508_public_export_independent_review_scope.csv`: 508 export rows,
  now showing selected test-file and literal-reference evidence while
  retaining all per-export independent review fields FALSE.
- `all_508_contract_review_priority.csv`: complete triage by candidate
  oracle, distinct backend/estimand, open source gap, nonselected function,
  and nonfunction contracts.
- `known_source_gap_resolution_queue.csv`: every declared open difference
  with its source witness and required resolution.
- `review_lane_counts.csv` and the four initial source pilot priorities.

New capture fails closed if a selected candidate's fixture test file is
absent from the recorded test-selection filter or no `test_that` cases are
declared in a referenced fixture. Older evidence bundles lacking a saved
filter are readable but explicitly report that selection was not recorded;
coverage is not invented.

## Expansion of directly attributable public-source calls

The owner-verified baseline `qualification_20261101T002012` at
`f5834982d10cb3018063551428b9723e8e2697b6` found 111/111 selected
test files but only four literal Python-export references. The original
reporting tests called Python public functions inside `py_run_string`,
which produced numerical/text evidence but was invisible to the initial R
syntax attribution scanner.

The following four existing tests now additionally invoke their **20
distinct** selected Python public functions through explicit
`etpy_get_export("...")` calls and compare the resulting source outputs
to native R results and the already-existing frozen Python fixtures:

- `test-native-inference-reporting.R`: eight inference report contracts
- `test-native-inference-reporting-extensions.R`: three other reports
- `test-native-source-text-inference.R`: five FoSR/covariance/surrogate reports
- `test-native-source-model-reports.R`: four sparse/mixed-model reporters

A fail-closed `test-native-direct-source-report-attribution.R` checks all
20 literal references, their frozen Python names and outstanding source gaps.
It runs in the offline and Python source qualification modes. The expected
static direct-reference count therefore rises from **4 to at least 24 of
111**, but this must be confirmed by an exact-HEAD RStudio run; do not
promote this expectation to a verified number before that run.

This improves **audit attribution**, not complete-domain behavior or
independent numerical/scientific approval. The source-gap register and
all independent approval flags remain unchanged.

## Verified 24-source baseline and further 15 direct public functions

Exact-head owner RStudio verification at `e2a61a1e7f3df6996e690a9416bc8902635b3fc4`
on 1 November 2026 completed native R and Python 1.2 suites without test
failures and wrote complete `qualification_20261101T004201` evidence.
It confirmed **111/111 fixture files selected** and **24/111 direct literal
Python exported calls**. All 508 full source contracts remain unsigned.

The next research patch extends executable pinned-source attribution to
**15 more distinct public Python functions** using only existing, known
source fixtures (no claims of new validated input domains):

- `test-native-scientific-source-frames.R`: six source frame functions,
  including generalized FoSR coefficient, prediction, contrast, exposure,
  and univariate/multivariate sparse FPCA score tables. Existing typed
  Python `DataFrame` results remain the numerical reference.
- `test-native-source-diagnostic-frames.R`: two public data-table
  functions, including standard and extended mixed full-refit covariance
  diagnostics; each direct Python table is checked against the original
  source `DataFrame`.
- `test-native-generalized-mixed-source-graphics.R`: seven public source
  Matplotlib plotting functions. Source line data from each new direct
  returned `Axes` is checked against the original frozen Python oracle;
  the native R base-graphics geometry is independently compared to that
  same retained numerical witness.

Two new static guards check the exact public exported function names and
keep all corresponding source gap/independent approval flags open:
`test-native-direct-source-frame-attribution.R` and
`test-native-direct-source-plot-attribution.R`. The normal qualification
and evidence capture filters run the source-frame, diagnostic-frame and
mixed graphics tests in both native-only and pinned Python modes. The
capture integrity manifest includes the new guards.

**Expected next direct source-reference count: at least 39/111, not yet
verified by RStudio.** This is executable source traceability on selected
fixtures, not independent full-domain certification. The distinction
between native R graphics and Python Matplotlib remains explicitly open.

## Remaining evidence needed for a genuine per-export certification

1. Independently rerun the frozen Python and native R repositories at their
   exact commits; preserve environment lockfiles, log files and hashes.
2. Attribute an actual Python and R test case, each with a pass/fail/skip
   outcome, to a specific public export—not merely to a shared file.
3. Cover input containers, coercion, accepted/rejected values, error behavior,
   output class/shape and numerical tolerances across the complete source
   domain. Inspect each scientifically distinct estimator or backend.
4. Independently verify source implementation, numerical oracle and
   scientifically relevant interpretation, then collect signed review and
   immutable supporting evidence. Full-source certification requires the
   explicit gap-resolution and approval gates to pass.
5. Never auto-promote a contract based on owner-run tests, static AST scans,
   aggregate suite PASS, source-name mapping, or package load.

**All 508 full-domain independent source contracts remain unsigned until
actual third-party review and explicit approval.**
