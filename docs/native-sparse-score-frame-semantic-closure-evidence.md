# Two sparse FPCA score-frame semantic source-contract closures

**Frozen Python oracle:** `eyetrajectoriespy==1.2.0`, source commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.

**Scope:** developer-verified *observational score-table semantics* for
valid fitted sparse FPCA and joint sparse MFPCA results. This is a
cross-language R `data.frame` / Python pandas `DataFrame` comparison,
**not** Python object-class identity, sklearn/fdapace source parity, an
independent certification, or a claim that the upstream estimators agree.

## Scientific input/result mapping

| Frozen source | Native R source | Required semantic behavior |
| --- | --- | --- |
| `sparse.py::sparse_fpca_score_frame` | `etr_sparse_fpca_score_frame` | Accept fitted sparse-score records; retain source curve order, metadata and SFPC values |
| `sparse_multivariate.py::sparse_mfpca_score_frame` | `etr_sparse_mfpca_score_frame` | Map frozen typed `SparseMFPCAResult` to native fitted `etr_sparse_mfpca_source`; retain joint SMFPC values |

The explicit reviewed equivalence policy is **observable table content for
valid mapped fitted results**, not binary identity of pandas and R
classes. The returned fields remain subject to a separate upstream
fit-estimator contract. The source row/column semantics are implemented
by a deliberately bounded deterministic adapter: `metadata.reset_index(drop=True).copy()`,
`insert(0, 'curve_id', curve_ids)`, then `frame['SFPCi'/'SMFPCi'] =
scores[:, i]`.

This order has material edge cases that are now handled deliberately:

- A pre-existing metadata column `curve_id` raises an error instead of
  silently overwriting the inserted curve ID.
- A pre-existing `SFPC1` / `SMFPC1` **does not** raise. It is replaced
  **in its existing column position**, as in pandas.
- Duplicated metadata column labels are retained. If the duplicated
  label is the selected score name, pandas assignment writes the same
  score vector to every column with that label.
- Ordered Unicode curve identifiers, numeric score values, retained
  missing scores, and original metadata column values and basic dtypes
  are preserved; the output row index is reset.
- The joint sparse-MFPCA adapter rejects generic untyped R lists,
  matching the source's typed-result requirement at the native S3
  representation boundary.

The shared helper also powers an **internal workflow table** that uses
the previous, explicitly requested `preserve_workflow_metadata=TRUE`
policy. It must continue to rename colliding metadata safely. The public
source-contract behavior and that workflow-specific option are separate
and independently regression-tested.

## Verification evidence

The exact tests are
`tests/testthat/test-native-sparse-score-frame-collisions.R`
and `tests/testthat/test-native-scientific-source-frames.R`.
The dedicated workflow is
`.github/workflows/native-r-parity-sparse-score-frame-closures.yml`.

The pinned source oracle constructs the actual frozen Python dataclass
types without refitting, runs both published score-frame functions,
and compares each ordered column and value with its native counterpart,
including Unicode, duplicate score labels, unrelated duplicate labels,
ordered score replacement and invalid `curve_id` insertion.
Native-only and full source-audit tests additionally verify that
workflow-specific aliasing remains intact. Required CI environments:
Linux, Windows, macOS, and Linux with the exact frozen Python 1.2
package. **Never treat a queued/pending/failed run as a pass.**

## Representation and certification limits

The native `data.frame` is not `pandas.DataFrame`: Python dataclass
identity, pandas extension-array class identity, arbitrary Python object
pointer identity, and Python-specific exception subclasses are not
claimed. The semantic mapping applies to fitted-result data representable
as native R metadata columns; the source's underlying sparse fit,
covariance/score estimators and independently certified input-schema
equivalence remain separate. The Python data-frame output is observed
only; this is not a claim of complete Python runtime emulation.

The authoritative historical source-gap records retain the source
reason and witness and clear exactly two `unresolved_source_gap`
flags for **developer-scoped semantic frames**. Independent approval
fields, `one_to_one_native_contract_complete`, and all estimator
source-gap flags remain FALSE/open.

### Effective 508 inventory after integration with PR #84

| Measure | PR #79 after PR #84 | After this PR's two frame closures |
| --- | ---: | ---: |
| Gap-free (native-language semantic coverage) | 308/508 | **310/508 (61.02%)** |
| Remaining source gaps | 200 | **198** |
| Independently certified | 0 | **0** |

This requires clean exact-head regression and ledger reconciliation on
the ultimate integration commit. The source branch was created before
the two catalog closures landed, so compare changes by function name,
not by assuming that its standalone CSV snapshot includes PR #84.
