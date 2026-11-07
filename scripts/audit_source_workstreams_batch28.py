#!/usr/bin/env python3
"""No auto-closing of gaps. Review source-backed primary blocker workstreams."""
from __future__ import annotations
import argparse,csv,json
from collections import Counter
from pathlib import Path

FOCUS={"workflow_steps_frame","workflow_decisions_frame",
 "workflow_summary_frame","workflow_reporting_text",
 "functional_simulation_scenario_frame",
 "functional_recovery_scenario_catalog_frame"}
SCIENCE={
 "fit_sparse_fpca_fdapy":"Python FDApy UFPCA versus alternate fdapace PACE",
 "fit_elastic_fpca":"Python fdasrsf elastic SRVF alignment versus native identity alignment",
 "fit_functional_mixed_effects_regression":"Python statsmodels MixedLM likelihood/REML versus native moments",
 "fit_generalized_function_on_scalar_regression":"Python statsmodels GEE versus native GLM estimating equations",
 "fit_sparse_mfpca":"Python joint multivariate sparse covariance versus native score PCA",
}

def read(path):
 with path.open(encoding="utf-8",newline="") as f:
  r=csv.DictReader(f);return list(r)

def run(root:Path):
 p=root/"artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv"
 if not p.is_file():raise RuntimeError("Run the existing 204-gap audit first")
 rows=read(p)
 if len(rows)!=204 or len({r['python_name'] for r in rows})!=204:
  raise RuntimeError("Expected original 204 unique frozen source gaps")
 recorded=sum(r['recorded_source_gap'].upper()=='TRUE' for r in rows)
 closed=sum(r['developer_verified_full_function_contract'].upper()=='TRUE' for r in rows)
 active=sum(r['developer_active_source_gap'].upper()=='TRUE' for r in rows)
 certified=sum(r['independent_scientific_certified'].upper()=='TRUE' for r in rows)
 if recorded!=204 or closed!=2 or active!=202 or certified!=0:
  raise RuntimeError("Batch 28 requires the 2 qualifying Batch 27 closures and zero independent approvals")
 focus=[r for r in rows if r['python_name'] in FOCUS]
 alt=[r for r in rows if r['provisional_primary_blocker']=='scientifically_alternative_estimator_or_backend']
 plots=[r for r in rows if r['provisional_primary_blocker']=='visualization_backend_and_graphical_schema']
 if len(focus)!=6 or len(alt)!=16 or len(plots)!=71:
  raise RuntimeError("Reporting or estimator review targets differ from source inventory")
 out=root/'artifacts/native_source_contract_reaudit_20261106'
 out.mkdir(parents=True,exist_ok=True)
 with (out/'batch28_scientific_estimator_workstream.csv').open('w',encoding='utf-8',newline='') as h:
  wr=csv.DictWriter(h,fieldnames=['python_name','native_r_candidate','source_difference','required_scientific_oracle','independent_reviewer_decision'])
  wr.writeheader()
  for r in alt:
   name=r['python_name'];difference=SCIENCE.get(name,r['ledger_gap_kind'])
   wr.writerow({'python_name':name,'native_r_candidate':r['native_r_candidate'],
    'source_difference':difference,
    'required_scientific_oracle':'Compare original frozen estimator objective, seed, optimization, fitted coefficients, inference, boundaries and error schema',
    'independent_reviewer_decision':'PENDING'})
 with (out/'batch28_visualization_geometry_workstream.csv').open('w',encoding='utf-8',newline='') as h:
  wr=csv.DictWriter(h,fieldnames=['python_name','native_r_candidate','source_plot_contract','native_equivalent_geometry_review','matplotlib_to_R_return_representation','source_axes_numeric_replay','independent_reviewer_decision'])
  wr.writeheader()
  for r in sorted(plots,key=lambda r:r['python_name']):
   wr.writerow({'python_name':r['python_name'],'native_r_candidate':r['native_r_candidate'],
    'source_plot_contract':r['ledger_gap_kind'],
    'native_equivalent_geometry_review':'PENDING_PANEL_TRACE_AND_DATA_REPLAY',
    'matplotlib_to_R_return_representation':'DIFFERENT_AND_NOT_CLAIMED_IDENTICAL',
    'source_axes_numeric_replay':'PENDING','independent_reviewer_decision':'PENDING'})
 with (out/'batch28_reporting_review_matrix.csv').open('w',encoding='utf-8',newline='') as h:
  fields=['python_name','category','numeric_or_field_oracle','json_and_utf8','input_error_domain','python_vs_native_return_class','independent_decision','signature']
  wr=csv.DictWriter(h,fieldnames=fields);wr.writeheader()
  for r in sorted(focus,key=lambda x:x['python_name']):
   wr.writerow({'python_name':r['python_name'],'category':r['provisional_primary_blocker'],
    'numeric_or_field_oracle':'PENDING_LIVE_REPLAY','json_and_utf8':'PENDING_LIVE_REPLAY',
    'input_error_domain':'UNBOUNDED_SOURCE_DOMAIN_OPEN',
    'python_vs_native_return_class':'DIFFERENT_NATIVE_R_VS_PYTHON',
    'independent_decision':'PENDING','signature':''})
 summary={'historical_recorded_source_gaps':recorded,'developer_verified_complete_contracts':closed,
  'developer_active_source_gaps':active,'independent_certifications':certified,
  'targeted_reporting_and_schema_functions':len(focus),
  'separate_alternative_estimator_workstream':len(alt),
  'separate_plotting_geometry_workstream':len(plots),
  'not_a_full_contract_or_external_certification':True,
  'by_blocker':dict(sorted(Counter(r['provisional_primary_blocker'] for r in rows).items()))}
 (out/'batch28_workstream_summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
 print('BATCH28_REAUDIT_PASS=204;DEVELOPER_ACTIVE=202;REPORTING_TARGETS=6;PLOTS=71;ALT_ESTIMATORS=16;INDEPENDENT=0')
 return summary

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--repo',default='.')
 a=ap.parse_args();run(Path(a.repo).resolve())
