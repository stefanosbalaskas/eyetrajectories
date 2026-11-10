# Native Python 1.2 reporting and alternative-estimator workstreams — Batch 28

This batch directly addresses data-frame, report-text, nested JSON, and result-schema
behavior for six published Python functions. It is **not** a release or a full-domain
third-party certification. Source pin: `c1cd95ad718327550f7e55393ff38582872f7a94`.

## Six target functions

- `workflow_steps_frame`, `workflow_decisions_frame` (compact, sorted-key JSON)
- `workflow_summary_frame`, `workflow_reporting_text` (summary, source `repr`)
- `functional_simulation_scenario_frame`, `functional_recovery_scenario_catalog_frame`
  (spaced Python-default JSON, full 23/26-column data-frame outputs)

`R/native-python-json-contracts.R` implements native scalar/sequence/mapping
serialization without Python at runtime. It distinguishes doubles (`1.0`)
from integers (`1`), preserves negative zero, one-element arrays, nested mapping
ordering, Unicode escaping, and default-vs-compact JSON separator policies.
The source oracle tests 6 workflow identifiers and 3 scenario-replicate regimes
across all native/source output columns. The R numeric formatting uses a
shortest-roundtrip algorithm for ordinary floating-point values; extreme
floating-point formatting and arbitrary Python input protocols remain open.

## Evidence and strict metrics

- Full source gate: `source("scripts/capture_reporting_contract_evidence_batch28.R")`
- Triage: `python scripts/audit_source_workstreams_batch28.py --repo .`
- Independent matrix: `artifacts/native_source_contract_reaudit_20261106/batch28_reporting_review_matrix.csv`
- Alternative-estimator queue: `batch28_scientific_estimator_workstream.csv`
- Frozen history 204, two Batch 27 developer verified closures, 202 active.
- This batch **activates no additional complete-contract closures** merely by
  applying code or passing bounded tests. Python class identity and full
  accepted input/error domains are not falsely counted as complete.
- Zero independent approvals. External reviewers must replay and sign outside
  the developer's own execution, without pre-filled decisions.

## High-priority separate native estimators

Source-specific scientific gaps include Python FDApy UFPCA versus native R
`fdapace`, Python `fdasrsf` SRVF alignment versus identity warps, Python
statsmodels `MixedLM` REML/likelihood versus native method-of-moments, and
multivariate sparse covariance/PACE versus native joint-score alternatives.
A separate 71-function plotting geometry workstream is generated, with explicit
Matplotlib-Axes versus base-R/ggplot-return differences and unsigned panel-level
source numeric-replay requirements. The full list of 16 recorded alternative backend/estimand gaps is generated
from the current 204-gap audit rather than guessed or deleted.

## Direct usage

After a clean verified `6519e02` checkout, install the guarded patch, run
`testthat::test_local(".",filter="native-python-json-reporting-batch28",
reporter="summary",stop_on_failure=TRUE,stop_on_warning=TRUE)` with
`ET_RUN_PYTHON_TESTS=true`, then the capture script and the 204-gap audit.
Run both full qualification modes before making any CRAN readiness claim.
