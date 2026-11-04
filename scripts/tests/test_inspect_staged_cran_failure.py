"""Tests: existing staged CRAN log inspection is read-only on build verdict."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "inspect_staged_cran_failure.py"
spec = importlib.util.spec_from_file_location("cran_diag", SCRIPT)
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)

CHECK = """* checking package dependencies ... OK
* checking R code for possible problems ... WARNING
  Warning: global variable 'x' not bound
  Full warning detail line
* checking whether package 'example' can be installed ... NOTE
  This is a test NOTE with context
* checking tests ... OK
  Running 'testthat.R'
* checking examples ... OK
* checking PDF version of manual ... OK
* checking for leftover files ... NOTE
  This is another NOTE
* DONE
Status: 1 WARNING, 2 NOTEs
"""


def stage(root: Path, name: str, text: str = CHECK) -> Path:
    path = root.parent / "eyetrajectories_release_staging" / name / (
        "eyetrajectories_0.4.2_from_d95288756df0")
    logs = path / "eyetrajectories.Rcheck"
    logs.mkdir(parents=True)
    (logs / "00check.log").write_text(text, encoding="utf-8")
    (path / "STAGING_MANIFEST.json").write_text(json.dumps({
        "source_git_head": "d95288756df03f155d6b8577eb66f68d8d5e71ef",
        "source_version": "0.4.1.9000",
        "candidate_version": "0.4.2",
        "candidate_release_status": "HOLD",
        "candidate_check": "NOT EXECUTED",
    }), encoding="utf-8")
    return path


class StagedDiagnosticTests(unittest.TestCase):
    def test_extracts_actual_warning_and_two_notes_without_waiver(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "eyetrajectories"
            root.mkdir()
            candidate = stage(root, "20261104T101840078027Z")
            old_log = (candidate / "eyetrajectories.Rcheck" /
                       "00check.log").read_bytes()
            old_manifest = (candidate / "STAGING_MANIFEST.json").read_bytes()
            summary, text = diag.diagnose(candidate)
            self.assertEqual(summary["original_check_status"], "1 WARNING, 2 NOTEs")
            self.assertEqual([x["kind"] for x in summary["sections"]],
                             ["WARNING", "NOTE", "NOTE"])
            self.assertIn("global variable 'x' not bound", text)
            self.assertIn("This is another NOTE", text)
            self.assertIn("CRAN_STATUS=HOLD", text)
            self.assertIn("CANDIDATE_SOURCE_HEAD=d95288756df03f", text)
            self.assertEqual((candidate / "eyetrajectories.Rcheck" /
                              "00check.log").read_bytes(), old_log)
            self.assertEqual((candidate / "STAGING_MANIFEST.json").read_bytes(),
                             old_manifest)

    def test_entrypoint_writes_only_new_diagnostics_under_previous_stage(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "eyetrajectories"
            root.mkdir()
            candidate = stage(root, "20261104T101840078027Z")
            result = subprocess.run([
                sys.executable, str(SCRIPT), "--root", str(root)],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("CHECK_STATUS=1 WARNING, 2 NOTEs", result.stdout)
            self.assertIn("WARNING_SECTIONS=1", result.stdout)
            self.assertIn("NOTE_SECTIONS=2", result.stdout)
            self.assertTrue((candidate / "STAGED_CRAN_DIAGNOSTICS.txt").is_file())
            parsed = json.loads((candidate / "STAGED_CRAN_DIAGNOSTICS.json")
                                .read_text(encoding="utf-8"))
            self.assertTrue(parsed["diagnostic_only"])
            self.assertIn("HOLD", parsed["candidate_release_status"])
            self.assertEqual(parsed["candidate_version"], "0.4.2")
            self.assertEqual(json.loads((candidate / "STAGING_MANIFEST.json")
                                        .read_text())["candidate_check"],
                             "NOT EXECUTED")

    def test_missing_stage_and_incomplete_verdict_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "eyetrajectories"
            root.mkdir()
            with self.assertRaises(FileNotFoundError):
                diag.latest_candidate(root)
            candidate = stage(root, "20261104T101840078027Z", "* DONE\n")
            with self.assertRaisesRegex(ValueError, "exactly one"):
                diag.diagnose(candidate)

    def test_no_phase_warning_details_does_not_invent_a_clean_verdict(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "eyetrajectories"
            root.mkdir()
            candidate = stage(root, "20261104T101840078027Z",
                              "* DONE\nStatus: 1 WARNING, 2 NOTEs\n")
            summary, text = diag.diagnose(candidate)
            self.assertEqual(summary["sections"], [])
            self.assertIn("Inspect ORIGINAL_00CHECK_LOG", text)
            self.assertIn("CRAN_STATUS=HOLD", text)


if __name__ == "__main__":
    unittest.main()
