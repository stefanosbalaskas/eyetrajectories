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
- Separately tracked source differences:
  `inst/extdata/native_source_contract_gaps_stage22.csv`.

## Current draft review census

| Domain | Number | Meaning |
|---|---:|---|
| Python function mappings | 248 / 380 | Names associated with native R candidates |
| Native implementations started | 223 | Implemented operations; **not** proof of source equivalence |
| Unmapped Python functions | 132 | No declared native candidate |
| Known open source differences | 70 | Class, input, numerical, backend, error or scope boundaries |
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
