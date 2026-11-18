#!/usr/bin/env python3
"""Package four executed synthetic native R workflows with a SHA256 manifest.

No original OneStop/PoTeC/human participant files are accepted. A bundle is
reproducibility evidence for these defined demonstrations, NOT independent
certification of all exported eyetrajectories methods or nominal inference.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

WORKFLOWS = {
    "01-dense": "01_complete_gaze_trajectory.R",
    "02-multilevel": "02_multilevel_functional_variation.R",
    "03-sparse": "03_sparse_irregular_recovery.R",
    "04-uncertainty": "04_uncertainty_paired_contrast.R",
}
STABLE_SHA = "20e6db830d480b55456c2acf85e5fdb12cfa398f"
SCHEMA = "eyetrajectories-synthetic-reproducibility-bundle/v1"
ALLOWED = {".pdf", ".csv", ".md", ".txt"}


def sha256(raw):
    return hashlib.sha256(raw).hexdigest()


def require_file(path):
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"Source file missing or symbolic link: {path}")
    return path.read_bytes()


def build(results, scripts, destination, protocol=None):
    results, scripts, destination = Path(results), Path(scripts), Path(destination)
    if not results.is_dir() or not scripts.is_dir():
        raise ValueError("Both source scripts and generated results must exist")
    files = {}
    count_pdfs = 0
    for slug, script in WORKFLOWS.items():
        code = require_file(scripts / script)
        if b"synthetic" not in code.lower():
            raise AssertionError(f"Script lacks synthetic provenance: {script}")
        files[f"source/{script}"] = code
        folder = results / slug
        if not folder.is_dir():
            raise ValueError(f"Missing executed workflow result: {slug}")
        candidates = sorted(folder.iterdir())
        pdf = [f for f in candidates if f.suffix.lower() == ".pdf"]
        if len(pdf) != 3:
            raise ValueError(f"{slug} must have three original vector R PDF figures")
        count_pdfs += len(pdf)
        for required in ("METHODS_AND_LIMITATIONS.md", "sessionInfo.txt"):
            if not (folder / required).is_file():
                raise ValueError(f"{slug} missing {required}")
        note = require_file(folder / "METHODS_AND_LIMITATIONS.md")
        if b"synthetic" not in note.lower():
            raise AssertionError(f"{slug} does not label synthetic data")
        for path in candidates:
            if path.is_dir():
                raise ValueError(f"Unexpected nested result folder: {path}")
            if path.suffix.lower() not in ALLOWED:
                raise ValueError(f"Unexpected file type in scientific bundle: {path.name}")
            files[f"results/{slug}/{path.name}"] = require_file(path)
    if count_pdfs != 12:
        raise AssertionError("Expected exactly twelve native R vector PDF figures")
    if protocol is not None:
        files["protocol/SCIENTIFIC_TIERS_AND_FLAGSHIP_WORKFLOWS.md"] = require_file(Path(protocol))
    readme = """# eyetrajectories: four reproducible synthetic R research workflows

Release API baseline: v0.4.3, source commit 20e6db830d480b55456c2acf85e5fdb12cfa398f.
These FOUR examples, their source scripts, numerical results, vector PDF
figures, method-specific limitations and exact R session manifests were
executed on the archived R API. Data are SIMULATED, NOT human eye tracking.

Workflow 01: dense trajectory geometry and multivariate FPCA.
Workflow 02: descriptive two-stratum participant/trial decomposition.
Workflow 03: irregular sparse observation and known-truth fdapace recovery.
Workflow 04: participant-averaged paired contrasts with exploratory bootstrap.

No nominal confidence-band coverage is guaranteed by a single example.
The source package includes optional R backends; Python is not used here.
This archive does not contain raw OneStop, PoTeC or personal gaze records.
API count, numerical tests and synthetic figures are not an independent
scientific certification of every exported method.

MANIFEST.json contains a SHA256 and byte size for each archived file.
Source software: https://github.com/stefanosbalaskas/eyetrajectories
Archived software: https://doi.org/10.5281/zenodo.24288857
"""
    files["README.md"] = readme.encode("utf-8")
    records = [{"path":name, "sha256":sha256(raw), "size_bytes":len(raw)}
               for name, raw in sorted(files.items())]
    manifest = {
        "schema": SCHEMA,
        "software": "eyetrajectories",
        "api_release": "v0.4.3",
        "source_commit": STABLE_SHA,
        "workflows": list(WORKFLOWS),
        "input_provenance": "all trajectories are generated synthetically by included R scripts",
        "requires_original_human_data": False,
        "number_of_vector_PDF_figures": count_pdfs,
        "general_scientific_certification": False,
        "files": records
    }
    files["MANIFEST.json"] = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Stable ZIP metadata: differences across runs reflect content/session
    # changes rather than uncontrolled ZIP entry times.
    with zipfile.ZipFile(destination, mode="w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=8) as z:
        for name, raw in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, raw, compress_type=zipfile.ZIP_DEFLATED)
    # Re-open every archive item and check its exact SHA256 provenance.
    with zipfile.ZipFile(destination, "r") as z:
        assert set(z.namelist()) == set(files)
        parsed = json.loads(z.read("MANIFEST.json"))
        for record in parsed["files"]:
            assert sha256(z.read(record["path"])) == record["sha256"]
            assert len(z.read(record["path"])) == record["size_bytes"]
    return manifest


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--results", required=True)
    p.add_argument("--scripts", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--protocol")
    a = p.parse_args()
    m = build(a.results, a.scripts, a.output, a.protocol)
    print("FOUR_FLAGSHIP_SHA256_REPRODUCIBILITY_BUNDLE_PASS",
          "figures", m["number_of_vector_PDF_figures"],
          "files", len(m["files"]), "output", a.output)


if __name__ == "__main__":
    main()
