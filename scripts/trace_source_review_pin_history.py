#!/usr/bin/env python3
"""Trace SHA256-pinned scientific review evidence through Git history.

READ-ONLY PROVENANCE ANALYSIS, NOT REVIEW / RE-CERTIFICATION.
No review records, source files, expected hashes, or approval flags are changed.

From the repository root:
    python scripts/trace_source_review_pin_history.py
or:
    python scripts/trace_source_review_pin_history.py --audit path/to/audit.csv

A pinned SHA256 that matches an OLD Git commit establishes the provenance of
the original review, not equivalence of the CURRENT source. The current source
still requires renewed author review and fresh frozen Python differential
evidence; independent scientific approval is a separate external process.
"""
from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

HEX64 = re.compile(r"^[a-f0-9]{64}$")
REQUIRED = frozenset({"python_name", "path", "source", "pinned_sha256", "verdict"})


def git(root: Path, *arguments: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=False, timeout=90)


def checked_root() -> Path:
    root = Path(__file__).resolve().parent.parent
    if not (root / "DESCRIPTION").is_file() or git(root, "rev-parse", "--is-inside-work-tree").stdout.strip() != b"true":
        raise RuntimeError("Not an EyeTrajectories Git checkout")
    return root


def blob_digest(root: Path, revision: str, path: str) -> str | None:
    result = git(root, "show", revision + ":" + path)
    if result.returncode:
        return None
    return hashlib.sha256(result.stdout).hexdigest()


def revs_for_path(root: Path, path: str) -> list[str]:
    result = git(root, "log", "--all", "--format=%H", "--", path)
    if result.returncode:
        return []
    return [x for x in result.stdout.decode("ascii", errors="replace").splitlines()
            if re.fullmatch(r"[0-9a-f]{40}", x)]


def write_table(path: Path, records: list[dict], columns: list[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(records)


def trace(audit: Path, root: Path) -> tuple[Path, Path]:
    with audit.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None or not REQUIRED.issubset(reader.fieldnames):
            raise ValueError("Audit lacks the required source-review fields")
        data = list(reader)
    failed = [x for x in data if x["verdict"].startswith("FAIL_")]
    pinned = defaultdict(set)
    for row in failed:
        path, digest = row["path"], row["pinned_sha256"]
        parts = PurePosixPath(path)
        if (parts.is_absolute() or ".." in parts.parts or "\\" in path or
                not HEX64.fullmatch(digest)):
            raise ValueError("Unsafe path or invalid pinned digest: " + repr(path))
        pinned[(path, digest)].add(row["python_name"])
    if not pinned:
        print("NO_FAILED_REVIEW_EVIDENCE; independent_certification=FALSE")
        return audit, audit

    path_history: dict[str, list[str]] = {}
    seen_git_blobs: dict[tuple[str, str], str | None] = {}
    findings = []
    for path, expected in sorted(pinned):
        head_key = (path, "HEAD")
        head_digest = seen_git_blobs.setdefault(
            head_key, blob_digest(root, "HEAD", path))
        if path not in path_history:
            path_history[path] = revs_for_path(root, path)
        first_match = ""
        for sha in path_history[path]:
            key = (path, sha)
            if key not in seen_git_blobs:
                seen_git_blobs[key] = blob_digest(root, sha, path)
            if seen_git_blobs[key] == expected:
                first_match = sha
                break
        if head_digest == expected:
            status = "MATCHES_CURRENT_GIT_HEAD"
        elif first_match:
            status = ("HISTORICAL_PIN_FILE_REMOVED_OR_RENAMED"
                      if head_digest is None else
                      "HISTORICAL_PIN_CURRENT_SOURCE_CHANGED")
        else:
            status = "PIN_NOT_FOUND_IN_AVAILABLE_GIT_HISTORY"
        findings.append({
            "path": path, "pinned_sha256": expected,
            "status": status, "current_head_sha256": head_digest or "",
            "source_commit_with_pinned_bytes": first_match,
            "failed_reference_count": sum(
                1 for row in failed
                if row["path"] == path and row["pinned_sha256"] == expected),
            "affected_contracts": len(pinned[(path, expected)]),
            "contract_names": " | ".join(sorted(pinned[(path, expected)])),
            "requires_current_source_rereview":
                "TRUE" if status != "MATCHES_CURRENT_GIT_HEAD" else "FALSE",
            "independent_certification": "FALSE",
        })

    by_contract: dict[str, list[dict]] = defaultdict(list)
    for result in findings:
        for name in result["contract_names"].split(" | "):
            by_contract[name].append(result)
    contracts = [{
        "python_name": name,
        "affected_pinned_file_versions": len(records),
        "historical_pins_found": sum(
            r["status"].startswith("HISTORICAL_PIN_") for r in records),
        "pins_not_found_in_git_history": sum(
            r["status"] == "PIN_NOT_FOUND_IN_AVAILABLE_GIT_HISTORY"
            for r in records),
        "current_source_review_required": "TRUE",
        "independent_certification": "FALSE",
        "affected_paths": " | ".join(sorted({r["path"] for r in records})),
    } for name, records in sorted(by_contract.items())]

    tag = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    dest = root / "artifacts" / "review_sha256_checkout_audit"
    dest.mkdir(parents=True, exist_ok=True)
    unique_path = dest / ("review_git_history_" + tag + "_unique_pins.csv")
    contract_path = dest / ("review_git_history_" + tag + "_contracts.csv")
    write_table(unique_path, findings, list(findings[0]))
    write_table(contract_path, contracts, list(contracts[0]))
    print("REVIEW_GIT_PIN_TRACED_DISTINCT_PATH_SHA256=", len(findings), sep="")
    print("REVIEW_GIT_PIN_TRACED_CONTRACTS=", len(contracts), sep="")
    for key, n in sorted(Counter(f["status"] for f in findings).items()):
        print("REVIEW_GIT_PROVENANCE_", key, "=", n, sep="")
    print("REVIEW_GIT_PIN_HISTORY_DETAILS=", unique_path, sep="")
    print("REVIEW_GIT_PIN_HISTORY_CONTRACTS=", contract_path, sep="")
    print("REVIEW_GIT_HISTORY_PROVENANCE_ONLY; NO HASH REWRITES; CERTIFICATION=FALSE")
    return unique_path, contract_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path,
                        help="Existing review_integrity_*.csv; default latest")
    options = parser.parse_args()
    root = checked_root()
    audit = options.audit
    if audit is None:
        folder = root / "artifacts" / "review_sha256_checkout_audit"
        files = list(folder.glob("review_integrity_*.csv"))
        if not files:
            parser.error("No prior review-integrity audit CSV found")
        audit = max(files, key=lambda p: p.stat().st_mtime)
    trace(audit.resolve(strict=True), root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
