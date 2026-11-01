#!/usr/bin/env python3
"""Verify unsigned 508-export reviewer worklist integrity (NOT scientific parity).

Usage:
  python scripts/verify_508_certification_batch.py PACKET_DIRECTORY \
    --expected-r-head SEPARATELY_TRUSTED_40_HEX_COMMIT

The SHA256 manifest is author-generated, not independently authenticated.
Its PASS proves neither reviewer identity nor any scientific certification.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
from pathlib import Path
import re
import sys

FROZEN_PYTHON = "c1cd95ad718327550f7e55393ff38582872f7a94"
MANIFEST = "certification_first_batch_sha256_manifest.csv"
FILES = (
    "certification_508_prioritized_work_queue.csv",
    "certification_first_function_and_nonfunction_batches.csv",
    "certification_first_batch_reviewer_checklist.csv",
    "certification_first_batch_UNSIGNED_decisions.csv",
)
CRITERIA = (
    "frozen_python_and_native_source_identity",
    "source_signature_parameters_and_defaults",
    "complete_accepted_input_and_coercion_domain",
    "numerical_reference_randomized_precision",
    "boundary_nan_inf_overflow_missing_and_empty",
    "return_dimension_order_dtype_and_metadata",
    "exception_warning_and_side_effect_semantics",
    "scientific_estimand_and_backend_equivalence",
    "independently_created_case_and_replay_logs",
    "independent_reviewer_identity_evidence_and_signature",
)
INTERFACE_INVENTORY = "first_wave_source_interface_inventory.csv"
INTERFACE_SHA256 = "first_wave_source_interface_inventory_sha256.csv"
HEX40 = re.compile(r"[a-f0-9]{40}\Z")
HEX64 = re.compile(r"[a-f0-9]{64}\Z")


class ReviewBatchError(ValueError):
    """Incomplete, altered, or falsely approved author review worklist."""


def check(ok: bool, message: str) -> None:
    if not ok:
        raise ReviewBatchError(message)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1048576), b""):
            h.update(chunk)
    return h.hexdigest()


def read_csv(path: Path) -> list[dict[str, str]]:
    check(path.is_file() and not path.is_symlink(),
          f"Missing or symlinked reviewer file: {path.name}")
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        check(bool(reader.fieldnames) and
              len(reader.fieldnames) == len(set(reader.fieldnames)) and
              all(bool(name) for name in reader.fieldnames),
              f"Invalid CSV header: {path.name}")
        rows = list(reader)
    check(all(None not in row and None not in row.values() for row in rows),
          f"Malformed row length: {path.name}")
    return rows


def columns(rows: list[dict[str, str]], required: tuple[str, ...], label: str) -> None:
    check(bool(rows), f"Missing {label} rows")
    check(set(required).issubset(rows[0]), f"Missing {label} columns")


def all_flags(rows: list[dict[str, str]], names: tuple[str, ...],
              value: str, label: str) -> None:
    columns(rows, names, label)
    check(all(row[name] == value for row in rows for name in names),
          f"{label}: approval flag must be {value}")


def key(row: dict[str, str]) -> tuple[str, str]:
    return (row["namespace"], row["python_name"])


def verify(packet_dir: str | Path, expected_r_head: str | None = None) -> dict[str, object]:
    root = Path(packet_dir).resolve(strict=True)
    check(root.is_dir(), "Packet path must be a directory")
    manifest = read_csv(root / MANIFEST)
    check(len(manifest) == 4, "Expected four SHA256-reviewed files")
    columns(manifest, ("filename", "sha256", "recorded_r_git_head",
                       "frozen_python_commit", "independent_review_signoff_present"),
            "manifest")
    check({r["filename"] for r in manifest} == set(FILES),
          "Manifest contains missing or unexpected filenames")
    check(len({r["filename"] for r in manifest}) == 4,
          "Duplicate evidence filenames")
    heads = {r["recorded_r_git_head"] for r in manifest}
    check(len(heads) == 1 and HEX40.fullmatch(next(iter(heads))) is not None,
          "Inconsistent recorded R commit")
    head = next(iter(heads))
    if expected_r_head is not None:
        check(HEX40.fullmatch(expected_r_head) is not None and
              head == expected_r_head,
              "R commit differs from separately trusted expected head")
    check(all(row["frozen_python_commit"] == FROZEN_PYTHON and
              row["independent_review_signoff_present"] == "FALSE"
              for row in manifest),
          "Manifest claims signing or wrong Python source version")
    for row in manifest:
        p = root / row["filename"]
        check(p.is_file() and not p.is_symlink(),
              f"Missing or symlinked evidence: {p.name}")
        check(HEX64.fullmatch(row["sha256"]) is not None and
              sha256(p) == row["sha256"],
              f"Evidence SHA256 mismatch: {p.name}")

    full, batch, cases, decisions = [read_csv(root / f) for f in FILES]
    columns(full, ("namespace", "python_name", "kind", "review_lane",
                   "recorded_r_git_head", "frozen_python_commit",
                   "source_gap_open", "backend_or_estimand_distinct",
                   "currently_authoritatively_certified",
                   "developer_queue_is_not_scientific_certification"), "508 worklist")
    check(len(full) == 508, "Full export inventory must have 508 rows")
    full_keys = [key(r) for r in full]
    check(len(set(full_keys)) == 508, "Duplicate 508-export keys")
    check(sum(r["kind"] == "function" for r in full) == 380 and
          sum(r["kind"] != "function" for r in full) == 128,
          "Incorrect frozen 380-function/128-nonfunction inventory")
    check(sum(r["source_gap_open"] == "TRUE" for r in full) == 203,
          "Incorrect open source gap inventory")
    check(sum(r["backend_or_estimand_distinct"] == "TRUE" for r in full) == 19,
          "Incorrect alternative backend/estimand inventory")
    all_flags(full, ("currently_authoritatively_certified",),
              "FALSE", "source certification state")
    all_flags(full, ("developer_queue_is_not_scientific_certification",),
              "TRUE", "developer disclaimer")
    check(all(r["recorded_r_git_head"] == head and
              r["frozen_python_commit"] == FROZEN_PYTHON for r in full),
          "508 worklist source version pins differ")

    columns(batch, ("namespace", "python_name", "kind", "review_lane",
                    "source_gap_open", "backend_or_estimand_distinct",
                    "currently_authoritatively_certified",
                    "recorded_r_git_head", "frozen_python_commit"),
            "selected batch")
    check(len(batch) == 36 and len({key(r) for r in batch}) == 36,
          "Expected 36 distinct selected first-batch exports")
    check(sum(r["review_lane"] == "FUNCTION_NO_RECORDED_GAP" for r in batch) == 24 and
          sum(r["review_lane"] == "NONFUNCTION_NO_RECORDED_GAP" for r in batch) == 12,
          "Expected first batch of 24 gap-free functions and 12 nonfunctions")
    source_by_key = {key(r): r for r in full}
    check(all(key(r) in source_by_key and
              r["kind"] == source_by_key[key(r)]["kind"] and
              r["review_lane"] == source_by_key[key(r)]["review_lane"] and
              r["source_gap_open"] == "FALSE" and
              r["backend_or_estimand_distinct"] == "FALSE" and
              r["currently_authoritatively_certified"] == "FALSE" and
              r["recorded_r_git_head"] == head and
              r["frozen_python_commit"] == FROZEN_PYTHON for r in batch),
          "Selected batch includes a mismatched source contract")

    columns(cases, ("namespace", "python_name", "kind",
                    "native_r_candidate", "recorded_r_git_head",
                    "frozen_python_commit", "criterion",
                    "reviewer_case_passed", "independently_replayed",
                    "full_domain_approved", "reviewer_created_evidence_reference",
                    "reviewer_written_findings"),
            "reviewer checklists")
    check(len(cases) == 360, "Expected 360 unsigned reviewer checks")
    check({(key(r), r["criterion"]) for r in cases} ==
          {(key(b), item) for b in batch for item in CRITERIA},
          "Missing or unexpected per-contract criteria")
    selected_by_key = {key(row): row for row in batch}
    check(all(row["kind"] == selected_by_key[key(row)]["kind"] and
              row["native_r_candidate"] ==
                  selected_by_key[key(row)]["native_r_candidate"] and
              row["recorded_r_git_head"] == head and
              row["frozen_python_commit"] == FROZEN_PYTHON
              for row in cases),
          "Unsigned reviewer case source identity does not match selected batch")
    all_flags(cases, ("reviewer_case_passed", "independently_replayed",
                      "full_domain_approved"), "FALSE", "reviewer checklists")
    check(all(not r["reviewer_created_evidence_reference"].strip() and
              not r["reviewer_written_findings"].strip() for r in cases),
          "Reviewer checklist must not contain invented findings")

    columns(decisions, ("namespace", "python_name", "kind",
                        "native_r_candidate", "recorded_r_git_head",
                        "frozen_python_commit", "scope_decision",
                        "reviewer_name", "reviewer_affiliation", "reviewer_contact",
                        "reviewer_independent_of_implementation_team",
                        "reviewer_python_replay_pass", "reviewer_r_replay_pass",
                        "complete_input_error_schema_review_pass",
                        "scientific_estimand_review_pass",
                        "all_source_gaps_resolved_after_review",
                        "reviewer_signed_evidence_reference", "reviewer_signed_utc",
                        "full_domain_certification_approved"),
            "reviewer decisions")
    check(len(decisions) == 36 and
          {key(r) for r in decisions} == {key(r) for r in batch},
          "Missing independent reviewer decision rows")
    check(all(row["kind"] == selected_by_key[key(row)]["kind"] and
              row["native_r_candidate"] ==
                  selected_by_key[key(row)]["native_r_candidate"] and
              row["recorded_r_git_head"] == head and
              row["frozen_python_commit"] == FROZEN_PYTHON
              for row in decisions),
          "Unsigned reviewer decision source identity does not match selected batch")
    all_flags(decisions, ("reviewer_independent_of_implementation_team",
                          "reviewer_python_replay_pass", "reviewer_r_replay_pass",
                          "complete_input_error_schema_review_pass",
                          "scientific_estimand_review_pass",
                          "all_source_gaps_resolved_after_review",
                          "full_domain_certification_approved"),
              "FALSE", "reviewer decisions")
    check(all(r["scope_decision"] == "PENDING_INDEPENDENT_REVIEW" and
              all(not r[name].strip() for name in (
                  "reviewer_name", "reviewer_affiliation", "reviewer_contact",
                  "reviewer_signed_evidence_reference", "reviewer_signed_utc"))
              for r in decisions),
          "First-batch decisions must remain unsigned and pending")

    # An optional first-party Python/R interface inventory is a separate
    # descriptive evidence attachment. It MUST be paired with a SHA256
    # sidecar and source-pinned to the same 36-reviewer worklist.
    inventory = root / INTERFACE_INVENTORY
    inventory_sha = root / INTERFACE_SHA256
    attached = inventory.exists() or inventory_sha.exists()
    if attached:
        check(inventory.is_file() and inventory_sha.is_file() and
              not inventory.is_symlink() and not inventory_sha.is_symlink(),
              "First-wave interface inventory and SHA256 sidecar must both exist")
        sidecar = read_csv(inventory_sha)
        check(len(sidecar) == 1, "Interface SHA256 sidecar must have one row")
        columns(sidecar, ("filename", "sha256", "recorded_r_git_head",
                          "frozen_python_commit", "independently_verified",
                          "fully_certified"), "interface SHA256 sidecar")
        h = sidecar[0]
        check(h["filename"] == INTERFACE_INVENTORY and
              HEX64.fullmatch(h["sha256"]) is not None and
              sha256(inventory) == h["sha256"] and
              h["recorded_r_git_head"] == head and
              h["frozen_python_commit"] == FROZEN_PYTHON and
              h["independently_verified"] == "FALSE" and
              h["fully_certified"] == "FALSE",
              "First-wave interface SHA256, source pin, or unsigned state invalid")
        interfaces = read_csv(inventory)
        columns(interfaces, ("namespace", "python_name", "kind",
                "native_r_candidate", "recorded_r_git_head",
                "frozen_python_commit", "signature_text_is_not_semantic_parity",
                "independently_reproduced", "source_full_domain_certified",
                "python_export_lookup_ok", "python_interface_inspected",
                "native_r_function_present", "native_nonfunction_representation",
                "first_review_blocker", "reviewer_next_action"),
                "first-wave source interfaces")
        check(len(interfaces) == 36 and
              len({key(row) for row in interfaces}) == 36 and
              {key(row) for row in interfaces} == {key(row) for row in batch},
              "First-wave source interface coverage does not match batch")
        check(all(row["kind"] == selected_by_key[key(row)]["kind"] and
                  row["native_r_candidate"] ==
                    selected_by_key[key(row)]["native_r_candidate"] and
                  row["recorded_r_git_head"] == head and
                  row["frozen_python_commit"] == FROZEN_PYTHON
                  for row in interfaces),
              "First-wave source interface identity mismatch")
        for row in interfaces:
            check(row["reviewer_next_action"].strip() and
                  row["python_export_lookup_ok"] in {"TRUE", "FALSE"} and
                  row["python_interface_inspected"] in {"TRUE", "FALSE"} and
                  row["native_r_function_present"] in {"TRUE", "FALSE"},
                  "First-wave reviewer triage missing explicit evidence state")
            if row["python_export_lookup_ok"] == "FALSE":
                required_blocker = "FROZEN_PYTHON_EXPORT_LOOKUP_FAILED"
            elif row["python_interface_inspected"] == "FALSE":
                required_blocker = "PYTHON_INTERFACE_INTROSPECTION_FAILED"
            elif row["kind"] == "function":
                check(row["native_nonfunction_representation"] ==
                      "NOT_APPLICABLE_FUNCTION",
                      "A function cannot claim nonfunction native representation")
                required_blocker = (
                    "FULL_DOMAIN_SCIENTIFIC_AND_EXTERNAL_REVIEW_MISSING"
                    if row["native_r_function_present"] == "TRUE"
                    else "NATIVE_R_FUNCTION_MISSING"
                )
            else:
                check(row["native_r_function_present"] == "FALSE",
                      "Python nonfunction must not masquerade as a native R function")
                required_blocker = (
                    "NATIVE_R_NONFUNCTION_REPRESENTATION_MISSING"
                    if not row["native_nonfunction_representation"].strip()
                    else "FULL_DOMAIN_SCIENTIFIC_AND_EXTERNAL_REVIEW_MISSING"
                )
            check(row["first_review_blocker"] == required_blocker,
                  "First-wave reviewer blocker does not agree with source evidence")
        all_flags(interfaces, ("signature_text_is_not_semantic_parity",),
                  "TRUE", "source interface qualification disclaimer")
        all_flags(interfaces, ("independently_reproduced",
                               "source_full_domain_certified"),
                  "FALSE", "source interface independent approval")

    return {
        "result": "PASS: 508 author-generated reviewer queue integrity / UNSIGNED",
        "r_git_head": head,
        "frozen_python_commit": FROZEN_PYTHON,
        "export_count": 508,
        "function_count": 380,
        "nonfunction_count": 128,
        "open_source_gap_exports": 203,
        "first_review_batch": 36,
        "descriptive_source_interface_inventory_verified": attached,
        "independent_case_replays": 0,
        "independently_certified_full_domain_contracts": 0,
        "separately_trusted_head_checked": expected_r_head is not None,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet_dir")
    parser.add_argument("--expected-r-head")
    args = parser.parse_args(argv)
    try:
        outcome = verify(args.packet_dir, args.expected_r_head)
    except (ReviewBatchError, OSError, UnicodeError, csv.Error) as exc:
        print(f"REVIEW BATCH FAILED: {exc}", file=sys.stderr)
        return 1
    for k, value in outcome.items():
        print(f"{k}: {value}")
    print("IMPORTANT: HASH INTEGRITY AND AUTHOR TRIAGE ARE NOT SCIENTIFIC CERTIFICATION.")
    if args.expected_r_head is None:
        print("WARNING: R HEAD not compared against a separately trusted source.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
