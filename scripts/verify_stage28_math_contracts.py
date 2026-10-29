#!/usr/bin/env python3
"""Complete read-only published Python 1.2 mathematical registry attestation.

Requires the *installed published* eyetrajectoriespy==1.2.0, not the
development checkout. Emits a deterministic canonical digest of all 88
public scientific documentation rows after a full cell-by-cell check.
No estimators run, no release gates are self-approved.
"""
from __future__ import annotations

import csv
import hashlib
import importlib.metadata
import json
from pathlib import Path
import sys

EXPECTED_PYTHON_VERSION = "1.2.0"
EXPECTED_CONTRACTS = 41
EXPECTED_ROWS = 88
COLUMNS = ("contract_key", "title", "function", "latex", "site_anchor", "scope")


def verify() -> dict[str, object]:
    actual_version = importlib.metadata.version("eyetrajectoriespy")
    if actual_version != EXPECTED_PYTHON_VERSION:
        raise AssertionError(
            f"Expected published Python {EXPECTED_PYTHON_VERSION}, got {actual_version}"
        )

    from eyetrajectoriespy import (
        get_mathematical_contract,
        list_mathematical_contracts,
        mathematical_contract_frame,
    )

    path = (
        Path(__file__).resolve().parent.parent
        / "inst"
        / "extdata"
        / "native_mathematical_contract_frame_py120.csv"
    )
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if tuple(reader.fieldnames or ()) != COLUMNS:
            raise AssertionError("Pinned native source schema differs")
        native = list(reader)

    source = mathematical_contract_frame()
    contracts = list_mathematical_contracts()
    if len(native) != EXPECTED_ROWS or len(source) != EXPECTED_ROWS:
        raise AssertionError("Published source mathematical frame is not 88 rows")
    if len(contracts) != EXPECTED_CONTRACTS:
        raise AssertionError("Published Python mathematical registry is not 41 contracts")
    if tuple(source.columns) != COLUMNS:
        raise AssertionError("Published source mathematical frame schema differs")
    if len({row["function"] for row in native}) != EXPECTED_ROWS:
        raise AssertionError("Pinned source contains duplicate public functions")

    keys_in_order = []
    for row_index, (row, (_, expected)) in enumerate(zip(native, source.iterrows(), strict=True)):
        for column in COLUMNS:
            if row[column] != expected[column]:
                raise AssertionError(
                    f"Mathematical contract mismatch at row={row_index} field={column}: "
                    f"{row[column]!r} != {expected[column]!r}"
                )
        if row["contract_key"] not in keys_in_order:
            keys_in_order.append(row["contract_key"])
    if len(keys_in_order) != EXPECTED_CONTRACTS:
        raise AssertionError("Pinned mathematical registry does not include 41 unique contracts")
    if tuple(c.key for c in contracts) != tuple(keys_in_order):
        raise AssertionError("Published source mathematical contract order differs")

    for index, contract in enumerate(contracts):
        rows = [x for x in native if x["contract_key"] == contract.key]
        if tuple(x["function"] for x in rows) != contract.public_api:
            raise AssertionError(f"Contract public_api mismatch for {contract.key}")
        for row in rows:
            if row["title"] != contract.title:
                raise AssertionError(f"Contract title mismatch for {contract.key}")
            if row["latex"] != "\n\n".join(contract.equations):
                raise AssertionError(f"Equation string mismatch for {contract.key}")
            if row["site_anchor"] != contract.site_anchor:
                raise AssertionError(f"Site anchor mismatch for {contract.key}")
            if row["scope"] != contract.scope:
                raise AssertionError(f"Scientific scope mismatch for {contract.key}")
            if get_mathematical_contract(row["function"]) != contract:
                raise AssertionError(
                    f"Function lookup mismatch for {row['function']}"
                )
        if get_mathematical_contract(contract.key) != contract:
            raise AssertionError(f"Contract key lookup mismatch at {index}")

    canonical_bytes = json.dumps(
        native,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return {
        "evidence_type": "source_content_only_no_human_approval",
        "source_distribution": "eyetrajectoriespy",
        "source_version": actual_version,
        "source_contracts": len(contracts),
        "source_public_function_rows": len(native),
        "all_fields_exact": True,
        "row_content_sha256": hashlib.sha256(canonical_bytes).hexdigest(),
        "fully_independent_source_contracts_certified": 0,
    }


if __name__ == "__main__":
    try:
        print(json.dumps(verify(), sort_keys=True, indent=2))
    except Exception as exc:
        print(f"Stage 28 full source content audit FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
