#!/usr/bin/env python3
"""Read-only verification of author-produced four-pilot reviewer evidence.

A PASS establishes internal SHA-256 consistency and an unsigned state.
It does NOT establish independent scientific replay, full source parity,
reviewer identity or GPG authenticity. Python standard library only.

Usage: python scripts/verify_four_pilot_review_bundle.py PACKET_DIR
       --expected-r-head FULL_TRUSTED_40_HEX_R_COMMIT
"""
from __future__ import annotations
import argparse
import csv
import hashlib
from pathlib import Path
import re
import sys

FROZEN_PYTHON = "c1cd95ad718327550f7e55393ff38582872f7a94"
PILOTS = frozenset(("alr_transform", "inverse_alr", "score_distance_matrix",
                    "functional_trapezoid_weights"))
FILES = (
    "evidence_bundle_status.csv",
    "four_numerical_pilots_external_review_priority.csv",
    "four_pilot_boundary_review_matrix.csv",
    "four_pilot_developer_paired_numeric_replay.csv",
    "four_pilot_developer_source_boundary_observations.csv",
    "known_source_gap_resolution_queue.csv",
)
MANIFEST = "four_pilot_external_evidence_sha256_manifest.csv"
TEMPLATE = "four_pilot_EXTERNAL_REVIEW_TEMPLATE.csv"
INSTRUCTIONS = "EXTERNAL_REVIEW_AND_SIGNATURE_INSTRUCTIONS.md"
HEX40 = re.compile(r"[0-9a-f]{40}\Z")
HEX64 = re.compile(r"[0-9a-f]{64}\Z")

class BundleError(ValueError):
    """Missing evidence or an inconsistent assertion."""

def require(test: bool, message: str) -> None:
    if not test:
        raise BundleError(message)

def csv_rows(path: Path) -> list[dict[str, str]]:
    require(path.is_file() and not path.is_symlink(),
            f"Missing or symlinked file: {path.name}")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        require(reader.fieldnames is not None and
                len(reader.fieldnames) == len(set(reader.fieldnames)),
                f"Missing or duplicate header: {path.name}")
        require(all(bool(field) for field in reader.fieldnames),
                f"Empty header: {path.name}")
        rows = list(reader)
    require(all(None not in row and None not in row.values() for row in rows),
            f"Malformed row length: {path.name}")
    return rows

def fields(rows: list[dict[str, str]], required: set[str], label: str) -> None:
    require(bool(rows), f"Empty {label}")
    require(required.issubset(rows[0]),
            f"Missing {label} columns: {sorted(required - rows[0].keys())}")

def flags(rows: list[dict[str, str]], columns: tuple[str, ...],
          expected: str, label: str) -> None:
    fields(rows, set(columns), label)
    for row in rows:
        for column in columns:
            require(row[column].strip().upper() == expected,
                    f"{label}: {column} must be {expected}")

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()

def verify(packet_dir: str | Path, expected_r_head: str | None = None) -> dict[str, object]:
    root = Path(packet_dir).resolve(strict=True)
    require(root.is_dir(), "Packet path must be a directory")
    manifest_path = root / MANIFEST
    rows = csv_rows(manifest_path)
    require(len(rows) == len(FILES), "Expected exactly six SHA256 entries")
    fields(rows, {"filename", "sha256", "recorded_r_git_head",
                  "frozen_python_commit"}, "manifest")
    names = [row["filename"] for row in rows]
    require(set(names) == set(FILES) and len(set(names)) == len(FILES),
            "Unexpected, duplicate or missing evidence filename")
    heads = {row["recorded_r_git_head"] for row in rows}
    require(len(heads) == 1 and bool(HEX40.fullmatch(next(iter(heads)))),
            "Missing or inconsistent R commit SHA")
    head = next(iter(heads))
    if expected_r_head is not None:
        require(bool(HEX40.fullmatch(expected_r_head)) and head == expected_r_head,
                "Packet R commit differs from separately trusted expected head")
    require(all(row["frozen_python_commit"] == FROZEN_PYTHON for row in rows),
            "Frozen Python source revision differs")
    for row in rows:
        name = row["filename"]
        path = root / name
        require(path.is_file() and not path.is_symlink(),
                f"Missing or symlinked source evidence: {name}")
        require(bool(HEX64.fullmatch(row["sha256"])), f"Malformed SHA256: {name}")
        require(sha256(path) == row["sha256"], f"Evidence SHA256 mismatch: {name}")

    status = csv_rows(root / FILES[0])
    require(len(status) == 1, "Evidence status must have one row")
    fields(status, {"recorded_r_git_head", "checkout_matches_evidence",
                    "source_file_manifest_matches_checkout", "native_suite_pass",
                    "pinned_python_suite_pass", "independent_review_approved",
                    "full_source_contract_certified"}, "status")
    require(status[0]["recorded_r_git_head"] == head,
            "Packet and manifest R heads differ")
    flags(status, ("checkout_matches_evidence",
                   "source_file_manifest_matches_checkout",
                   "native_suite_pass", "pinned_python_suite_pass"), "TRUE", "status")
    flags(status, ("independent_review_approved", "full_source_contract_certified"),
          "FALSE", "status")

    pilots = csv_rows(root / FILES[1])
    require(len(pilots) == 4, "Expected four pilot records")
    fields(pilots, {"python_name", "pinned_python_commit",
                    "native_r_candidate"}, "pilots")
    require({row["python_name"] for row in pilots} == PILOTS,
            "Unexpected four-pilot identities")
    require(all(row["pinned_python_commit"] == FROZEN_PYTHON for row in pilots),
            "Pilot frozen source revision differs")
    flags(pilots, ("independent_reviewer_approved",
                   "full_accepted_input_domain_approved",
                   "complete_error_semantics_approved",
                   "scientific_scope_approved"), "FALSE", "pilot approvals")

    matrix = csv_rows(root / FILES[2])
    require(len(matrix) == 16, "Expected 16 review worklist cases")
    fields(matrix, {"python_name", "case_id"}, "review matrix")
    cases = {"finite_scientific_fixture", "broader_accepted_containers",
             "exception_or_extreme_boundary", "scientific_and_schema_scope"}
    require({(r["python_name"], r["case_id"]) for r in matrix} ==
            {(name, case) for name in PILOTS for case in cases},
            "Review matrix must contain four cases for each pilot")
    flags(matrix, ("fully_certified", "independently_replayed_case"),
          "FALSE", "review matrix")

    finite = csv_rows(root / FILES[3])
    require(len(finite) == 10, "Expected 10 developer numerical replays")
    fields(finite, {"python_name"}, "finite replay")
    require({row["python_name"] for row in finite} == PILOTS,
            "Finite replay missing a pilot")
    flags(finite, ("developer_numeric_fixture_pass",), "TRUE", "finite replay")
    flags(finite, ("independently_replayed_case", "fully_certified"),
          "FALSE", "finite replay")

    boundaries = csv_rows(root / FILES[4])
    require(len(boundaries) == 4, "Expected four boundary observations")
    fields(boundaries, {"python_name", "relation"}, "boundaries")
    require({r["python_name"] for r in boundaries} == PILOTS,
            "Boundary pilot names differ")
    require(sum(r["relation"] == "documented_source_difference"
                for r in boundaries) == 3 and
            sum(r["relation"] == "both_reject_error_schema_unreviewed"
                for r in boundaries) == 1,
            "Known source differences removed or misclassified")
    flags(boundaries, ("observed_behavior_as_expected",
                       "opt_in_python_boundary_mode_matches_source_category"),
          "TRUE", "boundary observations")
    flags(boundaries, ("opt_in_mode_full_source_parity_certified",
                       "source_domain_equivalence_established",
                       "independent_reviewer_approved",
                       "independently_replayed_case", "fully_certified"),
          "FALSE", "boundary approvals")

    gaps = csv_rows(root / FILES[5])
    require(len(gaps) == 203, "Expected 203 recorded source gaps")
    fields(gaps, {"python_name", "resolved"}, "source gaps")
    require(len({r["python_name"] for r in gaps}) == 203,
            "Duplicate source-gap names")
    require(PILOTS.issubset({r["python_name"] for r in gaps}),
            "Four pilot gap names missing")
    flags(gaps, ("resolved",), "FALSE", "source gaps")

    template = csv_rows(root / TEMPLATE)
    require(len(template) == 4, "Expected four unsigned reviewer template rows")
    fields(template, {"python_name", "native_r_candidate",
                      "recorded_r_git_head", "frozen_python_commit",
                      "evidence_manifest_sha256", "scope_decision",
                      "reviewer_name"}, "review template")
    require({r["python_name"] for r in template} == PILOTS,
            "Reviewer template pilot identities differ")
    manifest_hash = sha256(manifest_path)
    native = {r["python_name"]: r["native_r_candidate"] for r in pilots}
    for row in template:
        require(row["native_r_candidate"] == native[row["python_name"]],
                "Reviewer template native function differs")
        require(row["recorded_r_git_head"] == head and
                row["frozen_python_commit"] == FROZEN_PYTHON,
                "Reviewer template version pins differ")
        require(row["evidence_manifest_sha256"] == manifest_hash,
                "Reviewer template does not bind exact manifest")
        require(row["scope_decision"] == "PENDING_EXTERNAL_REVIEW"
                and not row["reviewer_name"].strip(),
                "Expected an unsigned reviewer template, not approval")
    flags(template, ("reviewer_is_independent_of_authors",
                     "reviewer_replayed_python_separately",
                     "reviewer_replayed_native_r_separately",
                     "accepted_input_domain_reviewed",
                     "error_warning_semantics_reviewed",
                     "return_schema_dtype_reviewed",
                     "scientific_estimand_reviewed",
                     "documented_source_gap_resolved"),
          "FALSE", "reviewer template")
    instructions = root / INSTRUCTIONS
    require(instructions.is_file() and not instructions.is_symlink(),
            "Missing independent-review instructions")
    require("NOT an independent certification" in
            instructions.read_text(encoding="utf-8"),
            "Instructions omit the noncertification disclosure")
    return {"result": "PASS: author packet integrity / unsigned state only",
            "native_r_head": head,
            "separately_trusted_head_checked": expected_r_head is not None,
            "frozen_python_head": FROZEN_PYTHON,
            "verified_evidence_files": 6,
            "developer_finite_probes": len(finite),
            "documented_source_differences": 3,
            "open_source_gaps": len(gaps),
            "independent_replays": 0, "full_domain_certifications": 0}

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet_dir", help="Captured independent-review packet directory")
    parser.add_argument("--expected-r-head",
                        help="Full native R SHA obtained from separately trusted source")
    args = parser.parse_args(argv)
    try:
        result = verify(args.packet_dir, expected_r_head=args.expected_r_head)
    except (BundleError, OSError, UnicodeError, csv.Error) as exc:
        print(f"REVIEW HANDOFF FAILED: {exc}", file=sys.stderr)
        return 1
    for name, value in result.items():
        print(f"{name}: {value}")
    print("IMPORTANT: PASS does not prove scientific or independent reviewer certification.")
    if args.expected_r_head is None:
        print("WARNING: R HEAD was not compared to a separately trusted channel.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
