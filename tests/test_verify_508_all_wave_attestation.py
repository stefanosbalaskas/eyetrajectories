"""Synthetic structural tests; GPG is mocked, not an external reviewer."""
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1] / "scripts"))
import build_508_all_export_review_waves as waves
import verify_508_all_wave_attestation as attest


class WaveAttestationTests(unittest.TestCase):
    def prepare(self, packet):
        wave_dir=packet/waves.DIRECTORY/"wave_01"
        wave_dir.mkdir(parents=True)
        row={
            "namespace":"root", "python_name":"f", "kind":"function",
            "native_r_candidate":"etr_f",
            "recorded_r_git_head":"a"*40,
            "frozen_python_commit":waves.baseline.FROZEN_PYTHON,
            "source_gap_open":"TRUE", "review_lane":"RECORDED_SOURCE_DIFFERENCE",
            "native_implementation_started":"TRUE",
            "backend_or_estimand_distinct":"FALSE",
            "native_nonfunction_representation":"",
            "first_unresolved_requirement":"source gap",
        }
        contracts=[waves.contract(row,"wave_01")]
        cases=waves.cases_for(row)
        decisions=[waves.decision(row)]
        for name,rows in zip(waves.FILES,(contracts,cases,decisions)):
            waves.write_csv(wave_dir/name,rows)
        for c in cases:
            c["reviewer_created_evidence_reference"]="independently created replay log"
            c["reviewer_written_findings"]="Verified published source mismatch at boundary"
            c["independently_replayed"]="TRUE"
        d=decisions[0]
        for key in ("reviewer_name","reviewer_affiliation","reviewer_contact",
                    "reviewer_signed_evidence_reference","reviewer_signed_utc"):
            d[key]="independent reviewer evidence"
        d["reviewer_independent_of_implementation_team"]="TRUE"
        d["scope_decision"]="NOT_EQUIVALENT"
        case_file=packet/"completed_cases.csv"
        decisions_file=packet/"completed_decisions.csv"
        waves.write_csv(case_file,cases)
        waves.write_csv(decisions_file,decisions)
        return case_file,decisions_file

    def test_signed_negative_finding_valid_receipt_but_zero_certificates(self):
        with tempfile.TemporaryDirectory() as td:
            packet=Path(td)
            c,d=self.prepare(packet)
            with patch.object(attest.waves,"verify",return_value={}), \
                 patch.object(attest.original,"verify_signature",return_value=None):
                result=attest.receipt(packet,1,c,d,packet/"c.asc",packet/"d.asc",
                                       "a"*40,"b"*40)
            self.assertEqual(result["signed_exports_reviewed"],1)
            self.assertEqual(result["full_source_parity_findings"],0)
            self.assertEqual(result["automatically_certified_exports"],0)

    def test_known_source_gap_forbids_full_parity_even_if_signed(self):
        with tempfile.TemporaryDirectory() as td:
            packet=Path(td)
            c,d=self.prepare(packet)
            rows=waves.baseline.read_csv(d)
            rows[0]["scope_decision"]="FULL_SOURCE_PARITY"
            for field in attest.FULL_GATES:
                rows[0][field]="TRUE"
            waves.write_csv(d,rows)
            with patch.object(attest.waves,"verify",return_value={}), \
                 patch.object(attest.original,"verify_signature",return_value=None):
                with self.assertRaisesRegex(waves.baseline.ReviewBatchError,
                                            "known gap"):
                    attest.receipt(packet,1,c,d,packet/"c.asc",packet/"d.asc",
                                   "a"*40,"b"*40)


if __name__=="__main__":
    unittest.main()
