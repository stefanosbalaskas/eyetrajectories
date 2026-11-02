"""Standalone stdlib regression tests for local matrix orchestration."""
import importlib.util
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "run_local_release_matrix.py"
spec = importlib.util.spec_from_file_location("local_release_matrix", SCRIPT)
matrix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(matrix)
SHA = "a" * 40
BASE = "EXPERIMENTAL_R_CANDIDATE_HEAD=" + SHA + "\n" + "\n".join([
    "R CMD check errors: 0", "R CMD check warnings: 0", "R CMD check notes: 1",
    "Native source example: PASS",
    "native_r_offline: QUALIFICATION COMPLETED WITHOUT TEST FAILURES",
    "python_1_2_direct_source: QUALIFICATION COMPLETED WITHOUT TEST FAILURES",
    "NO PACKAGE HAS BEEN PUBLISHED OR TAGGED."
])


class MatrixTests(unittest.TestCase):
    def test_proof_requires_all_scientific_and_cran_tracks(self):
        self.assertEqual(matrix.interpret_log(BASE, 0, SHA, False)[0], "PASS_WITH_NOTE_REVIEW")
        self.assertEqual(matrix.interpret_log(BASE.replace("R CMD check warnings: 0", "R CMD check warnings: 1"), 0, SHA, False)[0], "FAIL")
        self.assertEqual(matrix.interpret_log(BASE.replace("python_1_2_direct_source:", "omitted:"), 0, SHA, False)[0], "FAIL")
        self.assertEqual(matrix.interpret_log(BASE, 1, SHA, False)[0], "FAIL")
        self.assertEqual(matrix.interpret_log(BASE, 0, "b" * 40, False)[0], "FAIL")

    def test_python312_is_not_inferred_from_python_12_package(self):
        self.assertEqual(matrix.interpret_log(BASE, 0, SHA, True)[0], "FAIL")
        self.assertEqual(matrix.interpret_log(BASE + "\nRETICULATE_PYTHON_312_CONFIRMED=/path/to/python\n", 0, SHA, True)[0], "PASS_WITH_NOTE_REVIEW")

    def test_notes_are_manual_review_not_release_approval(self):
        self.assertEqual(matrix.interpret_log(BASE.replace("notes: 1", "notes: 0"), 0, SHA, False)[0], "PASS")

    def test_docker_uses_prebuilt_offline_image_and_parent_mount(self):
        command = matrix.docker_command(pathlib.Path("/tmp/repo/eyetrajectories"), "r-local-ci:4.6", "source('x')")
        self.assertIn("none", command)
        self.assertEqual(command[0:3], ["docker", "run", "--rm"])
        self.assertIn("source('x')", command)
        with self.assertRaises(ValueError):
            matrix.docker_command(pathlib.Path("/tmp/repo/eyetrajectories"), "", "x")

    def test_dirty_checkout_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            (root / "scripts").mkdir()
            (root / "scripts/qualify_experimental_candidate.R").write_text("x")
            (root / "DESCRIPTION").write_text("Package: eyetrajectories\nVersion: 0.4.1.9000\n")
            with self.assertRaises(Exception):
                matrix.validate_root(root)


if __name__ == "__main__":
    unittest.main()
