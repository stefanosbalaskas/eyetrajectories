"""AUTHOR-ONLY fake-review gate tests; mocked GPG never implies a real signer."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import verify_508_certification_batch as base
import verify_508_external_attestation as att
from test_verify_508_certification_batch import (make_packet, write_csv,
                                                 synthetic_gap_counts)


class TestSignedReceiptStructure(unittest.TestCase):
    def setUp(self):
        # Synthetic signed-submission structure tests require their own
        # synthetic gap counts; a real stale author receipt must not prevent
        # testing forged GPG and reviewer-approval safeguards.
        self.count_patch = patch.object(
            base.source_gap_inventory, "read_inventory",
            return_value=synthetic_gap_counts())
        self.count_patch.start()
        self.addCleanup(self.count_patch.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        make_packet(self.root)
        d = base.read_csv(self.root / base.FILES[3])[0]
        c = [r for r in base.read_csv(self.root / base.FILES[2])
             if base.key(r) == base.key(d)]
        d.update(scope_decision="RESTRICTED_SUBSET_MATCH",
            reviewer_name="Synthetic QA reviewer, NOT a real independent signer",
            reviewer_affiliation="Synthetic QA",
            reviewer_contact="synthetic@example.invalid",
            reviewer_independent_of_implementation_team="TRUE",
            reviewer_signed_evidence_reference="synthetic-evidence-do-not-trust",
            reviewer_signed_utc="2026-11-01T12:00:00Z")
        for row in c:
            row["independently_replayed"] = "TRUE"
            row["reviewer_case_passed"] = "TRUE"
            row["reviewer_created_evidence_reference"] = "fake-fixture"
            row["reviewer_written_findings"] = "Synthetic test only"
        self.decisions = [d]
        self.cases = c
        self.case_path = self.root / "synthetic_completed_cases.csv"
        self.decision_path = self.root / "synthetic_completed_decisions.csv"
        self.sig_c = self.root / "not_actually_signed_cases.asc"
        self.sig_d = self.root / "not_actually_signed_decisions.asc"
        self.write_submissions()

    def tearDown(self):
        self.temp.cleanup()

    def write_submissions(self):
        write_csv(self.case_path, self.cases)
        write_csv(self.decision_path, self.decisions)
        # The real validator rejects these absent signatures. Unit tests
        # explicitly mock signature verification ONLY for structure checks.

    def submit_structure(self):
        with patch.object(att, "verify_signature", lambda *args: None):
            return att.verify_submission(self.root, self.case_path,
                self.decision_path, self.sig_c, self.sig_d,
                "a" * 40, "b" * 40)

    def test_unsigned_real_execution_rejects_missing_gpg_signatures(self):
        with self.assertRaisesRegex(base.ReviewBatchError, "Missing or symlinked"):
            att.verify_submission(self.root, self.case_path, self.decision_path,
                self.sig_c, self.sig_d, "a" * 40, "b" * 40)

    def test_synthetic_restricted_decision_not_auto_promoted(self):
        result = self.submit_structure()
        self.assertEqual(result["signed_exports_reviewed"], 1)
        self.assertEqual(result["reviewer_full_source_parity_findings"], 0)
        self.assertEqual(result["authoritative_certification_updates"], 0)

    def test_forged_full_decision_without_complete_gates_rejected(self):
        self.decisions[0]["scope_decision"] = "FULL_SOURCE_PARITY"
        self.write_submissions()
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "lacks complete reviewer gates"):
            self.submit_structure()

    def test_reviewer_cannot_mark_authoritative_approval(self):
        self.decisions[0]["full_domain_certification_approved"] = "TRUE"
        self.write_submissions()
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "cannot self-promote"):
            self.submit_structure()

    def test_signer_fingerprint_must_be_40_hex(self):
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "fingerprint must be"):
            att.verify_submission(self.root, self.case_path, self.decision_path,
                self.sig_c, self.sig_d, "a" * 40, "fake")

    def test_altered_frozen_source_pin_rejected(self):
        self.cases[0]["recorded_r_git_head"] = "0" * 40
        self.write_submissions()
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "changes original source identity"):
            self.submit_structure()

    def test_unreplayed_case_rejected(self):
        self.cases[0]["independently_replayed"] = "FALSE"
        self.write_submissions()
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "must be independently"):
            self.submit_structure()

    def test_full_decision_requires_all_ten_case_approvals(self):
        self.decisions[0]["scope_decision"] = "FULL_SOURCE_PARITY"
        for name in att.REQUIRED_DECISION_TRUE:
            self.decisions[0][name] = "TRUE"
        self.cases[0]["full_domain_approved"] = "FALSE"
        self.write_submissions()
        with self.assertRaisesRegex(base.ReviewBatchError,
                                    "lacks independent ten-case review"):
            self.submit_structure()


if __name__ == "__main__":
    unittest.main()
