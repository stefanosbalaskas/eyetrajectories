"""Synthetic security and triage tests; no independent scientific approval."""
import csv
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import reconcile_508_contract_progress as progress

HEAD = "a" * 40


def write_rows(path, rows):
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


class ReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.rows = []
        for i in range(508):
            self.rows.append({
                "namespace": "root",
                "python_name": "export_" + str(i).zfill(3),
                "kind": "function" if i < 380 else "other",
                "native_r_candidate": "etr_export_" + str(i).zfill(3),
                "recorded_r_git_head": HEAD,
                "frozen_python_commit": progress.baseline.FROZEN_PYTHON,
                "source_gap_open": "TRUE" if i < 203 or i == 380 else "FALSE",
                "backend_or_estimand_distinct": "TRUE" if i < 19 else "FALSE",
                "currently_authoritatively_certified": "FALSE",
                "native_implementation_started": "TRUE",
                "native_nonfunction_representation":
                    "Synthetic native class representation" if i >= 380 else "",
                "source_fixture_attributed": "TRUE" if i < 111 else "FALSE",
            })
        # Frozen source roots of the four numerical developer pilots must be
        # represented in the 508 export inventory, as in real packets.
        for j, name in enumerate(("alr_transform", "inverse_alr",
                                  "score_distance_matrix",
                                  "functional_trapezoid_weights"), start=4):
            self.rows[j]["python_name"] = name
        write_rows(self.root / progress.baseline.FILES[0], self.rows)
        self.mock_verify = patch.object(progress.baseline, "verify",
                                        return_value={"r_git_head": HEAD})
        self.mock_verify.start()

    def tearDown(self):
        self.mock_verify.stop()
        self.temp.cleanup()

    def evidence(self, index, all_true=True):
        q = self.rows[index]
        f = self.root / ("source_" + str(index) + ".txt")
        f.write_text("developer numerical replay for export " + str(index),
                     encoding="utf-8")
        out = {key: q[key] for key in progress.IDENTITY}
        out.update({flag: "TRUE" if all_true else "FALSE"
                    for flag in progress.FLAGS})
        out.update(evidence_file=str(f),
                   evidence_sha256=progress.baseline.sha256(f),
                   developer_findings="Direct source comparison performed, review pending")
        return out

    def test_without_evidence_all_508_prioritized_and_no_certification(self):
        z = progress.reconcile(self.root, HEAD)
        self.assertEqual(z["export_count"], 508)
        self.assertEqual(z["callable_count"], 380)
        self.assertEqual(z["historical_documented_source_gaps"], 204)
        self.assertEqual(z["developer_evidence_ready_for_review"], 0)
        self.assertEqual(z["independently_certified"], 0)
        output = Path(z["output_dir"])
        rows = progress.baseline.read_csv(output / progress.PROGRESS)
        self.assertEqual(len(rows), 508)
        dispatch = progress.baseline.read_csv(output / progress.DISPATCH)
        self.assertEqual(len(dispatch), 28)
        self.assertEqual(sum(x["dispatch_lane"] == "KNOWN_GAP_PILOT_REPLAY"
                             for x in dispatch), 4)
        self.assertEqual(sum(x["dispatch_lane"] ==
                             "FUNCTION_SOURCE_FULL_DOMAIN_REVIEW"
                             for x in dispatch), 12)
        self.assertEqual(sum(x["dispatch_lane"] ==
                             "NONFUNCTION_REPRESENTATION_REVIEW"
                             for x in dispatch), 12)
        self.assertTrue(all(x["independently_certified"] == "FALSE"
                            for x in dispatch))
        template = progress.baseline.read_csv(output / progress.TEMPLATE)
        self.assertEqual(len(template), 508)
        self.assertTrue(all(x["source_signature_checked"] == "FALSE"
                            for x in template))
        self.assertTrue(all(x["evidence_sha256"] == "" for x in template))
        self.assertTrue(all(x["source_gap_closed"] == "FALSE" for x in rows))
        self.assertTrue(all(x["independently_certified"] == "FALSE" for x in rows))
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError,
                                    "already exists"):
            progress.reconcile(self.root, HEAD)

    def test_exact_sha_evidence_ready_never_closes_a_known_gap(self):
        evidence = [self.evidence(0), self.evidence(300)]
        file = self.root / "proof.csv"
        write_rows(file, evidence)
        result = progress.reconcile(self.root, HEAD, evidence_csv=file)
        self.assertEqual(result["developer_evidence_ready_for_review"], 2)
        self.assertEqual(result["gap_reconciliation_candidates"], 1)
        self.assertEqual(result["source_gaps_closed"], 0)
        priorities = progress.baseline.read_csv(
            Path(result["output_dir"]) / progress.PRIORITY)
        no_gap = next(x for x in priorities if x["python_name"] == "export_300")
        gap = next(x for x in priorities if x["python_name"] == "export_000")
        self.assertEqual(no_gap["review_priority"], "1")
        self.assertEqual(gap["review_priority"], "2")
        self.assertEqual(gap["historical_source_gap_open"], "TRUE")
        self.assertEqual(gap["source_gap_closed"], "FALSE")

    def test_missing_partial_flags_do_not_count_as_developer_ready(self):
        file = self.root / "partial.csv"
        write_rows(file, [self.evidence(300, all_true=False)])
        z = progress.reconcile(self.root, HEAD, evidence_csv=file)
        self.assertEqual(z["evidence_records_verified_sha256"], 1)
        self.assertEqual(z["developer_evidence_ready_for_review"], 0)

    def test_tampered_evidence_sha256_fails_closed(self):
        data = self.evidence(300)
        data["evidence_sha256"] = "0" * 64
        file = self.root / "tamper.csv"
        write_rows(file, [data])
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError,
                                    "SHA256 mismatch"):
            progress.reconcile(self.root, HEAD, evidence_csv=file)
        self.assertFalse((self.root / ("developer_reconciliation_" + HEAD[:12])).exists())

    def test_wrong_head_unknown_export_and_duplicate_rejected(self):
        d = self.evidence(300)
        file = self.root / "wrong.csv"
        d["recorded_r_git_head"] = "b" * 40
        write_rows(file, [d])
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError, "source pins"):
            progress.reconcile(self.root, HEAD, evidence_csv=file)
        d["recorded_r_git_head"] = HEAD
        write_rows(file, [d, d])
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError, "duplicate"):
            progress.reconcile(self.root, HEAD, evidence_csv=file)
        d["python_name"] = "no_such_export"
        write_rows(file, [d])
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError, "Unknown"):
            progress.reconcile(self.root, HEAD, evidence_csv=file)

    def pilot_csv(self, forged=False):
        cases = {
            "alr_transform": ("finite_reference_0", "finite_reference_2"),
            "inverse_alr": ("finite_reference_0", "finite_reference_2"),
            "score_distance_matrix": ("score_components_1", "score_components_2"),
            "functional_trapezoid_weights": ("unnormalized", "normalized",
                "string_truthy", "empty_string_false"),
        }
        # Synthetic test inventory must use real frozen root export names.
        write_rows(self.root / progress.baseline.FILES[0], self.rows)
        records = []
        for name, ids in cases.items():
            for case in ids:
                records.append({
                    "python_name": name, "case_id": case,
                    "max_absolute_difference": "0",
                    "tolerance": "1e-11", "shapes_equal": "TRUE",
                    "developer_numeric_fixture_pass": "TRUE",
                    "recorded_r_git_head": HEAD,
                    "frozen_python_commit": progress.baseline.FROZEN_PYTHON,
                    "independent_reviewer_approved": "FALSE",
                    "independently_replayed_case": "FALSE",
                    "fully_certified": "FALSE",
                })
        if forged:
            records[0]["independently_replayed_case"] = "TRUE"
        file = self.root / "pilot_numeric.csv"
        write_rows(file, records)
        return file

    def test_source_pinned_numerical_pilots_are_partial_only(self):
        file = self.pilot_csv()
        z = progress.reconcile(self.root, HEAD, pilot_evidence_csv=file)
        self.assertEqual(z["evidence_records_verified_sha256"], 4)
        self.assertEqual(z["developer_evidence_ready_for_review"], 0)
        self.assertEqual(z["source_gaps_closed"], 0)
        queue = progress.baseline.read_csv(
            Path(z["output_dir"]) / progress.PROGRESS)
        one = next(q for q in queue if q["python_name"] == "alr_transform")
        self.assertEqual(one["developer_evidence_gates_passed"], "1")
        self.assertEqual(one["historical_source_gap_open"], "TRUE")
        self.assertEqual(one["independently_certified"], "FALSE")

    def test_pilot_forged_independent_claim_is_rejected(self):
        file = self.pilot_csv(forged=True)
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError,
                                    "forged approvals"):
            progress.reconcile(self.root, HEAD, pilot_evidence_csv=file)

    def test_invalid_evidence_boolean_fails_closed(self):
        d = self.evidence(301)
        d[progress.FLAGS[0]] = "PASS"
        file = self.root / "boolean.csv"
        write_rows(file, [d])
        with self.assertRaisesRegex(progress.baseline.ReviewBatchError,
                                    "explicitly TRUE or FALSE"):
            progress.reconcile(self.root, HEAD, evidence_csv=file)


if __name__ == "__main__":
    unittest.main()
