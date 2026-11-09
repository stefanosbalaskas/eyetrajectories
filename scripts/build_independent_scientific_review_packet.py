#!/usr/bin/env python3
"""Export source-pinned pending-review casebooks; never self-certify parity."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import subprocess

import summarize_scientific_source_evidence as scientific
from source_gap_inventory import FROZEN_PYTHON


def run(root: Path, head: str, *, min_cases: int = 1,
        max_functions: int = 32, write: bool = True) -> dict:
    root = root.resolve(strict=True)
    if not isinstance(min_cases, int) or min_cases < 1:
        raise ValueError("min_cases must be a positive integer")
    if not isinstance(max_functions, int) or max_functions < 1:
        raise ValueError("max_functions must be a positive integer")
    report = scientific.summarize(root, head, require_all=True, write=False)
    gapfile = root / "inst" / "extdata" / (
        "native_source_contract_gaps_stage22.csv")
    with gapfile.open(newline="", encoding="utf-8-sig") as source:
        gaps = {row["python_name"]: row for row in csv.DictReader(source)}
    candidates = sorted(
        (f for f in report["function_evidence"]
         if f["source_gap_still_open"]
         and f["matched_case_passes"] >= min_cases
         and f["source_disagreements"] == 0
         and f["insufficient_both_acceptance_cases"] == 0),
        key=lambda f: (-f["matched_case_passes"], f["python_name"])
    )[:max_functions]
    items = []
    for function in candidates:
        source = gaps.get(function["python_name"])
        if source is None or source["unresolved_source_gap"] != "TRUE":
            raise scientific.EvidenceAuditError(
                "Evidence references a non-active source gap: "
                + function["python_name"])
        items.append(dict(
            python_name=function["python_name"],
            native_r_candidate=source["native_r_candidate"],
            gap_kind=source["gap_kind"],
            documented_source_difference=source["known_source_difference"],
            frozen_source_witness=source["source_witness"],
            recommended_audit=source["review_resolution"],
            finite_source_cases=function["total_matched_cases"],
            finite_source_passes=function["matched_case_passes"],
            numerical_disagreements=function["source_disagreements"],
            fields_with_finite_cases=function["reported_fields"],
            accepted_input_domain="PENDING_EXTERNAL_REVIEW",
            complete_numerical_domain="PENDING_EXTERNAL_REVIEW",
            output_and_error_schema="PENDING_EXTERNAL_REVIEW",
            stochastic_contract="PENDING_EXTERNAL_REVIEW",
            current_source_gap="OPEN",
            external_reviewer_decision="NO_SIGNED_DECISION",
            independently_certified=False))
    result = dict(
        exact_r_git_head=head,
        frozen_python_commit=FROZEN_PYTHON,
        source_report_sha256=report["source_report_sha256"],
        authoritative_gap_ledger_sha256=scientific.sha256(gapfile),
        developer_source_cases=report["total_observed_comparison_cases"],
        developer_passing_cases=report["passing_bounded_comparison_cases"],
        developer_divergences=report["divergent_or_invalid_cases"],
        open_callable_source_gaps=report["open_callable_gaps"],
        open_nonfunction_source_gaps=report["open_nonfunction_gaps"],
        independent_approvals=0,
        status="UNSIGNED_PRE_REVIEW_NOT_AN_ATTESTATION",
        candidates=items)
    if write:
        output = (root / "artifacts" / "independent_scientific_review" /
                  head[:12])
        output.mkdir(parents=True, exist_ok=True)
        with (output / "pending_contract_review_UNSIGNED.json").open(
                "w", encoding="utf-8") as fp:
            json.dump(result, fp, indent=2, sort_keys=True)
            fp.write("\n")
        if items:
            with (output / "pending_contract_review_UNSIGNED.csv").open(
                    "w", newline="", encoding="utf-8") as fp:
                writer = csv.DictWriter(fp, fieldnames=list(items[0]))
                writer.writeheader()
                writer.writerows(items)
        with (output / "reviewer_casebook_PENDING.md").open(
                "w", encoding="utf-8") as fp:
            fp.write("# External scientific review candidates\n\n")
            fp.write("This is an unsigned author-produced pre-review bundle, "
                     "NOT a source parity certificate.\n\n")
            fp.write("R SHA: " + head + "\nFrozen Python SHA: "
                     + FROZEN_PYTHON + "\n\n")
            fp.write("Finite developer cases: "
                     + str(result["developer_source_cases"]) + "\n")
            fp.write("Outstanding recorded callable gaps: "
                     + str(result["open_callable_source_gaps"]) + "\n")
            fp.write("Independent signed approvals: 0\n\n")
            fp.write("Independent reviewers must adjudicate complete "
                     "accepted domains, error classes, returned schemas, "
                     "numeric precision, random laws and backend equivalence "
                     "before any source-gap closure.\n")
            for item in items:
                fp.write("\n## " + item["python_name"] + "\n\n")
                fp.write("Native candidate: " +
                         item["native_r_candidate"] + "\n")
                fp.write("Finite source cases: " +
                         str(item["finite_source_passes"]) + "\n")
                fp.write("Documented difference: " +
                         item["documented_source_difference"] + "\n")
                fp.write("Frozen source witness: " +
                         item["frozen_source_witness"] + "\n")
                fp.write("Next independent review: " +
                         item["recommended_audit"] + "\n")
                fp.write("External decision: PENDING\n")
        print(f"INDEPENDENT_REVIEW_CANDIDATE_FUNCTIONS={len(items)}")
        print("INDEPENDENT_REVIEW_CERTIFICATIONS=0")
        print(f"INDEPENDENT_REVIEW_PACKET={output}")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--head")
    parser.add_argument("--min-cases", type=int, default=1)
    parser.add_argument("--max-functions", type=int, default=32)
    args = parser.parse_args()
    base = args.root.resolve(strict=True)
    head = args.head or subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=base, text=True).strip()
    run(base, head, min_cases=args.min_cases,
        max_functions=args.max_functions)
