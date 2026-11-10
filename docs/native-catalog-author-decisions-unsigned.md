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
| `get_mathematical_contract` | Accepts an exact key or registered API name. The Python wrapper checks the joint sparse contract before the base string type check. Unknown strings raise `KeyError`, ordinary nonstrings raise `TypeError`. | Returns the same six-field native record for every matching key or alias. Unknown strings signal `etr_mathematical_contract_key_error` with a `name` field. Other ordinary invalid types signal `etr_mathematical_contract_type_error`. R also accepts abbreviated named arguments and some shaped inputs. | Decide the record mapping and whether the complete public input is an ordinary scalar string with the native R argument and error conventions. If the Python equality protocol and NumPy facade behavior are in scope, keep the gap open for the boundary implementation. |
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

| Input | Frozen Python 1.2 behavior | Current native R behavior |
| --- | --- | --- |
| Omitted, extra or abbreviated argument | `TypeError` | Omitted and extra arguments raise R errors. `na="quadrature"` is partially matched to `name`. |
| Unknown, empty, differently cased or padded scalar string | `KeyError` with the Python `repr` of the input in the message | `etr_mathematical_contract_key_error` carries the exact input in `name`. Message formatting uses R text. |
| A 1×1 array or matrix containing `"quadrature"` | `TypeError` | The R matrix returns the quadrature record. |
| A 1×1 array or matrix containing `"fit_sparse_mfpca"` | Returns the joint sparse record through the Python facade check. | The R matrix returns the joint sparse record through the alias lookup. |
| A two-element NumPy string array or R character vector | Python raises an ambiguous truth value `ValueError`. | `etr_mathematical_contract_type_error`. |

Python's `str` subclasses and objects that implement custom equality
can also reach the facade comparisons. If the author chooses the
ordinary-string interpretation, the signed statement needs to specify
whether R scalar matrices, partial argument matching and error payloads
are accepted native semantics or require a code change before closure.
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
