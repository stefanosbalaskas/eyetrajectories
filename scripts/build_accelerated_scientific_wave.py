#!/usr/bin/env python3
"""Prioritize 32 difficult frozen Python 1.2 scientific function contracts.

This creates a deterministic AUTHOR work queue, not a certification claim,
and never modifies the authoritative source-gap CSV. A function is not
considered implemented, equal or independently reviewed merely because
it appears in this queue.
"""
from __future__ import annotations
import csv
import subprocess
from pathlib import Path
import source_gap_inventory as ledger

# Exactly 32 distinct algorithmic work items, not metadata aliases/plots.
WAVE_TARGETS = {
    "sparse_fpca_and_bridge": (
        "fit_elastic_fpca", "fit_sparse_mfpca",
        "run_sparse_mfpca_async_workflow", "run_sparse_mfpca_workflow",
        "run_sparse_multilevel_workflow", "run_sparse_prediction_workflow",
        "run_sparse_fpca_workflow", "fit_sparse_fpca_fdapy",
        "to_fdapy_irregular", "to_skfda_grid", "to_skfda_basis",
        "detect_functional_outliers_skfda",
    ),
    "functional_mixed_likelihood_and_inference": (
        "functional_mixed_effects_covariance_sensitivity",
        "bootstrap_functional_mixed_effects_coefficients",
        "bootstrap_functional_mixed_effects_full_refit",
        "run_functional_mixed_effects_workflow",
    ),
    "generalized_functional_regression": (
        "fit_generalized_function_on_scalar_regression",
        "generalized_function_on_scalar_predict",
        "bootstrap_generalized_function_on_scalar_coefficients",
        "bootstrap_generalized_function_on_scalar_predictions",
        "generalized_function_on_scalar_prediction_bands",
        "generalized_function_on_scalar_mean_difference_band",
        "generalized_function_on_scalar_simultaneous_bands",
        "run_generalized_functional_workflow",
    ),
    "fpcr_prediction_and_resampling": (
        "cross_validate_fpca_regression",
        "nested_cross_validate_fpca_regression",
        "fpca_regression_future_prediction_interval",
        "bootstrap_fpca_regression_uncertainty",
        "wild_bootstrap_fpca_projection",
        "scan_wild_bootstrap_fpca_truncations",
    ),
    "multivariate_surrogates": (
        "generate_multivariate_iaaft_surrogates",
        "multivariate_surrogate_nonlinearity_test",
    ),
}
COUNT = 32
FROZEN = ledger.FROZEN_PYTHON
QUEUE_FIELDS = (
    "priority", "scientific_family", "frozen_python_function",
    "native_r_candidate", "recorded_gap_kind", "source_witness",
    "full_domain_case_status", "matched_finite_source_cases",
    "divergent_source_cases", "numerical_algorithm_certified",
    "python_source_commit", "independent_reviewer_approved",
)


def is_algorithmic_gap(name: str) -> bool:
    if name.startswith("plot_") or name.endswith((
            "_frame", "_reporting_text", "_summary_frame")):
        return False
    if name.startswith(("to_", "export_", "save_")):
        return False
    return name.startswith((
        "fit_", "run_", "bootstrap_", "cross_validate_",
        "nested_cross_validate_", "wild_bootstrap_", "scan_",
        "generate_", "evaluate_", "simulate_", "select_",
        "detect_", "functional_mixed_effects_", "recurrence_",
        "multivariate_", "windowed_rqa_", "fpca_regression_",
        "generalized_function_", "score_distance_"))


def infer_scientific_family(name: str) -> str:
    if "sparse" in name or "skfda" in name or "fdapy" in name:
        return "sparse_fpca_and_bridge"
    if "mixed" in name or "covariance" in name:
        return "functional_mixed_likelihood_and_inference"
    if "generalized" in name:
        return "generalized_functional_regression"
    if "bootstrap" in name or "fpca" in name:
        return "fpcr_prediction_and_resampling"
    if "recurrence" in name or "rqa" in name:
        return "recurrence_and_nonlinear"
    return "other_scientific_algorithms"


def targets() -> list[tuple[str, str]]:
    out = [(group, name) for group, names in WAVE_TARGETS.items()
           for name in names]
    if len(out) != COUNT or len({name for _, name in out}) != COUNT:
        raise RuntimeError("Scientific wave target count or uniqueness drift")
    return out


def observed_source_evidence(root: Path) -> dict[str, dict]:
    """Read exact-head developer oracle outcomes if already recorded.

    A finite source comparison is never a full-domain approval. The frozen
    Python head and author R commit must match the exact report manifest.
    """
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return {}
    head = result.stdout.strip()
    reports = root / "artifacts" / "native_batch_numeric_diff" / head[:12]
    if not reports.is_dir():
        return {}
    import summarize_scientific_source_evidence as evidence
    actual = evidence.summarize(root, head, write=False)
    return {row["python_name"]: row
            for row in actual["function_evidence"]}


def write_queue(root: Path | str = ".",
                output: Path | str | None = None) -> Path:
    base = Path(root).resolve(strict=True)
    stats = ledger.read_inventory(base)
    path = base / "inst" / "extdata" / "native_source_contract_gaps_stage22.csv"
    with path.open(encoding="utf-8-sig", newline="") as file:
        source = list(csv.DictReader(file))
    indexed = {r["python_name"]: r for r in source}
    oracle = observed_source_evidence(base)
    active = {
        name: row for name, row in indexed.items()
        if row["unresolved_source_gap"] == "TRUE"
    }
    # A reviewed source contract must be replaced in the next implementation
    # wave, not cause an "unexpected resolved gap" halt. First preserve the
    # coherent 32 baseline families; then backfill other algorithmic gaps.
    chosen = [(group, name) for group, name in targets()
              if name in active]
    present = {name for _, name in chosen}
    if len(chosen) < COUNT:
        for name in sorted(active):
            if name in present or not is_algorithmic_gap(name):
                continue
            chosen.append((infer_scientific_family(name), name))
            present.add(name)
            if len(chosen) >= COUNT:
                break
    out = []
    for rank, (group, name) in enumerate(chosen[:COUNT], 1):
        record = active[name]
        observed = oracle.get(name, {})
        passes = int(observed.get("matched_case_passes", 0))
        disagreements = int(observed.get("source_disagreements", 0))
        if disagreements:
            status = "REPAIR_RECORDED_PYTHON_NUMERICAL_DIVERGENCE"
        elif passes:
            status = "FINITE_SOURCE_CASES_PASS_NEEDS_FULL_CONTRACT_REVIEW"
        else:
            status = "PENDING_SOURCE_FIXTURE"
        out.append(dict(
            priority=rank,
            scientific_family=group,
            frozen_python_function=name,
            native_r_candidate=record["native_r_candidate"],
            recorded_gap_kind=record["gap_kind"],
            source_witness=record["source_witness"],
            full_domain_case_status=status,
            matched_finite_source_cases=passes,
            divergent_source_cases=disagreements,
            numerical_algorithm_certified="FALSE",
            python_source_commit=FROZEN,
            independent_reviewer_approved="FALSE"))
    dest = (Path(output) if output is not None else
            base / "artifacts" / "accelerated_scientific_wave" /
            "32_algorithm_contracts_UNSIGNED.csv")
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=QUEUE_FIELDS)
        w.writeheader()
        w.writerows(out)
    print(f"ACCELERATED_SCIENTIFIC_WAVE_TARGETS={len(out)}")
    print("ACCELERATED_SCIENTIFIC_WAVE_OPEN_FUNCTIONS="
          f"{stats.active_callable}")
    print(f"ACCELERATED_SCIENTIFIC_WAVE_QUEUE={dest}")
    print("ACCELERATED_SCIENTIFIC_WAVE_CERTIFICATIONS=0")
    return dest


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--root",default=".")
    parser.add_argument("--output",default=None)
    args = parser.parse_args()
    write_queue(args.root,args.output)
