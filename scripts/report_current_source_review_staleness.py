#!/usr/bin/env python3
"""Read-only source-review SHA256 inventory for current EyeTrajectories HEAD.

Never authorizes a gap closure, updates a receipt, or certifies source parity.
The LIVE qualification gate invokes this reporter only after its independent
strict source_gap_inventory.read_inventory() has already failed.

Run from repository root:
    py -3 scripts/report_current_source_review_staleness.py
"""
from __future__ import annotations

from collections import Counter
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess

RECEIPTS = "inst/extdata/reviewed_source_contract_closures_v1.csv"
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def git(root: Path, *args: str):
    return subprocess.run(
        ["git", "-C", str(root), *args], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, check=False, timeout=60)


def resolve_path(root: Path, relative: str) -> Path:
    p = PurePosixPath(relative)
    if (not relative or p.is_absolute() or ".." in p.parts
            or "." in p.parts or "\\" in relative
            or not (relative in ("NAMESPACE", "DESCRIPTION")
                    or relative.startswith(("R/", "tests/",
                                            "docs/source_contract_reviews/"))
                    or (relative.startswith("man/") and
                        relative.endswith(".Rd")))):
        raise ValueError("Unsafe scientific evidence path " + repr(relative))
    target = root.joinpath(*p.parts)
    if target.is_symlink() or not target.resolve().is_relative_to(root.resolve()):
        raise ValueError("Symlinked or out-of-repo evidence path " + repr(relative))
    return target


def report(root: Path) -> tuple[Path, Counter]:
    root = root.resolve()
    registry = root / RECEIPTS
    with registry.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        columns = {"python_name", "review_record_path", "review_record_sha256"}
        if not reader.fieldnames or not columns.issubset(reader.fieldnames):
            raise ValueError("Missing source-review registry columns")
        rows = list(reader)
    if not rows or any(None in r or None in r.values() for r in rows):
        raise ValueError("Malformed source-review registry")
    refs = []
    for row in rows:
        name = row["python_name"]
        p = row["review_record_path"]
        refs.append((name, p, row["review_record_sha256"], "review_json"))
        path = resolve_path(root, p)
        if not path.is_file():
            continue
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
            for key in ("native_files", "case_evidence",
                        "additional_regression_evidence"):
                for evidence in doc.get(key, []) or []:
                    refs.append((name, evidence["path"], evidence["sha256"],
                                 evidence.get("kind", key)))
        except (ValueError, TypeError, KeyError, UnicodeError) as exc:
            refs.append((name, p, "", "REVIEW_JSON_UNREADABLE:" + str(exc)))
    # Cache canonical Git objects once per tracked path, not six times
    # per scientific review domain.
    cache: dict[str, tuple[str | None, bytes | None]] = {}
    findings = []
    counts: Counter = Counter()
    for name, relative, pinned, kind in refs:
        valid = HEX64.fullmatch(pinned) is not None
        target = resolve_path(root, relative)
        if relative not in cache:
            blob = git(root, "show", "HEAD:" + relative)
            cache[relative] = (hashlib.sha256(blob.stdout).hexdigest(),
                               blob.stdout) if blob.returncode == 0 else (None, None)
        git_sha, canonical = cache[relative]
        current = target.read_bytes() if target.is_file() else None
        raw_sha = hashlib.sha256(current).hexdigest() if current is not None else ""
        normalized = current.replace(b"\r\n", b"\n") if current is not None else None
        if not target.is_file():
            status = "FAIL_MISSING"
        elif not valid:
            status = "FAIL_INVALID_SHA256_PIN_OR_RECORD"
        elif git_sha != pinned:
            status = "FAIL_STALE_PIN_VERSUS_GIT_HEAD"
        elif current != canonical and normalized != canonical:
            status = "FAIL_WORKTREE_BYTES_DIFFER_FROM_GIT_HEAD"
        else:
            status = "PASS_ORIGINAL_PIN_MATCHES_CURRENT_CANONICAL_SOURCE"
        counts[status] += 1
        if status.startswith("FAIL_"):
            findings.append({
                "python_name": name, "path": relative, "source": kind,
                "pinned_sha256": pinned, "current_git_head_sha256": git_sha or "",
                "worktree_sha256": raw_sha, "status": status,
                "independent_certification": "FALSE",
            })
    outdir = root / "artifacts" / "review_sha256_checkout_audit"
    outdir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output = outdir / ("live_source_review_blockers_" + timestamp + ".csv")
    if output.exists():
        raise FileExistsError("Refuse overwriting previous integrity report")
    fields = ["python_name", "path", "source", "pinned_sha256",
              "current_git_head_sha256", "worktree_sha256", "status",
              "independent_certification"]
    with output.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(findings)
    print("LIVE_AUTHOR_REVIEW_REFERENCES=", sum(counts.values()), sep="")
    print("LIVE_AUTHOR_REVIEW_FAILURE_REFERENCES=", len(findings), sep="")
    print("LIVE_AUTHOR_REVIEW_FAILED_CONTRACTS=",
          len({x["python_name"] for x in findings}), sep="")
    print("LIVE_AUTHOR_REVIEW_FAILED_PATHS=",
          len({x["path"] for x in findings}), sep="")
    for status, n in sorted(counts.items()):
        print("LIVE_AUTHOR_REVIEW_", status, "=", n, sep="")
    print("LIVE_AUTHOR_REVIEW_FAILURE_REPORT=", output, sep="")
    print("INDEPENDENT_508_CERTIFICATION=FALSE")
    return output, counts


if __name__ == "__main__":
    from pathlib import Path
    root = Path(__file__).resolve().parent.parent
    _, counts = report(root)
    raise SystemExit(2 if any(k.startswith("FAIL_") for k in counts) else 0)
