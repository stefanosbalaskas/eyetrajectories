#!/usr/bin/env python3
"""Offline completeness audit for the committed Python-backed R API snapshot.

No Python packages or R installation required. This checks source declarations,
not whether the installed Python package can execute scientific functions.

Run from the eyetrajectories repository root:
    python scripts/audit_etpy_api.py
Optional upstream checkout:
    python scripts/audit_etpy_api.py --upstream ../eyetrajectoriespy
"""
from __future__ import annotations

import argparse
import ast
import csv
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "inst/extdata/python_api_2026-10-25.csv"
RSOURCE = ROOT / "R/etpy-generated.R"
NAMESPACE = ROOT / "NAMESPACE"
RD = ROOT / "man/etpy_python_functions.Rd"
EXPECTED = {"root": (458, 362), "workflows": (50, 18)}


def exports_from_python(path: pathlib.Path) -> list[str]:
    """Read explicit __all__ assignment as data, never execute the module."""
    parsed = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in parsed.body:
        if isinstance(node, ast.Assign):
            if any(isinstance(t, ast.Name) and t.id == "__all__" for t in node.targets):
                value = ast.literal_eval(node.value)
                if not isinstance(value, list) or not all(isinstance(x, str) for x in value):
                    raise ValueError("__all__ is not a literal list of strings")
                return value
    raise ValueError(f"No static __all__ assignment in {path}")


def main() -> int:
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--upstream", type=pathlib.Path, default=None,
                     help="Checkout root of the upstream eyetrajectoriespy repository")
    options = arg.parse_args()

    with MANIFEST.open(encoding="utf-8", newline="") as handle:
        items = list(csv.DictReader(handle))
    source = RSOURCE.read_text(encoding="utf-8")
    ns = NAMESPACE.read_text(encoding="utf-8")
    rd = RD.read_text(encoding="utf-8")

    errors: list[str] = []
    if len(items) != 508:
        errors.append(f"Expected 508 recorded symbols; got {len(items)}")
    shas = {row.get("source_git_sha") for row in items}
    if len(shas) != 1 or not all(re.fullmatch("[a-f0-9]{40}", str(s)) for s in shas):
        errors.append("Manifest does not have exactly one full Python Git SHA")

    seen_symbols: set[tuple[str, str]] = set()
    functions: set[str] = set()
    by_namespace: dict[str, list[dict[str, str]]] = {
        "root": [], "workflows": []}
    for row in items:
        ns_name = row["namespace"]
        name = row["python_name"]
        kind = row["kind"]
        r_name = row["r_wrapper"]
        key = (ns_name, name)
        if ns_name not in by_namespace or key in seen_symbols:
            errors.append(f"Invalid or duplicated upstream symbol {key}")
            continue
        seen_symbols.add(key)
        by_namespace[ns_name].append(row)
        if kind == "function":
            expected = ("etpy_" if ns_name == "root" else "etpy_workflow_") + name
            if r_name != expected:
                errors.append(f"Incorrect wrapper name: {r_name!r}, expected {expected!r}")
            functions.add(r_name)
            if not re.search(rf"(?m)^{re.escape(r_name)} <- function\(\.\.\., \.convert = FALSE\)", source):
                errors.append(f"R wrapper not defined: {r_name}")
            if f"export({r_name})" not in ns:
                errors.append(f"R wrapper not exported: {r_name}")
            if f"\\alias{{{r_name}}}" not in rd:
                errors.append(f"R wrapper missing Rd alias: {r_name}")
            if f"{r_name}(..., .convert = FALSE)" not in rd:
                errors.append(f"R wrapper missing Rd usage: {r_name}")
        elif kind != "other_export" or r_name:
            errors.append(f"Invalid nonfunction export {key}")
    for key, (expected_total, expected_funcs) in EXPECTED.items():
        rows = by_namespace[key]
        total, funcs = len(rows), sum(x["kind"] == "function" for x in rows)
        if (total, funcs) != (expected_total, expected_funcs):
            errors.append(f"{key}: expected ({expected_total},{expected_funcs}), got ({total},{funcs})")
    wrappers = set(re.findall(r"(?m)^(etpy_[a-z0-9_]+) <- function\(\.\.\., \.convert = FALSE\)", source))
    if wrappers != functions:
        errors.append("Wrapper function set differs from CSV callable set")

    if options.upstream is not None:
        root = options.upstream / "src/eyetrajectoriespy/__init__.py"
        workflows = options.upstream / "src/eyetrajectoriespy/workflows/__init__.py"
        for kind, path in [("root", root), ("workflows", workflows)]:
            try:
                actual = exports_from_python(path)
            except (OSError, SyntaxError, ValueError) as exc:
                errors.append(f"Could not parse {path}: {exc}")
                continue
            recorded = [r["python_name"] for r in by_namespace[kind]]
            if actual != recorded:
                errors.append(f"{kind}: recorded __all__ order/content differs from upstream checkout")

    if errors:
        for err in errors:
            print("FAIL:", err, file=sys.stderr)
        return 1
    print(f"PASS: {len(items)} public symbols; {len(functions)} function wrappers")
    print("  root 362 functions / 458 exports; workflows 18 functions / 50 exports")
    print("  Each function is defined, exported, and has an Rd alias/usage.")
    print("  Python source commit:", next(iter(shas)))
    print("  Scientific execution/calibration: NOT tested by this inventory audit.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
