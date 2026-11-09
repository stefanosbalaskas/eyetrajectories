#!/usr/bin/env python3
"""Prioritize 32 difficult frozen Python 1.2 scientific function contracts.

This creates a deterministic AUTHOR work queue, not a certification claim,
and never modifies the authoritative source-gap CSV. A function is not
considered implemented, equal or independently reviewed merely because
it appears in this queue.
"""
from __future__ import annotations
import csv
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


def targets() -> list[tuple[str, str]]:
    out = [(group, name) for group, names in WAVE_TARGETS.items()
           for name in names]
    if len(out) != COUNT or len({name for _, name in out}) != COUNT:
        raise RuntimeError("Scientific wave target count or uniqueness drift")
    return out


def write_queue(root: Path | str = ".",
                output: Path | str | None = None) -> Path:
    base = Path(root).resolve(strict=True)
    stats = ledger.read_inventory(base)
    path = base / "inst" / "extdata" / "native_source_contract_gaps_stage22.csv"
    with path.open(encoding="utf-8-sig", newline="") as file:
        source = list(csv.DictReader(file))
    indexed = {r["python_name"]: r for r in source}
    out = []
    for rank, (group, name) in enumerate(targets(), 1):
        if name not in indexed:
            raise RuntimeError(f"Target not in frozen source ledger: {name}")
        record = indexed[name]
        if record["unresolved_source_gap"] != "TRUE":
            raise RuntimeError(f"Unexpected resolved algorithmic gap: {name}")
        out.append(dict(
            priority=rank,
            scientific_family=group,
            frozen_python_function=name,
            native_r_candidate=record["native_r_candidate"],
            recorded_gap_kind=record["gap_kind"],
            source_witness=record["source_witness"],
            full_domain_case_status="PENDING_SOURCE_FIXTURE",
            numerical_algorithm_certified="FALSE",
            python_source_commit=FROZEN,
            independent_reviewer_approved="FALSE"))
    dest = (Path(output) if output is not None else
            base / "artifacts" / "accelerated_scientific_wave" /
            "32_algorithm_contracts_UNSIGNED.csv")
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)
    print("ACCELERATED_SCIENTIFIC_WAVE_TARGETS=32")
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
