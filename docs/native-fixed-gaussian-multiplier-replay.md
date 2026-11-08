# Frozen Python 1.2 — same-draw functional mean and windowed-RQA bands

Source: `eyetrajectoriespy==1.2.0` at `c1cd95ad718327550f7e55393ff38582872f7a94`; `inference.py` and `functional_rqa.py`.

Native exported routines `etr_multiplier_functional_mean_band()` and `etr_windowed_rqa_functional_mean_band()` now accept an **optional R-only** argument `gaussian_multiplier_draws`, a finite numeric matrix with `n_multiplier` rows and one column for each *independent* unit in source order. `unit="participant"` columns correspond to the first occurrence of participant identifiers, **not trial curves**. Calls with this input bypass R's random-number generator, preserve `.Random.seed`, and do not use `random_state` for sampling.

This is a conditional, common-random-number **numerical replay**; it does not change the Python 1.2 public function signatures, and it does not claim an R implementation of NumPy PCG64. Without fixed draws, native R keeps the existing isolated base-R random seed and empirical functional-inference behavior.

The corresponding mandatory R test compares **all** of `mean`, `pointwise_se`, `lower`, `upper`, `max_statistics`, and `critical_value` with frozen Python 1.2 on identical NumPy-generated multiplier matrices. The direct RQA test checks the full derived-functional RQA mean-band, including equal-weight participant aggregation and the calibrated maximum-statistic distribution. Additional tests cover malformed matrices, deterministic seeds, no RNG perturbation, and entire numerical band identities.

Important remaining differences: the public Python API has no fixed-draw input, the normal R seeded stream still differs from NumPy PCG64, native result types remain native S3 rather than Python dataclasses, and full-domain errors and inference semantics have not been independently verified. The `windowed_rqa_functional_mean_band` unresolved source-gap flag is deliberately **not closed**. Developer test evidence is not independent scientific certification.
