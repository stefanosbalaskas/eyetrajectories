# Frozen Python 1.2 wild-bootstrap inference: source-contract review packet

**Status:** candidate evidence, **not fully independently certified**.

## Frozen source and operations

- Published package: `eyetrajectoriespy==1.2.0`.
- Published code commit: `c1cd95ad718327550f7e55393ff38582872f7a94`.
- Python sources: `src/eyetrajectoriespy/wild_selection.py`,
  `wild_regression.py`, `wild_simultaneous.py`, `wild_testing.py`.
- Native code: `R/native-wild-source-inference.R`.
- Deterministic native and direct source oracles:
  `tests/testthat/test-native-wild-source-inference.R`.
- Source export inventory: frozen 508-symbol manifest, of which 380 are functions.
- Each of the five operations remains in the explicit open-source-gap register.

| Python frozen public function | Native R function | Numerical contract |
|---|---|---|
| `select_fpca_wild_bootstrap_truncation` | `etr_select_fpca_wild_bootstrap_truncation` | Earliest candidate with r+1 consecutive jointly stable width/center transitions; zero-based source candidate indices; no silent largest-h fallback; per-target missing selections |
| `fpca_wild_bootstrap_projection_frame` | `etr_fpca_wild_bootstrap_projection_frame` | Source-order projection, pseudo-truth, SE, critical value and interval |
| `fpca_wild_bootstrap_simultaneous_frame` | `etr_fpca_wild_bootstrap_simultaneous_frame` | Source targetwise criticals and derived intervals, repeated family critical, simultaneous bounds |
| `fpca_wild_bootstrap_family_test_frame` | `etr_fpca_wild_bootstrap_family_test_frame` | Fixed target nulls, statistics, unadjusted/adjusted p-values, target/family/global decisions |
| `fpca_wild_bootstrap_monte_carlo_diagnostic_frame` | `etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame` | Original source Monte Carlo exceedances, MCSE, bounds, and three-valued precision status |

## Qualification evidence currently supplied

1. Deterministic native source-order fixtures and exact field-order checks.
2. Failure-path checks for unsupported threshold, transition count, candidate
   shape, missing stable runs and refusal to substitute the largest candidate.
3. Direct opt-in Python 1.2 typed-source oracle of the complete selection
   outcome: delta matrices, stability matrices, selected indices/values,
   provenance and all four pandas result tables.
4. Additional **72 seeded differential source cases** varying candidate-grid
   lengths, number of targets, thresholds, stability run and cases with
   missing selections. Each computes Python source expected values and
   independently computes the native R result from identical arrays.
5. Tests assert these contracts remain unapproved while any source schema
   gap remains open.

**Execution status:** Python-oracle and 72-case stress tests newly added and
not yet run on this branch HEAD. Prior green RStudio logs cover the earlier
FPCR/PACE plotting methods, not these five new operations.

## Independent reviewer requirements before FULL approval

- Verify the reference package artifact/source tag, and that source SHA and
  the frozen public export manifest identify the exact released API.
- Independently execute full native and opt-in Python 1.2 tests, including
  72 differential cases; retain the complete seed, outputs and logs.
- Extend adversarial tests to threshold equality at floating-point boundaries,
  multiple qualifying starts, all missing selections, singleton targets,
  empty/invalid metadata, and extreme finite condition numbers.
- Evaluate *full* accepted input domain and exact errors. Python requires
  frozen typed result dataclasses; the native port currently accepts validated
  R named records. Python pandas output semantics and nullable cell types
  must receive explicit cross-language schema equivalence review.
- Reconcile S3 typing/validation of returned R selection object with
  frozen Python `FPCAWildBootstrapTruncationSelectionResult` properties.
- Verify scientific interpretation of fixed-target selection and inference:
  these functions do NOT estimate FPCA, simulate observations, generate
  bootstrap replicates, or establish calibrated coverage.
- Record a reproducible GitHub commit permalink identifying the complete
  independent review and explicit numeric, schema, scope and reviewer approvals.
  The existing certification gate refuses to approve known unresolved differences.

## Operational gates

The draft branch should **not** be merged, published, or described as having
full 508-source-contract certification on the strength of function counts,
a single numerical test, or GitHub CI statuses without executed job steps.

The registry `etr_native_certification_readiness_frame()` remains the
authoritative fail-closed report of first/all missing evidence per export.
