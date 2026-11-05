#!/usr/bin/env python3
"""Read-only GPG receipt for third-party findings on any 508-export wave.

Receipt validity NEVER changes the official 0/508 approval register.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import re
import sys

import build_508_all_export_review_waves as waves
import verify_508_external_attestation as original

TRUE = {"TRUE", "FALSE"}
FULL_GATES = (
    "reviewer_independent_of_implementation_team",
    "reviewer_python_replay_pass", "reviewer_r_replay_pass",
    "complete_input_error_schema_review_pass",
    "scientific_estimand_review_pass",
    "all_source_gaps_resolved_after_review",
)
DECISIONS = {"FULL_SOURCE_PARITY", "RESTRICTED_SUBSET_MATCH",
             "NOT_EQUIVALENT"}
SIGNED_TEXT = ("reviewer_name","reviewer_affiliation","reviewer_contact",
               "reviewer_signed_evidence_reference","reviewer_signed_utc")
CHECK_TEXT = ("reviewer_created_evidence_reference", "reviewer_written_findings")


def check(value, reason):
    waves.check(value,reason)


def receipt(packet_dir: str | Path, wave: int, cases: str | Path,
            decisions: str | Path, cases_signature: str | Path,
            decisions_signature: str | Path, head: str,
            trusted_fingerprint: str):
    check(re.fullmatch("[0-9A-Fa-f]{40}", trusted_fingerprint) is not None,
          "A separately verified complete 40-hex GPG fingerprint is mandatory")
    waves.verify(packet_dir,head)
    check(1 <= wave <= 15, "Unknown wave number")
    root=Path(packet_dir).resolve(strict=True)
    wave_dir=root/waves.DIRECTORY/f"wave_{wave:02d}"
    unsigned_cases=waves.baseline.read_csv(wave_dir/waves.FILES[1])
    unsigned_decisions=waves.baseline.read_csv(wave_dir/waves.FILES[2])
    contracts=waves.baseline.read_csv(wave_dir/waves.FILES[0])
    originals={waves.baseline.key(row):row for row in unsigned_decisions}
    contracted={waves.baseline.key(row):row for row in contracts}
    signed_case_path=Path(cases).absolute()
    signed_decision_path=Path(decisions).absolute()
    check(signed_case_path != wave_dir/waves.FILES[1] and
          signed_decision_path != wave_dir/waves.FILES[2],
          "Signer cannot change immutable unsigned templates")
    original.verify_signature(signed_case_path,Path(cases_signature).absolute(),
                              trusted_fingerprint)
    original.verify_signature(signed_decision_path,
                              Path(decisions_signature).absolute(),
                              trusted_fingerprint)
    completed=waves.baseline.read_csv(signed_case_path)
    submitted=waves.baseline.read_csv(signed_decision_path)
    check(1 <= len(submitted) <= len(originals) and
          len({waves.baseline.key(row) for row in submitted}) == len(submitted),
          "Reviewed exports missing, duplicated, or oversized")
    waves.baseline.columns(completed,tuple(unsigned_cases[0]),"signed wave cases")
    waves.baseline.columns(submitted,tuple(unsigned_decisions[0]),"signed wave decisions")
    selected={waves.baseline.key(row) for row in submitted}
    check(selected.issubset(originals),"Signed decisions include unknown export")
    check(len(completed)==len(submitted)*len(waves.baseline.CRITERIA),
          "Each export needs ten reviewed criteria")
    keys={(waves.baseline.key(row),row["criterion"]) for row in completed}
    check(len(keys)==len(completed) and
          keys=={(identity,criterion) for identity in selected
                 for criterion in waves.baseline.CRITERIA},
          "Missing or duplicate export-specific criteria")
    original_cases={(waves.baseline.key(row),row["criterion"]):row
                    for row in unsigned_cases}
    full=set()
    for row in submitted:
        identity=waves.baseline.key(row)
        expected=originals[identity]
        for column in waves.IDENTITY:
            check(row[column] == expected[column],
                  "Signed source identity modified: "+column)
        check(row["scope_decision"] in DECISIONS,
              "Unsupported signed scientific verdict")
        for field in SIGNED_TEXT:
            check(bool(row[field].strip()),"Missing reviewer identity/time/evidence "+field)
        check(all(row[f] in TRUE for f in FULL_GATES+
              ("full_domain_certification_approved",)),
              "Invalid signed boolean")
        check(row["reviewer_independent_of_implementation_team"]=="TRUE",
              "Actual external reviewer must attest to independence")
        check(row["full_domain_certification_approved"]=="FALSE",
              "Receipt cannot promote authoritative 508 count")
        if row["scope_decision"]=="FULL_SOURCE_PARITY":
            check(contracted[identity]["review_blocker"] ==
                  "INDEPENDENT_SOURCE_AND_SCIENTIFIC_REVIEW_MISSING",
                  "Full parity not allowed with known gap/backend/native missing")
            check(all(row[f]=="TRUE" for f in FULL_GATES),
                  "Full parity requires all reviewer replay/scientific gates")
            full.add(identity)
    for row in completed:
        key=(waves.baseline.key(row),row["criterion"])
        orig=original_cases[key]
        for field in waves.IDENTITY+("criterion",):
            check(row[field]==orig[field],
                  "Review case source identity modified: "+field)
        check(all(row[f] in TRUE for f in waves.CASE_FLAGS)
              if hasattr(waves,"CASE_FLAGS") else
              all(row[f] in TRUE for f in ("reviewer_case_passed",
                 "independently_replayed","full_domain_approved")),
              "Invalid signed per-case boolean")
        check(all(row[f].strip() for f in CHECK_TEXT),
              "Independent case findings/evidence missing")
        check(row["independently_replayed"]=="TRUE",
              "Independently reviewed/replayed case required")
        if waves.baseline.key(row) in full:
            check(row["reviewer_case_passed"]=="TRUE" and
                  row["full_domain_approved"]=="TRUE",
                  "FULL_SOURCE_PARITY lacks complete cases")
    return {
        "gpg_signatures":"VERIFIED_USING_OUT_OF_BAND_TRUSTED_FINGERPRINT",
        "wave":wave, "signed_exports_reviewed":len(submitted),
        "full_source_parity_findings":len(full),
        "restricted_or_non_equivalent_findings":len(submitted)-len(full),
        "automatically_certified_exports":0, "authoritative_register_modified":False,
        "human_scientific_adjudication":"STILL_REQUIRED",
    }


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet_dir")
    parser.add_argument("--wave",type=int,required=True)
    parser.add_argument("--cases",required=True)
    parser.add_argument("--decisions",required=True)
    parser.add_argument("--cases-signature",required=True)
    parser.add_argument("--decisions-signature",required=True)
    parser.add_argument("--expected-r-head",required=True)
    parser.add_argument("--trusted-fingerprint",required=True)
    args=parser.parse_args(argv)
    try:
        result=receipt(args.packet_dir,args.wave,args.cases,args.decisions,
                       args.cases_signature,args.decisions_signature,
                       args.expected_r_head,args.trusted_fingerprint)
    except (waves.baseline.ReviewBatchError,OSError,ValueError,
            KeyError,csv.Error) as exc:
        print("INDEPENDENT_WAVE_RECEIPT_REJECTED: "+str(exc),file=sys.stderr)
        return 1
    for k,v in result.items():
        print(f"{k}={v}")
    print("GPG receipts cannot prove reviewer independence/scientific truth or certify 508 contracts")
    return 0


if __name__=="__main__":
    raise SystemExit(main())
