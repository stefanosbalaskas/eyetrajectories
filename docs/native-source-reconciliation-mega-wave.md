# Frozen 508-export source reconciliation

The reconciler reads both public Python namespaces from the frozen
`c1cd95ad718327550f7e55393ff38582872f7a94` checkout and matches them against
the 508-export manifest. It loads the R package's offline parity catalog,
finds the actual exported function and definition for each named native
candidate, and verifies the authoritative gap flags and review receipts.
It records Python definition paths and signatures or constant values,
native definition paths and formals, the current ledger blockers, and
the paths of any checked-in witness files cited by the ledger.

```sh
python scripts/reconcile_frozen_source_contracts.py --python-checkout ../eyetrajectoriespy
```

Run from a clean R source tree with `pkgload` and the frozen Python
runtime dependencies installed. Output under
`artifacts/source_contract_reconciliation/<r-head-prefix>/` includes
`all_public_exports.csv`, `active_source_gaps.csv`,
`reconciliation_summary.json` and the unsigned catalog packet. An
optional `--evidence-root` identifies another checkout holding strict
reports for the exact R commit. Reports with a mismatched source pin
fail validation. No exact-head reports yields no attributed comparisons.

On the integrated baseline `ca6bb53fcb0b74973e756f772fcce993eaa298bd`,
the two public Python namespaces matched the manifest and all 202 open
gap rows mapped to actual exported R definitions. The reconciler found
201 callable and one nonfunction gap, 306 exports without a recorded
gap, two legacy table-semantic closures, and zero full author reviews
or independent certifications. The exact-head strict suite supplied
1,690 passing bounded comparisons across 25 exports, 24 with open gaps.
The full inventory carries implementation status, gap status, bounded
evidence, an author receipt path when available, and the independent
certificate flag as separate fields.

## Deterministic contracts ready for focused review

| Group | Observed evidence | Remaining decision or implementation |
| --- | --- | --- |
| Catalog records and lookup | The source tests compare every ordered field and alias. The no-argument record catalogs have finite complete payloads. | Review the two record representations separately. Resolve the shaped input and call/error differences before claiming full lookup closure. See the [unsigned decisions](native-catalog-author-decisions-unsigned.md). |
| Workflow and scenario reporting | The Batch 28 source gate passes `workflow_steps_frame`, `workflow_decisions_frame`, `workflow_summary_frame`, `workflow_reporting_text`, `functional_simulation_scenario_frame` and `functional_recovery_scenario_catalog_frame`. It covers five identifiers and three replicate regimes. | Agree on dataclass-to-record and DataFrame-to-data.frame semantics. Extend validation to rejected records, default and extreme replicate inputs, exact Unicode identifier representation and JSON coercion. `workflow_config_to_dict` still needs arbitrary dataclass and nested Path/NumPy value decisions. |
| Quadrature and other numeric coercion | The integrated strict runner supplies 18 `functional_trapezoid_weights` comparisons. Current R source mode accepts list/null and finite scalar normalization flags, plus some nonfinite-grid inputs. | Exercise remaining NumPy array and custom object truthiness, warnings on nonfinite input, and explicit native coercion/error mappings. |
| Trajectory and result-frame metadata | The open constructor maps to `etr_trajectory_set`. Native source mode covers missing/nonfinite samples, empty curve axes, coercible array forms and metadata indexing. | Review the complete constructor/method domain, including curve ID collisions after stringification, index representation and provenance. Keep source-compatible result schemas separate from estimator and resampling changes. |
| Portable snapshots | Direct Python loader and native reader now verify ordered table values, Unicode, integer and logical types, missing cells and empty metadata. | `export_portable_result` remains open for arbitrary dataclass/opaque fields, Python environment capture, overwrite semantics and exact exception classes. `load_portable_result` has no historical gap row and the R reader still limits dtypes, byte sizes and supported table representations. |

The source ledger is authoritative for counts. In particular, absence
of a gap row establishes the recorded inventory status. Full developer
verification requires the linked author receipt, and independent
certification requires the external review register. Plots and
alternative estimators are identifiable by their published source
module, ledger blocker and native estimator marker. Review stable
scientific geometry and object representation separately from fits
with distinct backends or estimands.

## Portable snapshot regression

The previous native writer encoded the ordered list of metadata columns
as a JSON mapping. The Python 1.2 loader iterated that mapping and
interpreted its keys as column values. The corrected writer emits the
published ordered array layout, uses NumPy's little-endian dtype
descriptors, and carries missing text and logical values in unpickled
JSON object arrays. The native reader restores the observed primitive
type and the original curve index, including metadata with zero
columns. An all-null object array decodes to logical missing values
because the source encoding has no element type information.

```sh
ET_RUN_PYTHON_TESTS=true Rscript --vanilla -e 'testthat::test_local(
  ".", filter="native-python-portable-(reader|writer)",
  stop_on_failure=TRUE, stop_on_warning=TRUE)'
Rscript --vanilla scripts/capture_reporting_contract_evidence_batch28.R
```

The portable replay checks exact values and schemas in Python with
`pandas.testing.assert_frame_equal()` and verifies the native reader
with Python-produced bundles. The reporting capture writes its six
export names, fixture domain and content hashes to
`artifacts/native_full_contract_evidence/reporting_batch28_source_replay.json`.
