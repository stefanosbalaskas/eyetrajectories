#!/usr/bin/env python3
"""Unsigned, source-pinned, per-export scientific evidence progression.

Reads the *actual* output of live Python 1.2/native R differential runners,
and the authoritative historical gap registry. No code tests the output of
this tool as proof that a function's entire source contract is complete.
Never modifies the gap or independent certification ledgers.

Usage:
    python scripts/summarize_scientific_source_evidence.py
    python scripts/summarize_scientific_source_evidence.py \
       --root . --head "$(git rev-parse HEAD)" --json
"""
from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

from source_gap_inventory import FROZEN_PYTHON, read_inventory

# The filenames identify actual *runner output formats*, not an assumed
# count of passed functions, cases, source gaps, or certifications.
REPORTS = {
    "bounded_numeric": "source_numeric_cases_UNSIGNED.csv",
    "generalized_functional_gee": "generalized_functional_gee_source_cases_UNSIGNED.csv",
    "generalized_gee_bootstrap": "generalized_gee_bootstrap_source_cases_UNSIGNED.csv",
}
# Research families are opt-in until their live R/Python source cases have
# passed. Their absence must not invalidate the existing verified reports.
OPTIONAL_REPORTS = {
    "sparse_fpca_native": "sparse_fpca_source_cases_UNSIGNED.csv",
    "sparse_mfpca_native": "sparse_mfpca_source_cases_UNSIGNED.csv",
}
PASS = frozenset({
    "PASS_NUMERIC", "PASS_BOTH_REJECT", "PASS_SCHEMA",
    "PASS_BOTH_NULL", "SOURCE_INPUT_MATCH",
})
NONPROOF = frozenset({"PASS_BOTH_ACCEPT"})
BAD = frozenset({
    "DIVERGENT_ACCEPTANCE", "DIVERGENT_NUMERIC",
    "DIVERGENT_SCHEMA", "INVALID_FIXTURE", "SOURCE_EXCEPTION",
})
HEX40 = re.compile(r"[0-9a-f]{40}\Z")


class EvidenceAuditError(ValueError):
    """Runner evidence is missing, inconsistent, or cannot be attributed."""


def require(ok: bool, why: str) -> None:
    if not ok:
        raise EvidenceAuditError(why)


def read_rows(path: Path) -> list[dict[str, str]]:
    require(path.is_file() and not path.is_symlink(),
            f"Evidence report missing/symlinked: {path}")
    with path.open(encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        require(reader.fieldnames is not None and
                len(reader.fieldnames) == len(set(reader.fieldnames)),
                f"Invalid source CSV headers: {path}")
        rows = list(reader)
    require(bool(rows) and all(None not in row and
            None not in row.values() for row in rows),
            f"Empty/malformed source comparison evidence: {path}")
    return rows


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git_head(root: Path) -> str:
    cmd = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"],
                         check=True, capture_output=True, text=True)
    return cmd.stdout.strip()


def read_gaps(root: Path) -> dict[str, bool]:
    """Map every public frozen callable, not only the 203 historical gaps."""
    directory = root / "inst" / "extdata"
    catalog = read_rows(directory / "python_api_2026-10-25.csv")
    keys = [(row.get("namespace"), row.get("python_name"))
            for row in catalog]
    names = [row.get("python_name", "") for row in catalog]
    functions = [row for row in catalog if row.get("kind") == "function"]
    require(len(catalog) == 508 and len(functions) == 380 and
            len(keys) == len(set(keys)) and
            len(names) == len(set(names)) and
            all(bool(key) for key in names),
            "Frozen Python 508-public-export inventory is incomplete")
    statuses = {row["python_name"]: False for row in functions}
    path = directory / "native_source_contract_gaps_stage22.csv"
    rows = read_rows(path)
    require(len(rows) == 203 and
            all(row.get("unresolved_source_gap") in {"TRUE", "FALSE"}
                for row in rows), "Malformed authoritative callable gap flags")
    require(len({row["python_name"] for row in rows}) == 203 and
            all(row["python_name"] in statuses for row in rows),
            "Historical source-gap records not in frozen callable catalog")
    statuses.update({row["python_name"]:
                     row["unresolved_source_gap"] == "TRUE"
                     for row in rows})
    return statuses


def summarize(root: Path, head: str, *, require_all: bool = False,
              write: bool = True) -> dict[str, object]:
    require(HEX40.fullmatch(head) is not None,
            "A real 40-digit exact R Git commit is required")
    root = root.resolve(strict=True)
    counts = read_inventory(root)
    gaps = read_gaps(root)
    report_dir = (root / "artifacts" / "native_batch_numeric_diff" /
                  head[:12])
    seen = set()
    records = []
    digests = {}
    found = []
    for family, filename in {**REPORTS, **OPTIONAL_REPORTS}.items():
        path = report_dir / filename
        if not path.exists():
            if require_all and family in REPORTS:
                raise EvidenceAuditError(f"Expected source report missing: {path}")
            continue
        require(not path.is_symlink(), f"Symlinked evidence report: {path}")
        rows = read_rows(path)
        digests[family] = sha256(path)
        found.append(family)
        for i, row in enumerate(rows, start=2):
            require(row.get("r_git_head") == head and
                    row.get("frozen_python_commit") == FROZEN_PYTHON,
                    f"Wrong R/Python pin in {filename}, line {i}")
            name = row.get("python_name", "")
            require(bool(name) and name in gaps,
                    f"Unexpected source callable in {filename}, line {i}: {name}")
            outcome = row.get("outcome", "")
            require(outcome in PASS | NONPROOF | BAD,
                    f"Unknown comparison outcome {outcome!r} in {filename}")
            item = (
                family, name, row.get("scientific_family", ""),
                row.get("source_fixture", row.get("case", row.get("case_id", ""))),
                row.get("field", "<numeric>"), outcome, i
            )
            # Case identity includes input fixture and field; legitimate
            # repeat observations are retained only with an explicit index.
            unique = item[:5]
            require(unique not in seen,
                    f"Duplicate source function/fixture/field case: {unique}")
            seen.add(unique)
            records.append(dict(report_family=family,
                python_name=name,
                scientific_family=item[2],
                input_case=item[3],
                compared_field=item[4],
                outcome=outcome,
                recorded_source_gap_open=gaps[name],
                author_source_evidence_only=True,
                complete_contract_verified=False,
                independently_certified=False))
    require(bool(found),
            f"No matched source comparison reports at {report_dir}")
    names = sorted({r["python_name"] for r in records})
    function_rows = []
    for name in names:
        rr = [r for r in records if r["python_name"] == name]
        status = {s: sum(q["outcome"] == s for q in rr)
                  for s in sorted(PASS | BAD | NONPROOF)}
        n_pass = sum(status[s] for s in PASS)
        n_bad = sum(status[s] for s in BAD)
        function_rows.append(dict(
            python_name=name,
            source_gap_still_open=gaps[name],
            total_matched_cases=len(rr),
            matched_case_passes=n_pass,
            source_disagreements=n_bad,
            insufficient_both_acceptance_cases=sum(
                q["outcome"] in NONPROOF for q in rr),
            reported_fields=";".join(sorted(set(q["compared_field"] for q in rr))),
            developer_finite_domain_oracle_evidence=n_pass > 0,
            developer_full_contract_approved=False,
            independent_full_contract_certified=False))
    total = len(records)
    passing = sum(q["outcome"] in PASS for q in records)
    differences = sum(q["outcome"] in BAD for q in records)
    insufficient = sum(q["outcome"] in NONPROOF for q in records)
    result = dict(
        recorded_r_git_head=head,
        frozen_python_commit=FROZEN_PYTHON,
        source_report_sha256=digests,
        reports_included=found,
        total_observed_comparison_cases=total,
        passing_bounded_comparison_cases=passing,
        divergent_or_invalid_cases=differences,
        inconclusive_both_acceptance_cases=insufficient,
        unique_python_functions_with_actual_source_cases=len(names),
        unique_python_functions_with_passing_bounded_cases=sum(
            r["matched_case_passes"] > 0 for r in function_rows),
        of_those_with_recorded_open_source_gap=sum(
            r["matched_case_passes"] > 0 and r["source_gap_still_open"]
            for r in function_rows),
        open_documented_source_gaps=counts.open_total,
        open_callable_gaps=counts.active_callable,
        open_nonfunction_gaps=counts.active_nonfunction,
        no_recorded_gap_exports=counts.no_recorded_gap_exports,
        developer_full_contract_approvals_inferred=0,
        independent_certifications_inferred=0,
        all_observed_comparisons_without_divergence=differences == 0,
        scope="DEVELOPER_UNSIGNED_FINITE_DOMAIN_ONLY",
        function_evidence=function_rows,
    )
    if write:
        dest = root / "artifacts" / "scientific_source_evidence" / head[:12]
        dest.mkdir(parents=True, exist_ok=True)
        with (dest / "developer_source_progress_UNSIGNED.json").open(
                "w", encoding="utf-8") as file:
            json.dump(result, file, indent=2, sort_keys=True)
            file.write("\n")
        with (dest / "developer_source_functions_UNSIGNED.csv").open(
                "w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=list(function_rows[0]))
            writer.writeheader()
            writer.writerows(function_rows)
        print(f"SCIENTIFIC_SOURCE_EVIDENCE_CASES={total}")
        print(f"SCIENTIFIC_SOURCE_EVIDENCE_PASSING={passing}")
        print(f"SCIENTIFIC_SOURCE_EVIDENCE_DIVERGENT={differences}")
        print("SCIENTIFIC_SOURCE_EVIDENCE_FUNCTIONS="
              f"{len(names)}")
        print("SCIENTIFIC_SOURCE_EVIDENCE_OPEN_GAPS="
              f"{counts.open_total}")
        print("SCIENTIFIC_SOURCE_EVIDENCE_FULL_DOMAIN_CERTIFIED=0")
        print(f"SCIENTIFIC_SOURCE_EVIDENCE_REPORT={dest}")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--head", default=None)
    parser.add_argument("--require-all", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    base = Path(args.root).resolve(strict=True)
    head = args.head or git_head(base)
    try:
        result = summarize(base, head,
                           require_all=args.require_all, write=True)
    except EvidenceAuditError as error:
        parser.exit(2, f"SOURCE_EVIDENCE_AUDIT_FAIL: {error}\n")
    if args.json:
        shallow = {k: v for k, v in result.items()
                   if k != "function_evidence"}
        print(json.dumps(shallow, sort_keys=True))
