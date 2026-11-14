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
        # Unit fixtures deliberately begin from the immutable two legacy
        # closures. Real subsequently reviewed receipts are validated at
        # the checked-out repository root in test_ledger_uses_active_count.
        witness = folder / "native_source_contract_gaps_stage22.csv"
        with witness.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            fields, rows = reader.fieldnames, list(reader)
        for row in rows:
            if row["python_name"] not in ledger.CLOSED_SEMANTIC_SCOPE:
                row["unresolved_source_gap"] = "TRUE"
        with witness.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        # Keep the isolated test baseline's one historical nonfunction
        # unresolved; otherwise a future live closure without copied
        # production review files could contaminate negative unit tests.
        other = folder / "native_nonfunction_source_gaps_v1.csv"
        with other.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            nf_fields, nf_rows = reader.fieldnames, list(reader)
        for row in nf_rows:
            row["unresolved"] = "TRUE"
        with other.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=nf_fields)
            writer.writeheader()
            writer.writerows(nf_rows)
        receipt = folder / "reviewed_source_contract_closures_v1.csv"
        receipt.write_text(",".join(ledger.REVIEWED_FIELDS) + "\n",
                           encoding="utf-8")

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
        result = ledger.read_inventory(self.base)
        self.assertEqual(result.historical_callable, 203)
        self.assertEqual(result.active_callable + len(result.resolved_semantic),
                         result.historical_callable)
        self.assertEqual(result.historical_nonfunction, 1)
        self.assertIn(result.active_nonfunction, (0, 1))
        self.assertEqual(result.no_recorded_gap_exports + result.open_total, 508)

    def test_pre_receipt_legacy_closure_rejects_missing_frozen_witness(self):
        self._replace_row(
            "sparse_fpca_score_frame",
            {"unresolved_source_gap": "FALSE",
             "source_witness": "unverified native-only example"})
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError,
                "Legacy pre-receipt developer closure witness"):
            ledger.read_inventory(self.root)

    def test_pre_receipt_exception_cannot_extend_to_new_export(self):
        self._replace_row(
            "functional_trapezoid_weights",
            {"unresolved_source_gap": "FALSE",
             "source_witness": (
                 "Frozen Python " + ledger.FROZEN_PYTHON +
                 " tests/testthat/test-native-trapezoid-full-source-closure.R")})
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "Unreviewed/forged"):
            ledger.read_inventory(self.root)

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

    def _add_reviewed_full_contract_fixture(self, name, *, scoped=False):
        """Synthetic-only receipt, full or explicitly limited author scope."""
        code = self.root / "R" / "reviewed-native-implementation.R"
        code.parent.mkdir(parents=True, exist_ok=True)
        candidate = ("etr_trajectory_set" if name == "TrajectorySet"
                     else "etr_alr_transform")
        code.write_text(candidate + " <- function(x) x\n",
                        encoding="utf-8")
        native_sha = hashlib.sha256(code.read_bytes()).hexdigest()
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
            "scope": ("SCOPED_TEST_NATIVE_REVIEW" if scoped
                      else "FULL_SOURCE_CONTRACT"),
            "author_decision": ("SCOPED_CONTRACT_REVIEWED" if scoped
                                else "FULL_CONTRACT_REVIEWED"),
            "independently_certified": False,
            "language_specific_limits": ([
                "Synthetic limited R source review cannot establish complete "
                "Python optimizer semantics or independent certification."
            ] if scoped else []),
            "native_files": [{
                "path": "R/reviewed-native-implementation.R",
                "sha256": native_sha,
            }],
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
                "author_full_contract_decision": (
                    "AUTHOR_SCOPED_CONTRACT_REVIEWED" if scoped
                    else "AUTHOR_FULL_CONTRACT_REVIEWED"),
                "independently_certified": "FALSE",
            })
        if name == "TrajectorySet":
            self._replace_nonfunction_flag("FALSE")
        else:
            self._replace_row(name, {"unresolved_source_gap": "FALSE"})
        return proof, record, receipt

    def _replace_nonfunction_flag(self, value):
        path = self.root / "inst" / "extdata" / (
            "native_nonfunction_source_gaps_v1.csv")
        with path.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            fields, rows = reader.fieldnames, list(reader)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["python_name"], "TrajectorySet")
        rows[0]["unresolved"] = value
        with path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)

    def test_nonfunction_never_closes_with_bare_csv_flag(self):
        self._replace_nonfunction_flag("FALSE")
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "Unreviewed/forged"):
            ledger.read_inventory(self.root)

    def test_future_nonfunction_review_receipt_uses_same_source_gate(self):
        self._add_reviewed_full_contract_fixture("TrajectorySet")
        stats = ledger.read_inventory(self.root)
        self.assertEqual(stats.active_nonfunction, 0)
        self.assertEqual(stats.open_total, stats.active_callable)
        self.assertEqual(stats.no_recorded_gap_exports, 508 -
                         stats.active_callable)
        # Synthetic test only: no production nonfunction gap was closed.

    def test_test_only_full_contract_receipt_allows_nonlegacy_gap_count_to_change(self):
        self._add_reviewed_full_contract_fixture("alr_transform")
        result = ledger.read_inventory(self.root)
        self.assertEqual(result.active_callable, 200)
        self.assertEqual(result.open_total, 201)
        self.assertIn("alr_transform", result.resolved_semantic)
        # No independent sign-off was produced by developer review.

    def test_exact_scope_limited_author_review_is_allowed_but_not_full_parity(self):
        # Existing production registry has separately authored full and scoped
        # source records. This synthetic case must validate author-side SHA256,
        # not claim Python optimizer or independent source equivalence.
        self._add_reviewed_full_contract_fixture("alr_transform", scoped=True)
        result = ledger.read_inventory(self.root)
        self.assertIn("alr_transform", result.resolved_semantic)
        self.assertEqual(result.active_callable, 200)
        with (self.root / "inst/extdata/reviewed_source_contract_closures_v1.csv").open(
                newline="", encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(rows[0]["author_full_contract_decision"],
                         "AUTHOR_SCOPED_CONTRACT_REVIEWED")
        self.assertEqual(rows[0]["independently_certified"], "FALSE")

    def test_scoped_receipt_cannot_be_relabelled_as_full_source_parity(self):
        _, record, receipt = self._add_reviewed_full_contract_fixture(
            "alr_transform", scoped=True)
        payload = json.loads(record.read_text(encoding="utf-8"))
        payload["scope"] = "FULL_SOURCE_CONTRACT"
        record.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        with receipt.open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream)
            fields, rows = reader.fieldnames, list(reader)
        rows[0]["review_record_sha256"] = hashlib.sha256(
            record.read_bytes()).hexdigest()
        with receipt.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "misclassified full versus scoped"):
            ledger.read_inventory(self.root)

    def test_scoped_receipt_requires_explicit_native_language_limits(self):
        _, record, receipt = self._add_reviewed_full_contract_fixture(
            "alr_transform", scoped=True)
        payload = json.loads(record.read_text(encoding="utf-8"))
        payload["language_specific_limits"] = []
        record.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        with receipt.open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream)
            fields, rows = reader.fieldnames, list(reader)
        rows[0]["review_record_sha256"] = hashlib.sha256(
            record.read_bytes()).hexdigest()
        with receipt.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        with self.assertRaisesRegex(ledger.SourceGapInventoryError,
                                    "misclassified full versus scoped"):
            ledger.read_inventory(self.root)

    def test_review_record_digest_tampering_blocks_closure(self):
        _, record, _ = self._add_reviewed_full_contract_fixture(
            "alr_transform")
        record.write_text(record.read_text(encoding="utf-8") + "\n",
                          encoding="utf-8")
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError, "Wrong digest"):
            ledger.read_inventory(self.root)

    def test_changed_native_algorithm_invalidates_reviewed_closure(self):
        self._add_reviewed_full_contract_fixture("alr_transform")
        code = self.root / "R" / "reviewed-native-implementation.R"
        code.write_text(code.read_text(encoding="utf-8") +
                        "# changed implementation\n", encoding="utf-8")
        with self.assertRaisesRegex(
                ledger.SourceGapInventoryError,
                "Native implementation changed"):
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
