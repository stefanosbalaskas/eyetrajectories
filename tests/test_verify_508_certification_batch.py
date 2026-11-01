"""Synthetic packet-regression tests: NOT third-party scientific verification."""
import csv
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import verify_508_certification_batch as v


def write_csv(path, rows):
    assert rows
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def make_packet(folder):
    head = "a" * 40
    full = []
    for i in range(508):
        isfn = i < 380
        gap = i < 203
        backend = i < 19
        name = f"fn_{i:03d}" if isfn else f"obj_{i - 380:03d}"
        lane = ("DIFFERENT_BACKEND_OR_ESTIMAND" if backend else
                "RECORDED_SOURCE_DIFFERENCE" if gap else
                "FUNCTION_NO_RECORDED_GAP" if isfn else
                "NONFUNCTION_NO_RECORDED_GAP")
        full.append(dict(namespace="root", python_name=name,
                         kind="function" if isfn else "other_export",
                         native_r_candidate=f"etr_{name}" if isfn else "",
                         review_lane=lane,
                         source_gap_open=str(gap).upper(),
                         backend_or_estimand_distinct=str(backend).upper(),
                         currently_authoritatively_certified="FALSE",
                         developer_queue_is_not_scientific_certification="TRUE",
                         recorded_r_git_head=head,
                         frozen_python_commit=v.FROZEN_PYTHON))
    batch = [
        dict(row) for row in (
            [r for r in full if r["review_lane"] ==
             "FUNCTION_NO_RECORDED_GAP"][:24] +
            [r for r in full if r["review_lane"] ==
             "NONFUNCTION_NO_RECORDED_GAP"][:12]
        )
    ]
    cases = []
    for r in batch:
        for crit in v.CRITERIA:
            # Mirror the real R-generated checklist source identity
            # schema. The separate GPG receipt verifier must compare these
            # fields against unsigned source evidence without KeyError.
            cases.append(dict(namespace=r["namespace"],
                python_name=r["python_name"],
                kind=r["kind"],
                native_r_candidate=r["native_r_candidate"],
                recorded_r_git_head=r["recorded_r_git_head"],
                frozen_python_commit=r["frozen_python_commit"],
                criterion=crit,
                reviewer_case_passed="FALSE", independently_replayed="FALSE",
                full_domain_approved="FALSE",
                reviewer_created_evidence_reference="",
                reviewer_written_findings=""))
    decisions = []
    for r in batch:
        # Keep all six immutable identity fields identical to the native
        # R-generated unsigned reviewer decision template. A missing field
        # used to raise KeyError('kind') in signed-receipt structural tests.
        decisions.append(dict(namespace=r["namespace"],
            python_name=r["python_name"],
            kind=r["kind"],
            native_r_candidate=r["native_r_candidate"],
            recorded_r_git_head=r["recorded_r_git_head"],
            frozen_python_commit=r["frozen_python_commit"],
            scope_decision="PENDING_INDEPENDENT_REVIEW",
            reviewer_name="", reviewer_affiliation="", reviewer_contact="",
            reviewer_independent_of_implementation_team="FALSE",
            reviewer_python_replay_pass="FALSE",
            reviewer_r_replay_pass="FALSE",
            complete_input_error_schema_review_pass="FALSE",
            scientific_estimand_review_pass="FALSE",
            all_source_gaps_resolved_after_review="FALSE",
            reviewer_signed_evidence_reference="", reviewer_signed_utc="",
            full_domain_certification_approved="FALSE"))
    for path, rows in zip(v.FILES, (full, batch, cases, decisions)):
        write_csv(folder / path, rows)
    write_csv(folder / v.MANIFEST, [
        dict(filename=name, sha256=v.sha256(folder / name),
             recorded_r_git_head=head,
             frozen_python_commit=v.FROZEN_PYTHON,
             independent_review_signoff_present="FALSE") for name in v.FILES
    ])


class TestUnsignedBatchIntegrity(unittest.TestCase):
    def setUp(self):
        self.t = tempfile.TemporaryDirectory()
        self.root = Path(self.t.name)
        make_packet(self.root)

    def tearDown(self):
        self.t.cleanup()

    def update_manifest(self):
        path = self.root / v.MANIFEST
        rows = v.read_csv(path)
        for row in rows:
            row["sha256"] = v.sha256(self.root / row["filename"])
        write_csv(path, rows)

    def test_clean_unsigned_packet_passes(self):
        result = v.verify(self.root, expected_r_head="a" * 40)
        self.assertEqual(result["export_count"], 508)
        self.assertEqual(result["first_review_batch"], 36)
        self.assertEqual(result["independently_certified_full_domain_contracts"], 0)

    def test_expected_head_mismatch_fails(self):
        with self.assertRaisesRegex(v.ReviewBatchError, "separately trusted"):
            v.verify(self.root, expected_r_head="b" * 40)

    def test_source_byte_tamper_fails(self):
        with (self.root / v.FILES[3]).open("a", encoding="utf-8") as f:
            f.write("\n")
        with self.assertRaisesRegex(v.ReviewBatchError, "SHA256 mismatch"):
            v.verify(self.root)

    def test_forged_approval_rehashed_fails(self):
        p = self.root / v.FILES[3]
        rows = v.read_csv(p)
        rows[0]["full_domain_certification_approved"] = "TRUE"
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "must be FALSE"):
            v.verify(self.root)

    def test_forged_scientific_replay_rehashed_fails(self):
        p = self.root / v.FILES[2]
        rows = v.read_csv(p)
        rows[1]["independently_replayed"] = "TRUE"
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "must be FALSE"):
            v.verify(self.root)

    def test_forged_case_source_pin_rehashed_fails(self):
        p = self.root / v.FILES[2]
        rows = v.read_csv(p)
        rows[0]["recorded_r_git_head"] = "0" * 40
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "case source identity"):
            v.verify(self.root)

    def test_missing_case_identity_column_rehashed_fails(self):
        p = self.root / v.FILES[2]
        rows = v.read_csv(p)
        for row in rows:
            del row["frozen_python_commit"]
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "Missing reviewer checklists columns"):
            v.verify(self.root)

    def test_missing_decision_source_identity_rehashed_fails(self):
        p = self.root / v.FILES[3]
        rows = v.read_csv(p)
        for row in rows:
            del row["kind"]
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError,
                                    "Missing reviewer decisions columns"):
            v.verify(self.root)

    def test_forged_decision_source_identity_rehashed_fails(self):
        p = self.root / v.FILES[3]
        rows = v.read_csv(p)
        rows[0]["recorded_r_git_head"] = "0" * 40
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError,
                                    "decision source identity"):
            v.verify(self.root)

    def test_missing_case_criterion_rehashed_fails(self):
        p = self.root / v.FILES[2]
        rows = v.read_csv(p)
        rows[0]["criterion"] = "not_a_real_review_requirement"
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "criteria"):
            v.verify(self.root)

    def test_forged_gap_closure_rehashed_fails(self):
        p = self.root / v.FILES[0]
        rows = v.read_csv(p)
        rows[0]["source_gap_open"] = "FALSE"
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "source gap inventory"):
            v.verify(self.root)

    def test_unsigned_template_name_forgery_rehashed_fails(self):
        p = self.root / v.FILES[3]
        rows = v.read_csv(p)
        rows[0]["reviewer_name"] = "Invented external researcher"
        write_csv(p, rows)
        self.update_manifest()
        with self.assertRaisesRegex(v.ReviewBatchError, "unsigned and pending"):
            v.verify(self.root)

    def test_symlink_manifest_source_fails(self):
        p = self.root / v.FILES[0]
        backup = self.root / "backup.csv"
        p.rename(backup)
        try:
            p.symlink_to(backup)
        except (OSError, NotImplementedError):
            self.skipTest("Symlinks unavailable on this platform")
        with self.assertRaisesRegex(v.ReviewBatchError, "symlinked"):
            v.verify(self.root)


if __name__ == "__main__":
    unittest.main()
