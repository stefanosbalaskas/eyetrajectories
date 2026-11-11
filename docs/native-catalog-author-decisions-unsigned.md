# Unsigned author decisions for the Python 1.2 catalogs

These decisions concern the three PR #76 source-gap IDs. The oracle is
`eyetrajectoriespy==1.2.0` at `c1cd95ad718327550f7e55393ff38582872f7a94`.
The native implementations are `etr_list_mathematical_contracts()`,
`etr_get_mathematical_contract(name)` and
`etr_functional_recovery_metric_catalog()`. Each ID needs a separate
author decision.

| Source-gap ID | Frozen Python behavior | Native R behavior | Decision for the author |
| --- | --- | --- | --- |
| `list_mathematical_contracts` | Returns one cached tuple with 41 frozen, slotted, hashable `MathematicalContract` records in documentation order. | Returns an ordered list named by contract key with six-field `etr_mathematical_contract` records. `public_api` and `equations` are character vectors. The caller can edit a copy without changing subsequent lookups. | Decide whether the complete metadata contract is exact ordered values, shapes and fresh-call isolation, with language-native container semantics. Approve that mapping or leave the gap open for an explicit identity contract. |
| `get_mathematical_contract` | Accepts an exact key or registered API name. The Python wrapper checks the joint sparse contract before the base string type check. Unknown strings raise `KeyError`, ordinary nonstrings raise `TypeError`. | Returns the same six-field native record for every matching key or alias. The explicit `python_boundary_mode = TRUE` adds exact name binding, quoted key errors and typed NumPy-shaped array outcomes. The default uses ordinary R argument matching. | Decide the record mapping and whether the explicit boundary mode covers the intended contract. Custom Python equality methods and native return identity still need a scope decision. |
| `functional_recovery_metric_catalog` | Returns a fresh tuple of 27 shared frozen, hashable `FunctionalRecoveryMetric` instances in insertion order. The six fields are scalar strings. | Returns an ordered list named by metric, containing six-field `etr_recovery_metric` records. Editing a caller's copy leaves future calls intact. | Decide whether the complete contract is exact ordered metric values and fresh-call isolation, with the documented R named-list representation. Approve that mapping or leave the gap open for an explicit identity contract. |

The mathematical fields are `key`, `title`, `public_api`, `equations`,
`site_anchor` and `scope`. The recovery fields are `name`, `quantity`,
`direction`, `units`, `scope` and `description`. The source replay
compares declared fields, order and UTF-8 content exactly across all
records, all 41 mathematical keys and all 88 aliases. It checks rejection
of extra positional and named arguments for the zero-argument exports.
The APIs return fixed metadata, so numerical tolerances, random draws
and fitting convergence are inapplicable.

## Lookup witnesses requiring a decision

| Input | Frozen Python 1.2 behavior | Native R with `python_boundary_mode = TRUE` |
| --- | --- | --- |
| Omitted, extra or abbreviated argument | `TypeError` | `etr_mathematical_contract_type_error`, including forwarded abbreviated arguments. |
| Unknown, empty, differently cased or padded scalar string | `KeyError` with the Python `repr` of the input in the message | `etr_mathematical_contract_key_error` carries the exact input in `name` and uses Python-style quoting in the message. |
| A 1×1 array or matrix containing `"quadrature"` | `TypeError` | `etr_mathematical_contract_type_error`. |
| A 1×1 array or matrix containing `"fit_sparse_mfpca"` | Returns the joint sparse record through the Python facade check. | Returns the joint sparse record. |
| Empty or multi-element NumPy array or R dimensioned array | Ambiguous truth value `ValueError` on NumPy 2.3.5. | `etr_mathematical_contract_value_error`. |

Python's `str` subclasses and objects that implement custom equality
can also reach the facade comparisons. The default R mode still accepts
ordinary partial name matching and scalar character matrices. An author
decision should specify the mode and represented domain under review.
The frozen wrapper and base implementation are
`src/eyetrajectoriespy/mathematical_contracts.py` and
`src/eyetrajectoriespy/_mathematical_contracts_base.py`.
The recovery record and catalog are in `src/eyetrajectoriespy/recovery.py`.

## Reproduction and recording

With the frozen checkout on the test Python import path and the native
R development dependencies available, run from the R repository root.

```sh
ET_RUN_PYTHON_TESTS=true Rscript --vanilla -e 'testthat::test_local(
  ".", filter="native-(catalog-contract-boundaries|zeroarg-metadata-source-semantic-closure)",
  stop_on_failure=TRUE, stop_on_warning=TRUE)'
python scripts/reconcile_frozen_source_contracts.py --python-checkout ../eyetrajectoriespy
```

The audit writes `catalog_author_decisions_UNSIGNED.json` under
`artifacts/source_contract_reconciliation/<r-head-prefix>/`. It pins the
native source, static catalog data and test file SHA-256 for each export
and leaves the decision and reviewer statement empty. The human author
records an affirmative decision under the
[source-contract closure process](source-contract-closure-review-process.md)
after reviewing the complete accepted contract. All three IDs are open.
Independent certification requires its own review.
