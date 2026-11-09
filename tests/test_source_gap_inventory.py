"""Regression guards for the single frozen Python 1.2 source-gap counter."""
import csv
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
                     "native_nonfunction_source_gaps_v1.csv"):
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
