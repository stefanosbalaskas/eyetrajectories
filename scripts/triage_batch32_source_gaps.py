#!/usr/bin/env python3
"""Read-only Batch 32 gap triage from the verified 204-row export inventory.

The generated audit ledger is authoritative for WHICH exports have recorded
source gaps. The checked-in historical ledger can supply missing descriptive
metadata, but it must never silently add/remove an export or grant approval.
"""
from __future__ import annotations
import argparse
import csv
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import tempfile

HISTORIC_EXPECTED = 204
FIELDS = ('native_r_candidate', 'gap_kind', 'known_source_difference')


def read_ledger(path: Path):
    with path.open('r', newline='', encoding='utf-8-sig') as stream:
        rdr = csv.DictReader(stream)
        headers = rdr.fieldnames or []
        if 'python_name' not in headers:
            raise ValueError(f"Ledger {path} has no python_name column; headers={headers!r}")
        rows = list(rdr)
    seen = set()
    for idx, row in enumerate(rows, 1):
        name = (row.get('python_name') or '').strip()
        if not name or name in seen:
            raise ValueError(f'Duplicate or missing Python export at row {idx} in {path}')
        seen.add(name)
        row['python_name'] = name
    return rows, headers


def classify(name: str, kind: str, description: str):
    k = kind.lower()
    d = description.lower()
    if name.startswith('plot_'):
        return 'graphical_semantics', 'Compare numerical plot geometry separately from renderer classes'
    if any(x in k for x in ('scientifically_distinct', 'alternative', 'estimator', 'backend')):
        return 'estimator_or_backend', 'Compare scientific estimands and actual backends'
    if any(x in k for x in ('numeric', 'scientific', 'stochastic', 'simulation', 'rng', 'overflow')):
        return 'numeric_source_parity', 'Compare finite, exceptional and stochastic numerical behavior'
    if any(x in name for x in ('_reporting_text', '_frame', '_summary')):
        return 'reporting_and_table', 'Compare values, schemas, serialization and return-type policy separately'
    if any(x in k for x in ('class', 'return', 'tuple', 'pandas', 's3', 'dataclass', 'type', 'domain', 'representation')):
        return 'cross_language_representation', 'Document the native R and Python cross-language mapping'
    if 'matplotlib' in d:
        return 'graphical_semantics', 'Compare geometry and renderer mapping'
    return 'needs_scientific_review', 'Inspect frozen Python and native R implementations'


def write_json_atomic(path: Path, data: dict):
    with tempfile.NamedTemporaryFile('w', dir=path.parent, encoding='utf-8',
                                     newline='\n', delete=False) as fh:
        tmp = Path(fh.name)
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write('\n')
    os.replace(tmp, path)


def write_csv_atomic(path: Path, rows: list[dict]):
    with tempfile.NamedTemporaryFile('w', dir=path.parent, encoding='utf-8',
                                     newline='', delete=False) as fh:
        tmp = Path(fh.name)
        writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tmp, path)


def run(repo: Path) -> dict:
    generated = repo / 'artifacts/native_source_contract_reaudit_20261106/all_204_source_gaps.csv'
    canonical = repo / 'inst/extdata/native_source_contract_gaps_stage22.csv'
    if not generated.exists() and not canonical.exists():
        raise ValueError('Neither generated nor checked-in source gap ledger exists')
    primary = generated if generated.exists() else canonical
    rows, source_headers = read_ledger(primary)
    if len(rows) != HISTORIC_EXPECTED:
        raise ValueError(f'Expected {HISTORIC_EXPECTED} historical gaps; {primary} has {len(rows)}')

    supplemental = {}
    supplemental_count = 0
    if canonical.exists() and canonical != primary:
        canonical_rows, canonical_headers = read_ledger(canonical)
        supplemental = {row['python_name']: row for row in canonical_rows}
        supplemental_count = len(canonical_rows)
    else:
        canonical_headers = source_headers

    missing_names = []
    incomplete = []
    counter = Counter()
    work = []
    for row in rows:
        name = row['python_name']
        alternative = supplemental.get(name, {})
        if supplemental and not alternative:
            missing_names.append(name)
        enriched = {}
        provenance = {}
        for key in FIELDS:
            native = (row.get(key) or '').strip()
            fallback = (alternative.get(key) or '').strip()
            value = native or fallback
            enriched[key] = value
            provenance[key] = ('generated' if native else
                               ('checked_in' if fallback else 'unavailable'))
        missing_fields = [key for key in FIELDS if not enriched[key]]
        if missing_fields:
            incomplete.append({'python_name': name, 'missing_fields': missing_fields})
        stream, criterion = classify(name, enriched['gap_kind'], enriched['known_source_difference'])
        counter[stream] += 1
        work.append({
            'python_name': name,
            'native_r_candidate': enriched['native_r_candidate'],
            'workstream': stream,
            'gap_kind': enriched['gap_kind'],
            'review_requirement': criterion,
            'metadata_source': ';'.join(f'{k}:{provenance[k]}' for k in FIELDS),
            'metadata_complete': not missing_fields,
            'source_gap_unchanged': True,
            'developer_full_contract_approved_by_this_script': False,
            'independent_certified_by_this_script': False,
        })
    priority = {'numeric_source_parity': 1, 'estimator_or_backend': 2,
                'needs_scientific_review': 3, 'reporting_and_table': 4,
                'graphical_semantics': 5, 'cross_language_representation': 6}
    work.sort(key=lambda item: (priority[item['workstream']], item['python_name']))
    counts = {kind: counter[kind] for kind in priority}
    report = {
        'input_ledger': primary.relative_to(repo).as_posix(),
        'input_schema_fields': source_headers,
        'input_ledger_sha256': hashlib.sha256(primary.read_bytes()).hexdigest(),
        'descriptive_fallback_ledger': canonical.relative_to(repo).as_posix() if supplemental else None,
        'fallback_schema_fields': canonical_headers,
        'fallback_ledger_sha256': hashlib.sha256(canonical.read_bytes()).hexdigest() if supplemental else None,
        'fallback_ledger_rows': supplemental_count,
        'fallback_missing_export_names': missing_names,
        'metadata_incomplete_count': len(incomplete),
        'metadata_incomplete_details': incomplete,
        'historic_gap_rows': len(work),
        'workstream_counts': counts,
        'is_classification_only': True,
        'updates_gap_ledger': False,
        'developer_contract_closures': 0,
        'independent_certifications': 0,
    }
    out = repo / 'artifacts/native_full_contract_evidence'
    out.mkdir(parents=True, exist_ok=True)
    write_json_atomic(out / 'batch32_gap_workstream_summary.json', report)
    write_csv_atomic(out / 'batch32_gap_workstream_queue.csv', work)
    return report


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', required=True)
    args = p.parse_args()
    try:
        report = run(Path(args.repo).resolve())
    except (OSError, ValueError, csv.Error) as exc:
        p.error(f'{exc}; no source gap ledger was modified')
    print('BATCH32_SOURCE_GAP_TRIAGE_ROWS='+str(report['historic_gap_rows']))
    print('BATCH32_SOURCE_LEDGER_SCHEMA='+','.join(report['input_schema_fields']))
    print('BATCH32_METADATA_FALLBACK_ROWS='+str(report['fallback_ledger_rows']))
    print('BATCH32_METADATA_INCOMPLETE='+str(report['metadata_incomplete_count']))
    print('BATCH32_WORKSTREAM_COUNTS='+json.dumps(report['workstream_counts'],sort_keys=True))
    print('BATCH32_NO_NEW_CLOSURES=TRUE;INDEPENDENT=0')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
