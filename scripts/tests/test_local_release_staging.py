"""Tests: staging does not modify Git HEAD or confer release approval."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import json
import types
import contextlib
import io

SCRIPT = Path(__file__).resolve().parents[1] / "stage_local_release_candidate.py"
spec = importlib.util.spec_from_file_location("release_stage", SCRIPT)
stage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stage)


class StageTests(unittest.TestCase):
    def test_stage_only_changes_exported_copy(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)/"eyetrajectories"
            root.mkdir()
            (root/"scripts").mkdir()
            (root/"scripts/qualify_experimental_candidate.R").write_text("# green only if executed\n")
            (root/"DESCRIPTION").write_text("Package: eyetrajectories\nVersion: 0.4.1.9000\nAuthors@R: person(\"Tester\", \"One\")\n")
            (root/"NEWS.md").write_text("# eyetrajectories 0.4.1.9000 (development)\n")
            (root/"README.md").write_text("currently\n" + chr(96) + "0.4.1.9000" + chr(96) + "\n")
            def cmd(*args):
                return subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)
            cmd("init", "-q")
            cmd("-c", "user.name=Tester", "-c", "user.email=tester@example.org", "add", ".")
            cmd("-c", "user.name=Tester", "-c", "user.email=tester@example.org", "commit", "-q", "-m", "initial")
            sha = cmd("rev-parse", "HEAD").stdout.decode().strip()
            stage_dir = stage.prepare(root, Path(td)/"staging", "0.4.2")
            content = (stage_dir/"eyetrajectories"/"DESCRIPTION").read_text()
            self.assertIn("Version: 0.4.2\nAuthors@R:",content)
            self.assertIn("Version: 0.4.1.9000",(root/"DESCRIPTION").read_text())
            manifest = (stage_dir/"STAGING_MANIFEST.json").read_text()
            self.assertIn(sha, manifest)
            self.assertIn('"candidate_check": "NOT EXECUTED"', manifest)
            self.assertIn('"candidate_release_status": "HOLD"', manifest)
            self.assertEqual(cmd("rev-parse","HEAD").stdout.decode().strip(),sha)
            with self.assertRaises(FileExistsError):
                stage.prepare(root, Path(td)/"staging", "0.4.2")

    def test_staged_check_requires_real_status_and_preserves_hold(self):
        with tempfile.TemporaryDirectory() as td:
            folder = Path(td)
            (folder/"STAGING_MANIFEST.json").write_text(json.dumps({"candidate_check":"NOT EXECUTED","candidate_release_status":"HOLD"}))
            def fake_run(cmd, cwd, **kwargs):
                if cmd[2] == "build":
                    (folder/"eyetrajectories_0.4.2.tar.gz").write_bytes(b"test source bytes")
                else:
                    (folder/"eyetrajectories.Rcheck").mkdir()
                    (folder/"eyetrajectories.Rcheck/00check.log").write_text(
                        "* checking tests ... OK\n"
                        "  Running 'testthat.R'\n"
                        "* checking examples ... OK\n"
                        "* checking PDF version of manual ... OK\n"
                        "* DONE\nStatus: 1 NOTE\n")
                return types.SimpleNamespace(returncode=0,stdout="mock subprocess output")
            with patch.object(stage.subprocess,"run",side_effect=fake_run):
                status=stage.check_candidate(folder,"0.4.2","R")
            self.assertEqual(status,"PASS_WITH_NOTE_REVIEW")
            manifest=json.loads((folder/"STAGING_MANIFEST.json").read_text())
            self.assertEqual(manifest["candidate_release_status"],"HOLD: platform and NOTE review required")
            self.assertEqual(len(manifest["candidate_check_tarball_sha256"]),64)

    def test_staged_check_refuses_skipped_scientific_or_manual_phases(self):
        with tempfile.TemporaryDirectory() as td:
            folder = Path(td)
            (folder/"STAGING_MANIFEST.json").write_text("{}")
            def fake_run(cmd, cwd, **kwargs):
                if cmd[2] == "build":
                    (folder/"eyetrajectories_0.4.2.tar.gz").write_bytes(b"tar")
                else:
                    (folder/"eyetrajectories.Rcheck").mkdir()
                    (folder/"eyetrajectories.Rcheck/00check.log").write_text(
                        "* DONE\nStatus: OK\n")
                return types.SimpleNamespace(returncode=0,stdout="")
            with patch.object(stage.subprocess,"run",side_effect=fake_run):
                with self.assertRaisesRegex(RuntimeError,"mandatory phases"):
                    stage.check_candidate(folder,"0.4.2","R")
            self.assertNotIn("candidate_check_tarball_sha256",
                json.loads((folder/"STAGING_MANIFEST.json").read_text()))

    def test_staged_check_prints_installed_test_failure_context(self):
        with tempfile.TemporaryDirectory() as td:
            folder = Path(td)
            (folder/"STAGING_MANIFEST.json").write_text("{}")
            def fake_run(cmd, cwd, **kwargs):
                if cmd[2] == "build":
                    (folder/"eyetrajectories_0.4.2.tar.gz").write_bytes(b"tar")
                    return types.SimpleNamespace(returncode=0,stdout="built")
                path = folder/"eyetrajectories.Rcheck"/"tests"
                path.mkdir(parents=True)
                (path/"testthat.Rout.fail").write_text(
                    "══ Failed ══════════\n"
                    "── 1. Failure (test-native-example.R:19:3): bad source case\n"
                    "Expected source contract to agree\n", encoding="utf-8")
                return types.SimpleNamespace(returncode=1,stdout="R test failure")
            stderr = io.StringIO()
            with patch.object(stage.subprocess,"run",side_effect=fake_run):
                with contextlib.redirect_stderr(stderr):
                    with self.assertRaisesRegex(RuntimeError,
                                                "R CMD check exited 1"):
                        stage.check_candidate(folder,"0.4.2","R")
            output = stderr.getvalue()
            self.assertIn("STAGED_TEST_FAILURE_DETAILS_BEGIN",output)
            self.assertIn("test-native-example.R:19:3",output)
            self.assertIn("STAGED_TEST_FAILURE_DETAILS_END",output)

    def test_missing_candidate_check_verdict_does_not_pass(self):
        with tempfile.TemporaryDirectory() as td:
            folder=Path(td)
            (folder/"STAGING_MANIFEST.json").write_text("{}")
            def fake_run(cmd, cwd, **kwargs):
                if cmd[2]=="build":
                    (folder/"eyetrajectories_0.4.2.tar.gz").write_bytes(b"tar")
                else:
                    (folder/"eyetrajectories.Rcheck").mkdir()
                    (folder/"eyetrajectories.Rcheck/00check.log").write_text("* DONE\n")
                return types.SimpleNamespace(returncode=0,stdout="")
            with patch.object(stage.subprocess,"run",side_effect=fake_run):
                with self.assertRaisesRegex(RuntimeError,"Missing final"):
                    stage.check_candidate(folder,"0.4.2","R")

    def test_failed_r_command_prints_real_error_and_preserves_log(self):
        with tempfile.TemporaryDirectory() as td:
            folder = Path(td)
            (folder/"STAGING_MANIFEST.json").write_text('{}')
            with patch.object(stage.subprocess,"run",
                return_value=types.SimpleNamespace(returncode=7,
                    stdout="error: missing installed R package\n")):
                err = io.StringIO()
                with contextlib.redirect_stderr(err):
                    with self.assertRaisesRegex(RuntimeError, "R CMD build exited 7"):
                        stage.check_candidate(folder,"0.4.2","R")
            self.assertIn("STAGED_R_CHILD_FAILURE_PHASE=build", err.getvalue())
            self.assertIn("error: missing installed R package", err.getvalue())
            self.assertIn("error: missing installed R package", (folder/"STAGED_R_CMD_CHECK.log").read_text())

    def test_invalid_version_fails(self):
        with self.assertRaises(ValueError):
            stage.prepare(Path("."), Path("/tmp/unused"), "0.4.1.9000")

if __name__ == "__main__":
    unittest.main()
