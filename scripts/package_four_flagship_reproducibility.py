#!/usr/bin/env python3
"""Package only explicitly generated synthetic eyetrajectories workflows.

No raw gaze, participant-level user dataset, secret, external download or
non-source checked directory is ever copied. Python stdlib only.
A SHA-256 manifest is created from the exact files emitted by R on this runner.
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
from hashlib import sha256
import json
from pathlib import Path
import re
import shutil
import sys
import zipfile

STABLE_REF = "v0.4.3"
STABLE_SHA = "20e6db830d480b55456c2acf85e5fdb12cfa398f"
WORKFLOWS = (
    ("01-dense", "01_complete_gaze_trajectory.R", 3),
    ("02-multilevel", "02_multilevel_functional_variation.R", 3),
    ("03-sparse", "03_sparse_irregular_recovery.R", 3),
    ("04-uncertainty", "04_uncertainty_paired_contrast.R", 3),
)
RELEASE_DOCS = (
    "SCIENTIFIC_TIERS_AND_FLAGSHIP_WORKFLOWS.md",
    "SCIENTIFIC_VALIDATION_RESULTS_20261117.md",
    "POTEC_REAL_SOURCE_AND_L2_RESULTS_20261118.md",
)
ARCHIVE_NAME = "eyetrajectories_0.4.3_four_synthetic_flagships_v1.zip"


def digest(path: Path) -> str:
    h = sha256()
    with path.open("rb") as handle:
        for part in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(part)
    return h.hexdigest()


def nonempty(path: Path, min_size: int = 1) -> Path:
    if not path.is_file() or path.is_symlink() or path.stat().st_size < min_size:
        raise ValueError(f"Expected nonempty regular file: {path}")
    return path


def copy_checked(source: Path, target: Path, min_size: int = 1) -> None:
    nonempty(source, min_size)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        raise ValueError(f"Empty structured CSV: {path}")
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="Research checkout")
    parser.add_argument("--stable", required=True, type=Path, help="Exact v0.4.3 checkout")
    parser.add_argument("--r-output", required=True, type=Path, help="Synthetic R output folder")
    parser.add_argument("--destination", required=True, type=Path)
    args = parser.parse_args()

    base = args.source.resolve(strict=True)
    stable = args.stable.resolve(strict=True)
    generated = args.r_output.resolve(strict=True)
    destination = args.destination.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    payload = destination / "reproducibility-v1"
    if payload.exists():
        shutil.rmtree(payload)
    payload.mkdir()

    description = nonempty(stable / "DESCRIPTION").read_text(encoding="utf-8")
    if not re.search(r"(?m)^Version:\s*0\.4\.3\s*$", description):
        raise ValueError("Stable checkout is not exact v0.4.3 metadata")
    nonempty(stable / "NAMESPACE", 1000)

    copy_checked(stable / "DESCRIPTION", payload / "published-package" / "DESCRIPTION")
    copy_checked(stable / "NAMESPACE", payload / "published-package" / "NAMESPACE")
    copy_checked(stable / "LICENSE", payload / "published-package" / "LICENSE")
    for name in RELEASE_DOCS:
        copy_checked(base / "docs" / name, payload / "scientific-context" / name)
    copy_checked(base / "inst" / "method-registry" / "curated-evidence.json",
                 payload / "method-registry" / "curated-evidence.json")
    copy_checked(base / "scripts" / "generate_scientific_method_registry.py",
                 payload / "method-registry" / "generate_scientific_method_registry.py")

    totals = {"workflows": 0, "pdf_figures": 0, "csv_tables": 0}
    for slug, script, expected_pdfs in WORKFLOWS:
        target = payload / "examples" / slug
        copy_checked(base / "inst" / "examples" / "flagship" / script,
                     target / script, 100)
        folder = generated / slug
        if not folder.is_dir():
            raise ValueError(f"Missing executed R workflow: {folder}")
        docs = ["METHODS_AND_LIMITATIONS.md", "sessionInfo.txt"]
        for name in docs:
            copy_checked(folder / name, target / name, 100)
        note = (target / docs[0]).read_text(encoding="utf-8").lower()
        if "synthetic" not in note:
            raise ValueError(f"Workflow does not explicitly declare synthetic provenance: {slug}")
        pdfs = sorted(folder.glob("*.pdf"))
        csvs = sorted(folder.glob("*.csv"))
        if len(pdfs) != expected_pdfs or len(csvs) < 2:
            raise ValueError(f"{slug}: expected {expected_pdfs} PDFs and at least 2 CSVs, got "
                             f"{len(pdfs)} and {len(csvs)}")
        for p in pdfs:
            if nonempty(p, 100).read_bytes()[:5] != b"%PDF-":
                raise ValueError(f"{p}: not a PDF document")
            copy_checked(p, target / p.name, 100)
        for p in csvs:
            csv_rows(p)
            copy_checked(p, target / p.name, 20)
        totals["workflows"] += 1
        totals["pdf_figures"] += len(pdfs)
        totals["csv_tables"] += len(csvs)

    if totals["workflows"] != 4 or totals["pdf_figures"] != 12:
        raise AssertionError("Incomplete research-workflow bundle")

    guide = """# eyetrajectories 0.4.3 — four SYNTHETIC research workflows

This archive contains reproducible example analyses with NO human eye-tracking
participant data. All observation curves in the four examples were generated
programmatically. The PDF figures and CSV tables came from a CI execution of
the versioned R scripts against the exact published v0.4.3 package.

Archive input software reference: GitHub tag v0.4.3,
commit 20e6db830d480b55456c2acf85e5fdb12cfa398f.
The research-example source is a separate later development commit and is
not part of the immutable v0.4.3 source tarball. The manifest records this
fact; it MUST NOT be described as v0.4.3 source-package behavior beyond the
executed R calls.

Re-run: check out the recorded research-source commit and exact v0.4.3
package; install R >=4.2, reticulate and optional fdapace; set
ET_FLAGSHIP_OUTPUT and source the four R scripts. Review METHOD_AND_LIMITATIONS
files and sessionInfo before interpreting results.

This archive is an illustrative reproducibility bundle, NOT independent
scientific certification. Descriptive FPCA is not a significance test;
multilevel decomposition is not REML inferential mixed modeling;
fdapace sparse PACE is delegated estimation; participant bootstrap bands
are not universally calibrated; none of the synthetic figures validates raw
gaze calibration or the original Data Viewer record provenance.

The present archive does not replace the package source, CRAN submission
materials, or Zenodo DOI. A public research claim must cite the exact archive
and software revision and distinguish generated evidence from source integrity.
"""
    (payload / "README.md").write_text(guide, encoding="utf-8")

    content_files = sorted(p for p in payload.rglob("*") if p.is_file())
    items = [
        {"relative_path": p.relative_to(payload).as_posix(),
         "bytes": p.stat().st_size,
         "sha256": digest(p)}
        for p in content_files
    ]
    summary = {
        "schema": "eyetrajectories-four-synthetic-flagships-reproducibility/v1",
        "source_package_release": STABLE_REF,
        "source_package_commit": STABLE_SHA,
        "research_source_commit": str(
            __import__("os").environ.get("GITHUB_SHA", "LOCAL_UNSPECIFIED")),
        "data_type": "entirely_synthetic",
        "contains_private_human_observations": False,
        "qualified_as_independent_scientific_truth": False,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "counts": totals,
        "files": items,
    }
    (payload / "SHA256_MANIFEST.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8")

    archive = destination / ARCHIVE_NAME
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, mode="w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=8) as zf:
        for p in sorted(payload.rglob("*")):
            if not p.is_file():
                continue
            rel = p.relative_to(payload).as_posix()
            info = zipfile.ZipInfo("reproducibility-v1/" + rel,
                                   date_time=(2026, 11, 18, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            zf.writestr(info, p.read_bytes(), compress_type=zipfile.ZIP_DEFLATED,
                        compresslevel=8)
    with zipfile.ZipFile(archive) as zf:
        corrupt = zf.testzip()
        if corrupt is not None:
            raise RuntimeError(f"ZIP corruption: {corrupt}")
        names = zf.namelist()
        if len(names) != len(items) + 1:
            raise AssertionError("ZIP manifest does not match file inventory")
    (destination / (ARCHIVE_NAME + ".sha256")).write_text(
        f"{digest(archive)}  {archive.name}\n", encoding="ascii")
    print("FOUR_SYNTHETIC_FLAGSHIP_REPRODUCIBILITY_BUNDLE_PASS")
    print(json.dumps({"archive": str(archive), "sha256": digest(archive),
                      "counts": totals, "file_count": len(items) + 1}, indent=2))


if __name__ == "__main__":
    main()
