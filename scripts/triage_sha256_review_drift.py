#!/usr/bin/env python3
"""Read-only historical triage of SHA256 drift in reviewed source contracts.

Usage (repository root):
    python scripts/triage_sha256_review_drift.py
    python scripts/triage_sha256_review_drift.py path/to/review_integrity_....csv

This tool NEVER updates review pins or certifies Python/R parity.
It discovers the most recent Git commit whose canonical blob matches each
originally reviewed SHA256, then writes bounded per-path diffs and a worklist.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
from collections import defaultdict
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
AUDITS = ROOT / "artifacts" / "review_sha256_checkout_audit"
OUT = AUDITS / "source_drift_triage"


def git(*args: str, check: bool = True) -> bytes:
    proc = subprocess.run(
        ["git", "-C", str(ROOT), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and proc.returncode:
        raise RuntimeError(
            f"git {' '.join(args)} failed: "
            + proc.stderr.decode("utf-8", errors="replace").strip()
        )
    return proc.stdout if proc.returncode == 0 else b""


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def latest_audit() -> Path:
    options = sorted(
        AUDITS.glob("review_integrity_*.csv"),
        key=lambda p: p.stat().st_mtime,
    )
    if not options:
        raise RuntimeError(
            "No integrity CSV found. Run the strict R SHA256 checkout audit first."
        )
    return options[-1]


def safe_path(value: str) -> str:
    p = Path(value)
    if p.is_absolute() or ".." in p.parts or not p.parts:
        raise ValueError(f"Unsafe source path: {value!r}")
    if (ROOT / p).resolve().is_relative_to(ROOT.resolve()) is False:
        raise ValueError(f"Path escapes repository: {value!r}")
    return p.as_posix()


def history(path: str) -> list[str]:
    raw = git("log", "--format=%H", "HEAD", "--", path)
    return raw.decode("ascii", errors="replace").splitlines()


def historical_pin(path: str, pin: str, revisions: list[str]) -> str:
    for commit in revisions:
        blob = git("show", f"{commit}:{path}", check=False)
        # A missing path yields empty bytes; SHA256 of that empty blob can never
        # be treated as proof of a source file.
        if blob and sha256(blob) == pin:
            return commit
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("audit_csv", nargs="?", type=Path)
    args = parser.parse_args()
    if not (ROOT / "DESCRIPTION").is_file():
        raise RuntimeError("Cannot find package DESCRIPTION")
    audit = args.audit_csv or latest_audit()
    if not audit.is_absolute():
        audit = (ROOT / audit).resolve()
    with audit.open("r", encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    needed = {"python_name", "path", "pinned_sha256", "verdict"}
    if not rows or not needed.issubset(rows[0]):
        raise RuntimeError("Input is not a valid source-integrity audit CSV")

    bad = [r for r in rows if r["verdict"].startswith("FAIL_")]
    if not bad:
        print(f"No source SHA256 failures in {audit}")
        return 0
    if git("status", "--porcelain", "--untracked-files=no").strip():
        print("WARNING: tracked files are modified; do not certify this checkout.",
              file=sys.stderr)
    OUT.mkdir(parents=True, exist_ok=True)
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in bad:
        grouped[safe_path(row["path"])].append(row)

    worklist: list[dict[str, str]] = []
    for path, refs in sorted(grouped.items()):
        current = git("show", f"HEAD:{path}", check=False)
        current_sha = sha256(current) if current else ""
        revisions = history(path)
        pins = sorted({r["pinned_sha256"] for r in refs})
        located = {pin: historical_pin(path, pin, revisions) for pin in pins}
        for pin in pins:
            matched = located[pin]
            verdict = ("STALE_REVIEW_PIN_REQUIRES_REVIEW"
                       if matched else "HISTORICAL_PIN_NOT_FOUND")
            diff_name = (
                path.replace("/", "__").replace("\\", "__")
                + "__" + pin[:12] + ".patch"
            )
            if matched:
                difference = git("diff", "--no-ext-diff",
                                 matched, "HEAD", "--", path)
                (OUT / diff_name).write_bytes(difference)
            else:
                diff_name = ""
            selected = [r for r in refs if r["pinned_sha256"] == pin]
            worklist.append({
                "path": path,
                "verdict": verdict,
                "number_of_review_references": str(len(selected)),
                "number_of_python_contracts": str(len({
                    r["python_name"] for r in selected
                })),
                "python_contracts": ";".join(sorted({
                    r["python_name"] for r in selected
                })),
                "reviewed_sha256": pin,
                "current_head_sha256": current_sha,
                "matching_historical_commit": matched,
                "latest_path_commit": revisions[0] if revisions else "",
                "diff_file": diff_name,
                "independently_certified": "FALSE",
            })
    fields = list(worklist[0])
    target = OUT / "review_drift_recheck_worklist.csv"
    with target.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(worklist)
    print(f"Failing references: {len(bad)}")
    print(f"Affected source paths: {len(grouped)}")
    print(f"Unique reviewed source revisions: {len(worklist)}")
    for row in worklist:
        print(f"  {row['verdict']} | refs={row['number_of_review_references']}"
              f" | {row['path']} | reviewed_commit="
              f"{row['matching_historical_commit'][:12] or 'NOT_FOUND'}")
    print(f"Worklist: {target}")
    print("This is review drift diagnosis, NOT resolved parity or certification.")
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError) as err:
        print(f"REVIEW_DRIFT_TRIAGE_ERROR: {err}", file=sys.stderr)
        sys.exit(3)
