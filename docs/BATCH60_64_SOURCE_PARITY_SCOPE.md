# Batches 60–64: native nested source-attribute alignment (developer verification)

Frozen source: `eyetrajectoriespy` 1.2.0 at `c1cd95ad718327550f7e55393ff38582872f7a94`, particularly `_covariance_diagnostics()` in `functional_mixed_effects_nested.py`.

- **60** — Explicit one-curve-per-(participant,trial) duplicate-error context and missing trial identifier validation, preserving prior error regexes.
- **61** — Reproduce source-based covariance eigenvalue/condition-number and singular/boundary rules on participant unstructured covariance.
- **62** — Reproduce the distinct trial covariance boundary rule, including the `0.10 * max(participant spectral scale, residual variance, floating-point epsilon)` criterion.
- **63** — Return non-mutating covariance diagnostic fields in both the nested trial and nested slope models, with new R regression tests and documentation.
- **64** — Guarded baseline commit, native R/Python qualification, clean Git-snapshot CRAN check, and evidence collection after targeted tests.

No fit optimizer, likelihood, fixed-effect, BLUP, residual-correlation model, or numerical estimation path is changed. The newly returned flags are source-derived diagnostics for identification issues exposed in the previous stress tests, not evidence of complete one-to-one equivalence. The original 204 source-gap triage records and 0 independent certifications remain unchanged until supported by full-contract review.
