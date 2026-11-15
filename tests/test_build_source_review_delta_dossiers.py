"""Git-backed structural tests of unsigned scientific review delta dossiers."""
from __future__ import annotations

import csv
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import build_source_review_delta_dossiers as delta


class ReviewDeltaDossierTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.git("init")
        self.git("config", "user.email", "author@example.invalid")
        self.git("config", "user.name", "Author only")
        (self.root / "R").mkdir()
        self.path = "R/method.R"
        old = b"method <- function(x) x + 1\n"
        new = b"method <- function(x) x + 2\n"
        (self.root / self.path).write_bytes(old)
        self.git("add", "R/method.R")
        self.git("commit", "-m", "historical author review")
        self.old_head = self.git("rev-parse", "HEAD").strip()
        (self.root / self.path).write_bytes(new)
        self.git("add", "R/method.R")
        self.git("commit", "-m", "changed estimator")
        self.old_hash = hashlib.sha256(old).hexdigest()
        self.new_hash = hashlib.sha256(new).hexdigest()
        self.audit = self.root / "audit.csv"
        self.history = self.root / "history.csv"
        self.output = self.root / "output"
        self.write_inputs()

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        r = subprocess.run(["git", "-C", str(self.root), *args],
            capture_output=True, text=True, check=False)
        self.assertEqual(r.returncode, 0, r.stderr)
        return r.stdout

    @staticmethod
    def write(path, rows):
        with path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)

    def write_inputs(self, override_hash=None):
        self.write(self.audit, [
            dict(path=self.path, pinned_sha256=self.old_hash,
                 python_name="model_a", verdict="FAIL_PIN_MISMATCH"),
            dict(path=self.path, pinned_sha256=self.old_hash,
                 python_name="model_b", verdict="FAIL_PIN_MISMATCH"),
        ])
        self.write(self.history, [
            dict(path=self.path, pinned_sha256=self.old_hash,
                 status="HISTORICAL_PIN_CURRENT_SOURCE_CHANGED",
                 current_head_sha256=override_hash or self.new_hash,
                 source_commit_with_pinned_bytes=self.old_head,
                 contract_names="model_a | model_b")
        ])

    def test_unchanged_pins_are_not_reissued_as_approvals(self):
        totals = delta.build(self.root, self.audit, self.history, self.output)
        self.assertEqual(totals["historical_path_sha256_pairs"], 1)
        self.assertEqual(totals["distinct_changed_paths"], 1)
        self.assertEqual(totals["contracts_requiring_revalidation"], 2)
        self.assertEqual(totals["source_or_namespace_changed_contracts"], 2)
        with (self.output / "contracts_to_revalidate.csv").open(
                newline="", encoding="utf-8") as stream:
            records = list(csv.DictReader(stream))
        self.assertEqual({x["python_name"] for x in records},
                         {"model_a", "model_b"})
        self.assertTrue(all(x["priority"] == "P1_PRODUCTION_SCIENCE"
                            for x in records))
        self.assertTrue(all(x["independent_certification"] == "FALSE"
                            for x in records))
        with (self.output / "changed_evidence_versions.csv").open(
                newline="", encoding="utf-8") as stream:
            versions = list(csv.DictReader(stream))
        self.assertEqual(len(versions), 1)
        self.assertEqual(versions[0]["pinned_sha256"], self.old_hash)
        patch = self.output / versions[0]["unified_diff"]
        self.assertTrue(patch.exists())
        content = patch.read_text(encoding="utf-8")
        self.assertIn("-method <- function(x) x + 1", content)
        self.assertIn("+method <- function(x) x + 2", content)
        self.assertTrue((self.output / "README.txt").read_text(
                            encoding="utf-8").startswith("UNSIGNED"))

    def test_changed_source_without_audited_current_digest_fails(self):
        self.write_inputs(override_hash="f" * 64)
        with self.assertRaisesRegex(ValueError, "not the SHA256-audited"):
            delta.build(self.root, self.audit, self.history, self.output)
        self.assertFalse(self.output.exists())

    def test_invalid_path_is_rejected(self):
        self.assertRaisesRegex(
            ValueError, "Unsafe", delta.checked_path, "../outside.R")


if __name__ == "__main__":
    unittest.main()
