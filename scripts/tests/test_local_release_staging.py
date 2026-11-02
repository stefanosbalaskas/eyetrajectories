"""Tests: staging does not modify Git HEAD or confer release approval."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

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

    def test_invalid_version_fails(self):
        with self.assertRaises(ValueError):
            stage.prepare(Path("."), Path("/tmp/unused"), "0.4.1.9000")

if __name__ == "__main__":
    unittest.main()
