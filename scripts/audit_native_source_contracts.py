#!/usr/bin/env python3
"""Deterministic 508-inventory source-gap triage; NEVER awards certification.

Reads frozen 203 callable and 1 nonfunction gap ledgers, scans local R source
for mapped definitions, and prepares an unsigned 36-export review handoff.
No network access, Python runtime dependency, or self-attestation.

Only a named implementation is verified automatically. Classifications are
provisional triage, not scientific/domain equality decisions.
"""
from __future__ import annotations
import argparse, csv, hashlib, json, re
from collections import Counter
from pathlib import Path

PINNED_PYTHON = "c1cd95ad718327550f7e55393ff38582872f7a94"
DEFAULT_BASELINE = "1e32391"  # User-qualified Batch 22 local HEAD; Batch 23 still pending.
ALTERNATIVE_NAMES = (
    "fit_elastic_fpca", "fit_sparse_mfpca", "run_sparse_mfpca_workflow",
    "run_sparse_mfpca_async_workflow", "run_sparse_multilevel_workflow",
    "run_sparse_prediction_workflow",
    "functional_mixed_effects_covariance_sensitivity",
    "bootstrap_functional_mixed_effects_coefficients",
    "bootstrap_functional_mixed_effects_full_refit",
    "to_skfda_grid", "to_skfda_basis", "detect_functional_outliers_skfda",
    "to_fdapy_irregular", "fit_sparse_fpca_fdapy", "fit_sparse_fpca",
    "fit_functional_mixed_effects_regression", "fit_multilevel_fpca",
    "run_functional_mixed_effects_workflow", "run_sparse_fpca_workflow",
)


# Bounded evidence registry; a named test proves NEITHER full scientific
# equivalence nor independent approval. This field reports REVIEW TARGETS
# and will remain pending until the named R/Python test is actually executed.
BOUNDED_SOURCE_TESTS = {
    "recurrence_network": (
        "tests/testthat/test-native-recurrence-sparse-source.R",
        "six-node graph and 2501-state sparse-output boundary passed Batch 22; Batch 23 sparse-input tests pending",
        "SciPy CSR Python dataclass versus native sparse Matrix/S3 result, including legacy R aliases"),
    "recurrence_network_node_frame": (
        "tests/testthat/test-native-recurrence-sparse-source.R",
        "source-aligned node frame from sparse recurrence adjacency",
        "Python pandas DataFrame versus native R data.frame"),
    "recurrence_network_summary_frame": (
        "tests/testthat/test-native-recurrence-sparse-source.R",
        "source-aligned global graph statistics from sparse adjacency",
        "Python pandas DataFrame versus native R data.frame"),
}


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def csv_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        return reader.fieldnames, list(reader)


def classify(name: str, gap_kind: str, alternative: bool) -> str:
    if name == "TrajectorySet":
        return "constructor_class_and_domain"
    if alternative:
        return "scientifically_alternative_estimator_or_backend"
    if name.startswith("plot_"):
        return "visualization_backend_and_graphical_schema"
    if name.endswith("_reporting_text"):
        return "narrative_reporting_format_and_possible_domain"
    if name.endswith("_frame"):
        return "tabular_reporting_schema_and_possible_numerics"
    scientific_markers = (
        "estimator", "numerical", "stochastic", "bootstrap", "covariance",
        "scientific", "sparse", "likelihood", "simulation", "recovery",
        "mixedlm", "source_model", "statistical", "inference", "moment",
        "quantile", "regression", "selection", "fit", "domain",
    )
    if any(word in gap_kind.lower() for word in scientific_markers):
        return "scientific_or_numeric_domain_and_result_schema"
    return "mixed_input_domain_or_cross_language_representation"


def next_action(category: str) -> str:
    if category == "scientifically_alternative_estimator_or_backend":
        return "Implement or validate the Python estimand/backend; establish numerical and boundary oracle"
    if category.startswith("visualization"):
        return "Review plot data, panel geometry and backend-specific return policy; certify source semantics separately"
    if category.startswith("tabular"):
        return "Compare row ordering, all numeric columns, missing values and R/pandas schema; request reviewer approval"
    if category.startswith("narrative"):
        return "Compare generated statistic values, formatting, optional inputs and transcript source semantics"
    if category.startswith("constructor"):
        return "Compare full constructor validation, coercions and methods on dense/missing/irregular arrays"
    return "Compare accepted input domain, full numerical/statistical outputs, error behavior and result schema"


def run(root: Path, out_dir: Path) -> dict:
    ledger = root / "inst/extdata/native_source_contract_gaps_stage22.csv"
    extra = root / "inst/extdata/native_nonfunction_source_gaps_v1.csv"
    fields, callable_rows = csv_rows(ledger)
    other_fields, others = csv_rows(extra)
    expected_fields = ["python_name", "native_r_candidate", "gap_kind",
        "known_source_difference", "source_witness", "review_resolution", "unresolved_source_gap"]
    if fields != expected_fields or len(callable_rows) != 203 or len(others) != 1:
        raise ValueError("Frozen recorded-gap inventory is not the expected 203+1 domain")
    if any(r["unresolved_source_gap"].upper() != "TRUE" for r in callable_rows):
        raise ValueError("Recorded callable status differs; do not infer approved contracts")
    if any(r.get("unresolved", "").upper() != "TRUE" for r in others):
        raise ValueError("Recorded nonfunction status differs; do not infer approved contracts")
    source_files = sorted((root / "R").rglob("*.R"))
    sources = {p.relative_to(root).as_posix(): p.read_text(encoding="utf-8")
               for p in source_files}
    audit = []
    for item in callable_rows + others:
        name = item["python_name"]
        candidate = item["native_r_candidate"]
        callable_kind = item in callable_rows
        # Count only a real named definition, not a comment or NAMESPACE export.
        pattern = re.compile(r"(?m)^\s*" + re.escape(candidate) + r"\s*<-\s*function\s*\(")
        locations = [p for p, data in sources.items() if pattern.search(data)]
        alternate = name in ALTERNATIVE_NAMES
        cat = classify(name, item["gap_kind"], alternate)
        audit.append({
            "python_name": name,
            "native_r_candidate": candidate,
            "python_export_kind": "function" if callable_kind else "nonfunction",
            "recorded_source_gap": "TRUE",
            "native_named_definition_found": str(bool(locations)).upper(),
            "native_definition_files": ";".join(locations),
            "provisional_primary_blocker": cat,
            "scientific_alternative_registry_member": str(alternate).upper(),
            "cross_language_representation_review_required": "TRUE",
            "numerical_full_domain_verified": "FALSE",
            "independent_scientific_certified": "FALSE",
            "verified_input_error_result_schema": "FALSE",
            "ledger_gap_kind": item["gap_kind"],
            "ledger_source_witness": item["source_witness"],
            "next_full_contract_action": next_action(cat),
            # A planned source oracle is not an executed scientific verdict.
            "bounded_source_test": BOUNDED_SOURCE_TESTS.get(name,("","",""))[0],
            "bounded_tested_domain": BOUNDED_SOURCE_TESTS.get(name,("","",""))[1],
            "remaining_representation_difference": BOUNDED_SOURCE_TESTS.get(name,("","",""))[2],
            "bounded_source_test_status": "DEVELOPER_LOCAL_PASS_AT_1E32391_NOT_INDEPENDENT"
                if name == "recurrence_network" else
                "AWAITING_LOCAL_R_AND_PYTHON_EXECUTION"
                if name in BOUNDED_SOURCE_TESTS else "NO_NEW_BATCH_23_ORACLE",
            "review_state": "PENDING_INDEPENDENT_REPLAY",
        })
    if len(audit) != 204 or len({r["python_name"] for r in audit}) != 204:
        raise ValueError("Reaudit must contain 204 unique frozen exports")
    # Guard against silent missing candidate implementations; report them.
    # We do not use a negative result as proof an analogue is absent: dynamic
    # functions can be registered outside the statically visible root.
    audit.sort(key=lambda r: r["python_name"])
    out_dir.mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "all_204_source_gaps.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, audit[0].keys(), lineterminator="\n")
        w.writeheader(); w.writerows(audit)
    priorities = {
        "scientifically_alternative_estimator_or_backend": 0,
        "scientific_or_numeric_domain_and_result_schema": 1,
        "mixed_input_domain_or_cross_language_representation": 2,
        "constructor_class_and_domain": 3,
        "tabular_reporting_schema_and_possible_numerics": 4,
        "narrative_reporting_format_and_possible_domain": 5,
        "visualization_backend_and_graphical_schema": 6,
    }
    candidates = sorted(audit, key=lambda r:(
        priorities[r["provisional_primary_blocker"]], r["python_name"]))
    review = []
    for item in candidates[:36]:
        review.append({
            "python_name": item["python_name"],
            "native_r_candidate": item["native_r_candidate"],
            "frozen_python_sha": PINNED_PYTHON,
            "evidence_reference": item["ledger_source_witness"],
            "review_dimension": item["provisional_primary_blocker"],
            "numerical_oracle": "PENDING",
            "accepted_domain_and_errors": "PENDING",
            "source_estimand_and_statistics": "PENDING",
            "native_result_schema": "PENDING",
            "independent_reviewer_decision": "PENDING",
            "signed_evidence_file": "",
        })
    with (out_dir / "independent_review_handoff.csv").open("w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,review[0].keys(),lineterminator="\n")
        w.writeheader();w.writerows(review)
    category_count = dict(sorted(Counter(r["provisional_primary_blocker"] for r in audit).items()))
    summary = {
        "baseline_commit_prefix": DEFAULT_BASELINE,
        "frozen_python_commit": PINNED_PYTHON,
        "inventory_exports": 508,
        "mapped_python_functions_previous_qualification": 380,
        "source_gap_export_count": 204,
        "callable_recorded_gaps": 203,
        "nonfunction_recorded_gaps": 1,
        "scientific_alternative_names_in_registry": len(ALTERNATIVE_NAMES),
        "scientific_alternatives_with_recorded_source_gap": sum(r["scientific_alternative_registry_member"]=="TRUE" for r in audit),
        "scientific_alternatives_without_recorded_source_gap": len(ALTERNATIVE_NAMES)-sum(r["scientific_alternative_registry_member"]=="TRUE" for r in audit),
        "named_R_definition_observed": sum(r["native_named_definition_found"]=="TRUE" for r in audit),
        "review_candidates": len(review),
        "independent_certifications_from_this_audit": 0,
        "new_targeted_source_functions": len(BOUNDED_SOURCE_TESTS),
        "new_targeted_recorded_gap_exports": sum(r["python_name"] in BOUNDED_SOURCE_TESTS for r in audit),
        "new_targeted_test_source_executions_claimed": 1,
        "developer_bounded_replay_passes_from_batch22_log": 1,
        "batch23_sparse_source_extension_awaiting_R_execution": True,
        "strict_contract_gap_flags_changed": 0,
        "provisional_categories": category_count,
        "limitations": [
            "File-based audit: no independent numerical execution across all 204 exports",
            "Provisional classification uses names, recorded gap-kind and audited alternative-estimator registry",
            "Scientific vs representation categories can overlap; category is a triage, not a certification",
            "Full-domain statuses are deliberately FALSE pending source replays and independent sign-off",
            "Batch 22's recurrence-network source test passed in the user-provided qualification log for 1e32391; that is developer-side, not external review",
            "Batch 23 sparse-input and sparse-joint tests are authored but still require local execution",
        ],
        "source_ledger_sha256": file_digest(ledger),
        "nonfunction_ledger_sha256": file_digest(extra),
        "all_204_csv_sha256": file_digest(csv_path),
        "review_handoff_sha256": file_digest(out_dir/"independent_review_handoff.csv"),
    }
    with (out_dir/"summary.json").open("w",encoding="utf-8") as f:
        json.dump(summary,f,indent=2,ensure_ascii=False,sort_keys=True);f.write("\n")
    return summary


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--repo",type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output-dir",type=Path)
    a=parser.parse_args()
    root=a.repo.resolve()
    directory = a.output_dir or root/"artifacts/native_source_contract_reaudit_20261106"
    summary=run(root,directory)
    print("SOURCE_CONTRACT_REAUDIT_PASS=204",summary["provisional_categories"])
    print("INDEPENDENT_REVIEW_QUEUE=36; CERTIFICATIONS_GRANTED=0")

if __name__=="__main__": main()
