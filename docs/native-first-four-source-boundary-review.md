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
| `alr_transform` | `etr_alr_transform` | Finite numeric-string/Boolean simplex arrays, regular numeric-like nested sequences, zero clipping, modulo reference channels including singleton | Python's `epsilon <= 0` does not reject NaN, which propagates NaN through NumPy operations. R deliberately rejects nonfinite epsilon. Broader array conversion/input-error domains still require review. |
| `inverse_alr` | `etr_inverse_alr` | Finite 3D numeric, numeric-string and Boolean arrays; singleton channel; exact reconstruction for moderate finite logits | Python's `np.exp` can overflow for large finite logits and produce nonfinite normalized outputs. Native R deliberately errors on nonfinite denominator; this is not source-identical. |
| `score_distance_matrix` | `etr_score_distance_matrix` | Native FPCA fit and finite matrix-score list; accepts finite numeric-string and Boolean score matrices as supported by sklearn coercion | Broader Python duck-typed objects, coercion, exception behavior, and sklearn floating-point edge behavior are not fully adjudicated. |

## Tests and exact-head qualification

- `tests/testthat/test-native-pilot-source-adversarial.R`: direct Python
  adversarial boundary witnesses for quadrature `+Inf` and truthiness,
  ALR NaN epsilon, inverse exponential overflow, and numeric-string/Boolean inverse plus numeric-string/Boolean source ALR inputs.
- `tests/testthat/test-native-source-contract-alignment.R`: numeric-string
  and Boolean FPCA score coercion, invalid strings, and direct pinned Python score oracles.
- These tests are part of `scripts/qualify_native_current_contracts.R`
  and `scripts/capture_native_source_qualification_evidence.R`. The direct
  Python cases run only with `ET_RUN_PYTHON_TESTS=true`.
- The 508-export review packet now emits
  `all_508_contract_review_priority.csv`,
  `known_source_gap_resolution_queue.csv`, and
  `review_lane_counts.csv` in addition to the existing source evidence.
  These are **unsigned priority queues**, never certificate approvals.

## November 3: source-scalar boundary extensions (new, unqualified)

The frozen source at Python commit
`c1cd95ad718327550f7e55393ff38582872f7a94` was inspected
directly in `fpca.py`, `compositional.py` and `analysis.py`.
The four first-party pilot contracts received the following **new
bounded compatibility behaviors**, all only when explicitly requested
with `python_boundary_mode=TRUE` where noted:

- **`functional_trapezoid_weights`**: Python `bool(complex)` is
  false for `0+0i` and true for nonzero real or imaginary parts.
  Native R now accepts finite complex **normalization scalars** in
  Python boundary mode. The scientific default still rejects them.
  Complex-valued time grids and arbitrary Python object truthiness
  are not certified.
- **`alr_transform`**: Python's `epsilon <= 0` comparison treats
  `True` as 1 and `False` as 0. R now normalizes a Boolean
  `epsilon` to its corresponding scalar only in compatibility
  mode. The prior NaN/Inf compatibility path is retained.
- **`inverse_alr`**: retained the NumPy exception boundary for
  Boolean shape arguments: `np.ones((n_curve,n_time,True))`
  rejects Boolean shape elements even though Python modulo
  arithmetic accepts them. Source boundary mode **does not**
  coerce Boolean `n_dimensions`.
- **`score_distance_matrix`**: Python accepts `n_components=True`
  as a valid slice index and rejects `n_components=1.0` even
  though it is numerically integral. Native R compatibility mode
  now enforces the frozen Python slice-index type, including a
  Boolean `fpca.n_components` attribute on minimal score objects.
  Legacy native R numerically integral double input remains supported
  by default. The 2-million-entry sparse densification cap remains.

`tests/testthat/test-native-four-pilot-scalar-boundary-source.R`
provides both native rejection/acceptance tests and an opt-in direct
frozen Python 1.2 scientific oracle covering all four families.
It is included in both native and Python qualification test filters
and the source-file inventory.

**Testing status:** source changes have been committed; Windows native
and pinned Python qualification must be rerun at the new exact HEAD.
Do not reclassify any of the **204 historical source-gap exports**,
count the four as scientifically approved, or mark even one of
the **508 independent certificates** as obtained. These are additional
first-party source-domain comparisons, not full scientific review.

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
