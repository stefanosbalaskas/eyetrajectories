"""Isolated historical frozen-508 gap census for developer evidence tests.

Do not import production reviewed-source closures into temporary fixtures:
such records are cryptographically bound to native source and test files,
which are deliberately absent from these lightweight temporary test roots.
Actual closure verification belongs to test_source_gap_inventory.py.
"""
from __future__ import annotations

import csv
from pathlib import Path
import shutil

from source_gap_inventory import CLOSED_SEMANTIC_SCOPE, REVIEWED_FIELDS


def install_historical_source_inventory(real: Path, target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    for name in (
        "native_source_contract_gaps_stage22.csv",
        "native_nonfunction_source_gaps_v1.csv",
        "python_api_2026-10-25.csv",
    ):
        shutil.copyfile(real / name, target / name)

    callable_path = target / "native_source_contract_gaps_stage22.csv"
    with callable_path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fields, rows = reader.fieldnames, list(reader)
    for row in rows:
        if row["python_name"] not in CLOSED_SEMANTIC_SCOPE:
            row["unresolved_source_gap"] = "TRUE"
    with callable_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

    other_path = target / "native_nonfunction_source_gaps_v1.csv"
    with other_path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fields, rows = reader.fieldnames, list(reader)
    for row in rows:
        row["unresolved"] = "TRUE"
    with other_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

    review_manifest = target / "reviewed_source_contract_closures_v1.csv"
    review_manifest.write_text(",".join(REVIEWED_FIELDS) + "\n",
                               encoding="utf-8")
