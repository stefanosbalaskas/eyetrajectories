"""32-function source implementation wave is unsigned, bounded and ordered."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import build_accelerated_scientific_wave as wave
import source_gap_inventory


class ConsolidatedScientificWaveTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(__file__).resolve().parents[1]

    def test_32_distinct_functions_all_have_open_historical_witnesses(self):
        ordered = wave.targets()
        self.assertEqual(len(ordered), 32)
        self.assertEqual(len({name for _, name in ordered}), 32)
        with (self.root / "inst" / "extdata" /
              "native_source_contract_gaps_stage22.csv").open(
                  encoding="utf-8", newline="") as f:
            gaps = {row["python_name"]: row
                    for row in csv.DictReader(f)}
        for group, name in ordered:
            self.assertIn(name, gaps)
            self.assertIn(gaps[name]["unresolved_source_gap"],
                          ("TRUE", "FALSE"))
            self.assertTrue(gaps[name]["native_r_candidate"])
            self.assertNotIn("plot_", name)
            self.assertNotIn("reporting_text", name)

    def test_writer_creates_only_unsigned_author_scientific_queue(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            folder = root / "inst" / "extdata"
            folder.mkdir(parents=True)
            # Run against the actual checked-out source registry, so
            # future reviewed closures and their pinned proof files are
            # validated rather than copying receipts without source proofs.
            out = root / "output" / "wave.csv"
            self.assertEqual(wave.write_queue(self.root, out), out)
            with out.open(encoding="utf-8", newline="") as f:
                rows = list(csv.DictReader(f))
            self.assertEqual(len(rows), 32)
            # A source report may already exist for this *same* HEAD on
            # repeated user runs. Bounded passes change the work-phase
            # status, never the certification flags.
            self.assertTrue(all(
                r["full_domain_case_status"] in {
                    "PENDING_SOURCE_FIXTURE",
                    "FINITE_SOURCE_CASES_PASS_NEEDS_FULL_CONTRACT_REVIEW",
                    "REPAIR_RECORDED_PYTHON_NUMERICAL_DIVERGENCE",
                } for r in rows))
            self.assertTrue(all(int(r["matched_finite_source_cases"]) >= 0
                                for r in rows))
            self.assertTrue(all(r["numerical_algorithm_certified"] ==
                                "FALSE" for r in rows))
            self.assertTrue(all(r["independent_reviewer_approved"] ==
                                "FALSE" for r in rows))
            self.assertTrue(all(r["python_source_commit"] ==
                                source_gap_inventory.FROZEN_PYTHON
                                for r in rows))


    def test_queue_backfills_completed_scientific_contracts(self):
        """A reviewed closure must not permanently block the 32-item wave."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ext = root / "inst" / "extdata"
            ext.mkdir(parents=True)
            for name in ("native_source_contract_gaps_stage22.csv",
                         "native_nonfunction_source_gaps_v1.csv",
                         "reviewed_source_contract_closures_v1.csv"):
                shutil.copy2(self.root / "inst" / "extdata" / name,
                             ext / name)
            filename = ext / "native_source_contract_gaps_stage22.csv"
            with filename.open(encoding="utf-8", newline="") as stream:
                reader = csv.DictReader(stream)
                headers, rows = reader.fieldnames, list(reader)
            # A test-only historical baseline isolates queue replenishment
            # from any real future reviewed closures.
            for entry in rows:
                if (entry["python_name"] not in
                        source_gap_inventory.CLOSED_SEMANTIC_SCOPE):
                    entry["unresolved_source_gap"] = "TRUE"
            completed = "run_sparse_prediction_workflow"
            row = next(r for r in rows if r["python_name"] == completed)
            row["unresolved_source_gap"] = "FALSE"
            with filename.open("w", encoding="utf-8", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=headers)
                writer.writeheader()
                writer.writerows(rows)
            proof = root / "tests" / "proof.R"
            proof.parent.mkdir(parents=True)
            proof.write_text("stopifnot(TRUE)\n", encoding="utf-8")
            proof_sha = hashlib.sha256(proof.read_bytes()).hexdigest()
            record = root / "docs" / "source_contract_reviews" / "proof.json"
            record.parent.mkdir(parents=True)
            record.write_text(json.dumps(dict(
                audit_version="source-contract-v1",
                python_name=completed,
                frozen_python_commit=source_gap_inventory.FROZEN_PYTHON,
                scope="FULL_SOURCE_CONTRACT",
                author_decision="FULL_CONTRACT_REVIEWED",
                independently_certified=False,
                reviewer_statement="TEST FIXTURE ONLY: this is not a scientific sign off.",
                case_evidence=[dict(kind=k, path="tests/proof.R",
                                    sha256=proof_sha)
                    for k in sorted(
                        source_gap_inventory.REQUIRED_REVIEW_KINDS)])),
                encoding="utf-8")
            manifest = ext / "reviewed_source_contract_closures_v1.csv"
            with manifest.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream,
                    fieldnames=source_gap_inventory.REVIEWED_FIELDS)
                writer.writeheader()
                writer.writerow(dict(
                    python_name=completed,
                    frozen_python_commit=source_gap_inventory.FROZEN_PYTHON,
                    review_record_path="docs/source_contract_reviews/proof.json",
                    review_record_sha256=hashlib.sha256(
                        record.read_bytes()).hexdigest(),
                    author_full_contract_decision=
                        "AUTHOR_FULL_CONTRACT_REVIEWED",
                    independently_certified="FALSE"))
            output = wave.write_queue(root,
                                      root / "artifacts" / "queue.csv")
            with output.open(newline="", encoding="utf-8") as stream:
                rebuilt = list(csv.DictReader(stream))
            self.assertEqual(len(rebuilt), 32)
            self.assertNotIn(completed,
                             {r["frozen_python_function"] for r in rebuilt})
            self.assertEqual(len({
                r["frozen_python_function"] for r in rebuilt}), 32)
            self.assertTrue(all(r["independent_reviewer_approved"] ==
                                "FALSE" for r in rebuilt))


if __name__ == "__main__":
    unittest.main()
