#!/usr/bin/env python3
"""Build and verify UNSIGNED 508-export reviewer wave packets, not certificates."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sys

import verify_508_certification_batch as baseline

DIRECTORY = "all_508_unsigned_review_waves"
MANIFEST = "all_508_wave_manifest.json"
INDEX = "all_508_wave_index.csv"
FILES = ("contracts.csv", "cases_UNSIGNED.csv", "decisions_UNSIGNED.csv")
IDENTITY = ("namespace", "python_name", "kind", "native_r_candidate",
            "recorded_r_git_head", "frozen_python_commit")
BATCH_SIZE = 36


def check(value: bool, explanation: str) -> None:
    if not value:
        raise baseline.ReviewBatchError(explanation)


def write_csv(file: Path, rows: list[dict[str, str]]) -> None:
    check(bool(rows), "Cannot write an empty review sheet")
    with file.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def id_fields(row: dict[str, str]) -> dict[str, str]:
    return {field: row[field] for field in IDENTITY}


def review_blocker(row: dict[str, str]) -> str:
    if row["source_gap_open"] == "TRUE":
        return "KNOWN_SOURCE_GAP"
    if row["backend_or_estimand_distinct"] == "TRUE":
        return "BACKEND_OR_ESTIMAND_DIFFERS"
    if row["kind"] == "function" and row["native_implementation_started"] != "TRUE":
        return "NATIVE_FUNCTION_MISSING"
    if row["kind"] != "function" and not row["native_nonfunction_representation"].strip():
        return "NATIVE_REPRESENTATION_MISSING"
    return "INDEPENDENT_SOURCE_AND_SCIENTIFIC_REVIEW_MISSING"


def contract(row: dict[str, str], wave: str) -> dict[str, str]:
    return {
        **id_fields(row), "wave_id": wave,
        "review_lane": row["review_lane"],
        "source_gap_open": row["source_gap_open"],
        "backend_or_estimand_distinct": row["backend_or_estimand_distinct"],
        "native_implementation_started": row["native_implementation_started"],
        "native_nonfunction_representation": row["native_nonfunction_representation"],
        "first_unresolved_requirement": row["first_unresolved_requirement"],
        "documented_gap_kind": row.get("documented_gap_kind",""),
        "documented_source_difference": row.get("documented_source_difference",""),
        "documented_python_source_witness": row.get("documented_python_source_witness",""),
        "required_gap_resolution": row.get("required_gap_resolution",""),
        "review_blocker": review_blocker(row),
        "source_full_domain_certified": "FALSE",
    }


def cases_for(row: dict[str, str]) -> list[dict[str, str]]:
    return [{
        **id_fields(row), "criterion": criterion,
        "reviewer_case_passed": "FALSE",
        "reviewer_created_evidence_reference": "",
        "reviewer_written_findings": "",
        "independently_replayed": "FALSE",
        "full_domain_approved": "FALSE",
    } for criterion in baseline.CRITERIA]


def decision(row: dict[str, str]) -> dict[str, str]:
    return {
        **id_fields(row),
        "reviewer_name": "", "reviewer_affiliation": "",
        "reviewer_contact": "",
        "reviewer_independent_of_implementation_team": "FALSE",
        "reviewer_python_replay_pass": "FALSE",
        "reviewer_r_replay_pass": "FALSE",
        "complete_input_error_schema_review_pass": "FALSE",
        "scientific_estimand_review_pass": "FALSE",
        "all_source_gaps_resolved_after_review": "FALSE",
        "reviewer_signed_evidence_reference": "",
        "reviewer_signed_utc": "",
        "scope_decision": "PENDING_INDEPENDENT_REVIEW",
        "full_domain_certification_approved": "FALSE",
    }


def source_queue(packet: Path, head: str) -> list[dict[str, str]]:
    check(baseline.HEX40.fullmatch(head) is not None,
          "Supply a separately trusted full R Git SHA")
    baseline.verify(packet, expected_r_head=head)
    queue = baseline.read_csv(packet / baseline.FILES[0])
    check(len(queue) == 508 and len({baseline.key(r) for r in queue}) == 508,
          "Source queue must contain 508 unique exports")
    check(sum(r["kind"] == "function" for r in queue) == 380 and
          sum(r["kind"] != "function" for r in queue) == 128,
          "Expected 380 frozen callable + 128 nonfunction exports")
    check(sum(r["source_gap_open"] == "TRUE" and r["kind"] == "function"
              for r in queue) == 201 and
          sum(r["source_gap_open"] == "TRUE" and r["kind"] != "function"
              for r in queue) == 1,
          "Recorded 201 callable and 1 nonfunction differences changed")
    for row in queue:
        check(row["recorded_r_git_head"] == head and
              row["frozen_python_commit"] == baseline.FROZEN_PYTHON and
              row["currently_authoritatively_certified"] == "FALSE",
              "Mixed source pins or false certification")
        for field in ("source_gap_open", "backend_or_estimand_distinct",
                      "native_implementation_started"):
            check(row[field] in ("TRUE", "FALSE"),
                  "Invalid audit boolean: " + field)
    return queue


def wave_rows(queue: list[dict[str,str]], number: int):
    wave = "wave_" + str(number).zfill(2)
    rows = queue[(number-1)*BATCH_SIZE:number*BATCH_SIZE]
    return ([contract(row, wave) for row in rows],
            [c for row in rows for c in cases_for(row)],
            [decision(row) for row in rows])


def build(packet_dir: str | Path, head: str):
    packet = Path(packet_dir).resolve(strict=True)
    queue = source_queue(packet, head)
    output = packet / DIRECTORY
    check(not output.exists(), "Wave directory exists: verify it; never overwrite")
    output.mkdir()
    try:
        checksums: dict[str,str] = {}
        index: list[dict[str,str]] = []
        for n in range(1,16):
            directory = output / ("wave_" + str(n).zfill(2))
            directory.mkdir()
            sheets = wave_rows(queue,n)
            for filename, rows in zip(FILES,sheets):
                f = directory / filename
                write_csv(f,rows)
                checksums[f.relative_to(output).as_posix()] = baseline.sha256(f)
            index.extend(sheets[0])
        index_file = output / INDEX
        write_csv(index_file,index)
        checksums[INDEX] = baseline.sha256(index_file)
        meta = {
            "format":"unsigned-source-pinned-508-review-waves-v1",
            "r_git_head":head, "frozen_python_commit":baseline.FROZEN_PYTHON,
            "source_queue_sha256":baseline.sha256(packet / baseline.FILES[0]),
            "export_count":508, "function_count":380, "nonfunction_count":128,
            "documented_callable_gaps":201, "documented_nonfunction_gaps":1,
            "wave_count":15, "review_criterion_count":508*len(baseline.CRITERIA),
            "signatures":"NONE", "independent_certifications":0,
            "registry_modified":False, "files_sha256":checksums,
        }
        (output / MANIFEST).write_text(json.dumps(meta,indent=2)+"\n",
                                        encoding="utf-8")
        verify(packet,head)
        return meta
    except Exception:
        (output / "BUILD_INCOMPLETE.txt").write_text(
            "FAILED: do not treat this packet as a reviewer handoff\n",
            encoding="utf-8")
        raise


def verify(packet_dir: str | Path, head: str):
    packet = Path(packet_dir).resolve(strict=True)
    queue = source_queue(packet,head)
    output = packet / DIRECTORY
    check(output.is_dir() and not output.is_symlink() and
          not (output / "BUILD_INCOMPLETE.txt").exists(),
          "Missing or incomplete 508 review waves")
    path = output / MANIFEST
    check(path.is_file() and not path.is_symlink(),
          "Missing 508-wave integrity manifest")
    meta = json.loads(path.read_text(encoding="utf-8"))
    check(meta["format"] == "unsigned-source-pinned-508-review-waves-v1" and
          meta["r_git_head"] == head and
          meta["frozen_python_commit"] == baseline.FROZEN_PYTHON and
          meta["source_queue_sha256"] == baseline.sha256(packet / baseline.FILES[0]) and
          meta["export_count"] == 508 and meta["function_count"] == 380 and
          meta["nonfunction_count"] == 128 and
          meta["documented_callable_gaps"] == 201 and
          meta["documented_nonfunction_gaps"] == 1 and
          meta["wave_count"] == 15 and
          meta["review_criterion_count"] == 508*len(baseline.CRITERIA) and
          meta["signatures"] == "NONE" and
          meta["independent_certifications"] == 0 and
          meta["registry_modified"] is False,
          "Author packet metadata source/independence mismatch")
    expected_files = {INDEX} | {f"wave_{n:02d}/{f}"
                                for n in range(1,16) for f in FILES}
    existing_files = {f.relative_to(output).as_posix() for f in output.rglob("*")
                      if f.is_file() and f != path}
    check(existing_files == expected_files and
          set(meta["files_sha256"]) == expected_files,
          "Missing, extraneous or unsigned evidence file")
    for filename in expected_files:
        file = output / filename
        check(not file.is_symlink() and
              re.fullmatch("[0-9a-f]{64}",meta["files_sha256"][filename]) is not None and
              baseline.sha256(file) == meta["files_sha256"][filename],
              "Checksum verification failed: " + filename)
    index: list[dict[str,str]] = []
    for n in range(1,16):
        basepath = output / f"wave_{n:02d}"
        expected = wave_rows(queue,n)
        actual = [baseline.read_csv(basepath / f) for f in FILES]
        check(actual == list(expected),
              f"Wave {n}: contract source fields, review criteria or blank decisions altered")
        index.extend(expected[0])
    check(index == baseline.read_csv(output / INDEX) and len(index) == 508 and
          len({baseline.key(row) for row in index}) == 508,
          "Full wave index lacks unique 508-export coverage")
    return {"export_count":508,"wave_count":15,
            "review_criteria":508*len(baseline.CRITERIA),
            "independent_certifications":0,
            "status":"PASS_UNSIGNED_PACKET_INTEGRITY_ONLY"}


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command",choices=("build","verify"))
    parser.add_argument("packet_dir")
    parser.add_argument("--expected-r-head",required=True)
    args=parser.parse_args(argv)
    try:
        result=(build(args.packet_dir,args.expected_r_head)
                if args.command=="build" else
                verify(args.packet_dir,args.expected_r_head))
    except (baseline.ReviewBatchError, OSError, ValueError, KeyError,
            json.JSONDecodeError, csv.Error) as err:
        print("508_WAVE_FAILED: "+str(err),file=sys.stderr)
        return 1
    for key,value in result.items():
        if key!="files_sha256":
            print(f"{key}={value}")
    print("NO THIRD-PARTY INDEPENDENT SCIENTIFIC APPROVAL; 0/508 CERTIFIED")
    return 0


if __name__=="__main__":
    raise SystemExit(main())
