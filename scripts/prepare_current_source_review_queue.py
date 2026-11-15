#!/usr/bin/env python3
"""One-command, unsigned revalidation queue from CURRENT SHA256-pinned Git evidence.

This is an AUTHOR WORKLIST generator, not a parity or release certificate.
It collects a fresh live source-review audit, traces each OLD SHA256 to its
original Git commit, and writes versioned old->new source diffs plus a six-
domain contract worklist. It will NOT change pinned receipts, gap statuses,
package R files, source tests, or external reviewer decisions.

From repository root:
    py -3 scripts/prepare_current_source_review_queue.py

The generated dossiers tell the author WHAT must be re-reviewed with Python
1.2.0 and R evidence. They cannot approve revalidation automatically.
"""
from __future__ import annotations

import csv
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys

from report_current_source_review_staleness import report as live_report
from trace_source_review_pin_history import trace
from build_source_review_delta_dossiers import build


def run(root: Path) -> dict[str, object]:
    root = root.resolve()
    git = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"], check=False,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
    if git.returncode or len(git.stdout.strip()) != 40:
        raise RuntimeError("Requires a repository with a full Git HEAD")
    head = git.stdout.decode("ascii").strip()

    # Protect the correspondence between current working source and Git
    # HEAD, including changed tests for which the original pin is stale.
    # Git canonicalizes checkout line endings before comparing to HEAD.
    clean = subprocess.run(
        ["git", "-C", str(root), "diff", "--quiet", "HEAD", "--",
         "R", "tests", "NAMESPACE", "DESCRIPTION", "man",
         "docs/source_contract_reviews", "inst/extdata"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        timeout=60)
    if clean.returncode != 0:
        raise RuntimeError(
            "Substantive tracked evidence changes versus Git HEAD; commit "
            "or discard the changes before creating a source-bound worklist")

    live_csv, status = live_report(root)
    if any(key not in (
        "PASS_ORIGINAL_PIN_MATCHES_CURRENT_CANONICAL_SOURCE",
        "FAIL_STALE_PIN_VERSUS_GIT_HEAD") and count
        for key, count in status.items()):
        raise RuntimeError(
            "Live source review contains missing, unsafe, or modified "
            "evidence; no revalidation queue will be produced")
    if not status["FAIL_STALE_PIN_VERSUS_GIT_HEAD"]:
        print("CURRENT_SOURCE_REVIEW_STALE_REFERENCES=0")
        print("INDEPENDENT_CERTIFICATION=FALSE")
        return {"head": head, "pending": 0}

    with live_csv.open("r", encoding="utf-8", newline="") as handle:
        failed = list(csv.DictReader(handle))
    if (not failed or any(
            row["status"] != "FAIL_STALE_PIN_VERSUS_GIT_HEAD"
            or row["independent_certification"] != "FALSE"
            for row in failed)):
        raise RuntimeError("Live staleness report is incomplete or unexpected")

    audit_path = live_csv.with_name(
        live_csv.stem + "_unsigned_worklist_inputs.csv")
    with audit_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=[
            "python_name", "path", "source", "pinned_sha256", "verdict"])
        writer.writeheader()
        writer.writerows({
            "python_name": row["python_name"], "path": row["path"],
            "source": row["source"], "pinned_sha256": row["pinned_sha256"],
            "verdict": "FAIL_PIN_MISMATCH",
        } for row in failed)

    unique_pin_file, history_contracts = trace(audit_path, root)
    output = root / "artifacts" / "review_sha256_checkout_audit" / (
        "current_source_review_deltas_" +
        datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") +
        "_" + head[:12])
    totals = build(root, audit_path, unique_pin_file, output)

    # Independent review approvals are not inferred from passing author-side
    # tests, recovered historical SHA256, or unsigned diff dossiers.
    print("SOURCE_REVIEW_EXACT_GIT_HEAD=", head, sep="")
    print("SOURCE_REVIEW_ORIGINAL_AUDIT=", live_csv, sep="")
    print("SOURCE_REVIEW_HISTORY_PER_CONTRACT=", history_contracts, sep="")
    print("SOURCE_REVIEW_CURRENT_WORKLIST=", output / "contracts_to_revalidate.csv", sep="")
    print("SOURCE_REVIEW_CHANGED_PROOFS=", output / "changed_evidence_versions.csv", sep="")
    print("SOURCE_REVIEW_EVIDENCE_REFERENCES_STALE=",
          status["FAIL_STALE_PIN_VERSUS_GIT_HEAD"], sep="")
    print("SOURCE_REVIEW_WORKLIST_STATUS=GENERATED_PENDING_SIX_DOMAIN_AUTHOR_REVIEW")
    print("SOURCE_REVIEW_INDEPENDENT_CERTIFICATION=FALSE")
    return {"head": head, "pending": totals["contracts_requiring_revalidation"],
            "output": output}


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    try:
        run(repo)
    except Exception as error:
        print("SOURCE_REVIEW_WORKLIST_ERROR=" + str(error), file=sys.stderr)
        print("INDEPENDENT_CERTIFICATION=FALSE", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
