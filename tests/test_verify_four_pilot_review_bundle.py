"""Developer-only regression of review evidence integrity, not scientific parity."""
import csv
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
import verify_four_pilot_review_bundle as v

def write_csv(path, records):
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(records[0]))
        writer.writeheader()
        writer.writerows(records)

def synthetic_packet(root):
    head = "a" * 40
    pilots = sorted(v.PILOTS)
    write_csv(root / v.FILES[0], [dict(recorded_r_git_head=head,
        checkout_matches_evidence="TRUE", source_file_manifest_matches_checkout="TRUE",
        native_suite_pass="TRUE", pinned_python_suite_pass="TRUE",
        independent_review_approved="FALSE", full_source_contract_certified="FALSE")])
    write_csv(root / v.FILES[1], [dict(python_name=p, native_r_candidate="etr_" + p,
        pinned_python_commit=v.FROZEN_PYTHON, independent_reviewer_approved="FALSE",
        full_accepted_input_domain_approved="FALSE", complete_error_semantics_approved="FALSE",
        scientific_scope_approved="FALSE") for p in pilots])
    cases = ("finite_scientific_fixture", "broader_accepted_containers",
             "exception_or_extreme_boundary", "scientific_and_schema_scope")
    write_csv(root / v.FILES[2], [dict(python_name=p, case_id=c,
        fully_certified="FALSE", independently_replayed_case="FALSE")
        for p in pilots for c in cases])
    write_csv(root / v.FILES[3], [dict(python_name=p,
        developer_numeric_fixture_pass="TRUE", independently_replayed_case="FALSE",
        fully_certified="FALSE") for p in
        ([pilots[0]] * 4 + [pilots[1]] * 2 + [pilots[2]] * 2 + [pilots[3]] * 2)])
    write_csv(root / v.FILES[4], [dict(python_name=p,
        relation=("both_reject_error_schema_unreviewed" if p == "score_distance_matrix"
                  else "documented_source_difference"),
        observed_behavior_as_expected="TRUE", source_domain_equivalence_established="FALSE",
        independent_reviewer_approved="FALSE", independently_replayed_case="FALSE",
        fully_certified="FALSE") for p in pilots])
    write_csv(root / v.FILES[5], [dict(python_name=p, resolved="FALSE")
        for p in pilots + ["extra_%03d" % i for i in range(199)]])
    write_csv(root / v.MANIFEST, [dict(filename=f, sha256=v.sha256(root / f),
        recorded_r_git_head=head, frozen_python_commit=v.FROZEN_PYTHON) for f in v.FILES])
    manifest_hash = v.sha256(root / v.MANIFEST)
    write_csv(root / v.TEMPLATE, [dict(python_name=p,
        native_r_candidate="etr_" + p, recorded_r_git_head=head,
        frozen_python_commit=v.FROZEN_PYTHON, evidence_manifest_sha256=manifest_hash,
        scope_decision="PENDING_EXTERNAL_REVIEW", reviewer_name="",
        reviewer_is_independent_of_authors="FALSE",
        reviewer_replayed_python_separately="FALSE",
        reviewer_replayed_native_r_separately="FALSE",
        accepted_input_domain_reviewed="FALSE",
        error_warning_semantics_reviewed="FALSE",
        return_schema_dtype_reviewed="FALSE",
        scientific_estimand_reviewed="FALSE",
        documented_source_gap_resolved="FALSE") for p in pilots])
    (root / v.INSTRUCTIONS).write_text(
        "This is NOT an independent certification.", encoding="utf-8")

class TestReviewIntegrity(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        synthetic_packet(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def rehash(self):
        manifest = self.root / v.MANIFEST
        records = v.csv_rows(manifest)
        for row in records:
            row["sha256"] = v.sha256(self.root / row["filename"])
        write_csv(manifest, records)
        template = self.root / v.TEMPLATE
        records = v.csv_rows(template)
        for row in records:
            row["evidence_manifest_sha256"] = v.sha256(manifest)
        write_csv(template, records)

    def test_unsigned_packet_passes(self):
        result = v.verify(self.root)
        self.assertEqual(result["verified_evidence_files"], 6)
        self.assertEqual(result["full_domain_certifications"], 0)

    def test_trusted_head_mismatch_fails(self):
        self.assertTrue(v.verify(self.root, expected_r_head="a" * 40)[
            "separately_trusted_head_checked"])
        with self.assertRaisesRegex(v.BundleError, "separately trusted expected head"):
            v.verify(self.root, expected_r_head="b" * 40)

    def test_mutated_byte_fails(self):
        with (self.root / v.FILES[4]).open("a", encoding="utf-8") as f:
            f.write("\n")
        with self.assertRaisesRegex(v.BundleError, "SHA256 mismatch"):
            v.verify(self.root)

    def test_false_approval_fails_even_if_rehashed(self):
        p = self.root / v.FILES[0]
        p.write_text(p.read_text(encoding="utf-8").replace(
            "FALSE,FALSE", "TRUE,TRUE"), encoding="utf-8")
        self.rehash()
        with self.assertRaisesRegex(v.BundleError, "must be FALSE"):
            v.verify(self.root)

    def test_fake_replay_fails_even_if_rehashed(self):
        p = self.root / v.FILES[4]
        p.write_text(p.read_text(encoding="utf-8").replace(
            "FALSE,FALSE,FALSE,FALSE", "TRUE,FALSE,FALSE,FALSE", 1),
            encoding="utf-8")
        self.rehash()
        with self.assertRaisesRegex(v.BundleError, "must be FALSE"):
            v.verify(self.root)

    def test_manifest_substitution_fails(self):
        p = self.root / v.MANIFEST
        p.write_text(p.read_text(encoding="utf-8").replace(
            "a" * 40, "b" * 40), encoding="utf-8")
        with self.assertRaisesRegex(v.BundleError, "heads differ"):
            v.verify(self.root)

    def test_symlink_source_evidence_fails(self):
        p = self.root / v.FILES[0]
        backup = self.root / "backup.csv"
        p.rename(backup)
        try:
            p.symlink_to(backup)
        except (OSError, NotImplementedError):
            self.skipTest("Symlinks unavailable on this platform")
        with self.assertRaisesRegex(v.BundleError, "symlinked"):
            v.verify(self.root)

if __name__ == "__main__":
    unittest.main()
