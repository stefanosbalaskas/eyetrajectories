# Frozen Python 1.2 — first four native source-contract boundaries

Source of record: `eyetrajectoriespy==1.2.0`, frozen Python commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.
Native R research implementation: PR #48. All checks described below are
**first-party source witnesses**, not independent certification.

## Why numerical fixture PASS is insufficient

The four first pilots currently have a numerical fixture-pass flag, but
independent numerical equivalence, accepted-input domain, error-schema,
scientific-scope and independent reviewer approval remain **FALSE**.
The source-gap inventory intentionally prevents a full-source-parity claim.

| Python public contract | Native public analogue | Validated/added scientific domain | Explicit remaining boundary |
| --- | --- | --- | --- |
| `functional_trapezoid_weights` | `etr_trapezoid_weights` | Increasing finite numeric and coercible scalar-sequence grids; scalar numeric/logical normalize flags | Python accepts nonfinite grid `[0,1,+Inf]` under its `diff(time)>0` guard, yielding Inf weights; Python also accepts arbitrary truthy objects such as nonempty strings as `normalize`. R deliberately rejects both. |
| `alr_transform` | `etr_alr_transform` | Finite simplex arrays, regular numeric-like nested sequences, zero clipping, modulo reference channels including singleton | Python's `epsilon <= 0` does not reject NaN, which propagates NaN through NumPy operations. R deliberately rejects nonfinite epsilon. Broader array conversion/input-error domains still require review. |
| `inverse_alr` | `etr_inverse_alr` | Finite 3D numeric arrays and now 3D numeric-string arrays; singleton channel; exact reconstruction for moderate finite logits | Python's `np.exp` can overflow for large finite logits and produce nonfinite normalized outputs. Native R deliberately errors on nonfinite denominator; this is not source-identical. |
| `score_distance_matrix` | `etr_score_distance_matrix` | Native FPCA fit and finite matrix-score list; now accepts finite numeric-string score matrices in line with sklearn's coercion | Broader Python duck-typed objects, coercion, exception behavior, and sklearn floating-point edge behavior are not fully adjudicated. |

## Tests and exact-head qualification

- `tests/testthat/test-native-pilot-source-adversarial.R`: direct Python
  adversarial boundary witnesses for quadrature `+Inf` and truthiness,
  ALR NaN epsilon, inverse exponential overflow, and numeric-string inverse.
- `tests/testthat/test-native-source-contract-alignment.R`: numeric-string
  FPCA score coercion, invalid strings, and direct pinned Python score oracle.
- These tests are part of `scripts/qualify_native_current_contracts.R`
  and `scripts/capture_native_source_qualification_evidence.R`. The direct
  Python cases run only with `ET_RUN_PYTHON_TESTS=true`.
- The 508-export review packet now emits
  `all_508_contract_review_priority.csv`,
  `known_source_gap_resolution_queue.csv`, and
  `review_lane_counts.csv` in addition to the existing source evidence.
  These are **unsigned priority queues**, never certificate approvals.

## Mandatory scientific/reviewer decision

1. Re-run both qualification modes at the exact immutable native R commit,
   verify the frozen Python source/version, and preserve test logs and hashes.
2. Independently verify source-documented values, array shapes, coercions,
   errors and the scientific domain for **each** public contract, not only
   the shared test suite outcome.
3. Resolve each known discrepancy by a documented source-equivalent
   implementation or explicitly distinguish a **native scientific alternative**.
   Restricting the accepted domain is not full Python-source equivalence.
4. Record the reviewer's identity, independent rerun, signed exact commit,
   scientific decision, and linked evidence before considering any ledger
   approval. The implementer must not self-sign.
5. Extend the same process to 107 other selected candidates and the remaining
   public exports, including all 128 nonfunction contracts.

**Current source-contract certification remains 0/508.**
