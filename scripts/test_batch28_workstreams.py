#!/usr/bin/env python3
"""Fail closed on forged closures, missing 16 alternative estimators, false approvals."""
import csv,json,sys,tempfile,shutil
from pathlib import Path
from audit_source_workstreams_batch28 import run
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
summary=run(root)
assert summary['historical_recorded_source_gaps']==204
assert summary['developer_verified_complete_contracts']==2
assert summary['developer_active_source_gaps']==202
assert summary['independent_certifications']==0
assert summary['separate_plotting_geometry_workstream']==71
p=root/'artifacts/native_source_contract_reaudit_20261106'
with (p/'batch28_scientific_estimator_workstream.csv').open(encoding='utf-8') as f:
 rows=list(csv.DictReader(f));assert len(rows)==16
 assert all(r['independent_reviewer_decision']=='PENDING' for r in rows)
with (p/'batch28_reporting_review_matrix.csv').open(encoding='utf-8') as f:
 rows=list(csv.DictReader(f));assert len(rows)==6
 assert all(r['signature']=='' for r in rows)
with (p/'batch28_visualization_geometry_workstream.csv').open(encoding='utf-8') as f:
 rows=list(csv.DictReader(f));assert len(rows)==71
 assert all(r['independent_reviewer_decision']=='PENDING' for r in rows)
with tempfile.TemporaryDirectory() as d:
 t=Path(d)/'artifacts/native_source_contract_reaudit_20261106';t.mkdir(parents=True)
 src=p/'all_204_source_gaps.csv';dest=t/src.name;shutil.copy2(src,dest)
 records=list(csv.DictReader(dest.open(encoding='utf-8')))
 records[0]['independent_scientific_certified']='TRUE'
 with dest.open('w',encoding='utf-8',newline='') as f:
  w=csv.DictWriter(f,records[0].keys());w.writeheader();w.writerows(records)
 try:run(Path(d))
 except RuntimeError:pass
 else:raise AssertionError('forged external approval was not rejected')
print('BATCH28_WORKSTREAM_TEST_PASS=204/202;REPORTING=6;PLOTS=71;ESTIMATORS=16;EXTERNAL=0')
