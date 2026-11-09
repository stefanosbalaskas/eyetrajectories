"""32-function source implementation wave is unsigned, bounded and ordered."""
import csv
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
            self.assertEqual(gaps[name]["unresolved_source_gap"], "TRUE")
            self.assertTrue(gaps[name]["native_r_candidate"])
            self.assertNotIn("plot_", name)
            self.assertNotIn("reporting_text", name)

    def test_writer_creates_only_unsigned_author_scientific_queue(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            folder = root / "inst" / "extdata"
            folder.mkdir(parents=True)
            for name in ("native_source_contract_gaps_stage22.csv",
                         "native_nonfunction_source_gaps_v1.csv"):
                shutil.copy2(self.root / "inst" / "extdata" / name,
                             folder / name)
            out = root / "output" / "wave.csv"
            self.assertEqual(wave.write_queue(root, out), out)
            with out.open(encoding="utf-8", newline="") as f:
                rows = list(csv.DictReader(f))
            self.assertEqual(len(rows), 32)
            self.assertTrue(all(r["full_domain_case_status"] ==
                                "PENDING_SOURCE_FIXTURE" for r in rows))
            self.assertTrue(all(r["numerical_algorithm_certified"] ==
                                "FALSE" for r in rows))
            self.assertTrue(all(r["independent_reviewer_approved"] ==
                                "FALSE" for r in rows))
            self.assertTrue(all(r["python_source_commit"] ==
                                source_gap_inventory.FROZEN_PYTHON
                                for r in rows))


if __name__ == "__main__":
    unittest.main()
