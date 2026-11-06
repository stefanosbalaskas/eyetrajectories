# Batch 27 — full-contract evidence gate, five metadata APIs, native workflow quote parity

Pinned Python: `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`.

## Scientific versus representation discrepancies

- `mathematical_contract_frame` (88 rows, six exact UTF-8 fields) and
  `functional_recovery_metric_catalog_frame` (27 rows, six exact UTF-8 fields)
  are *deterministic zero-argument functions*. Their entire input domain is
  no arguments. A direct source replay checks all cells, names, row order, and
  excess-argument rejection. These are **eligible** for developer-level full
  semantic contract closure when a real local R/Python source replay succeeds.
- `list_mathematical_contracts` (41 structures),
  `get_mathematical_contract` (41 keys + each registered public function and
  invalid inputs), and `functional_recovery_metric_catalog` (27 structures)
  are also compared in their entire **metadata** domain. But Python tuples and
  dataclasses do NOT become the same runtime types as native R lists/S3 objects.
  Do not close their strict object contracts solely on field parity.
- `workflow_reporting_text`: native R now reproduces source Python `repr` for
  common quoted, escaped and control-character identifiers. Remaining exotic
  nonprintable Unicode and full workflow source dataclass domain are not closed.

## Three independent measurements

1. Historical recorded source gaps: 204 (203 callable + one Python class), immutable.
2. Evidence-gated developer-verified **full semantic frame contracts**:
   0 before actual R/Python execution; **2 after** successful live capture,
   SHA256 verification, and explicit registration. `developer_active_source_gap_count`
   moves 204 -> 202, while historical gap flags remain intact.
3. Signed independent scientific certifications: zero until external replay,
   review and actual authenticated decisions.

## Execute in the actual qualified Windows RStudio environment

1. Commit Batch 26 including its Boolean-CSR hotfix; execute full two-mode
   qualification. Apply Batch 27 only to a clean tracked checkout.
2. Apply Batch 27 guarded ZIP (`apply_batch.py --repo PATH --dry-run`, then apply).
3. Run the package `testthat` filter `native-catalog-contract-boundaries|native-workflow-source-audit`,
   `ET_RUN_PYTHON_TESTS=true` and `stop_on_failure=TRUE`.
4. Run `source("scripts/capture_catalog_contract_evidence_batch27.R")`.
   The script calls pinned Python directly and writes no evidence on a failed
   comparison. The resulting JSON is **author-side developer evidence**.
5. Run `python scripts/register_catalog_contract_evidence_batch27.py --repo .`
   for a dry run; run again with `--activate` to append the two audited rows.
6. Run `python scripts/audit_native_source_contracts.py --repo .`,
   `python scripts/test_audit_native_source_contracts.py .`, and
   `python scripts/test_catalog_contract_registry_batch27.py .`.
7. Commit updated files, the source replay evidence JSON, the developer registry,
   and updated generated audit reports. Then capture normal full two-mode
   qualification at the exact commit. Independent review remains unsigned.

Do not reinterpret `developer_active_source_gap_count=202` as 202 fully
certified Python contracts. It is a developer semantic clearance count only.
