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

## Exact-head 39 verified; 13 further direct numerical and plotting source oracles

The owner verified commit `db5c45ab6f1955dfdaf70e684fdb7247a3b96677`
on 1 November 2026. **305 R files parsed**, native R and pinned Python
1.2 source qualifications **PASS**, evidence capture under
`qualification_20261101T004632` **PASS**, checkout and file integrity
**TRUE**. Of the 111 selected unsigned contracts, 39 had direct literal
export calls in selected source fixtures. No independent approvals changed.

The next research source replay patch introduces **13 further distinct**
literal public Python source call sites, with computations cross-checked
against the already retained Python oracle arrays and R native results:

- Five sparse graphics source functions: `plot_sparse_fpca_component`,
  `plot_sparse_mfpca_component`, `plot_sparse_mfpca_covariance_blocks`,
  `plot_sparse_mfpca_cross_covariance`, and
  `plot_sparse_irregular_dimension`.
- Three inference graphics: `plot_fpca_component_envelope`,
  `plot_sparse_fpca_score_diagnostics`, and
  `plot_fpca_wild_bootstrap_family_test`.
- Two numerical interval estimands:
  `fpca_regression_slope_simultaneous_band` on global/dimension scopes,
  and `fpca_wild_bootstrap_projection_simultaneous_interval`.
- Wild source Monte Carlo precision plus two plotting helpers:
  `fpca_wild_bootstrap_family_test_monte_carlo_diagnostics`,
  `plot_fpca_wild_bootstrap_monte_carlo_diagnostics`, and
  `plot_fpca_wild_bootstrap_simultaneous_interval`.

`tests/testthat/test-native-direct-source-advanced-attribution.R`
asserts the 13 literal names are present in their actual Python-enabled
test fixtures and remain explicitly **uncertified**. The owner
qualification and full evidence-capture filters include all five source
fixture families and the guard in both execution modes. The evidence
manifest includes the new static guard.

**Expected next static source literal count: at least 52/111; not yet
confirmed by RStudio.** More direct source references and fixed-fixture
comparisons do not resolve the 203 recorded source gaps or 19 alternative
native estimator/backend differences, and no full-domain independent
scientific certification has been granted.

## Verified 52 direct source references; eight more numerical/estimator replays

At exact owner-verified RStudio checkout
`fa7c040c638cd82dc44e968bce9305cf101eea76`, the
`qualification_20261101T012433` evidence bundle confirmed 306 R
source files parsed, native R **PASS**, pinned Python 1.2 source **PASS**,
both source qualification/evidence modes **PASS**, checkout and file
integrity **TRUE**. All 111 selected fixtures were included in captured
test selection, and **52/111** selected contract files contained direct
literal source-export call references. No independent signoffs changed.

The following eight additional previously indirect public Python source
contracts now have typed direct-source replays and numeric comparisons
against the original pinned Python fixtures (new HEAD requires owner
RStudio qualification):

- Fixed-family wild bootstrap maxT:
  `fpca_wild_bootstrap_projection_family_test`
- Generalized FoSR link-scale simultaneous coefficient bands:
  `generalized_function_on_scalar_simultaneous_bands`
- Mixed model coefficient bands:
  `functional_mixed_effects_simultaneous_bands`
- Mixed model variance decomposition:
  `functional_mixed_effects_variance_decomposition`
- Known-truth hierarchy and registration recovery:
  `evaluate_hierarchy_truth_recovery`,
  `evaluate_registration_recovery`
- Mixed model known-truth recovery:
  `evaluate_functional_mixed_effects_recovery`
- Generalized FoSR mean difference and ratio contrasts:
  `generalized_function_on_scalar_mean_difference_band`

The original fixed arrays, estimands, nulls and source numerical results
are retained, and newly executed direct public-export results are checked
against them. The new
`test-native-direct-numerical-source-attribution.R` guards all eight
frozen Python names while requiring that their one-to-one complete and
independent certification flags remain **FALSE**. It is selected in both
qualification modes and evidence capture; its code and the maxT test are
included in the evidence integrity manifest.

**Expected next static attribution >=60/111, NOT yet measured at the
new research HEAD.** A direct source function call on a fixed fixture
does not qualify whole-domain errors, type coercion, nonidentical R
result structures, optimizer choices, scientific backend distinctions
or independent signoff. The 203 recorded source differences and 19
distinct backend/estimand alternatives are still open.

## Exact-head source evidence reaches 60, with nine estimator replays added

The owner verified `ac8203ccc99aca879764281db4105106a47cc338`
in RStudio: syntax preflight **307 source R files PASS**; offline native R
test mode **PASS**; pinned Python 1.2 direct source mode **PASS**; evidence
capture `qualification_20261101T013237` **PASS**; checkout hash and file
integrity **TRUE**. All 111 source candidate fixtures were included in
the recorded test selector; **60/111** contained direct literal public
Python export calls. No contract was independently approved.

The next research patch adds **nine distinct typed Python source replays**
to eight existing scientific test files, leaving their original native
R comparisons and frozen Python fixture data unchanged:

- `bootstrap_generalized_function_on_scalar_predictions` and
  `generalized_function_on_scalar_prediction_bands`: binomial, Poisson,
  exposed rate and expected-count projections, plus profile/family bands
- `generalized_function_on_scalar_predict`: four fixed-profile
  marginal-response cases including expected-count exposure
- `compare_functional_mixed_effects_bootstraps`: conditional versus
  full-refit uncertainty width ratios under both simultaneous scopes
- `evaluate_sparse_fpca_recovery`,
  `evaluate_sparse_mfpca_recovery`, and `evaluate_fpca_recovery`:
  original known-truth assessment metrics and one-/two-channel cases
- `cross_validate_fpca_regression` and
  `nested_cross_validate_fpca_regression`: original Gaussian folds,
  held-out predictions and minimum/one-SE nested selection rules

The new `test-native-direct-source-estimator-attribution.R` guards all
nine public names and requires their source-difference and independent
approval fields remain explicitly open. The normal qualification and
evidence capture scripts include the actual eight test files and the
additional guard in both native and Python modes; evidence integrity
hashes the new guard. New source calls use the existing recorded Python
inputs, output fields, fixed folds and original comparison tolerances.
No new source-domain or Python↔R RNG-stream identity is claimed.

**Expected after next owner exact-HEAD run: >=69/111 direct literal
source references (currently unverified).** This attribution is not an
independently certified per-case pass count. The 203 recorded source
differences and 19 known scientific backend/estimand differences remain
open; all 508 independent certification approvals remain FALSE.

## Exact-head 69/111 verified; six more stochastic source export replays

The owner's exact-HEAD RStudio qualification at
`50ec030586c1ddbaf602fac1abd382a442d97ac5` successfully parsed
**308 R files**, ran native offline R and pinned Python 1.2 direct-source
qualification **PASS**, and completed both evidence-capture modes
**PASS** with checkout and file integrity **TRUE**. The source capture
bundle is `qualification_20261101T014453`. All 111 selected source
candidate fixture files were selected, with **69/111 containing direct
literal frozen public Python export calls**. All certification flags
remain FALSE.

Six further distinct source functions now have explicit reruns in their
existing pinned-Python test cases, including strict direct-source
comparisons against the original frozen Python fixture output:

- `fpca_regression_future_prediction_interval`: centered residuals,
  predictive draws, quantiles and predictive SE using the original
  NumPy random seed. Native R continues to compare via retained source
  residual indices; R/NumPy random-stream equivalence is not implied.
- `fit_generalized_function_on_scalar_regression`: observed Poisson
  spline GEE basis, coefficients, robust standard errors, means and
  covariance, without changing the original R numerical tolerances.
- `simulate_functional_process`: seeded source curve, participant and
  trial simulation, latent scores and observed trajectories; native R
  continues using fixed published source draws for replay.
- `generate_multivariate_iaaft_surrogates`: exact frozen Python
  reference-source arrays and spectra under its fixed NumPy seed.
- `multivariate_surrogate_nonlinearity_test`: original observed
  statistic, generated surrogate statistics and plus-one p-value.
- `bootstrap_fpca_regression_uncertainty`: repeated source paired
  FPCR bootstrap reference and retained draws at its original seed.

The new `test-native-direct-source-stochastic-attribution.R` checks
all six names against their actual test fixtures and explicitly
requires unresolved source differences and unapproved contract flags.
Both qualification modes and evidence capture include the new test
and all six executable test files; the evidence manifest hashes the
seven files. The evidence-runner guard checks their presence in the
recorded selection filters.

**Expected direct-source fixture attribution after owner replay:
at least 75/111, NOT YET verified**. A repeated seed-matched Python
call does not establish RNG equivalence with R, complete-domain
source behavior, or independent full-contract certification. The 203
source differences, 19 distinct scientific backend/estimand
differences, and **0/508 independent approvals** are unchanged.

## Exact-head 75/111 verified; five wild-bootstrap root exports and two workflow-subpackage tests

The owner's exact-head RStudio qualification of
`d95b774a2abed7e51f28972a239669d5263c0b3e` completed
successfully: **309 R files parsed**, native offline **PASS**, pinned
Python 1.2 direct source **PASS**, both evidence-capture modes **PASS**,
checkout and file integrity **TRUE**. Evidence artifact:
`qualification_20261101T015459`. All 111 selected source-contract
fixtures were captured and **75/111** had literal direct root Python
public-export references. No independent approvals changed.

The next source patch adds **five further distinct frozen package-root
public exported function oracles** to two existing statistical tests:

- `wild_bootstrap_fpca_projection`: replay fixed Gaussian wild
  multipliers with a source sampling hook restored in `finally`;
  compare all source reference projections, SEs, resamples and roots
  exactly with the original frozen Python oracle. The R numerical
  FPCR comparison remains intact.
- `scan_wild_bootstrap_fpca_truncations`: replay the exact same 20
  multiplier rows across the adjacent inference-truncation candidates,
  preserving the source oracle and R numerical comparisons.
- `fpca_wild_bootstrap_truncation_scan_frame`: verify the source
  48-row (two truncations × 24 fixed targets) data-frame contract.
- `select_fpca_wild_bootstrap_truncation`: apply declared
  width/center thresholds and `stability_run=0` to the original
  source scan; verify exact earliest `h=2` decisions.
- `fpca_wild_bootstrap_truncation_selection_frame`: verify the
  24-target frame and exact source-selected inference components.

Separately, the public `eyetrajectoriespy.workflows` subpackage
(not the root `eyetrajectoriespy` 508-export catalogue) has two
direct source exercises: `run_recurrence_workflow` verifies exact
embedded states and recurrence adjacency, and `plot_workflow_result`
verifies ValueError versus TypeError dispatch. These must **not** be
counted as new root-export fixtures. This distinction was checked
against both frozen `__init__.py` files and corrected before replay.

`test-native-direct-source-workflow-attribution.R` guards the five
root names and separately checks that the workflow calls use the
subpackage. Every source test remains in both captured qualification
modes; evidence hashes the four modified test files and guard.
Static R delimiter checks passed. **Neither new test execution nor
an R parse check has been performed by the assistant.**

**Expected next file-level direct root-source attribution: up to
80/111, not yet RStudio verified**. The new tests strengthen
source-traceability and exact fixed-case numerical conditions; they
do not establish full-domain Python/R API equality, NumPy RNG
identity or external independent certification. Known audit
limitations remain 203 difference records, 19 alternative
backends/estimands and **0/508 independent approvals**.

## Owner verified 77/111; supplemental typed recovery frame source tests now part of qualification

Owner RStudio verified exact source qualification at
`d1d0844ac99df2c43acd4b8f31b50f2303efea0a` with
**310 native R source files parsed**, offline R source suite **PASS**,
frozen Python 1.2 direct-source suite **PASS**, full evidence capture
in both modes **PASS**, checkout integrity and file integrity **TRUE**.
Frozen evidence bundle: `qualification_20261101T020859`.
All 111 selected candidate fixtures matched the captured test filter,
but only **77/111** had a literal public Python root export reference.
The earlier 80/111 estimate was incorrect: multiple new source
functions were invoked in only two fixture files. Count files and
functions separately; never equate this with independent approval.

A supplemental scientific source fixture,
`test-native-functional-recovery-evidence.R`, is now included in
both qualification modes. Its pre-existing typed Python 1.2 versus
native R column-by-column scientific comparisons were preserved,
and their previously dynamic source function lookup was replaced
with literal public root exports for these three tests:

- `functional_recovery_frame`: record-to-table metric names, values,
  semantic 1-based component indices, scenario and replicate metadata.
- `functional_recovery_failure_frame`: per-scenario failure counts,
  rates and failure-rate Monte Carlo standard errors.
- `functional_recovery_summary_frame`: sample standard deviations,
  Monte Carlo SEs, source-matching quantiles and row/column schema.

The existing R figure checks, source Matplotlib point comparisons,
failure-domain checks and exact source record construction remain
unchanged. A new
`test-native-direct-source-recovery-evidence-attribution.R`
guard checks that all three literal root Python calls are present,
their R candidates exist, and the source-contract completion and
independent approval flags remain **FALSE**. The fixture and guard
are selected in native and pinned Python modes, tested by
`test-native-source-evidence-runner.R`, and both are now included
in the evidence integrity manifest.

**This supplemental fixture is not automatically part of the
existing 111-contract review queue; do not forecast a new 111
attribution count from it without examining the next captured
queue and file-to-contract mapping.** It is useful additional
executable source-domain evidence, not a new standalone native
implementation and not a third-party full-domain scientific
certification. Known 203 source differences, 19 alternate backend
or estimand cases and 0/508 independent signoffs remain open.

## Native FPCA implementation added: external score reconstruction (runtime replay pending)

The owner verified research HEAD `b2775ea6237778567e8f0d980bc015311f299468`:
**311 R files parsed**, offline native R PASS, frozen Python 1.2
source-qualified suite PASS, both evidence capture modes PASS, evidence
integrity TRUE, `qualification_20261101T022016`. The selected
111-source review queue retains **77/111 direct source-fixture
references**; no independent contract was approved.

A real native R API improvement now addresses an identified missing
Python 1.2 FPCA feature. Frozen `fpca.py::reconstruct_fpca` supports
`scores=None` or an explicit one- or two-dimensional score array.
Native `etr_reconstruct_fpca(fit, n_components=NULL, scores=NULL)`
now:

- preserves the existing `etr_trajectory_set` return and curve
  identifiers when `scores=NULL`;
- reconstructs a new numeric curve × time × channel array from external
  one-dimensional vectors or two-dimensional score matrices, without
  assigning invented IDs;
- defaults to `min(ncol(scores), fit$n_components)` on supplied
  scores and checks that the specified component count is available;
- rejects unsupported score rank, zero-length or nonfinite/nonnumeric
  source values rather than silently recycling;
- retains native component orientation and time/channel shape.

The new `test-native-fpca-external-score-reconstruction.R`
exercises fitted/held-out shapes, one- and two-component reconstructions,
missing/extra score columns, invalid domains and the backwards-compatible
native fitted-curve path. Its pinned Python mode invokes the public
frozen `reconstruct_fpca` source with a `SimpleNamespace` carrying
**the same frozen native fitted mean, components, and scores**; this
isolates the reconstruction *function's* source numerical contract
from Python-versus-R FPCA fitting sign indeterminacy. The test compares
both training-score and external-score Python/R array outputs. R source,
documentation and tests received structural syntax checks. No R or
Python runtime execution of the new patch has occurred in the assistant
environment; next owner replay is mandatory.

Full one-to-one equivalence remains open because Python supports
additional array coercion, typed results and broader exceptional-domain
behavior. The new source test is a supplementary fixture, not proof
that the 111 review queue file-to-contract mappings increased.
**Do not change 203 recorded gap and 19 alternate scientific backend
counts or 0/508 independent certifications from this patch.**

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
