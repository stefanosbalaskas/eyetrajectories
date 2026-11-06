#!/usr/bin/env python3
"""Source-aware 204-entry description triage, not 204 numerical certifications."""
import argparse,csv,json
from collections import Counter
from pathlib import Path

REVIEWED_DESCRIPTIONS={
 "workflow_reporting_text": "Bounded Python repr quoting now implemented, exotic Unicode and dataclass errors remain",
 "recurrence_network": "Batch 25 full qualification and Batch 26 targeted results update source witness",
 "mathematical_contract_frame": "88x6 complete semantic frame eligible for evidence-gated developer closure",
 "functional_recovery_metric_catalog_frame": "27x6 complete semantic frame eligible for evidence-gated developer closure",
}

def run(root):
    gap=root/'artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv'
    with gap.open(encoding='utf-8',newline='') as f:rows=list(csv.DictReader(f))
    if len(rows)!=204 or len({x['python_name'] for x in rows})!=204:
        raise ValueError('Expected complete 204-entry source audit')
    output=[]
    for x in rows:
        name=x['python_name'];cat=x['provisional_primary_blocker']
        if cat=='scientifically_alternative_estimator_or_backend':
            science='ALTERNATIVE_BACKEND_OR_ESTIMAND_REQUIRES_DIRECT_NUMERICAL_REPLAY'
        elif cat=='scientific_or_numeric_domain_and_result_schema':
            science='NUMERICAL_FULL_DOMAIN_NOT_VERIFIED'
        else:science='NO_SCIENTIFIC_DISCREPANCY_DETERMINATION_FROM_STATIC_CODE'
        output.append({
          'python_name':name,'native_r_candidate':x['native_r_candidate'],
          'provisional_blocker':cat,
          'named_R_implementation_observed':x['native_named_definition_found'],
          'description_review':'UPDATED_FROM_VERIFIED_BATCH_STATUS' if name in REVIEWED_DESCRIPTIONS else 'PENDING_MANUAL_SOURCE_DOMAIN_REVIEW',
          'description_review_detail':REVIEWED_DESCRIPTIONS.get(name,''),
          'scientific_method_discrepancy_review':science,
          'cross_language_runtime_representation_difference':x['cross_language_representation_review_required'],
          'full_domain_developer_verified':x.get('developer_verified_full_function_contract','FALSE'),
          'remaining_developer_source_gap':x.get('developer_active_source_gap','TRUE'),
          'independent_scientific_certified':'FALSE'})
    target=root/'artifacts/native_source_contract_reaudit_20261106/description_reaudit_204_batch27.csv'
    target.parent.mkdir(parents=True,exist_ok=True)
    with target.open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,output[0].keys(),lineterminator='\n');w.writeheader();w.writerows(output)
    assert len(output)==204
    print('BATCH27_204_DESCRIPTION_REAUDIT_PASS: descriptions_updated=',len(REVIEWED_DESCRIPTIONS),
      '; full-domain-not-established=',204-sum(x['full_domain_developer_verified']=='TRUE' for x in output),
      '; independent_certifications=0',sep='')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--repo',default='.')
    args=parser.parse_args();run(Path(args.repo).resolve())
