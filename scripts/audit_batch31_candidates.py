#!/usr/bin/env python3
"""Conservative two-candidate source-gap audit, never approves contracts."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys

TARGETS = {
    'functional_simulation_scenario_frame',
    'expand_functional_simulation_scenarios',
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', required=True)
    args = p.parse_args()
    repo = Path(args.repo).resolve()
    ledger = repo/'artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv'
    b30 = repo/'artifacts/native_full_contract_evidence/batch30_public_expansion_diagnostic.json'
    source = repo/'R/zz-native-scenario-expansion-batch29.R'
    try:
        with ledger.open(encoding='utf-8-sig', newline='') as f:
            rdr = csv.DictReader(f)
            rows = list(rdr)
        if len(rows) != 204 or 'python_name' not in rdr.fieldnames:
            raise ValueError('Expected 204 historical rows with python_name')
        found = {r['python_name']:r for r in rows if r['python_name'] in TARGETS}
        if set(found) != TARGETS:
            raise ValueError('The two named historical candidate rows are missing')
        b30_data = json.loads(b30.read_text(encoding='utf-8'))
        verified = b30_data.get('public_cases_matching') == 11 and b30_data.get('total_cases') == 11
        report = {
            'status': 'DEVELOPER_REAUDIT_PENDING_R_PYTHON_DIRECT_SOURCE',
            'historical_ledger_sha256': sha(ledger),
            'historical_ledger_rows': len(rows),
            'frozen_python_reference_commit':'c1cd95ad718327550f7e55393ff38582872f7a94',
            'source_sha256':sha(source),
            'batch30_11_case_reference_probe_pass': bool(verified),
            'candidates':[
                {
                    'python_name': target,
                    'native_r_candidate': found[target].get('native_r_candidate'),
                    'historical_gap_kind': found[target].get('gap_kind'),
                    'historical_gap_open': str(found[target].get('unresolved_source_gap')).strip().lower() == 'true',
                    'remaining_review_requirements': found[target].get('review_resolution'),
                    'new_developer_gap_closure': False,
                    'independent_approval': False,
                } for target in sorted(TARGETS)
            ],
            'open_source_gap_count_unchanged': True,
            'independent_certifications_added': 0,
            'notes': 'The Batch 31 signed-zero/float-name improvement does not establish full-domain Python dataclass/pandas/tuple equivalence. No counts change.',
        }
        out = repo/'artifacts/native_full_contract_evidence/batch31_source_candidate_reaudit.json'
        out.parent.mkdir(parents=True,exist_ok=True)
        out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
        print('BATCH31_HISTORICAL_GAPS=204;CANDIDATES=2')
        print('BATCH31_SOURCE_REAUDIT='+str(out))
        print('BATCH31_NEW_GAP_CLOSURES=0;INDEPENDENT=0')
        return 0
    except (OSError,ValueError,KeyError) as ex:
        print('BATCH31_AUDIT_ABORT: '+str(ex),file=sys.stderr)
        return 2

if __name__=='__main__':
    sys.exit(main())
