# Batch 26 — Native sparse fixed-radius recurrence construction

Pinned source: `eyetrajectoriespy==1.2.0` commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `recurrence.py` functions `recurrence_matrix` and `cross_recurrence_matrix`.

New opt-in `sparse_output=TRUE` for `etr_recurrence_matrix` and `etr_cross_recurrence_matrix`: one-dimensional finite state vectors and fixed nonnegative radius, with native Matrix sparse output. Inclusive radius, the original-time-order Theiler exclusion, the eligible-pair denominator, zero edges and curve metadata are preserved. This avoids dense construction for 12005-node auto and 9-million-pair cross examples. A 3-million-retained-pair cap avoids unexpectedly dense outputs. The default `sparse_output=FALSE` behavior is preserved.

The scientific scope is limited: Python supports multidimensional state vectors and target-rate sparse construction; native `sparse_output=TRUE` does not yet. Python rejects zero radius, whereas legacy R accepts it. Python CSR/dataclass output differs from R Matrix/S3 identity. Error-domain, precision, and full-domain independent certification remain unresolved. No source-gap flag was closed.

Source tests: `tests/testthat/test-native-recurrence-sparse-build.R` checks native dense/sparse outputs, nonfinite/invalid domains, >2500 auto nodes, >5m cross pairs, and optional pinned Python source comparison. `scripts/test_sparse_construction_geometry_batch26.py` is a SciPy-only reference and does NOT execute R. The two qualification modes now include the new suite. The unsigned checklist records no independent approvals.
