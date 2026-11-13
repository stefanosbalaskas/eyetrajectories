"""Offline regression tests for history-only SHA256 scientific evidence tracing."""
from __future__ import annotations

import csv
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import trace_source_review_pin_history as tracer


class SourcePinHistoryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.run_git("init")
        self.run_git("config", "user.name", "Source Audit Test")
        self.run_git("config", "user.email", "source-audit@example.invalid")
        (self.root / "DESCRIPTION").write_text("Package: eyetrajectories\n",
                                                encoding="utf-8")
        self.path = "R/example-source.R"
        (self.root / "R").mkdir()
        self.old_content = b"f <- function(x) x + 1\n"
        self.new_content = b"f <- function(x) x + 2\n"
        (self.root / self.path).write_bytes(self.old_content)
        self.run_git("add", ".")
        self.run_git("commit", "-m", "original pinned source")
        (self.root / self.path).write_bytes(self.new_content)
        self.run_git("add", ".")
        self.run_git("commit", "-m", "scientific source changed")
        self.audit = self.root / "audit.csv"

    def tearDown(self):
        self.tmp.cleanup()

    def run_git(self, *args):
        result = subprocess.run(
            ["git", "-C", str(self.root), *args],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        self.assertEqual(result.returncode, 0, result.stderr.decode(
            "utf-8", errors="replace"))

    def write_audit(self, cases):
        with self.audit.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(
                stream,
                fieldnames=["python_name", "path", "source", "pinned_sha256",
                            "verdict"])
            writer.writeheader()
            writer.writerows(cases)

    def test_frozen_pin_provenance_never_approves_changed_source(self):
        old_digest = hashlib.sha256(self.old_content).hexdigest()
        new_digest = hashlib.sha256(self.new_content).hexdigest()
        rows = [
            dict(python_name="old_source", path=self.path,
                 source="native_file", pinned_sha256=old_digest,
                 verdict="FAIL_PIN_MISMATCH"),
            dict(python_name="old_source_2", path=self.path,
                 source="native_file", pinned_sha256=old_digest,
                 verdict="FAIL_PIN_MISMATCH"),
            dict(python_name="current_source", path=self.path,
                 source="native_file", pinned_sha256=new_digest,
                 verdict="FAIL_PIN_MISMATCH"),
            dict(python_name="bogus_pin", path=self.path,
                 source="native_file", pinned_sha256="a"*64,
                 verdict="FAIL_PIN_MISMATCH"),
        ]
        self.write_audit(rows)
        result, contract_file = tracer.trace(self.audit, self.root)
        with result.open(encoding="utf-8", newline="") as stream:
            pin_rows = list(csv.DictReader(stream))
        self.assertEqual(len(pin_rows), 3)
        by_hash = {r["pinned_sha256"]: r for r in pin_rows}
        historical = by_hash[old_digest]
        self.assertEqual(historical["status"],
                         "HISTORICAL_PIN_CURRENT_SOURCE_CHANGED")
        self.assertEqual(historical["current_head_sha256"], new_digest)
        self.assertEqual(historical["failed_reference_count"], "2")
        self.assertRegex(historical["source_commit_with_pinned_bytes"],
                         r"^[0-9a-f]{40}$")
        self.assertEqual(historical["independent_certification"], "FALSE")
        self.assertEqual(by_hash[new_digest]["status"],
                         "MATCHES_CURRENT_GIT_HEAD")
        self.assertEqual(by_hash["a"*64]["status"],
                         "PIN_NOT_FOUND_IN_AVAILABLE_GIT_HISTORY")
        with contract_file.open(encoding="utf-8", newline="") as stream:
            contracts = list(csv.DictReader(stream))
        self.assertEqual(len(contracts), 4)
        self.assertTrue(all(row["independent_certification"] == "FALSE"
                            for row in contracts))

    def test_unsafe_path_rejected_without_git_execution(self):
        self.write_audit([
            dict(python_name="unsafe", path="../outside.R",
                 source="native_file", pinned_sha256="a"*64,
                 verdict="FAIL_PIN_MISMATCH")])
        with self.assertRaisesRegex(ValueError, "Unsafe path"):
            tracer.trace(self.audit, self.root)


if __name__ == "__main__":
    unittest.main()
