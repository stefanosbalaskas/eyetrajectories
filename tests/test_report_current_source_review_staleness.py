"""Regression checks for the read-only, fail-closed live SHA256 diagnostic."""
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
import report_current_source_review_staleness as audit


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class LiveReviewStalenessTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.git("init")
        self.git("config", "user.name", "Synthetic Source Audit")
        self.git("config", "user.email", "synthetic@example.invalid")
        self.git("config", "core.autocrlf", "false")
        (self.root / "R").mkdir()
        (self.root / "tests").mkdir()
        reviews = self.root / "docs" / "source_contract_reviews"
        reviews.mkdir(parents=True)
        registry = self.root / "inst" / "extdata"
        registry.mkdir(parents=True)

        original_code = b"source_value <- function(x) x + 1\n"
        original_test = b"testthat::expect_equal(source_value(2),3)\n"
        (self.root / "R" / "source.R").write_bytes(original_code)
        (self.root / "tests" / "source_test.R").write_bytes(original_test)
        self.test_pin = digest(original_test)
        record = {
            "python_name": "source_value",
            "native_files": [{"path": "R/source.R",
                              "sha256": digest(original_code)}],
            "case_evidence": [
                {"kind": domain, "path": "tests/source_test.R",
                 "sha256": self.test_pin} for domain in
                ("source_signature", "accepted_input_domain", "numerical_outputs",
                 "exception_semantics", "returned_schema", "scientific_estimand")
            ],
        }
        record_bytes = (json.dumps(record, sort_keys=True) + "\n").encode()
        (reviews / "source_value.json").write_bytes(record_bytes)
        with (registry / "reviewed_source_contract_closures_v1.csv").open(
                "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=[
                "python_name", "review_record_path", "review_record_sha256"])
            writer.writeheader()
            writer.writerow({
                "python_name": "source_value",
                "review_record_path": "docs/source_contract_reviews/source_value.json",
                "review_record_sha256": digest(record_bytes),
            })
        self.git("add", ".")
        self.git("commit", "-m", "source and matching six-domain test review")

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args: str) -> None:
        result = subprocess.run(["git", "-C", str(self.root), *args],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        self.assertEqual(result.returncode, 0,
                         result.stderr.decode("utf-8", errors="replace"))

    def test_changed_six_domain_test_cannot_be_mistaken_for_valid_review(self):
        (self.root / "tests" / "source_test.R").write_bytes(
            b"testthat::expect_equal(source_value(3),4)\n")
        self.git("add", ".")
        self.git("commit", "-m", "test evidence changed since author review")
        report, counts = audit.report(self.root)
        self.assertEqual(counts["FAIL_STALE_PIN_VERSUS_GIT_HEAD"], 6)
        self.assertEqual(counts["PASS_ORIGINAL_PIN_MATCHES_CURRENT_CANONICAL_SOURCE"], 2)
        with report.open("r", newline="", encoding="utf-8") as handle:
            lines = list(csv.DictReader(handle))
        self.assertEqual(len(lines), 6)
        self.assertEqual({line["path"] for line in lines},
                         {"tests/source_test.R"})
        self.assertTrue(all(line["independent_certification"] == "FALSE"
                            for line in lines))
        self.assertEqual({line["pinned_sha256"] for line in lines},
                         {self.test_pin})

    def test_current_worktree_changes_cannot_fake_exact_head_proof(self):
        (self.root / "R" / "source.R").write_bytes(
            b"source_value <- function(x) x + 100\n")
        report, counts = audit.report(self.root)
        self.assertEqual(counts["FAIL_WORKTREE_BYTES_DIFFER_FROM_GIT_HEAD"], 1)
        self.assertTrue(report.is_file())

    def test_missing_or_unsafe_path_stops_diagnostics(self):
        with self.assertRaisesRegex(ValueError, "Unsafe"):
            audit.resolve_path(self.root, "../out-of-scope")


if __name__ == "__main__":
    unittest.main()
