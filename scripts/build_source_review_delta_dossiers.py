#!/usr/bin/env python3
"""Build read-only old-versus-current scientific source-review delta dossiers.

This does NOT refresh a review, alter a SHA256 receipt, certify a Python API,
or infer scientific equivalence from historical Git provenance. Replaying an
old review against changed R source and changed six-domain tests is mandatory.

Run from repository root after fetching the pinned historical commits:
  py -3 scripts/build_source_review_delta_dossiers.py
Optionally:
  py -3 scripts/build_source_review_delta_dossiers.py --audit PATH --history PATH
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import difflib
import hashlib
from pathlib import Path, PurePosixPath
import re
import subprocess

HEX40 = re.compile(r"[a-f0-9]{40}\Z")
HEX64 = re.compile(r"[a-f0-9]{64}\Z")
REQUIRED_HISTORY = {
    "path", "pinned_sha256", "status", "current_head_sha256",
    "source_commit_with_pinned_bytes", "contract_names",
}
REQUIRED_AUDIT = {"path", "pinned_sha256", "python_name", "verdict"}
REVIEW_DOMAINS = (
    "source_signature", "accepted_input_domain", "numerical_outputs",
    "exception_semantics", "returned_schema", "scientific_estimand",
)


def read_csv(path: Path, required: set[str]) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise ValueError("Missing required audit fields: " + str(path))
        records = list(reader)
    if not records or any(None in r or None in r.values() for r in records):
        raise ValueError("Malformed evidence audit: " + str(path))
    return records


def git(root: Path, *args: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=False, timeout=90)
    if result.returncode:
        raise ValueError(
            "Git source provenance unavailable: " + " ".join(args) +
            ": " + result.stderr.decode("utf-8", errors="replace")[:200])
    return result.stdout


def sha(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def checked_path(name: str) -> str:
    parsed = PurePosixPath(name)
    if (not name or parsed.is_absolute() or ".." in parsed.parts
            or "." in parsed.parts or "\\" in name or
            (not name.startswith(("R/", "tests/"))
             and name != "NAMESPACE")):
        raise ValueError("Unsafe/out-of-scope source-review path: " + name)
    return name


def choose_latest(folder: Path, pattern: str) -> Path:
    matches = list(folder.glob(pattern))
    if not matches:
        raise FileNotFoundError("Cannot find matching historical review audit " + pattern)
    return max(matches, key=lambda p: p.stat().st_mtime)


def build(root: Path, audit: Path, history: Path, output: Path) -> dict[str, int]:
    a = read_csv(audit, REQUIRED_AUDIT)
    h = read_csv(history, REQUIRED_HISTORY)
    failed = [r for r in a if r["verdict"] == "FAIL_PIN_MISMATCH"]
    expected = {}
    for r in failed:
        key = (checked_path(r["path"]), r["pinned_sha256"])
        if not HEX64.fullmatch(key[1]):
            raise ValueError("Invalid pinned evidence SHA256")
        expected.setdefault(key, set()).add(r["python_name"])
    lookup = {(checked_path(r["path"]), r["pinned_sha256"]): r for r in h}
    if not expected:
        raise ValueError("No failed evidence pairs in supplied audit")
    if not expected.keys() <= lookup.keys():
        raise ValueError("Historical Git source evidence missing for a failed pair")

    changed = []
    diffs = {}
    contracts: dict[str, dict] = {}
    for n, ((path, old_sha), affected) in enumerate(sorted(expected.items()), 1):
        row = lookup[(path, old_sha)]
        rev = row["source_commit_with_pinned_bytes"]
        if not HEX40.fullmatch(rev):
            raise ValueError("Missing full-length pinned Git commit for " + path)
        previous = git(root, "show", rev + ":" + path)
        latest = git(root, "show", "HEAD:" + path)
        if sha(previous) != old_sha:
            raise ValueError("Historical Git source does not match pin: " + path)
        if sha(latest) != row["current_head_sha256"]:
            raise ValueError(
                "Current Git HEAD is not the SHA256-audited version: " + path)
        if previous == latest:
            raise ValueError("Source no longer differs; rerun integrity audit")
        if row["status"] != "HISTORICAL_PIN_CURRENT_SOURCE_CHANGED":
            raise ValueError("Unexpected historical source status: " + path)

        # Preserve BOTH frozen versions in the patch metadata, not as a new
        # signed source record. One file can have two historically valid pins.
        before = previous.decode("utf-8", errors="replace").splitlines(True)
        after = latest.decode("utf-8", errors="replace").splitlines(True)
        delta = "".join(difflib.unified_diff(
            before, after, fromfile=rev[:12] + ":" + path,
            tofile="HEAD:" + path, n=5))
        if not delta:
            raise ValueError("Changed canonical text has no inspectable diff")
        filename = f"{n:03d}_{path.replace('/', '_').replace('.', '_')}_{old_sha[:12]}.patch"
        diffs[filename] = delta
        kind = ("PRODUCTION_SOURCE" if path.startswith("R/")
                else "NAMESPACE" if path == "NAMESPACE"
                else "SOURCE_TEST")
        changed.append({
            "path": path, "kind": kind, "pinned_sha256": old_sha,
            "historical_git_revision": rev, "current_sha256": sha(latest),
            "affected_contracts": len(affected),
            "review_status": "CURRENT_VERSION_NOT_YET_REVIEWED",
            "requires_six_domain_replay": "TRUE",
            "independent_certification": "FALSE",
            "unified_diff": "patches/" + filename,
            "contracts": " | ".join(sorted(affected)),
        })
        for name in affected:
            item = contracts.setdefault(name, {
                "python_name": name, "production_source_paths": set(),
                "test_evidence_paths": set(), "namespace_paths": set(),
                "historical_review_versions": 0})
            item["historical_review_versions"] += 1
            col = ("production_source_paths" if kind == "PRODUCTION_SOURCE"
                   else "namespace_paths" if kind == "NAMESPACE"
                   else "test_evidence_paths")
            item[col].add(path)

    contract_rows = []
    for name, item in sorted(contracts.items()):
        code_paths = item["production_source_paths"]
        test_paths = item["test_evidence_paths"]
        namespace_paths = item["namespace_paths"]
        priority = ("P1_PRODUCTION_SCIENCE" if code_paths
                    else "P2_TEST_EVIDENCE" if test_paths
                    else "P3_NAMESPACE_ONLY")
        contract_rows.append({
            "python_name": name, "priority": priority,
            "review_status": "REQUIRES_UPDATED_AUTHOR_REVIEW",
            "historical_review_versions": item["historical_review_versions"],
            "changed_production_files": " | ".join(sorted(code_paths)),
            "changed_test_files": " | ".join(sorted(test_paths)),
            "changed_namespace_files": " | ".join(sorted(namespace_paths)),
            "six_source_domains_to_recheck": " | ".join(REVIEW_DOMAINS),
            "pinned_python_differential_required": "TRUE",
            "independent_certification": "FALSE",
        })

    if output.exists():
        raise FileExistsError("Refusing to overwrite existing review dossier " + str(output))
    (output / "patches").mkdir(parents=True)
    for name, delta in diffs.items():
        (output / "patches" / name).write_text(delta, encoding="utf-8", newline="\n")
    def write(filename: str, rows: list[dict]):
        with (output / filename).open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
    write("changed_evidence_versions.csv", changed)
    write("contracts_to_revalidate.csv", contract_rows)
    (output / "README.txt").write_text(
        "UNSIGNED ORIGINAL-VERSUS-CURRENT EVIDENCE DIFFS ONLY\n"
        "Historical Git hashes prove provenance, not current correctness.\n"
        "All six source domains and frozen Python differentials must be\n"
        "reviewed for affected contracts before updating a receipt.\n"
        "Independent certification: NONE. No package files modified.\n",
        encoding="utf-8")
    totals = {
        "historical_path_sha256_pairs": len(changed),
        "distinct_changed_paths": len({x["path"] for x in changed}),
        "contracts_requiring_revalidation": len(contract_rows),
        "source_or_namespace_changed_contracts": sum(
            bool(x["changed_production_files"] or x["changed_namespace_files"])
            for x in contract_rows),
        "test_evidence_only_contracts": sum(
            bool(x["changed_test_files"] and not x["changed_production_files"]
                 and not x["changed_namespace_files"])
            for x in contract_rows),
    }
    print("REVIEW_DELTA_OUTPUT=", output, sep="")
    for key, value in totals.items():
        print("REVIEW_DELTA_", key.upper(), "=", value, sep="")
    print("REVIEW_DELTA_STATUS=UNSIGNED_SIX_DOMAIN_REVALIDATION_REQUIRED")
    return totals


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path)
    parser.add_argument("--history", type=Path)
    options = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    folder = root / "artifacts" / "review_sha256_checkout_audit"
    audit = options.audit or choose_latest(folder, "review_integrity_*.csv")
    history = options.history or choose_latest(folder, "review_git_history_*_unique_pins.csv")
    tag = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output = folder / ("current_source_review_deltas_" + tag)
    build(root, audit, history, output)


if __name__ == "__main__":
    main()
