#!/usr/bin/env python3
"""Evidence-guarded, developer-only registration of TWO no-argument frame contracts.

Requires actual R+Python direct source execution by capture_catalog_contract_evidence_batch27.R.
No Python/R representation identity or third-party approval is implied.
"""
import argparse,csv,hashlib,json
from pathlib import Path

NAMES={"mathematical_contract_frame": (88,
 ("contract_key","title","function","latex","site_anchor","scope")),
 "functional_recovery_metric_catalog_frame": (27,
 ("metric","quantity","direction","units","scope","description"))}
PIN="c1cd95ad718327550f7e55393ff38582872f7a94"
EVIDENCE=Path("artifacts/native_full_contract_evidence/catalog_batch27_developer_evidence.json")
REGISTRY=Path("inst/extdata/native_developer_verified_contracts.csv")
COLUMNS=("python_name","verified_contract_level","evidence_file",
 "evidence_sha256","remaining_representation_difference",
 "independent_scientific_certified")

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def validate(root):
    path=root/EVIDENCE
    if not path.is_file():raise ValueError("No executed R/Python catalog evidence; do not register a closure")
    obj=json.loads(path.read_text(encoding="utf-8"))
    if obj.get("protocol")!="developer_catalog_contract_closure_v1" or \
       obj.get("python_version")!="1.2.0" or obj.get("frozen_python_commit")!=PIN:
        raise ValueError("Wrong source protocol/version/commit")
    if obj.get("independent_certification_granted") is not False or \
       obj.get("python_vs_R_runtime_class_equivalence_claimed") is not False:
        raise ValueError("Unsupported certification or runtime-identity claim")
    fs=obj.get("local_files_sha256")
    if not isinstance(fs,dict) or set(fs)!={
      "R/native-math-contracts-diagnostics.R",
      "R/native-functional-rqa-recovery.R",
      "inst/extdata/native_mathematical_contract_frame_py120.csv",
      "inst/extdata/native_recovery_metric_catalog_py120.csv",
      "scripts/capture_catalog_contract_evidence_batch27.R"}:
        raise ValueError("Incomplete source hash inventory")
    for name,d in fs.items():
        p=root/name
        if not p.is_file() or sha(p)!=d:raise ValueError("Source evidence digest mismatch: "+name)
    cases=obj.get("function_results",[])
    if not isinstance(cases,list) or len(cases)!=2 or \
      {c.get("python_name") for c in cases}!=set(NAMES):
        raise ValueError("Exactly two reviewed deterministic frames are required")
    for c in cases:
        n=c["python_name"];rows,cols=NAMES[n]
        if c.get("rows")!=rows or tuple(c.get("validated_columns",[]))!=cols or \
          any(c.get(t) is not True for t in (
            "complete_zero_argument_domain","full_field_equality",
            "excess_argument_rejected_by_both")):
            raise ValueError("Incomplete full output and boundary evidence: "+n)
    if set(obj.get("additional_semantic_comparisons",[]))!={
      "list_mathematical_contracts","get_mathematical_contract",
      "functional_recovery_metric_catalog"}:
        raise ValueError("Not all five catalogs were inspected")
    return sha(path)

def register(root,write):
    digest=validate(root)
    path=root/REGISTRY
    if path.exists():
      with path.open(encoding="utf-8",newline="") as h:
        reader=csv.DictReader(h)
        if tuple(reader.fieldnames or ())!=COLUMNS:raise ValueError("Invalid developer closure registry header")
        previous=list(reader)
    else:previous=[]
    if any(x["python_name"] not in NAMES for x in previous):
        raise ValueError("Refuse to overwrite unrelated verified contract registrations")
    desired=[]
    for name in sorted(NAMES):
        desired.append({"python_name":name,"verified_contract_level":"complete_noarg_native_data_frame",
          "evidence_file":EVIDENCE.as_posix(),"evidence_sha256":digest,
          "remaining_representation_difference":"Python pandas.DataFrame versus native R data.frame",
          "independent_scientific_certified":"FALSE"})
    if not write:
        print("BATCH27_DEVELOPER_CLOSURE_DRY_RUN_PASS=2;ACTIVE_GAPS_AFTER_ACTIVATION=202")
        return
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open("w",encoding="utf-8",newline="") as h:
        writer=csv.DictWriter(h,COLUMNS,lineterminator="\n");writer.writeheader();writer.writerows(desired)
    print("BATCH27_DEVELOPER_CLOSURES_ACTIVATED=2;INDEPENDENT_APPROVALS=0")

def main():
    parser=argparse.ArgumentParser();parser.add_argument("--repo",default=".")
    parser.add_argument("--activate",action="store_true")
    args=parser.parse_args();register(Path(args.repo).resolve(),args.activate)
if __name__=="__main__":main()
