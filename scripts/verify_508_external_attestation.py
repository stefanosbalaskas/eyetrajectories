#!/usr/bin/env python3
"""Check third-party GPG-signed 508-wave scientific review CSV submissions.

READ ONLY. Structural/cryptographic acceptance does NOT itself certify scientific
correctness, reviewer independence, or any source-contract equivalence. Never
auto-edit authoritative certification registers or increase the 0/508 count.

Use the author's immutable unsigned packet and reviewer-created, separately
signed COPIES of the case checklist and decisions. Trust the reviewer's GPG
fingerprint ONLY after verifying it out of band.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

import verify_508_certification_batch as base

HEX40 = re.compile(r"[0-9a-fA-F]{40}\Z")
DECISIONS_ALLOWED = frozenset((
    "FULL_SOURCE_PARITY", "RESTRICTED_SUBSET_MATCH", "NOT_EQUIVALENT"
))
REQUIRED_DECISION_TRUE = (
    "reviewer_independent_of_implementation_team",
    "reviewer_python_replay_pass",
    "reviewer_r_replay_pass",
    "complete_input_error_schema_review_pass",
    "scientific_estimand_review_pass",
    "all_source_gaps_resolved_after_review",
)
SIGNED_TEXT = (
    "reviewer_name", "reviewer_affiliation", "reviewer_contact",
    "reviewer_signed_evidence_reference", "reviewer_signed_utc"
)


def verify_signature(path: Path, detached: Path, fingerprint: str) -> None:
    base.check(path.is_file() and detached.is_file() and
               not path.is_symlink() and not detached.is_symlink(),
               f"Missing or symlinked GPG-signed review files: {path.name}")
    gpg = shutil.which("gpg")
    base.check(bool(gpg), "GPG is required for detached signature verification")
    proc = subprocess.run(
        [gpg, "--batch", "--no-tty", "--status-fd=1",
         "--verify", str(detached), str(path)],
        capture_output=True, text=True, check=False,
    )
    base.check(proc.returncode == 0, f"Detached signature failed: {path.name}")
    valid = re.findall(
        r"(?m)^\[GNUPG:\] VALIDSIG ([0-9A-Fa-f]{40})(?:\s|$)",
        proc.stdout,
    )
    base.check(len(valid) == 1 and
               valid[0].upper() == fingerprint.upper(),
               f"Signer fingerprint not independently trusted for: {path.name}")


def verify_submission(packet_dir: str | Path, completed_cases: str | Path,
                      completed_decisions: str | Path, cases_signature: str | Path,
                      decisions_signature: str | Path,
                      expected_r_head: str, trusted_fingerprint: str
                      ) -> dict[str, object]:
    base.check(HEX40.fullmatch(trusted_fingerprint) is not None,
               "Trusted GPG fingerprint must be a full 40-hex value")
    # Require separately supplied exact native R HEAD for third-party receipts.
    base.check(base.HEX40.fullmatch(expected_r_head) is not None,
               "Expected native R commit must be a 40-hex value")
    original = base.verify(packet_dir, expected_r_head=expected_r_head)
    root = Path(packet_dir).resolve(strict=True)
    case_path = Path(completed_cases).resolve(strict=True)
    decision_path = Path(completed_decisions).resolve(strict=True)
    sig_case = Path(cases_signature).resolve(strict=True)
    sig_decision = Path(decisions_signature).resolve(strict=True)
    base.check(case_path != root / base.FILES[2] and
               decision_path != root / base.FILES[3],
               "Reviewers must sign separate completed copies, not original blanks")
    verify_signature(case_path, sig_case, trusted_fingerprint)
    verify_signature(decision_path, sig_decision, trusted_fingerprint)

    unsigned_cases = base.read_csv(root / base.FILES[2])
    unsigned_decisions = base.read_csv(root / base.FILES[3])
    submitted_cases = base.read_csv(case_path)
    decisions = base.read_csv(decision_path)
    base.columns(decisions, tuple(unsigned_decisions[0]), "signed decisions")
    base.columns(submitted_cases, tuple(unsigned_cases[0]), "signed cases")
    allowed = {base.key(row) for row in unsigned_decisions}
    selected = {base.key(row) for row in decisions}
    base.check(0 < len(decisions) <= 36 and len(selected) == len(decisions) and
               selected.issubset(allowed),
               "Signed decisions contain duplicates or unknown exports")
    base.check(len(submitted_cases) == 10 * len(decisions),
               "Every signed export needs all ten independent case reviews")
    case_keys = [(base.key(row), row["criterion"]) for row in submitted_cases]
    base.check(len(set(case_keys)) == len(case_keys) and
               set(case_keys) == {(key, item)
                   for key in selected for item in base.CRITERIA},
               "Signed case submission missing independent review criteria")
    frozen_decisions = {base.key(row): row for row in unsigned_decisions}
    frozen_cases = {(base.key(row), row["criterion"]): row
                    for row in unsigned_cases}
    for row in decisions:
        orig = frozen_decisions[base.key(row)]
        for name in ("namespace", "python_name", "kind",
                     "native_r_candidate", "recorded_r_git_head",
                     "frozen_python_commit"):
            base.check(row[name] == orig[name],
                       f"Modified reviewed contract identity: {name}")
        base.check(row["scope_decision"] in DECISIONS_ALLOWED,
                   "Invalid signed review scientific scope decision")
        base.check(all(row[name].strip() for name in SIGNED_TEXT),
                   "Signed decisions lack identity, explanation, or UTC time")
        for name in REQUIRED_DECISION_TRUE + ("full_domain_certification_approved",):
            base.check(row[name] in {"TRUE", "FALSE"},
                       f"Nonboolean decision in {name}")
        base.check(row["reviewer_independent_of_implementation_team"] == "TRUE",
                   "Signed independent review must declare reviewer independence")
        full = row["scope_decision"] == "FULL_SOURCE_PARITY"
        # Even a genuinely GPG-signed CSV is NOT the final project approval.
        # The completed template may request a FULL parity finding but cannot
        # itself authorize the authoritative approval flag.
        base.check(row["full_domain_certification_approved"] == "FALSE",
                   "Reviewer cannot self-promote authoritative full certification")
        if full:
            base.check(all(row[name] == "TRUE" for name in REQUIRED_DECISION_TRUE),
                       "FULL_SOURCE_PARITY request lacks complete reviewer gates")

    full_keys = {base.key(row) for row in decisions
                 if row["scope_decision"] == "FULL_SOURCE_PARITY"}
    for row in submitted_cases:
        orig = frozen_cases[(base.key(row), row["criterion"])]
        for name in ("namespace", "python_name", "kind", "native_r_candidate",
                     "recorded_r_git_head", "frozen_python_commit", "criterion"):
            base.check(row[name] == orig[name],
                       "Signed case changes original source identity or requirement")
        for name in ("reviewer_case_passed", "independently_replayed",
                     "full_domain_approved"):
            base.check(row[name] in {"TRUE", "FALSE"},
                       f"Malformed signed scientific-case flag: {name}")
        base.check(row["reviewer_created_evidence_reference"].strip() and
                   row["reviewer_written_findings"].strip(),
                   "Every signed case requires independent evidence and findings")
        base.check(row["independently_replayed"] == "TRUE",
                   "Every signed case must be independently reviewed/replayed")
        if base.key(row) in full_keys:
            base.check(all(row[name] == "TRUE" for name in
                           ("reviewer_case_passed", "independently_replayed",
                            "full_domain_approved")),
                       "FULL_SOURCE_PARITY lacks independent ten-case review")

    return {
        "result": "GPG SIGNATURES VALID; external REVIEW RECEIVED, not certified",
        "reviewed_native_r_head": original["r_git_head"],
        "frozen_python_commit": base.FROZEN_PYTHON,
        "signed_exports_reviewed": len(decisions),
        "reviewer_full_source_parity_findings": len(full_keys),
        "reviewer_restricted_or_non_equivalent_findings":
            len(decisions) - len(full_keys),
        "authoritative_certification_updates": 0,
        "full_domain_certifications_automatically_promoted": 0,
        "trusted_reviewer_signer_fingerprint": trusted_fingerprint.upper(),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("packet_dir")
    p.add_argument("completed_cases")
    p.add_argument("completed_decisions")
    p.add_argument("cases_detached_signature")
    p.add_argument("decisions_detached_signature")
    p.add_argument("--expected-r-head", required=True)
    p.add_argument("--trusted-fingerprint", required=True)
    args = p.parse_args(argv)
    try:
        result = verify_submission(args.packet_dir, args.completed_cases,
            args.completed_decisions, args.cases_detached_signature,
            args.decisions_detached_signature,
            args.expected_r_head, args.trusted_fingerprint)
    except (base.ReviewBatchError, OSError, UnicodeError) as exc:
        print(f"REVIEW RECEIPT FAILED: {exc}", file=sys.stderr)
        return 1
    for k, value in result.items():
        print(f"{k}: {value}")
    print("Human independence, signed findings and scientific claims STILL "
          "need external review; no approval registry modified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
