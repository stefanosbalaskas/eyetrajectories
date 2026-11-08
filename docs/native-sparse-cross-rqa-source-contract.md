# Batch 25: native sparse cross-RQA contract extension

**Frozen Python reference:** `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `recurrence.py` (`_diagonal_lengths`, `_vertical_lengths`, `_line_rqa_sampling_steps`, `rqa_metrics`) and `nonlinear_types.py` (`RecurrenceResult`, `RQAResult`).

## Scientific change

Native `etr_rqa_metrics()` and `etr_cross_rqa_metrics()` now accept native sparse `Matrix` rectangular cross-recurrence matrices with explicitly declared `time_a` and `time_b` grids. The new sparse computation enumerates only nonzero coordinates, computes **all** diagonal runs and **all** vertical runs, applies the caller's minimum line lengths, and returns the Python source's 14 numerical keys. No n-by-m dense matrix is formed.

A cross recurrence differs scientifically from auto-recurrence: there is **no upper-triangle reduction**, no Theiler exclusion applied during quantification, and `center_of_recurrence_mass` is undefined (`NaN`). A finite approximately regular grid is required on both axes; their sampling steps must agree within the source tolerances. Empty CSR/Matrix graphs return `NaN` for undefined ratios and 0 for max line lengths/counts. Dense native R behavior is deliberately unchanged.

## Evidence status

- Batch 23 user full qualification: commit `3b69eb4`, zero failures.
- Batch 24 user targeted qualification: PASS after empty-sparse hotfix; full two-mode qualification **not** shown in the latest user log because commit was stopped by one trailing space.
- Batch 25: source-aligned R test authored and added to both qualification modes; **not yet executed in user RStudio**.
- Python/SciPy source result is a typed RQA dataclass and CSR input. Native R returns an S3 list and `Matrix` input. These are **representation differences** and strict Python identity parity is **not** claimed.
- No external reviewer decisions exist; no independent certifications are awarded. 203 callable source-gap rows plus one nonfunction remain recorded: **204** total. The `recurrence_network` row is updated with actual bounded evidence, not closed.

## Independent-review responsibilities

The external reviewer must independently verify numerical properties, finite/empty/invalid domains, sampling-tolerance boundaries, zero-index/one-index translation, matrix output class/shape semantics, error categories, and source version provenance before an approval. The bundled checklist is unsigned and intentionally contains no reviewer claims.
