"""Fail-closed shape and source blocker tests of 508-export wave builder."""
import sys
from pathlib import Path
import unittest
import tempfile
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1] / "scripts"))
import build_508_all_export_review_waves as m
from test_verify_508_certification_batch import synthetic_gap_counts


class Full508Tests(unittest.TestCase):
    def setUp(self):
        # Exercise the real 508-wave validator against a synthetic count
        # snapshot, not against currently stale author-side source receipts.
        # Production builds still invoke the strict live read_inventory().
        self.count_patch = patch.object(
            m.source_gap_inventory, "read_inventory",
            return_value=synthetic_gap_counts())
        self.count_patch.start()
        self.addCleanup(self.count_patch.stop)

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
        row["documented_source_difference"]="Python accepts a broader input domain"
        row["documented_python_source_witness"]="pinned module source and local replay"
        row["required_gap_resolution"]="Implement or restrict source domain"
        self.assertIn("broader input",m.contract(row,"wave_01")["documented_source_difference"])
        self.assertEqual(m.contract(row,"wave_01")["source_full_domain_certified"],"FALSE")
        row["source_gap_open"]="FALSE"
        row["backend_or_estimand_distinct"]="TRUE"
        self.assertEqual(m.review_blocker(row),"BACKEND_OR_ESTIMAND_DIFFERS")
        row["backend_or_estimand_distinct"]="FALSE"
        self.assertEqual(m.review_blocker(row),"INDEPENDENT_SOURCE_AND_SCIENTIFIC_REVIEW_MISSING")
        row["kind"]="nonfunction"
        self.assertEqual(m.review_blocker(row),"NATIVE_REPRESENTATION_MISSING")

    def test_full_508_build_verify_coverage_and_tamper_rejection(self):
        with tempfile.TemporaryDirectory() as tmp:
            packet = Path(tmp)
            source = packet / m.baseline.FILES[0]
            head = "c"*40
            gaps = m.source_gap_inventory.read_inventory()
            q=[]
            for i in range(508):
                kind = "function" if i < 380 else "nonfunction"
                q.append({
                    "namespace":"root",
                    "python_name":f"export_{i:03d}",
                    "kind":kind,
                    "native_r_candidate":f"etr_export_{i:03d}",
                    "recorded_r_git_head":head,
                    "frozen_python_commit":m.baseline.FROZEN_PYTHON,
                    "review_lane":("RECORDED_SOURCE_DIFFERENCE"
                                   if (i < gaps.active_callable or
                                       (i == 380 and gaps.active_nonfunction))
                                   else "FUNCTION_NO_RECORDED_GAP" if i < 380
                                   else "NONFUNCTION_NO_RECORDED_GAP"),
                    "source_gap_open":"TRUE"
                                   if (i < gaps.active_callable or
                                       (i == 380 and gaps.active_nonfunction))
                                   else "FALSE",
                    "backend_or_estimand_distinct":"FALSE",
                    "native_implementation_started":"TRUE",
                    "native_nonfunction_representation":"R equivalent" if i>=380 else "",
                    "first_unresolved_requirement":"unreviewed",
                    "currently_authoritatively_certified":"FALSE",
                })
            m.write_csv(source,q)
            with patch.object(m.baseline,"verify",return_value={"r_git_head":head}):
                outcome=m.build(packet,head)
                self.assertEqual(outcome["wave_count"],15)
                self.assertEqual(outcome["review_criterion_count"],5080)
                verified=m.verify(packet,head)
                self.assertEqual(verified["status"],"PASS_UNSIGNED_PACKET_INTEGRITY_ONLY")
                self.assertEqual(verified["independent_certifications"],0)
                with self.assertRaisesRegex(m.baseline.ReviewBatchError,"exists"):
                    m.build(packet,head)
                target=packet/m.DIRECTORY/"wave_15"/"cases_UNSIGNED.csv"
                with target.open("a",encoding="utf-8") as stream:
                    stream.write("tamper\n")
                with self.assertRaisesRegex(m.baseline.ReviewBatchError,"Checksum"):
                    m.verify(packet,head)

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
