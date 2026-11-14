"""Git-backed regression tests for unsigned CURRENT author revalidation queues."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import prepare_current_source_review_queue as queue


def digest(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


class CurrentSourceReviewQueueTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.git("init")
        self.git("config", "user.email", "author@example.invalid")
        self.git("config", "user.name", "Synthetic Reviewer")
        self.git("config", "core.autocrlf", "false")
        for directory in ("R", "tests", "docs/source_contract_reviews",
                          "inst/extdata"):
            (self.root / directory).mkdir(parents=True)
        (self.root / "DESCRIPTION").write_text(
            "Package: eyetrajectories\nVersion: 0.4.1.9000\n",
            encoding="utf-8")
        implementation = b"fit <- function(x) x + 1\n"
        original = b"testthat::expect_equal(fit(1),2)\n"
        (self.root / "R" / "fit.R").write_bytes(implementation)
        (self.root / "tests" / "test_fit.R").write_bytes(original)
        record = {
            "audit_version": "source-contract-v1",
            "python_name": "fit",
            "native_files": [{"path": "R/fit.R", "sha256": digest(implementation)}],
            "case_evidence": [
                {"kind": domain, "path": "tests/test_fit.R",
                 "sha256": digest(original)} for domain in
                ("source_signature", "accepted_input_domain", "numerical_outputs",
                 "exception_semantics", "returned_schema", "scientific_estimand")
            ],
        }
        raw_review = (json.dumps(record, sort_keys=True) + "\n").encode()
        (self.root / "docs/source_contract_reviews/fit.json").write_bytes(raw_review)
        with (self.root / "inst/extdata/reviewed_source_contract_closures_v1.csv").open(
                "w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=[
                "python_name", "review_record_path", "review_record_sha256"])
            writer.writeheader()
            writer.writerow({
                "python_name": "fit",
                "review_record_path": "docs/source_contract_reviews/fit.json",
                "review_record_sha256": digest(raw_review),
            })
        self.git("add", ".")
        self.git("commit", "-m", "historically pinned source review")
        self.original_pin = digest(original)
        (self.root / "tests" / "test_fit.R").write_bytes(
            b"testthat::expect_equal(fit(2),3)\n")
        self.git("add", ".")
        self.git("commit", "-m", "updated replay fixture")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        result = subprocess.run(
            ["git", "-C", str(self.root), *args],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        self.assertEqual(result.returncode, 0,
                         result.stderr.decode("utf-8", errors="replace"))

    def test_one_command_recovers_git_pin_and_creates_unsigned_dossier(self):
        before = (self.root /
                  "docs/source_contract_reviews/fit.json").read_bytes()
        result = queue.run(self.root)
        self.assertEqual(result["pending"], 1)
        output = result["output"]
        self.assertTrue((output / "README.txt").is_file())
        self.assertTrue((output / "patches").is_dir())
        self.assertIn("UNSIGNED", (output / "README.txt").read_text())
        with (output / "changed_evidence_versions.csv").open(
                newline="", encoding="utf-8") as file:
            rows = list(csv.DictReader(file))
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["path"], "tests/test_fit.R")
        self.assertEqual(rows[0]["pinned_sha256"], self.original_pin)
        self.assertEqual(rows[0]["independent_certification"], "FALSE")
        with (output / "contracts_to_revalidate.csv").open(
                newline="", encoding="utf-8") as file:
            contracts = list(csv.DictReader(file))
        self.assertEqual(len(contracts), 1)
        self.assertEqual(contracts[0]["priority"], "P2_TEST_EVIDENCE")
        self.assertEqual(contracts[0]["independent_certification"], "FALSE")
        self.assertEqual(
            (self.root / "docs/source_contract_reviews/fit.json").read_bytes(),
            before)

    def test_dirty_current_test_cannot_be_automatically_approved(self):
        (self.root / "tests" / "test_fit.R").write_bytes(
            b"testthat::expect_equal(fit(100),101)\n")
        with self.assertRaisesRegex(RuntimeError, "Substantive tracked evidence"):
            queue.run(self.root)
        self.assertFalse((self.root / "artifacts").exists())


if __name__ == "__main__":
    unittest.main()
