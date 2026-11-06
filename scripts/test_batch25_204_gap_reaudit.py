#!/usr/bin/env python3
"""Assert the existing source-gap inventory was not silently recertified."""
import csv,sys,json
from pathlib import Path
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
ledger=root/'inst/extdata/native_source_contract_gaps_stage22.csv'
audit=root/'artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv'
with ledger.open(newline='',encoding='utf-8') as f:rows=list(csv.DictReader(f))
with audit.open(newline='',encoding='utf-8') as f:all_rows=list(csv.DictReader(f))
assert len(rows)==203 and all(r['unresolved_source_gap']=='TRUE' for r in rows)
assert len(all_rows)==204 and len({r['python_name'] for r in all_rows})==204
assert all(r['independent_scientific_certified']=='FALSE' for r in all_rows)
assert any(r['python_name']=='TrajectorySet' and r['python_export_kind']=='nonfunction' for r in all_rows)
assert sum(bool(r['recorded_source_gap']=='TRUE') for r in all_rows)==204
network=next(r for r in rows if r['python_name']=='recurrence_network')
assert 'Batch 26 also adds' in network['known_source_difference']
assert 'Batch 24 user-qualified 3325897' in network['source_witness']
print('BATCH25_204_GAP_REAUDIT_PASS: 203 callable + 1 nonfunction; 0 independent approvals; no source gap closed')
