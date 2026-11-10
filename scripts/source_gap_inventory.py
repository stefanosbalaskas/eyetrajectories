#!/usr/bin/env python3
"""Author-side source-gap counts from frozen Python 1.2 witness ledgers.

The two historical zero-argument closures are preserved. Further source
closures can be recognized in coherent batches ONLY with a separately
authored, source-pinned, cryptographically verified full-domain review
record. Unsigned finite differential cases never close a function.
A developer-reviewed gap closure is NOT independent certification.
"""
from __future__ import annotations
import csv
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path, PurePosixPath

CLOSED_SEMANTIC_SCOPE = frozenset({
    "functional_recovery_metric_catalog_frame",
    "mathematical_contract_frame",
})

# Four separately developer-reviewed closures were entered in the historical
# source ledger before the SHA256 receipt gate existed. Their recorded
# statuses must not be silently revoked, but must also NEVER be counted as
# new, independently certified reviews. Permit only these exact old names
# with their frozen source pin, named tests and explicit resolution wording.
# Every NEW source closure still requires a hash-pinned six-domain receipt.
LEGACY_MIGRATED_REVIEW_WITNESSES = {
    "functional_recovery_metric_catalog":
        "test-native-zeroarg-catalog-source-semantic-closures.R",
    "list_mathematical_contracts":
        "test-native-zeroarg-catalog-source-semantic-closures.R",
    "sparse_fpca_score_frame":
        "test-native-sparse-score-frame-collisions.R",
    "sparse_mfpca_score_frame":
        "test-native-sparse-score-frame-collisions.R",
}
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
REVIEWED_CLOSURES = "reviewed_source_contract_closures_v1.csv"
REVIEWED_FIELDS = (
    "python_name", "frozen_python_commit", "review_record_path",
    "review_record_sha256", "author_full_contract_decision",
    "independently_certified",
)
REQUIRED_REVIEW_KINDS = frozenset({
    "source_signature", "accepted_input_domain", "numerical_outputs",
    "exception_semantics", "returned_schema", "scientific_estimand",
})


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



def _source_file(root: Path, name: str, *, expected_prefix: str) -> Path:
    """Reject path traversal, symlinks, and missing or out-of-repo proof."""
    parsed = PurePosixPath(name)
    if (not name or parsed.is_absolute() or
            ".." in parsed.parts or "." in parsed.parts or
            not name.startswith(expected_prefix) or "\\" in name):
        raise SourceGapInventoryError(
            f"Unsafe or out-of-scope source-review evidence path: {name!r}")
    target = root.joinpath(*parsed.parts)
    if (not target.is_file() or target.is_symlink() or
            not target.resolve().is_relative_to(root.resolve())):
        raise SourceGapInventoryError(
            f"Missing/symlinked source-review evidence: {name!r}")
    return target


def _validate_reviewed_closures(
        root: Path, historical: list[dict[str, str]],
        resolved: set[str]) -> set[str]:
    """Require separate full-domain author review; never infer approval."""
    catalog = _read(root / "inst" / "extdata" / REVIEWED_CLOSURES,
                    REVIEWED_FIELDS)
    seen: set[str] = set()
    historical_names = {row["python_name"] for row in historical}
    source_witnesses = {row["python_name"]: row["native_r_candidate"]
                        for row in historical}
    for row in catalog:
        name = row["python_name"]
        if (not name or name in seen or name not in historical_names or
                name in CLOSED_SEMANTIC_SCOPE or
                name in LEGACY_MIGRATED_REVIEW_WITNESSES):
            raise SourceGapInventoryError(
                f"Duplicate/unknown/legacy reviewed closure: {name!r}")
        seen.add(name)
        if name not in resolved:
            raise SourceGapInventoryError(
                f"Review receipt exists but source gap remains open: {name}")
        if row["frozen_python_commit"] != FROZEN_PYTHON:
            raise SourceGapInventoryError(
                f"Stale Python source pin in reviewed closure: {name}")
        if (row["author_full_contract_decision"] !=
                "AUTHOR_FULL_CONTRACT_REVIEWED" or
                row["independently_certified"] != "FALSE"):
            raise SourceGapInventoryError(
                f"Unapproved or forged independent closure: {name}")
        review = _source_file(root, row["review_record_path"],
                              expected_prefix="docs/source_contract_reviews/")
        digest = hashlib.sha256(review.read_bytes()).hexdigest()
        if row["review_record_sha256"] != digest:
            raise SourceGapInventoryError(
                f"Wrong digest for full source-contract review: {name}")
        try:
            data = json.loads(review.read_text(encoding="utf-8"))
        except (ValueError, UnicodeError) as error:
            raise SourceGapInventoryError(
                f"Malformed full source-contract review: {name}") from error
        if (not isinstance(data, dict) or
                data.get("audit_version") != "source-contract-v1" or
                data.get("python_name") != name or
                data.get("frozen_python_commit") != FROZEN_PYTHON or
                data.get("scope") != "FULL_SOURCE_CONTRACT" or
                data.get("author_decision") != "FULL_CONTRACT_REVIEWED" or
                data.get("independently_certified") is not False or
                not isinstance(data.get("reviewer_statement"), str) or
                len(data["reviewer_statement"].strip()) < 40):
            raise SourceGapInventoryError(
                f"Unsubstantiated full source-contract decision: {name}")
        implementation = data.get("native_files")
        if not isinstance(implementation, list) or not implementation:
            raise SourceGapInventoryError(
                f"No native source implementation pinned by review: {name}")
        declared_candidate = source_witnesses[name]
        candidate_witnessed = False
        for native in implementation:
            if not isinstance(native, dict):
                raise SourceGapInventoryError(
                    f"Malformed pinned native source: {name}")
            file = _source_file(root, native.get("path", ""),
                                expected_prefix="R/")
            if hashlib.sha256(file.read_bytes()).hexdigest() != native.get("sha256"):
                raise SourceGapInventoryError(
                    f"Native implementation changed after full-contract review: {name}")
            if declared_candidate in file.read_text(encoding="utf-8"):
                candidate_witnessed = True
        if not candidate_witnessed:
            raise SourceGapInventoryError(
                f"Reviewed native candidate not found in pinned R source: {name}")
        evidence = data.get("case_evidence")
        if not isinstance(evidence, list) or len(evidence) < 6:
            raise SourceGapInventoryError(
                f"Incomplete full-domain evidence groups: {name}")
        kinds = set()
        for case in evidence:
            if not isinstance(case, dict):
                raise SourceGapInventoryError(
                    f"Malformed review case evidence: {name}")
            kind = case.get("kind", "")
            if kind not in REQUIRED_REVIEW_KINDS:
                raise SourceGapInventoryError(
                    f"Invalid full-contract evidence type: {name}/{kind}")
            file = _source_file(
                root, case.get("path", ""), expected_prefix="tests/")
            if hashlib.sha256(file.read_bytes()).hexdigest() != case.get("sha256"):
                raise SourceGapInventoryError(
                    f"Wrong source test evidence digest: {name}/{kind}")
            kinds.add(kind)
        if kinds != REQUIRED_REVIEW_KINDS:
            raise SourceGapInventoryError(
                f"Missing full-domain evidence dimensions: {name}")
    return seen


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
    if (other[0]["python_name"] != "TrajectorySet" or
            other[0]["namespace"] != "root" or
            other[0]["unresolved"] not in ("TRUE", "FALSE") or
            other[0]["frozen_python_commit"] != FROZEN_PYTHON):
        raise SourceGapInventoryError(
            "Frozen nonfunction source witness identity/flag changed")
    resolved_other = {
        row["python_name"] for row in other
        if row["unresolved"] == "FALSE"
    }
    reviewable = set(resolved) | resolved_other
    required = (set(resolved) - CLOSED_SEMANTIC_SCOPE -
                set(LEGACY_MIGRATED_REVIEW_WITNESSES)) | resolved_other
    reviewed = _validate_reviewed_closures(
        root, funcs + other, reviewable)
    if reviewed != required:
        raise SourceGapInventoryError(
            "Unreviewed/forged gap closure: missing exact full-domain review receipt")
    for row in funcs:
        if (row["python_name"] not in CLOSED_SEMANTIC_SCOPE or
                row["python_name"] not in resolved):
            continue
        if ("Resolved as complete deterministic cross-language TABLE SEMANTICS"
                not in row["review_resolution"] or
            "test-native-zeroarg-metadata-source-semantic-closure.R"
                not in row["source_witness"] or
            FROZEN_PYTHON not in row["source_witness"]):
            raise SourceGapInventoryError(
                "Missing frozen-source semantic closure evidence")
    # Retain only the four documented pre-receipt developer reviews.
    # This is NOT a replacement for new full-source review receipts.
    for row in funcs:
        name = row["python_name"]
        witness = LEGACY_MIGRATED_REVIEW_WITNESSES.get(name)
        if witness is None or row["unresolved_source_gap"] != "FALSE":
            continue
        if (FROZEN_PYTHON not in row["source_witness"] or
                witness not in row["source_witness"] or
                not row["review_resolution"].startswith("Resolved ") or
                "native-language" not in row["review_resolution"] or
                not row["native_r_candidate"].startswith("etr_")):
            raise SourceGapInventoryError(
                f"Legacy pre-receipt developer closure witness changed: {name}")
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
