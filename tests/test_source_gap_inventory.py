"""Regression guards for the single frozen Python 1.2 source-gap counter."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import source_gap_inventory as ledger


class SourceGapInventoryTests(unittest.TestCase):
    def setUp(self):
        self.base = Path(__file__).resolve().parents[1]
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        folder = self.root / "inst" / "extdata"
        folder.mkdir(parents=True)
        for name in ("native_source_contract_gaps_stage22.csv",
                     "native_nonfunction_source_gaps_v1.csv",
                     "reviewed_source_contract_closures_v1.csv"):
            shutil.copy2(self.base / "inst" / "extdata" / name, folder / name)

    def tearDown(self):
        self.tmp.cleanup()

    def _replace_row(self, needle, updates):
        filename = self.root / "inst" / "extdata" / (
            "native_source_contract_gaps_stage22.csv")
        with filename.open(encoding="utf-8", newline="") as f:
            rd = csv.DictReader(f)
            names, rows = rd.fieldnames, list(rd)
        target = [r for r in rows if r["python_name"] == needle]
        self.assertEqual(len(target), 1)
        target[0].update(updates)
        with filename.open("w", encoding="utf-8", newline="") as f:
            wr = csv.DictWriter(f, fieldnames=names)
            wr.writeheader()
            wr.writerows(rows)

    def test_ledger_uses_active_not_historical_count(self):
        result = ledger.read_inventory(self.root)
        self.assertEqual(result.historical_callable, 203)
        self.assertEqual(result.active_callable + len(result.resolved_semantic),
                         result.historical_callable)
        self.assertEqual(result.historical_nonfunction, 1)
        self.assertEqual(result.active_nonfunction, 1)
        self.assertEqual(result.no_recorded_gap_exports + result.open_total, 508)

    def test_forged_new_close_must_fail(self):
        self._replace_row("alr_transform",
                          {"unresolved_source_gap": "FALSE"})
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "Unreviewed/forged"):
            ledger.read_inventory(self.root)

    def test_existing_closure_missing_replay_witness_must_fail(self):
        self._replace_row("mathematical_contract_frame",
                          {"source_witness": "No direct frozen Python replay"})
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "semantic closure evidence"):
            ledger.read_inventory(self.root)

    def _add_reviewed_full_contract_fixture(self, name):
        """Synthetic *test-only* complete review demonstrates dynamic count."""
        proofdir = self.root / "tests"
        proofdir.mkdir(parents=True, exist_ok=True)
        proof = proofdir / "frozen-source-domain-replay.R"
        proof.write_text("stopifnot(TRUE)\n", encoding="utf-8")
        proof_sha = hashlib.sha256(proof.read_bytes()).hexdigest()
        recorddir = self.root / "docs" / "source_contract_reviews"
        recorddir.mkdir(parents=True, exist_ok=True)
        record = recorddir / (name + ".json")
        record.write_text(json.dumps({
            "audit_version": "source-contract-v1",
            "python_name": name,
            "frozen_python_commit": ledger.FROZEN_PYTHON,
            "scope": "FULL_SOURCE_CONTRACT",
            "author_decision": "FULL_CONTRACT_REVIEWED",
            "independently_certified": False,
            "reviewer_statement": (
                "TEST FIXTURE ONLY: this does not attest or close any "
                "real mathematical source contract or grant certification."),
            "case_evidence": [
                {"kind": kind,
                 "path": "tests/frozen-source-domain-replay.R",
                 "sha256": proof_sha}
                for kind in sorted(ledger.REQUIRED_REVIEW_KINDS)
            ],
        }, indent=2), encoding="utf-8")
        receipt = self.root / "inst" / "extdata" / (
            "reviewed_source_contract_closures_v1.csv")
        with receipt.open("w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file,
                                    fieldnames=ledger.REVIEWED_FIELDS)
            writer.writeheader()
            writer.writerow({
                "python_name": name,
                "frozen_python_commit": ledger.FROZEN_PYTHON,
                "review_record_path":
                    f"docs/source_contract_reviews/{name}.json",
                "review_record_sha256":
                    hashlib.sha256(record.read_bytes()).hexdigest(),
                "author_full_contract_decision":
                    "AUTHOR_FULL_CONTRACT_REVIEWED",
                "independently_certified": "FALSE",
            })
        self._replace_row(name, {"unresolved_source_gap": "FALSE"})
        return proof, record, receipt

    def test_test_only_full_contract_receipt_allows_nonlegacy_gap_count_to_change(self):
        self._add_reviewed_full_contract_fixture("alr_transform")
        result = ledger.read_inventory(self.root)
        self.assertEqual(result.active_callable, 200)
        self.assertEqual(result.open_total, 201)
        self.assertIn("alr_transform", result.resolved_semantic)
        # No independent sign-off was produced by developer review.

    def test_review_record_digest_tampering_blocks_closure(self):
        _, record, _ = self._add_reviewed_full_contract_fixture(
            "alr_transform")
        record.write_text(record.read_text(encoding="utf-8") + "\n",
                          encoding="utf-8")
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "Wrong digest"):
            ledger.read_inventory(self.root)

    def test_missing_source_test_breaks_review_receipt(self):
        proof, _, _ = self._add_reviewed_full_contract_fixture(
            "alr_transform")
        proof.unlink()
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "Missing/symlinked"):
            ledger.read_inventory(self.root)

    def test_author_receipt_cannot_claim_independent_certification(self):
        _, _, receipt = self._add_reviewed_full_contract_fixture(
            "alr_transform")
        text = receipt.read_text(encoding="utf-8")
        receipt.write_text(text.replace(
            "AUTHOR_FULL_CONTRACT_REVIEWED,FALSE",
            "AUTHOR_FULL_CONTRACT_REVIEWED,TRUE"), encoding="utf-8")
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "forged independent"):
            ledger.read_inventory(self.root)

    def test_receipt_cannot_exist_for_still_open_source_gap(self):
        self._add_reviewed_full_contract_fixture("alr_transform")
        self._replace_row("alr_transform",
                          {"unresolved_source_gap": "TRUE"})
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "remains open"):
            ledger.read_inventory(self.root)

    def test_nonboolean_flag_must_fail(self):
        self._replace_row("inverse_alr",
                          {"unresolved_source_gap": "yes"})
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "Non-boolean"):
            ledger.read_inventory(self.root)

    def test_symlinked_source_must_fail(self):
        source = self.root / "inst" / "extdata" / (
            "native_source_contract_gaps_stage22.csv")
        copied = self.root / "source-copy.csv"
        source.rename(copied)
        try:
            source.symlink_to(copied)
        except (OSError, NotImplementedError):
            self.skipTest("Symlink not available")
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "symlinked"):
            ledger.read_inventory(self.root)

    def test_duplicate_historical_row_must_fail(self):
        path = self.root / "inst" / "extdata" / (
            "native_source_contract_gaps_stage22.csv")
        lines = path.read_text(encoding="utf-8").splitlines()
        path.write_text("\n".join(lines + [lines[-1]]) + "\n",
                        encoding="utf-8")
        with self.assertRaises(ledger.SourceGapInventoryError):
            ledger.read_inventory(self.root)


if __name__ == "__main__":
    unittest.main()
