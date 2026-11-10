"""Evidence-progress triage must not convert bounded tests into parity."""
import csv
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import summarize_scientific_source_evidence as evidence
import source_gap_inventory as inventory
from support_source_inventory_fixture import install_historical_source_inventory

HEAD = "a" * 40


def write_csv(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


class ScientificSourceEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        directory = self.root / "inst" / "extdata"
        real = Path(__file__).resolve().parents[1]
        install_historical_source_inventory(real / "inst" / "extdata",
                                            directory)
        self.reports = (
            self.root / "artifacts" / "native_batch_numeric_diff" /
            HEAD[:12])
        self.reports.mkdir(parents=True)
        self.case = dict(
            python_name="functional_trapezoid_weights",
            case_id="grid_positive", outcome="PASS_NUMERIC",
            r_git_head=HEAD, frozen_python_commit=inventory.FROZEN_PYTHON)
        self.gee = dict(
            python_name="fit_generalized_function_on_scalar_regression",
            source_fixture="poisson", field="basis",
            outcome="PASS_NUMERIC",
            r_git_head=HEAD, frozen_python_commit=inventory.FROZEN_PYTHON)
        self.bootstrap = dict(
            python_name="bootstrap_generalized_function_on_scalar_coefficients",
            scientific_family="grouped", case="bootstrap",
            field="bootstrap_coefficient_functions", outcome="PASS_NUMERIC",
            r_git_head=HEAD, frozen_python_commit=inventory.FROZEN_PYTHON)
        self.write_reports()

    def tearDown(self):
        self.temp.cleanup()

    def write_reports(self):
        write_csv(self.reports /
                  evidence.REPORTS["bounded_numeric"], [self.case])
        write_csv(self.reports /
                  evidence.REPORTS["generalized_functional_gee"], [self.gee])
        write_csv(self.reports /
                  evidence.REPORTS["generalized_gee_bootstrap"],
                  [self.bootstrap])

    def test_live_source_coverage_is_distinct_from_source_gap_closure(self):
        report = evidence.summarize(self.root, HEAD, require_all=True,
                                    write=False)
        self.assertEqual(report["total_observed_comparison_cases"], 3)
        self.assertEqual(report["passing_bounded_comparison_cases"], 3)
        self.assertEqual(report["divergent_or_invalid_cases"], 0)
        self.assertEqual(
            report["unique_python_functions_with_actual_source_cases"], 3)
        self.assertEqual(report["open_documented_source_gaps"],
                         inventory.read_inventory(self.root).open_total)
        self.assertEqual(report["independent_certifications_inferred"], 0)
        self.assertEqual(report["developer_full_contract_approvals_inferred"], 0)
        self.assertTrue(all(r["source_gap_still_open"] and
                            r["developer_finite_domain_oracle_evidence"] and
                            not r["developer_full_contract_approved"] and
                            not r["independent_full_contract_certified"]
                            for r in report["function_evidence"]))

    def test_output_writes_per_export_and_report_hashes(self):
        result = evidence.summarize(self.root, HEAD, write=True)
        folder = (self.root / "artifacts" /
                  "scientific_source_evidence" / HEAD[:12])
        self.assertTrue((folder / "developer_source_progress_UNSIGNED.json")
                        .is_file())
        with (folder / "developer_source_functions_UNSIGNED.csv").open(
                newline="", encoding="utf-8") as file:
            rows = list(csv.DictReader(file))
        self.assertEqual(len(rows), 3)
        self.assertEqual(len(result["source_report_sha256"]), 3)
        self.assertTrue(all(len(digest) == 64 for digest in
                            result["source_report_sha256"].values()))

    def test_mismatched_head_is_rejected(self):
        self.gee["r_git_head"] = "b" * 40
        self.write_reports()
        with self.assertRaisesRegex(evidence.EvidenceAuditError, "pin"):
            evidence.summarize(self.root, HEAD, write=False)

    def test_mismatched_python_source_is_rejected(self):
        self.bootstrap["frozen_python_commit"] = "b" * 40
        self.write_reports()
        with self.assertRaisesRegex(evidence.EvidenceAuditError, "pin"):
            evidence.summarize(self.root, HEAD, write=False)

    def test_failure_is_reported_not_promoted(self):
        self.bootstrap["outcome"] = "DIVERGENT_NUMERIC"
        self.write_reports()
        report = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(report["divergent_or_invalid_cases"], 1)
        self.assertFalse(report["all_observed_comparisons_without_divergence"])
        row = next(q for q in report["function_evidence"]
                   if q["python_name"] == self.bootstrap["python_name"])
        self.assertFalse(row["developer_finite_domain_oracle_evidence"])
        self.assertEqual(row["source_disagreements"], 1)

    def test_both_accept_is_inconclusive_not_proof(self):
        self.case["outcome"] = "PASS_BOTH_ACCEPT"
        self.write_reports()
        report = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(report["inconclusive_both_acceptance_cases"], 1)
        self.assertEqual(report["passing_bounded_comparison_cases"], 2)


    def test_sparse_async_public_workflow_evidence_is_not_independent_approval(self):
        row = dict(
            python_name="run_sparse_mfpca_async_workflow",
            source_fixture="async_correlated_noise",
            field="covariance_cxy",outcome="PASS_NUMERIC",
            r_git_head=HEAD,
            frozen_python_commit=inventory.FROZEN_PYTHON)
        write_csv(self.reports /
                  evidence.OPTIONAL_REPORTS["sparse_mfpca_async_native"],
                  [row])
        result = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(result["total_observed_comparison_cases"], 4)
        observed = next(
            item for item in result["function_evidence"]
            if item["python_name"] == "run_sparse_mfpca_async_workflow")
        self.assertTrue(observed["source_gap_still_open"])
        self.assertTrue(observed["developer_finite_domain_oracle_evidence"])
        self.assertFalse(observed["independent_full_contract_certified"])

    def test_sparse_multilevel_workflow_remains_unsigned_with_observed_source_cases(self):
        row = dict(
            python_name="run_sparse_multilevel_workflow",
            source_fixture="fixed_noise_6participants_24trials",
            field="between_covariance",outcome="PASS_NUMERIC",
            r_git_head=HEAD,
            frozen_python_commit=inventory.FROZEN_PYTHON)
        write_csv(self.reports /
                  evidence.OPTIONAL_REPORTS["sparse_multilevel_native"],
                  [row])
        report = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(report["total_observed_comparison_cases"], 4)
        observed = next(
            item for item in report["function_evidence"]
            if item["python_name"] == "run_sparse_multilevel_workflow")
        self.assertTrue(observed["source_gap_still_open"])
        self.assertTrue(observed["developer_finite_domain_oracle_evidence"])
        self.assertFalse(observed["independent_full_contract_certified"])

    def test_sparse_prediction_workflow_source_cases_respect_open_gap(self):
        row = dict(
            python_name="run_sparse_prediction_workflow",
            source_fixture="grouped_fixed_noise",
            field="critical_value",outcome="PASS_NUMERIC",
            r_git_head=HEAD,
            frozen_python_commit=inventory.FROZEN_PYTHON)
        write_csv(self.reports /
                  evidence.OPTIONAL_REPORTS["sparse_prediction_native"],
                  [row])
        report = evidence.summarize(
            self.root, HEAD, write=False, require_all=True)
        self.assertEqual(report["total_observed_comparison_cases"], 4)
        evidence_row = next(
            item for item in report["function_evidence"]
            if item["python_name"] == "run_sparse_prediction_workflow")
        self.assertTrue(evidence_row["source_gap_still_open"])
        self.assertTrue(
            evidence_row["developer_finite_domain_oracle_evidence"])
        self.assertFalse(
            evidence_row["independent_full_contract_certified"])

    def test_joint_sparse_source_cases_retained_as_unsigned_developer_evidence(self):
        row = dict(
            python_name="fit_sparse_mfpca",
            source_fixture="diagonal_noise", field="covariance_cxy",
            outcome="PASS_NUMERIC", r_git_head=HEAD,
            frozen_python_commit=inventory.FROZEN_PYTHON)
        write_csv(self.reports /
                  evidence.OPTIONAL_REPORTS["sparse_mfpca_native"], [row])
        result = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(result["total_observed_comparison_cases"], 4)
        mfpca = next(item for item in result["function_evidence"]
                     if item["python_name"] == "fit_sparse_mfpca")
        self.assertTrue(mfpca["source_gap_still_open"])
        self.assertTrue(mfpca["developer_finite_domain_oracle_evidence"])
        self.assertFalse(mfpca["developer_full_contract_approved"])
        self.assertFalse(mfpca["independent_full_contract_certified"])

    def test_frozen_public_no_gap_source_cases_are_counted_without_gap_promotion(self):
        row = dict(
            python_name="fit_sparse_fpca",
            source_fixture="fixed_noise", field="covariance",
            outcome="PASS_NUMERIC", r_git_head=HEAD,
            frozen_python_commit=inventory.FROZEN_PYTHON)
        write_csv(self.reports /
                  evidence.OPTIONAL_REPORTS["sparse_fpca_native"], [row])
        result = evidence.summarize(self.root, HEAD, require_all=True,
                                    write=False)
        self.assertEqual(result["total_observed_comparison_cases"], 4)
        self.assertEqual(
            result["unique_python_functions_with_actual_source_cases"], 4)
        sparse = next(item for item in result["function_evidence"]
                      if item["python_name"] == "fit_sparse_fpca")
        self.assertFalse(sparse["source_gap_still_open"])
        self.assertTrue(sparse["developer_finite_domain_oracle_evidence"])
        self.assertFalse(sparse["developer_full_contract_approved"])
        self.assertEqual(result["independent_certifications_inferred"], 0)

    def test_unknown_function_rejected(self):
        self.gee["python_name"] = "not_in_frozen_508_inventory"
        self.write_reports()
        with self.assertRaisesRegex(evidence.EvidenceAuditError,
                                    "Unexpected source callable"):
            evidence.summarize(self.root, HEAD, write=False)

    def test_duplicate_evidence_case_rejected(self):
        write_csv(self.reports /
                  evidence.REPORTS["bounded_numeric"],
                  [self.case, self.case])
        with self.assertRaisesRegex(evidence.EvidenceAuditError,
                                    "Duplicate source"):
            evidence.summarize(self.root, HEAD, write=False)

    def test_require_all_respects_omitted_optional_scientific_runner(self):
        (self.reports /
         evidence.REPORTS["generalized_gee_bootstrap"]).unlink()
        report = evidence.summarize(self.root, HEAD, write=False)
        self.assertEqual(report["total_observed_comparison_cases"], 2)
        with self.assertRaisesRegex(evidence.EvidenceAuditError,
                                    "Expected source report missing"):
            evidence.summarize(self.root, HEAD, require_all=True,
                               write=False)


if __name__ == "__main__":
    unittest.main()
