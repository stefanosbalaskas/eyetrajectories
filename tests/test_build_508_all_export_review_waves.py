"""Fail-closed shape and source blocker tests of 508-export wave builder."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1] / "scripts"))
import build_508_all_export_review_waves as m


class Full508Tests(unittest.TestCase):
    def test_source_gap_and_backend_gates(self):
        row={"namespace":"root","python_name":"f","kind":"function",
             "native_r_candidate":"etr_f","recorded_r_git_head":"a"*40,
             "frozen_python_commit":m.baseline.FROZEN_PYTHON,
             "review_lane":"RECORDED_SOURCE_DIFFERENCE",
             "source_gap_open":"TRUE","backend_or_estimand_distinct":"FALSE",
             "native_implementation_started":"TRUE",
             "native_nonfunction_representation":"",
             "first_unresolved_requirement":"gap"}
        self.assertEqual(m.review_blocker(row),"KNOWN_SOURCE_GAP")
        self.assertEqual(m.contract(row,"wave_01")["source_full_domain_certified"],"FALSE")
        row["source_gap_open"]="FALSE"
        row["backend_or_estimand_distinct"]="TRUE"
        self.assertEqual(m.review_blocker(row),"BACKEND_OR_ESTIMAND_DIFFERS")
        row["backend_or_estimand_distinct"]="FALSE"
        self.assertEqual(m.review_blocker(row),"INDEPENDENT_SOURCE_AND_SCIENTIFIC_REVIEW_MISSING")
        row["kind"]="nonfunction"
        self.assertEqual(m.review_blocker(row),"NATIVE_REPRESENTATION_MISSING")

    def test_unsigned_10_case_and_decision(self):
        r={key:"value" for key in m.IDENTITY}
        cases=m.cases_for(r)
        self.assertEqual(len(cases),10)
        self.assertEqual(len({c["criterion"] for c in cases}),10)
        self.assertTrue(all(c["independently_replayed"]=="FALSE" for c in cases))
        self.assertEqual(m.decision(r)["scope_decision"],"PENDING_INDEPENDENT_REVIEW")
        self.assertEqual(m.decision(r)["full_domain_certification_approved"],"FALSE")


if __name__=="__main__":
    unittest.main()
