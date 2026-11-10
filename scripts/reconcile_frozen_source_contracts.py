#!/usr/bin/env python3
"""Reconcile live public definitions, the gap ledgers and unsigned source evidence."""
from __future__ import annotations

import argparse
import ast
from collections import Counter
import csv
import importlib
import inspect
import io
import json
from pathlib import Path
import re
import subprocess
import sys

from source_gap_inventory import (
    CLOSED_SEMANTIC_SCOPE, FROZEN_PYTHON, REQUIRED_REVIEW_KINDS, read_inventory,
)
from summarize_scientific_source_evidence import git_head, read_rows, require, sha256, summarize


R_CATALOG = r"""
options(keep.source = TRUE, keep.source.pkgs = TRUE)
pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
package <- "eyetrajectories"
api <- eyetrajectories::etr_native_parity_catalog()
other <- read.csv("inst/extdata/native_nonfunction_source_gaps_v1.csv")
at <- match(other$python_name, api$python_name)
api$native_r_candidate[at] <- other$native_r_candidate
info <- lapply(api$native_r_candidate, function(name) {
  if (!nzchar(name)) return(c("", "", ""))
  stopifnot(name %in% getNamespaceExports(package))
  fn <- getExportedValue(package, name)
  stopifnot(is.function(fn))
  c(getSrcFilename(fn, full.names = TRUE), as.integer(getSrcref(fn))[1L],
    trimws(paste(head(deparse(args(fn), width.cutoff = 500L), -1L), collapse = " ")))
})
api$r_definition <- vapply(info, "[[", character(1L), 1L)
api$r_definition_line <- vapply(info, "[[", character(1L), 2L)
api$r_formals <- vapply(info, "[[", character(1L), 3L)
write.csv(api, stdout(), row.names = FALSE, na = "")
"""


def constant_locations(module_path: Path, names: set[str]) -> dict[str, tuple[Path, int]]:
    locations = {}
    for path in module_path.parent.glob("*.py"):
        source = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in source.body:
            if isinstance(node, ast.Assign):
                targets = node.targets
            elif isinstance(node, ast.AnnAssign):
                targets = [node.target]
            else:
                continue
            for target in targets:
                if isinstance(target, ast.Name) and target.id in names:
                    require(target.id not in locations, f"Ambiguous constant: {target.id}")
                    locations[target.id] = (path, node.lineno)
    require(locations.keys() == names, f"Unlocated constants: {names - locations.keys()}")
    return locations


def frozen_definitions(checkout: Path, manifest: list[dict]) -> dict[str, dict]:
    require(git_head(checkout) == FROZEN_PYTHON, "Wrong frozen Python checkout commit")
    subprocess.run(["git", "diff", "--quiet", "HEAD", "--", "src"],
                   cwd=checkout, check=True)
    source = checkout / "src"
    sys.path.insert(0, str(source))
    result = {}
    for namespace, module_name in (("root", "eyetrajectoriespy"),
                                   ("workflows", "eyetrajectoriespy.workflows")):
        module = importlib.import_module(module_name)
        module_path = Path(module.__file__).resolve()
        require(module_path.is_relative_to(source), f"Wrong import location: {module_path}")
        names = {row["python_name"]: row["kind"] for row in manifest
                 if row["namespace"] == namespace}
        require(set(module.__all__) == names.keys() and len(module.__all__) == len(names),
                f"Frozen manifest and {module_name}.__all__ differ")
        constants = constant_locations(
            module_path, {name for name in names if not callable(getattr(module, name))})
        for name, kind in names.items():
            obj = getattr(module, name)
            require(inspect.isfunction(obj) == (kind == "function"),
                    f"Public object kind differs for {namespace}.{name}")
            if name in constants:
                path, line = constants[name]
                signature = repr(obj)
            else:
                definition = inspect.unwrap(obj)
                path = Path(inspect.getsourcefile(definition)).resolve()
                line = inspect.getsourcelines(definition)[1]
                signature = str(inspect.signature(obj))
            require(path.is_relative_to(source), f"Non-frozen source for {name}: {path}")
            result[name] = dict(python_source=path.relative_to(checkout).as_posix(),
                                python_source_line=line, python_signature_or_value=signature)
    return result


def catalog_author_packet(root: Path, rows: list[dict]) -> list[dict]:
    decisions = {
        "list_mathematical_contracts": ("native_mathematical_contract_frame_py120.csv",
                                       "representation_decision_pending"),
        "get_mathematical_contract": ("native_mathematical_contract_frame_py120.csv",
                                      "representation_and_lookup_boundary_decisions_pending"),
        "functional_recovery_metric_catalog": ("native_recovery_metric_catalog_py120.csv",
                                               "representation_decision_pending"),
    }
    test = "tests/testthat/test-native-catalog-contract-boundaries.R"

    def pinned(path: str) -> dict:
        return dict(path=path, sha256=sha256(root / path))

    return [
        dict(audit_version="source-contract-v1", python_name=row["python_name"],
             r_git_head=row["r_git_head"], frozen_python_commit=FROZEN_PYTHON,
             python_source=row["python_source"], python_source_line=row["python_source_line"],
             native_files=[pinned(row["r_definition"])],
             native_catalog_data=pinned("inst/extdata/" + decisions[row["python_name"]][0]),
             proposed_evidence_by_kind=[dict(kind=kind, **pinned(test))
                                        for kind in sorted(REQUIRED_REVIEW_KINDS)],
             review_proposal="docs/native-catalog-author-decisions-unsigned.md",
             proposal_state=decisions[row["python_name"]][1],
             author_decision=None, reviewer_statement=None, independently_certified=False)
        for row in rows if row["python_name"] in decisions
    ]


def reconcile(root: Path, checkout: Path, output: Path, evidence_root: Path) -> dict:
    counts = read_inventory(root)
    head = git_head(root)
    subprocess.run(["git", "diff", "--quiet", "HEAD", "--", "R", "NAMESPACE",
                    "DESCRIPTION", "inst/extdata", "tests", "scripts"],
                   cwd=root, check=True)
    data = root / "inst" / "extdata"
    manifest = read_rows(data / "python_api_2026-10-25.csv")
    sources = frozen_definitions(checkout, manifest)
    callable_gaps = read_rows(data / "native_source_contract_gaps_stage22.csv")
    other_gaps = read_rows(data / "native_nonfunction_source_gaps_v1.csv")
    gaps = {row["python_name"]: row for row in callable_gaps + other_gaps}
    reviewed_file = data / "reviewed_source_contract_closures_v1.csv"
    with reviewed_file.open(encoding="utf-8", newline="") as file:
        reviewed = {row["python_name"]: row for row in csv.DictReader(file)}
    native = subprocess.run(["Rscript", "--vanilla", "-"], input=R_CATALOG,
                            cwd=root, capture_output=True, text=True, check=True)
    native_rows = {row["python_name"]: row
                   for row in csv.DictReader(io.StringIO(native.stdout))}
    require(set(native_rows) == set(sources) and len(manifest) == len(sources),
            "Native and frozen public export inventories differ")

    evidence = {}
    source_report_hashes = {}
    report_path = evidence_root / "artifacts" / "native_batch_numeric_diff" / head[:12]
    if report_path.is_dir():
        subprocess.run(["git", "diff", "--quiet", "HEAD", "--", "inst/extdata"],
                       cwd=evidence_root, check=True)
        report = summarize(evidence_root, head, write=False)
        evidence = {row["python_name"]: row for row in report["function_evidence"]}
        source_report_hashes = report["source_report_sha256"]

    witnesses = subprocess.check_output(["git", "ls-files", "tests", "scripts"],
                                       cwd=root, text=True).splitlines()
    rows = []
    for export in manifest:
        name = export["python_name"]
        candidate = native_rows[name]
        gap = gaps.get(name, {})
        open_gap = (candidate["source_contract_gap_unresolved"] == "TRUE" or
                    candidate["nonfunction_source_gap_unresolved"] == "TRUE")
        require(open_gap == (gap.get("unresolved_source_gap", gap.get("unresolved")) == "TRUE"),
                f"R and author source gap status differ for {name}")
        path = candidate["r_definition"]
        r_path = Path(path).resolve().relative_to(root).as_posix() if path else ""
        if gap:
            require(candidate["native_r_candidate"] == gap["native_r_candidate"] and
                    bool(r_path) and candidate["r_definition_line"].isdigit(),
                    f"No actual R definition for recorded gap {name}")
        observed = evidence.get(name, {})
        witness = gap.get("source_witness", "")
        mentioned = {Path(token).name for token in re.findall(r"[\w./-]+\.(?:R|py)", witness)}
        state = ("open" if open_gap else "reviewed_closed" if name in reviewed else
                 "legacy_table_semantics_closed" if name in CLOSED_SEMANTIC_SCOPE else
                 "no_gap_recorded")
        independent = candidate["one_to_one_native_contract_complete"] == "TRUE"
        rows.append(dict(
            namespace=export["namespace"], python_name=name, export_kind=export["kind"],
            **sources[name], native_r_candidate=candidate["native_r_candidate"],
            r_definition=r_path, r_definition_line=candidate["r_definition_line"],
            r_formals=candidate["r_formals"], native_support=candidate["status"],
            native_backend_or_estimand_differs=(
                candidate["native_backend_or_estimand_differs_from_python"] == "TRUE"),
            recorded_gap_state=state, gap_kind=gap.get("gap_kind", ""),
            recorded_difference=gap.get("known_source_difference", ""),
            recorded_witness=witness,
            located_witness_files=";".join(path for path in witnesses
                                            if Path(path).name in mentioned),
            required_resolution=gap.get("review_resolution", gap.get("required_resolution", "")),
            recorded_developer_fixture=candidate["contract_numerical_fixture_pass"] == "TRUE",
            exact_head_bounded_passes=observed.get("matched_case_passes", 0),
            exact_head_disagreements=observed.get("source_disagreements", 0),
            author_review_record=reviewed.get(name, {}).get("review_record_path", ""),
            independently_certified=independent,
            r_git_head=head, frozen_python_commit=FROZEN_PYTHON))

    open_rows = [row for row in rows if row["recorded_gap_state"] == "open"]
    require(len(open_rows) == counts.open_total, "Open source witnesses and ledger counts differ")
    output.mkdir(parents=True, exist_ok=True)
    for filename, selection in (("all_public_exports.csv", rows), ("active_source_gaps.csv", open_rows)):
        with (output / filename).open("w", encoding="utf-8", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(selection)
    result = dict(
        public_exports=len(rows), active_callable_gaps=counts.active_callable,
        active_nonfunction_gaps=counts.active_nonfunction,
        exports_without_recorded_gaps=len(rows) - len(open_rows),
        exports_with_located_native_definitions=sum(bool(row["r_definition"]) for row in rows),
        active_gaps_with_located_native_definitions=sum(bool(row["r_definition"]) for row in open_rows),
        full_author_reviews=len(reviewed),
        legacy_table_semantics_closures=len(CLOSED_SEMANTIC_SCOPE & set(counts.resolved_semantic)),
        independent_certifications=sum(row["independently_certified"] for row in rows),
        active_gap_python_source_counts=dict(Counter(row["python_source"] for row in open_rows)),
        exact_head_evidence_files=source_report_hashes,
        exact_head_bounded_passes=sum(row["exact_head_bounded_passes"] for row in rows),
        exact_head_source_disagreements=sum(row["exact_head_disagreements"] for row in rows),
        exact_head_exports_with_bounded_passes=sum(row["exact_head_bounded_passes"] > 0 for row in rows),
        exact_head_active_gaps_with_bounded_passes=sum(
            row["exact_head_bounded_passes"] > 0 for row in open_rows),
        active_gaps_with_alternative_backend_or_estimand=sum(
            row["native_backend_or_estimand_differs"] for row in open_rows),
        r_git_head=head, frozen_python_commit=FROZEN_PYTHON,
        input_sha256={path.name: sha256(path) for path in (
            data / "python_api_2026-10-25.csv", data / "native_source_contract_gaps_stage22.csv",
            data / "native_nonfunction_source_gaps_v1.csv", reviewed_file)})
    (output / "reconciliation_summary.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (output / "catalog_author_decisions_UNSIGNED.json").write_text(
        json.dumps(catalog_author_packet(root, rows), indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--python-checkout", required=True, type=Path)
    parser.add_argument("--evidence-root", type=Path,
                        help="R checkout holding strict source reports for the exact same commit")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    root = args.root.resolve(strict=True)
    output = args.output_dir or root / "artifacts" / "source_contract_reconciliation" / git_head(root)[:12]
    result = reconcile(root, args.python_checkout.resolve(strict=True), output,
                       (args.evidence_root or root).resolve(strict=True))
    print(json.dumps(result, indent=2, sort_keys=True))
    print(f"RECONCILED_SOURCE_INVENTORY={output.resolve()}")


if __name__ == "__main__":
    main()
