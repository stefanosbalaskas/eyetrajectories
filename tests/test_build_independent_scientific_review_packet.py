"""External review casebook must never turn developer cases into approval."""
import csv
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import source_gap_inventory as inventory
import summarize_scientific_source_evidence as evidence
import build_independent_scientific_review_packet as packet


HEAD = "a" * 40


class IndependentReviewPacketTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        original = Path(__file__).resolve().parents[1] / "inst" / "extdata"
        target = self.root / "inst" / "extdata"
        target.mkdir(parents=True)
        for name in ("native_source_contract_gaps_stage22.csv",
                     "native_nonfunction_source_gaps_v1.csv",
                     "python_api_2026-10-25.csv"):
            shutil.copyfile(original / name, target / name)
        self.reports = self.root / "artifacts" / "native_batch_numeric_diff" / (
            HEAD[:12])
        self.reports.mkdir(parents=True)
        cases = [
            ("bounded_numeric", "functional_trapezoid_weights",
             "grid_positive"),
            ("generalized_functional_gee",
             "fit_generalized_function_on_scalar_regression", "poisson"),
            ("generalized_gee_bootstrap",
             "bootstrap_generalized_function_on_scalar_coefficients",
             "grouped"),
        ]
        for kind, function, fixture in cases:
            row = dict(
                python_name=function,
                source_fixture=fixture,
                field="observed_numeric",
                outcome="PASS_NUMERIC",
                r_git_head=HEAD,
                frozen_python_commit=inventory.FROZEN_PYTHON)
            filename = evidence.REPORTS[kind]
            with (self.reports / filename).open(
                    "w", encoding="utf-8", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(row))
                writer.writeheader()
                writer.writerow(row)

    def tearDown(self):
        self.temporary.cleanup()

    def test_real_gaps_generate_unsigned_external_review_pending_items(self):
        result = packet.run(self.root, HEAD, min_cases=1, write=True)
        self.assertEqual(result["independent_approvals"], 0)
        self.assertEqual(result["status"],
                         "UNSIGNED_PRE_REVIEW_NOT_AN_ATTESTATION")
        self.assertGreaterEqual(len(result["candidates"]), 1)
        self.assertTrue(all(item["current_source_gap"] == "OPEN"
                            for item in result["candidates"]))
        self.assertTrue(all(not item["independently_certified"]
                            for item in result["candidates"]))
        self.assertTrue(all(item["external_reviewer_decision"] ==
                            "NO_SIGNED_DECISION"
                            for item in result["candidates"]))
        out = self.root / "artifacts" / "independent_scientific_review" / (
            HEAD[:12])
        self.assertTrue((out / "reviewer_casebook_PENDING.md").exists())
        self.assertTrue((out / "pending_contract_review_UNSIGNED.json").exists())

    def test_stale_report_does_not_create_a_reviewer_packet(self):
        file = self.reports / evidence.REPORTS["bounded_numeric"]
        content = file.read_text(encoding="utf-8")
        file.write_text(content.replace(HEAD, "b" * 40),
                        encoding="utf-8")
        with self.assertRaises(evidence.EvidenceAuditError):
            packet.run(self.root, HEAD, write=True)

    def test_selection_parameters_have_valid_positive_bounds(self):
        with self.assertRaises(ValueError):
            packet.run(self.root, HEAD, min_cases=0, write=False)
        with self.assertRaises(ValueError):
            packet.run(self.root, HEAD, max_functions=0, write=False)


if __name__ == "__main__":
    unittest.main()
