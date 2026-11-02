#!/usr/bin/env python3
"""Reconcile developer evidence for 508 frozen exports, without self-certification.

The signed independent-review register and original unsigned packet are
read-only. A passing suite or a named test file is not a full-domain verdict.
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import sys

import verify_508_certification_batch as baseline

PROGRESS = "contract_progress_508.csv"
PRIORITY = "reviewer_priority_508.csv"
DISPATCH = "reviewer_dispatch_28.csv"
SUMMARY = "developer_progress_summary.json"
MANIFEST = "developer_progress_sha256.json"
TEMPLATE = "developer_evidence_UNSIGNED_TEMPLATE.csv"
FLAGS = (
    "source_signature_checked",
    "accepted_input_domain_checked",
    "numerical_oracle_checked",
    "boundary_and_exception_checked",
    "result_schema_checked",
    "scientific_estimand_checked",
)
IDENTITY = ("namespace", "python_name", "recorded_r_git_head",
            "frozen_python_commit")
EVIDENCE = (*IDENTITY, *FLAGS, "evidence_file", "evidence_sha256",
            "developer_findings")
HEX64 = re.compile(r"[a-f0-9]{64}\Z")


def check(ok: bool, reason: str) -> None:
    baseline.check(ok, reason)


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    check(bool(rows), "Cannot write an empty progress export")
    with path.open("w", newline="", encoding="utf-8") as out:
        writer = csv.DictWriter(out, fieldnames=list(rows[0]), extrasaction="raise")
        writer.writeheader()
        writer.writerows(rows)


def inspect_evidence(path: str | Path, original: list[dict[str, str]],
                     head: str) -> dict[tuple[str, str], dict[str, str]]:
    rows = baseline.read_csv(Path(path))
    baseline.columns(rows, EVIDENCE, "developer per-contract evidence")
    source = {(r["namespace"], r["python_name"]): r for r in original}
    seen: dict[tuple[str, str], dict[str, str]] = {}
    for row in rows:
        key = (row["namespace"], row["python_name"])
        check(key in source and key not in seen,
              "Unknown or duplicate evidence export: " + str(key))
        q = source[key]
        check(row["recorded_r_git_head"] == head and
              row["frozen_python_commit"] == baseline.FROZEN_PYTHON and
              row["recorded_r_git_head"] == q["recorded_r_git_head"],
              "Developer evidence source pins do not match reviewed packet")
        check(all(row[field] in {"TRUE", "FALSE"} for field in FLAGS),
              "Developer gate must be explicitly TRUE or FALSE")
        check(bool(row["developer_findings"].strip()),
              "Every developer evidence record requires written findings")
        evidence = Path(row["evidence_file"]).absolute()
        check(evidence.is_file() and not evidence.is_symlink(),
              "Developer evidence file missing or symlinked")
        check(HEX64.fullmatch(row["evidence_sha256"]) is not None and
              baseline.sha256(evidence) == row["evidence_sha256"],
              "Developer evidence SHA256 mismatch")
        seen[key] = row
    return seen


def read_pilot_numeric_evidence(path: str | Path,
                                original: list[dict[str, str]],
                                head: str) -> dict[tuple[str, str], dict[str, str]]:
    """Accept ten genuine *partial* numerical observations, not six-gate parity."""
    pilot_path = Path(path).absolute()
    check(pilot_path.is_file() and not pilot_path.is_symlink(),
          "Four-pilot evidence file missing or symlinked")
    rows = baseline.read_csv(pilot_path)
    required = ("python_name", "case_id", "max_absolute_difference",
                "tolerance", "shapes_equal", "developer_numeric_fixture_pass",
                "recorded_r_git_head", "frozen_python_commit",
                "independent_reviewer_approved", "independently_replayed_case",
                "fully_certified")
    baseline.columns(rows, required, "ten developer pilot comparisons")
    names = {"alr_transform": 2, "inverse_alr": 2,
             "score_distance_matrix": 2, "functional_trapezoid_weights": 4}
    check(len(rows) == sum(names.values()),
          "Expected ten first-party pilot numerical source observations")
    expected_names = {k for k in names}
    check({r["python_name"] for r in rows} == expected_names and
          all(sum(q["python_name"] == name for q in rows) == n
              for name, n in names.items()),
          "Four-pilot numerical evidence has missing or unexpected functions")
    check(len({(r["python_name"], r["case_id"]) for r in rows}) == len(rows),
          "Duplicate developer numerical pilot case")
    source = {q["python_name"]: q for q in original
              if q["kind"] == "function"}
    check(all(name in source for name in expected_names),
          "Four pilot exports not uniquely mapped to frozen callable inventory")
    for r in rows:
        check(r["recorded_r_git_head"] == head and
              r["frozen_python_commit"] == baseline.FROZEN_PYTHON,
              "Pilot numerical source identity does not match exact checkout")
        check(r["developer_numeric_fixture_pass"] == "TRUE" and
              r["shapes_equal"] == "TRUE" and
              all(r[field] == "FALSE" for field in
                  ("independent_reviewer_approved", "independently_replayed_case",
                   "fully_certified")),
              "Pilot numerical evidence contains failed or forged approvals")
        try:
            difference = float(r["max_absolute_difference"])
            tolerance = float(r["tolerance"])
        except (ValueError, TypeError) as exc:
            raise baseline.ReviewBatchError("Malformed pilot numeric tolerance") from exc
        check(0 <= difference <= tolerance and tolerance >= 0 and
              difference < float("inf") and tolerance < float("inf"),
              "Pilot numerical comparison exceeds source tolerance")
    digest = baseline.sha256(pilot_path)
    partial = {}
    for name in names:
        q = source[name]
        key = (q["namespace"], name)
        entry = {field: q[field] for field in IDENTITY}
        entry.update({flag: "FALSE" for flag in FLAGS})
        entry["numerical_oracle_checked"] = "TRUE"
        entry["evidence_file"] = str(pilot_path)
        entry["evidence_sha256"] = digest
        entry["developer_findings"] = (
            "Only finite-domain, author-performed paired numerical pilot "
            "observations passed; input, boundary, schema and full scientific "
            "scope are NOT established. Historical source gap remains open."
        )
        partial[key] = entry
    return partial


def reconcile(packet_dir: str | Path, expected_r_head: str,
              evidence_csv: str | Path | None = None,
              output_dir: str | Path | None = None,
              pilot_evidence_csv: str | Path | None = None) -> dict[str, object]:
    packet = Path(packet_dir).resolve(strict=True)
    check(baseline.HEX40.fullmatch(expected_r_head) is not None,
          "Provide a separately trusted 40-character R commit SHA")
    # Existing verified packet remains the source of export identities and
    # original gap labels; that validator enforces all legacy safeguards.
    baseline.verify(packet, expected_r_head=expected_r_head)
    queue = baseline.read_csv(packet / baseline.FILES[0])
    check(len(queue) == 508 and
          len({baseline.key(x) for x in queue}) == 508,
          "Exactly 508 unique frozen source exports are required")
    evidence = (read_pilot_numeric_evidence(
        pilot_evidence_csv, queue, expected_r_head)
        if pilot_evidence_csv is not None else {})
    if evidence_csv is not None:
        # Individual source-pinned developer assessments override the
        # four automatically detected *partial* numerical pilot flags.
        evidence.update(inspect_evidence(evidence_csv, queue, expected_r_head))
    candidates = []
    for q in queue:
        key = baseline.key(q)
        ev = evidence.get(key)
        gates = sum(ev[f] == "TRUE" for f in FLAGS) if ev else 0
        ready = gates == len(FLAGS)
        gap = q["source_gap_open"] == "TRUE"
        backend = q["backend_or_estimand_distinct"] == "TRUE"
        if ready and gap:
            state = "DEVELOPER_EVIDENCE_READY_GAP_STILL_OPEN"
            rank = 2
        elif ready and backend:
            state = "DEVELOPER_EVIDENCE_READY_BACKEND_DISTINCT"
            rank = 3
        elif ready:
            state = "DEVELOPER_EVIDENCE_READY_INDEPENDENT_REVIEW_PENDING"
            rank = 1
        elif gap:
            state = "DOCUMENTED_GAP_REQUIRES_REVIEW"
            rank = 5
        elif backend:
            state = "BACKEND_OR_ESTIMAND_DISTINCT"
            rank = 6
        else:
            state = "NO_RECORDED_GAP_NOT_YET_EVIDENCE_READY"
            rank = 4
        candidates.append({
            "namespace": q["namespace"],
            "python_name": q["python_name"],
            "kind": q["kind"],
            "native_r_candidate": q["native_r_candidate"],
            "recorded_r_git_head": expected_r_head,
            "frozen_python_commit": baseline.FROZEN_PYTHON,
            "historical_source_gap_open": q["source_gap_open"],
            "backend_or_estimand_distinct": q["backend_or_estimand_distinct"],
            "developer_evidence_record_present": "TRUE" if ev else "FALSE",
            "developer_evidence_gates_passed": gates,
            "developer_evidence_gates_required": len(FLAGS),
            "developer_evidence_ready_for_review": "TRUE" if ready else "FALSE",
            "evidence_sha256": ev["evidence_sha256"] if ev else "",
            "developer_status": state,
            "review_priority": rank,
            "source_gap_closed": "FALSE",
            "independent_replay_verified": "FALSE",
            "independently_certified": "FALSE",
        })
    # A compact intake is easier to send to several independent reviewers
    # than the undifferentiated 508-export manifest. These are *work items*
    # only, not parity decisions, signed findings or certification approvals.
    pilot_names = ("alr_transform", "inverse_alr",
                   "score_distance_matrix", "functional_trapezoid_weights")
    index_by_name = {(q["namespace"], q["python_name"]): q for q in candidates}
    pilot = [index_by_name[("root", n)] for n in pilot_names]
    check(all(x["historical_source_gap_open"] == "TRUE" for x in pilot),
          "Four source-gap pilots cannot be silently promoted")
    def select_candidates(function: bool, size: int):
        eligible = [q for q in candidates
                    if (q["kind"] == "function") == function
                    and q["historical_source_gap_open"] == "FALSE"
                    and q["backend_or_estimand_distinct"] == "FALSE"]
        if function:
            eligible = [q for q in eligible
                        if queue_by_key[(q["namespace"], q["python_name"])]
                        ["native_implementation_started"] == "TRUE"]
        else:
            eligible = [q for q in eligible
                        if queue_by_key[(q["namespace"], q["python_name"])]
                        ["native_nonfunction_representation"].strip()]
        eligible.sort(key=lambda q: (
            q["developer_evidence_ready_for_review"] != "TRUE",
            queue_by_key[(q["namespace"], q["python_name"])]
                .get("source_fixture_attributed") != "TRUE",
            q["python_name"], q["namespace"]))
        check(len(eligible) >= size,
              "Not enough no-recorded-gap source candidates for dispatch")
        return eligible[:size]
    queue_by_key = {baseline.key(q): q for q in queue}
    first_functions = select_candidates(True, 12)
    first_nonfunctions = select_candidates(False, 12)
    dispatch = []
    for lane, rows, action in (
        ("KNOWN_GAP_PILOT_REPLAY", pilot,
         "Independently reproduce finite and adversarial Python/R cases; "
         "source gap remains blocking"),
        ("FUNCTION_SOURCE_FULL_DOMAIN_REVIEW", first_functions,
         "Independently examine full input/error/numeric/schema domain; "
         "no-recorded-gap is not parity evidence"),
        ("NONFUNCTION_REPRESENTATION_REVIEW", first_nonfunctions,
         "Independently review R representation against the frozen Python "
         "class/value contract, including coercion and round-trip behavior"),
    ):
        for q in rows:
            dispatch.append({
                "dispatch_lane": lane,
                "namespace": q["namespace"],
                "python_name": q["python_name"],
                "kind": q["kind"],
                "native_r_candidate": q["native_r_candidate"],
                "recorded_r_git_head": expected_r_head,
                "frozen_python_commit": baseline.FROZEN_PYTHON,
                "historical_source_gap_open": q["historical_source_gap_open"],
                "backend_or_estimand_distinct": q["backend_or_estimand_distinct"],
                "developer_evidence_gates_passed": q[
                    "developer_evidence_gates_passed"],
                "source_fixture_reference_file_only":
                    queue_by_key[(q["namespace"], q["python_name"])]
                        .get("source_fixture_attributed", "FALSE"),
                "required_reviewer_action": action,
                "independently_replayed": "FALSE",
                "full_contract_approved": "FALSE",
                "independently_certified": "FALSE",
            })
    check(len(dispatch) == 28 and
          len({(q["namespace"], q["python_name"]) for q in dispatch}) == 28,
          "Dispatch plan must cover 28 unique, source-pinned exports")
    check(all(q["independently_certified"] == "FALSE" for q in dispatch),
          "Reviewer dispatch must never self-certify exports")
    check(sum(q["independently_certified"] == "TRUE" for q in candidates) == 0,
          "Developer reconciliation cannot certify scientific contracts")
    target = (Path(output_dir) if output_dir is not None
              else packet / ("developer_reconciliation_" + expected_r_head[:12]))
    check(not target.exists(), "Progress output already exists; never overwrite evidence")
    target.mkdir(parents=True)
    ranked = sorted(candidates, key=lambda q:
                    (q["review_priority"], q["kind"] != "function",
                     q["python_name"], q["namespace"]))
    original_gap = sum(q["historical_source_gap_open"] == "TRUE"
                       for q in candidates)
    summary = {
        "format": "unsigned-508-developer-source-reconciliation-v1",
        "recorded_r_git_head": expected_r_head,
        "frozen_python_commit": baseline.FROZEN_PYTHON,
        "export_count": len(candidates),
        "callable_count": sum(q["kind"] == "function" for q in candidates),
        "nonfunction_count": sum(q["kind"] != "function" for q in candidates),
        "historical_documented_source_gaps": original_gap,
        "selected_source_reference_candidates": sum(
            q.get("source_fixture_attributed") == "TRUE" for q in queue),
        "historical_callable_gaps": sum(q["historical_source_gap_open"] == "TRUE"
                                        and q["kind"] == "function" for q in candidates),
        "evidence_records_verified_sha256": len(evidence),
        "developer_evidence_ready_for_review": sum(
            q["developer_evidence_ready_for_review"] == "TRUE" for q in candidates),
        "gap_reconciliation_candidates": sum(
            q["developer_status"] == "DEVELOPER_EVIDENCE_READY_GAP_STILL_OPEN"
            for q in candidates),
        "source_gaps_closed": 0,
        "reviewer_dispatch_work_items": len(dispatch),
        "reviewer_dispatch_known_gap_pilots": len(pilot),
        "reviewer_dispatch_no_gap_functions": len(first_functions),
        "reviewer_dispatch_nonfunction_representations": len(first_nonfunctions),
        "independently_certified": 0,
        "review_packet_modified": False,
        "source_gap_registry_modified": False,
        "signed_review_required": True,
        "note": ("Source gap closure requires explicit source-contract "
                 "adjudication; developer evidence and suite PASS do not "
                 "establish full parity or independent certification."),
    }
    write_csv(target / PROGRESS, candidates)
    write_csv(target / PRIORITY, ranked)
    write_csv(target / DISPATCH, dispatch)
    # Supply an unsigned, unapproved starting point for developers to fill
    # with case-specific evidence. Reviewers must not sign these templates.
    # The template is NOT an accepted proof until copied, completed and
    # individually verified in a later --evidence-csv invocation.
    templates = []
    for q in queue:
        row = {field: q[field] for field in IDENTITY}
        row.update({flag: "FALSE" for flag in FLAGS})
        row.update(evidence_file="", evidence_sha256="",
                   developer_findings="")
        templates.append(row)
    write_csv(target / TEMPLATE, templates)
    (target / SUMMARY).write_text(json.dumps(summary, indent=2) + "\n",
                                  encoding="utf-8")
    manifest = {name: baseline.sha256(target / name)
                for name in (PROGRESS, PRIORITY, DISPATCH, SUMMARY, TEMPLATE)}
    (target / MANIFEST).write_text(json.dumps(manifest, indent=2) + "\n",
                                   encoding="utf-8")
    return {**summary, "output_dir": str(target)}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet_dir")
    parser.add_argument("--expected-r-head", required=True)
    parser.add_argument("--evidence-csv")
    parser.add_argument("--pilot-evidence-csv")
    parser.add_argument("--output-dir")
    args = parser.parse_args(argv)
    try:
        result = reconcile(args.packet_dir, args.expected_r_head,
                           args.evidence_csv, args.output_dir,
                           args.pilot_evidence_csv)
    except (baseline.ReviewBatchError, OSError, KeyError, ValueError,
            csv.Error) as exc:
        print("DEVELOPER_RECONCILIATION_REJECTED: " + str(exc),
              file=sys.stderr)
        return 1
    for k, v in result.items():
        print(f"{k}={v}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
