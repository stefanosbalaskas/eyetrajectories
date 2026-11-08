#!/usr/bin/env python3
"""Non-certifying audit overlay for Batch29 scenario expansion (204 historical rows)."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys

TARGETS = ('functional_simulation_scenario_frame',
           'expand_functional_simulation_scenarios')

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True)
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    csv_path = repo / 'artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv'
    source = repo / 'R/native-functional-scenario-design.R'
    additive = repo / 'R/zz-native-scenario-expansion-batch29.R'
    if not csv_path.is_file():
        print(f'BATCH29_V4_AUDIT_NO_LEDGER: {csv_path}',file=sys.stderr)
        return 2
    if not additive.is_file():
        print(f'BATCH29_V4_AUDIT_NO_REFERENCE: {additive}',file=sys.stderr)
        return 2
    if not source.is_file():
        print(f'BATCH29_V4_AUDIT_NO_SOURCE: {source}',file=sys.stderr)
        return 2
    with csv_path.open(encoding='utf-8-sig',newline='') as f:
        reader=csv.DictReader(f)
        rows=list(reader)
        columns=reader.fieldnames or []
    if len(rows)!=204:
        print(f'BATCH29_V4_AUDIT_ABORT: historical ledger unexpectedly has {len(rows)} rows',file=sys.stderr)
        return 2
    candidates=[]
    for row in rows:
        combined=' '.join(str(v or '') for v in row.values())
        matching=[name for name in TARGETS if name in combined]
        if matching:
            candidates.append({
                'targets':matching,
                'row_identifiers':{k:row.get(k) for k in columns if
                                   ('name' in k or 'export' in k or 'category' in k)},
                'status':'reinspect_after_RStudio_source_replay',
                'source_gap_closed':False,
                'independent_approval':False,
            })
    native=source.read_bytes()
    report={
        'historical_ledger_rows':len(rows),
        'historical_ledger_sha256':hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        'native_scenario_source_sha256':hashlib.sha256(native).hexdigest(),
        'additive_reference_sha256':hashlib.sha256(additive.read_bytes()).hexdigest(),
        'existing_public_api_replaced':False,
        'frozen_python_reference_commit':'c1cd95ad718327550f7e55393ff38582872f7a94',
        'candidate_rows':candidates,
        'candidate_row_count':len(candidates),
        'new_developer_approved_closures':0,
        'new_independent_approvals':0,
        'review_note':'This reference does NOT replace the existing public R function. Do not alter 202 active semantic gaps or 204 historical rows based on this script.',
    }
    dest=repo / 'artifacts/native_full_contract_evidence/batch29_v4_reaudit_candidates.json'
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f'BATCH29_V4_REAUDIT_HISTORICAL_ROWS={len(rows)}')
    print(f'BATCH29_V4_REAUDIT_CANDIDATE_ROWS={len(candidates)}')
    print('BATCH29_V4_NEW_DEVELOPER_GAP_CLOSURES=0')
    print('BATCH29_V4_NEW_INDEPENDENT_APPROVALS=0')
    print(f'BATCH29_V4_REAUDIT_JSON={dest}')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
