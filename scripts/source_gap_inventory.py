#!/usr/bin/env python3
"""Author-side source-gap counts from the one historical frozen-gap registry.

This is *not* a parity verifier or an independent certification authority.
Only the two zero-argument metadata semantic closures are permitted in this
revision. Any other closed historical witness requires a reviewed explicit
policy change, not a self-elected CSV flag.
"""
from __future__ import annotations
import csv
from dataclasses import dataclass
from pathlib import Path

CLOSED_SEMANTIC_SCOPE = frozenset({
    "functional_recovery_metric_catalog_frame",
    "mathematical_contract_frame",
})
FUNCTION_HEADERS = (
    "python_name", "native_r_candidate", "gap_kind",
    "known_source_difference", "source_witness", "review_resolution",
    "unresolved_source_gap",
)
NONFUNCTION_FIELDS = (
    "namespace", "python_name", "native_r_candidate",
    "frozen_python_commit", "gap_kind", "known_source_difference",
    "source_witness", "required_resolution", "unresolved",
)
FROZEN_PYTHON = "c1cd95ad718327550f7e55393ff38582872f7a94"


class SourceGapInventoryError(ValueError):
    """Corrupted or unsupported authoritative gap inventory."""


@dataclass(frozen=True)
class SourceGapCounts:
    historical_callable: int
    active_callable: int
    resolved_semantic: tuple[str, ...]
    historical_nonfunction: int
    active_nonfunction: int

    @property
    def open_total(self) -> int:
        return self.active_callable + self.active_nonfunction

    @property
    def no_recorded_gap_exports(self) -> int:
        return 508 - self.open_total


def _read(path: Path, required: tuple[str, ...]) -> list[dict[str, str]]:
    if not path.is_file() or path.is_symlink():
        raise SourceGapInventoryError(f"Missing or symlinked gap ledger: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        if (reader.fieldnames is None or
            any(key not in reader.fieldnames for key in required) or
            len(reader.fieldnames) != len(set(reader.fieldnames))):
            raise SourceGapInventoryError(f"Invalid source-gap columns: {path}")
        rows = list(reader)
    if any(None in row or None in row.values() for row in rows):
        raise SourceGapInventoryError(f"Malformed source-gap row: {path}")
    return rows


def read_inventory(root: Path | str | None = None) -> SourceGapCounts:
    root = (Path(root) if root is not None else Path(__file__).resolve().parent.parent)
    directory = root / "inst" / "extdata"
    funcs = _read(directory / "native_source_contract_gaps_stage22.csv",
                  FUNCTION_HEADERS)
    other = _read(directory / "native_nonfunction_source_gaps_v1.csv",
                  NONFUNCTION_FIELDS)
    # 203 is a frozen HISTORICAL witness inventory, not an open-gap target.
    if len(funcs) != 203 or len(other) != 1:
        raise SourceGapInventoryError("Historical frozen 203+1 witnesses changed")
    names = [row["python_name"] for row in funcs]
    if len(names) != len(set(names)) or any(not n for n in names):
        raise SourceGapInventoryError("Duplicate/empty callable witness keys")
    if any(row["unresolved_source_gap"] not in ("TRUE", "FALSE")
           for row in funcs):
        raise SourceGapInventoryError("Non-boolean callable gap flag")
    if any(not row["native_r_candidate"] or not row["source_witness"] or
           not row["known_source_difference"] or not row["review_resolution"]
           for row in funcs):
        raise SourceGapInventoryError("Missing historical source witness")
    resolved = tuple(sorted(row["python_name"] for row in funcs
                            if row["unresolved_source_gap"] == "FALSE"))
    if not set(resolved) <= CLOSED_SEMANTIC_SCOPE:
        raise SourceGapInventoryError("Unreviewed/forged gap closure")
    for row in funcs:
        if row["python_name"] not in resolved:
            continue
        if ("Resolved as complete deterministic cross-language TABLE SEMANTICS"
                not in row["review_resolution"] or
            "test-native-zeroarg-metadata-source-semantic-closure.R"
                not in row["source_witness"] or
            FROZEN_PYTHON not in row["source_witness"]):
            raise SourceGapInventoryError(
                "Missing frozen-source semantic closure evidence")
    if (other[0]["python_name"] != "TrajectorySet" or
        other[0]["namespace"] != "root" or
        other[0]["unresolved"] != "TRUE" or
        other[0]["frozen_python_commit"] != FROZEN_PYTHON):
        raise SourceGapInventoryError(
            "Frozen nonfunction source gap must remain open")
    return SourceGapCounts(
        historical_callable=len(funcs),
        active_callable=sum(r["unresolved_source_gap"] == "TRUE" for r in funcs),
        resolved_semantic=resolved,
        historical_nonfunction=len(other),
        active_nonfunction=sum(r["unresolved"] == "TRUE" for r in other),
    )


if __name__ == "__main__":
    import json
    from dataclasses import asdict
    stats = read_inventory()
    print(json.dumps({**asdict(stats), "open_total": stats.open_total,
                      "no_recorded_gap_exports": stats.no_recorded_gap_exports},
                     sort_keys=True))
