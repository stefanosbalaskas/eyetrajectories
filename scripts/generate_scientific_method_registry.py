#!/usr/bin/env python3
"""Build a conservative 904-interface scientific method registry from v0.4.3.

Tier describes intended role; evidence_status describes what a specific
linked test demonstrated. Uncurated labels are lexical PROVISIONAL labels,
never independent certifications. Standard-library only.
"""
import argparse
import csv
import json
from pathlib import Path
import re

SCHEMA = "eyetrajectories-method-registry/v1"
EXPORT = re.compile(r"^export\(([A-Za-z][A-Za-z0-9_]*)\)$", re.M)
ADVANCED = re.compile(
    r"(fpcr|regress|mixed|multilevel|sparse|bootstrap|conformal|"
    r"uncertain|predict|confidence|interval|generalized|fosr|fpca|"
    r"simulat|variance|covariance|inference|coefficient|functional)",
    re.I,
)
EXPERIMENTAL = re.compile(
    r"(rqa|recurr|entropy|surrogate|transfer|nonlinear|network|"
    r"elastic|wavelet|graph|complexity|chaos|fractal|bifurcation)",
    re.I,
)
FIELDS = ("name", "tier", "family", "backend", "evidence_status",
          "classification_basis", "caveat", "evidence", "source_release")


def entries(namespace_text, config):
    assert config.get("schema") == SCHEMA
    assert config.get("source_release") == "v0.4.3"
    exported = EXPORT.findall(namespace_text)
    if len(exported) != len(set(exported)):
        raise ValueError("NAMESPACE contains duplicate exported function names")
    if len(exported) != 904:
        raise ValueError(f"Frozen v0.4.3 should have 904 exports; found {len(exported)}")
    overrides = config["method_overrides"]
    unrecognized = set(overrides) - set(exported)
    if unrecognized:
        raise ValueError(f"Curated methods not exported in v0.4.3: {sorted(unrecognized)}")
    out = []
    for name in sorted(exported):
        if name.startswith("etpy_"):
            backend = "python-bridge"
            tier = "experimental"
        elif name.startswith("et_"):
            backend = "hybrid-interface"
            tier = "experimental"
        elif name.startswith("etr_"):
            backend = "native-R"
            tier = ("experimental" if EXPERIMENTAL.search(name)
                    else "advanced" if ADVANCED.search(name)
                    else "experimental")
        else:
            backend = "other"
            tier = "experimental"
        row = dict(
            name=name, tier=tier,
            family="provisional-specialized-or-interface",
            backend=backend,
            evidence_status="evidence_not_curated",
            classification_basis="provisional_lexical",
            caveat=("No method-specific independent evidence is curated for this "
                    "interface. Existing tests may be elsewhere; inspect assumptions."),
            evidence="",
            source_release="v0.4.3",
        )
        if name in overrides:
            given = overrides[name]
            row.update({
                "tier": given["tier"],
                "family": given["family"],
                "backend": given["backend"],
                "evidence_status": given["evidence_status"],
                "classification_basis": "curated",
                "caveat": given["caveat"],
                "evidence": given["evidence"],
            })
        if row["tier"] not in ("core", "advanced", "experimental"):
            raise ValueError(f"{name}: unsupported tier {row['tier']}")
        if not row["caveat"].strip():
            raise ValueError(f"{name}: missing method caveat")
        out.append(row)
    if len(out) != 904:
        raise AssertionError("Source exports were lost")
    return out


def build(args):
    ns = Path(args.namespace).read_text(encoding="utf-8")
    config = json.loads(Path(args.curated).read_text(encoding="utf-8"))
    rows = entries(ns, config)
    payload = {
        "schema": SCHEMA,
        "release": "v0.4.3",
        "package": "eyetrajectories",
        "total_exports": len(rows),
        "curated": sum(r["classification_basis"] == "curated" for r in rows),
        "provisional": sum(r["classification_basis"] != "curated" for r in rows),
        "methodological_tier_is_not_scientific_certification": True,
        "description": ("All names are exported by frozen v0.4.3 NAMESPACE. "
           "Uncurated tier assignments are provisional; no scientific "
           "equivalence to Python, universal inference coverage, or independent "
           "method-level certification is inferred."),
        "methods": rows,
    }
    output = Path(args.output)
    if args.verify:
        original = json.loads(output.read_text(encoding="utf-8"))
        if original != payload:
            raise AssertionError("Committed/generated registry is stale")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
                          encoding="utf-8")
        csvout = output.with_suffix(".csv")
        with csvout.open("w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=FIELDS)
            writer.writeheader()
            writer.writerows(rows)
    print("METHOD_REGISTRY_PASS", "exports", len(rows),
          "curated", payload["curated"], "provisional", payload["provisional"])
    return payload


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--namespace", required=True, help="v0.4.3 NAMESPACE")
    p.add_argument("--curated", required=True, help="curated-evidence.json")
    p.add_argument("--output", required=True, help="output registry JSON")
    p.add_argument("--verify", action="store_true")
    build(p.parse_args())


if __name__ == "__main__":
    main()
