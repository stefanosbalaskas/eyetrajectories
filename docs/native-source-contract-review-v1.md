# Native R source-contract qualification — frozen Python 1.2.0

This is an evidence-oriented development note, **not a certification claim**.

## Source of record

- Python package: `eyetrajectoriespy==1.2.0`, published source commit
  `c1cd95ad718327550f7e55393ff38582872f7a94`.
- API census source snapshot `7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`:
  **508 exports = 380 callables + 128 classes/constants**.
- Auditable R inventory: `etr_native_parity_catalog()`.
- Actionable per-export review queue:
  `etr_native_source_contract_review_queue()`.
- First/all missing evidence for each of the 508 contracts:
  `etr_native_certification_readiness_frame()`. This is a read-only
  status report, not an auto-approval or source-equivalence claim.
- Separately tracked source differences:
  `inst/extdata/native_source_contract_gaps_stage22.csv`.

## Current draft review census

| Domain | Number | Meaning |
|---|---:|---|
| Python function mappings | 304 / 380 | Names associated with native R candidates |
| Native implementations started | 279 | Implemented operations; **not** proof of source equivalence |
| Unmapped Python functions | 76 | No declared native candidate |
| Known open source differences | 126 | Class, input, numerical, backend, error or scope boundaries |
| Nonfunction exports for independent review | 128 | Values/classes not counted as native functions |
| Complete independently certified public contracts | **0 / 508** | Four approval domains are not all independently signed off |

## Qualification gate for one contract

A function, class or constant may be marked complete **only after**:

1. The **same published source** is pinned and the accepted domain, version,
   signature and coercion/identity rules are exhaustively recorded.
2. Independently authored direct Python vs native R test suites reproduce
   numerical values, admissible rounding/tolerances, array shapes, masks,
   dtypes, deterministic/stochastic policy and all declared support domains.
3. Type, schema, metadata, return-value, warning/error and invalid-input
   boundaries are reviewed, including cases for which Python and R are
   intentionally different. A known unresolved gap **blocks** approval.
4. The scientific estimand, inference unit, assumptions, uncertainty,
   calibration/coverage scope and provenance are separately qualified.
5. An **independent reviewer** examines the evidence and records approval in
   a durable, exact-SHA GitHub commit reference. Green CI or a matching name
   is not independent reviewer approval.

The certification ledger is deliberately fail-closed:
`etr_native_parity_catalog(require_complete=TRUE)` throws until all 508
individual source contracts are approved. Never set approval flags merely to
satisfy a test or a release gate.

## Newly integrated restricted contracts

`etr_workflow_config_to_dict()` accepts native R S3 workflow configs rather
than Python frozen dataclasses. Source-class parity is **not** claimed.

`etr_functional_simulation_scenario()` declares observed-grid designs without
running a simulator. `etr_functional_simulation_scenario_frame()` reports a
source-ordered 23-column design summary. The native subset currently rejects
measurement noise covariance rather than silently substituting another noise
model; Python dataclass/class identity and JSON byte formatting differ.

`etr_expand_functional_simulation_scenarios()` implements explicit
scalar-factor Cartesian expansion and the Python `shared` / `disjoint`
seed-block policies in a declared subset; arbitrary complex Python factor
domains and Python result tuples remain unqualified.

`tests/testthat/test-native-functional-scenario-design.R` includes
Python-1.2-opt-in source witnesses and native invalid-domain cases. Running
these tests proves only the included fixtures, not full domain certification.

\`etr_functional_recovery_qualification_scenarios()\` adds the four published\nsource-defined CI recovery designs (dense Gaussian and Student-t, native\nsparse PACE, and hierarchical source variance) but no simulation execution.\nPython frozen dataclass tuple identity and extreme integer inputs are\nnot qualified.\n\nThe native R stress-design integration reproduces the fourteen published
stress regimes and combines them with the four qualification cases in an
eighteen-scenario catalogue. Explicit finite symmetric PSD covariance
is now supported when independent noise SD is zero. Full-source
Python dataclass/pandas equivalence and all accepted value types
remain open certification gaps.

Two newly mapped Python 1.2 read-only simulation audit adapters provide
source-ordered realized-truth frames and manuscript reporting without
native simulation. The full Python dataclass/pandas return contract and
significant-digit/error domain remain unqualified.

Three source-aligned read-only simulation diagnostic plot integrations now
cover curve truth audits, phase warps and score-source variance bars.
Population score variances use NumPy ddof=0. Returned R geometry remains
scientifically distinct from Python Matplotlib Axes and is recorded as a
known unresolved contract difference pending direct reviewer approval.

Six additional source-aligned audit frames cover participant and nested-trial
random effects, whole-participant and nested-trial full-refit bootstrap
identities, FPCA truncation scan metadata and target-specific selections.
All source identities are kept in source order and zero-based where published
Python uses zero-based indices. Python frozen dataclass/pandas return
semantics and accepted input domains remain explicitly unresolved.

Two additional source-aligned native R graphics functions now visualize
participant and nested-trial functional random effects without fitting.
Their base graphics results do not reproduce Python Matplotlib Axes and
therefore remain documented open full-source contracts.

Four predictive/CV and bootstrap sensitivity plots now expose exact
source diagnostic coordinates, including ddof=1 CV standard errors,
nested outer fold loss, sorted mixed band-width ratios and selected
wild-bootstrap truncation h. R returns base graphics and audit records,
not Python Matplotlib Axes or typed dataclass objects; those complete
source contract differences remain unapproved.

The fail-closed `etr_native_certification_readiness_frame()` gives every
frozen export its first/all missing evidence requirements, separating
unmapped functions, incomplete native integrations, published-source gaps,
numerical-oracle approval, schema, scientific scope, reviewer approval and
reproducible published-source evidence. Existing explicit certification
gates remain unchanged; no additional contracts have been promoted.

Six additional source-aligned read-only plots cover FPCR projection,
conditional mean, future-outcome and observed-grid slope uncertainty plus
sparse PACE conditioning diagnostics. Source oracles compare numerical
interval and line coordinates and PACE scatter masks. Native R named-list
inputs and base graphics are not Python dataclass and Matplotlib Axes
return contracts; all six differences remain open.

A source-exact native stabilized-volatility FPCR truncation selector is now
implemented alongside four read-only projection, simultaneous family-test
and Monte Carlo precision audit tables. The algorithm applies the earliest
candidate with r+1 consecutive stable transitions, reports missing targets,
and cannot silently choose the largest h. Frozen Python dataclass/pandas
type contracts and full accepted-domain/schema behavior remain explicit
open certification differences. Numerical source-oracle testing is opt-in.


Eight additional source-aligned native manuscript-reporting functions now
cover FPCR wild projections, future-outcome intervals, paired bootstrap
uncertainty, observed-grid simultaneous slope bands, nested CV performance,
familywise fixed-target tests, finite-bootstrap Monte Carlo diagnostics and
fixed-family simultaneous intervals. These return scientifically qualified
strings from explicit finite R records and have opt-in Python 1.2 exact-text
oracles. Native list acceptance is narrower than published Python dataclasses;
**all eight remain source-contract gaps, not independent certifications**.

Three additional read-only reporting integrations summarize held-out FPCA
regression CV, descriptive matched-component bootstrap envelopes and the
shared-multiplier stabilized-volatility truncation scan. Their native R
implementations use conservative validated list records, with opt-in
Python 1.2.0 exact-text oracles, explicit scientific-scope boundaries and
unresolved typed-source-contract gaps. No numerical certification flags
are automatically promoted.

## Frozen-source numerical diagnostics and R-native visualizations

Four source counterpart functions extend the release beyond report text:
`etr_multivariate_iaaft_diagnostics_frame()` retains 0-based
surrogate IDs, iterations, maximum and mean power-/cross-spectrum errors;
`etr_functional_mixed_effects_variance_bootstrap_frame()` retains
replicate-specific covariance traces, eigenvalues, condition numbers,
fit warnings, and optional residual/trial/slope submodels;
`etr_plot_multivariate_iaaft_diagnostics()` and
`etr_plot_multivariate_surrogate_nonlinearity()` provide source-inspired
R base-graphics diagnostics.

Both numeric frames have opt-in direct Python 1.2 typed-object dataframe
oracles, including a full-refit diagnostic record with all optional
covariance diagnostics. The plots are base-R graphic outputs rather than
Matplotlib Axes; **do not claim exact rendering/return-type parity**.
Source-domain limitations and four open differences are recorded in the
source-gap inventory, and certification stays unsigned.

## Sparse univariate native/FDApy reporting

The `etr_sparse_fpca_reporting_text()` source port covers both the
published native sparse PACE report and the historical FDApy reporting
branch, including evaluator grids, counts, retained eigenvalues,
PSD/noise diagnostics and scoring status. The accompanying Python 1.2.0
opt-in fixtures exercise both backend-specific report paths. This is a
validated conservative input and formatting subset, **not** complete
source-domain/type parity.

## Three additional scientific model source reporters

The native R source now includes fit-level marginal generalized
function-on-scalar reporting (including optional participant bootstrap
coefficient bands), within-trial mixed-effects residual dependence
reporting, and native sparse multivariate PACE scientific reporting.
Each preserves the published source's caveats about independent
participants, simultaneous-grid inference, residual covariance,
covariance-PSD repair, scoring failures and missing uncertainty terms.
The residual text intentionally preserves the frozen Python 1.2.0
source's repeated wording to permit strict, literal comparison.

`tests/testthat/test-native-source-model-reports.R` adds native
validation and opt-in pinned-source typed-object exact-string oracles.
Numeric array formatting for sparse measurement-error covariance
is deliberately restricted and remains an unresolved source contract.
None of these reporting functions performs a fit or calibrates bands.

## Five scientific interpretation reporters

Five more source-aligned, native-only reporting functions now cover
generalized function-on-scalar prediction, paired response-scale
contrasts, covariance-structure sensitivity, multivariate IAAFT
surrogates and surrogate-based nonlinearity inference. These reporters
do not estimate models or certify a family of confidence bands.
Scientific language explicitly retains the source limitations on
extrapolation, between-grid inference, covariance-model selection,
Monte Carlo p-values and deterministic-chaos interpretations.

`tests/testthat/test-native-source-text-inference.R` carries native
fail-closed boundaries and opt-in Python 1.2 exact-string witnesses.
All five have unresolved input/type/source scope differences. No
certification approval is set automatically.

## Six source-ordered scientific observation frames

Added native R extraction for generalized function-on-scalar coefficient,
prediction, mean-difference and exposure records, together with sparse
univariate FPCA and sparse multivariate FPCA score frames. These are
read-only, strongly validated list-data adapters, not new estimators.
Band columns, nullable Poisson fields, profile-by-time ordering and the
exposure_audit provenance attribute are included. A pinned Python 1.2
typed-object comparison covers source column schemas, cell values and
exposure audit. Broader Python dataclass/dtype acceptance is **not**
certified; six unresolved source differences remain tracked.

Run `source("scripts/qualify_native_inference_reporting.R")` locally to
exercise both offline and Python source tests, including
`test-native-scientific-source-frames.R`.

## Reproducible full-contract review dossier for twenty-six scientific ports

The eleven source-aligned inference reporting functions and six native scientific frame adapters plus nine source-interpretation/model reporters have an explicit
independent-review handoff, with source commit, test file, unresolved
requirements, and unapproved evidence columns:

```r
source("scripts/build_inference_contract_dossier.R")
```

This writes `artifacts/native_inference_contract_review/python_1_2_scientific_contract_review_queue.csv`.
It does **not** mark any full source contract certified. Local RStudio
assertions, an exact-string Python oracle, and independent documentation
of complete type/error domain and scientific scope are separate requirements.
A reviewer must provide exact SHA-linked signoff; never substitute a passing
fixture or a model-authored status statement for that approval.

## One-command local qualification of the latest reporting batch

Run from the repository root in RStudio:

```r
source("scripts/qualify_native_inference_reporting.R")
```

The script first runs native R tests with Python disabled, then requires
`eyetrajectoriespy==1.2.0` and executes pinned Python direct-source
reporting oracles. It stops on any failure; passing does not mark any of
the 508 full contracts independently certified.

## Local qualification on PR #46

Use the exact Git HEAD from the draft PR before reporting test results.

```r
pkgload::load_all(".", quiet = TRUE)
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
testthat::test_local(".", filter =
  "native-functional-scenario-design|native-private-helper-names|native-workflow-configuration|native-workflow-source-audit|full-native-r-parity-ledger|native-",
  reporter = "summary")

stopifnot(identical(et_python_version(), "1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS = "true")
tryCatch(
  testthat::test_local(".", filter =
    "native-functional-scenario-design|native-workflow-configuration|native-workflow-source-audit|native-functional-inference-visuals",
    reporter = "summary"),
  finally = Sys.unsetenv("ET_RUN_PYTHON_TESTS")
)
```

The current GitHub Actions runner failures with zero executed job steps are
an infrastructure qualification blocker, not empirical failure/success of a
scientific contract. Keep the changes draft; do not merge or release.
