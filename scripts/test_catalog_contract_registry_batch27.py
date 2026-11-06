#!/usr/bin/env python3
"""Fail-closed offline checks: a planned test or forged approval is not a closure."""
from __future__ import annotations
import hashlib,json,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from register_catalog_contract_evidence_batch27 import validate,register,NAMES,EVIDENCE

def run(root:Path):
    # Real source replay is unavailable here until RStudio runs. Never mark
    # a developer closure just because the test file exists.
    if not (root/EVIDENCE).exists():
        try:register(root,True)
        except ValueError as exc:assert 'No executed' in str(exc)
        else:raise AssertionError('missing replay incorrectly granted a closure')
    reg=root/'inst/extdata/native_developer_verified_contracts.csv'
    assert reg.exists()
    import csv
    with reg.open(encoding='utf-8',newline='') as f:
        rows=list(csv.DictReader(f))
    assert len(rows) in (0,2)
    if rows:
        assert set(row['python_name'] for row in rows)==set(NAMES)
        assert all(row['independent_scientific_certified']=='FALSE' for row in rows)
        assert validate(root)
    # Tampered/fake evidence is rejected without adding a scientific claim.
    with tempfile.TemporaryDirectory() as temp:
        t=Path(temp)
        p=t/EVIDENCE;p.parent.mkdir(parents=True)
        p.write_text(json.dumps({'protocol':'developer_catalog_contract_closure_v1',
            'independent_certification_granted':True}),encoding='utf-8')
        try:register(t,True)
        except ValueError:pass
        else:raise AssertionError('forged independent certification accepted')
    print('BATCH27_CATALOG_CLOSURE_GATE_PASS: historical=204; independent=0; no unexecuted closure')

if __name__=='__main__':run(Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1])
