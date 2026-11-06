#!/usr/bin/env python3
"""Audit must be deterministic, fail closed, and never grant an approval."""
import tempfile, sys, json, hashlib, csv
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from audit_native_source_contracts import run, classify, ALTERNATIVE_NAMES

def test_reaudit_package(root):
    with tempfile.TemporaryDirectory() as temp:
        out=Path(temp)/"audit"
        a=run(root,out)
        assert a["source_gap_export_count"] == 204
        assert a["callable_recorded_gaps"] == 203
        assert a["nonfunction_recorded_gaps"] == 1
        assert a["independent_certifications_from_this_audit"] == 0
        assert a["strict_contract_gap_flags_changed"] == 0
        assert sum(a["provisional_categories"].values()) == 204
        assert a["new_targeted_source_functions"] == 3
        assert a["new_targeted_recorded_gap_exports"] == 1
        assert a["new_targeted_test_source_executions_claimed"] == 0
        with (out/"all_204_source_gaps.csv").open(newline="") as f:
            rows=list(csv.DictReader(f))
        assert len(rows)==204
        assert len({r['python_name'] for r in rows}) == 204
        assert all(r['recorded_source_gap']=="TRUE" for r in rows)
        assert all(r['independent_scientific_certified']=="FALSE" for r in rows)
        targets = [r for r in rows if r['bounded_source_test']]
        assert {r['python_name'] for r in targets} == {'recurrence_network'}
        assert all(r['bounded_source_test_status'] ==
            'AWAITING_LOCAL_R_AND_PYTHON_EXECUTION' for r in targets)
        assert any(r['python_name']=="TrajectorySet" and r['python_export_kind']=="nonfunction" for r in rows)
        assert sum(r['scientific_alternative_registry_member']=="TRUE" for r in rows)==a["scientific_alternatives_with_recorded_source_gap"]
        assert all(r['native_definition_files'] for r in rows if r['native_named_definition_found']=="TRUE")
        with (out/"independent_review_handoff.csv").open(newline="") as f:
            review=list(csv.DictReader(f))
        assert len(review)==36
        assert all(r['independent_reviewer_decision']=="PENDING" and not r['signed_evidence_file'] for r in review)
        first=(out/"all_204_source_gaps.csv").read_bytes()
        b=run(root,out)
        assert first==(out/"all_204_source_gaps.csv").read_bytes()
        assert a==b
        assert classify('plot_fpca','backend',False).startswith('visualization')
        print("BATCH22_SOURCE_GAP_AUDIT_TEST_PASS=204;INDEPENDENT_APPROVALS=0")

if __name__=='__main__':
    root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
    test_reaudit_package(root)
