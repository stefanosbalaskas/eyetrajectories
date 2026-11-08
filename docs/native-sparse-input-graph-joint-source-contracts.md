# Sparse-source recurrence networks and joint recurrence — Batch 23

Frozen reference: `eyetrajectoriespy==1.2.0`, Git commit `c1cd95ad718327550f7e55393ff38582872f7a94`; `recurrence_networks.py` and `joint_recurrence.py`. Native baseline: locally qualified `1e32391`.

## Scientific implementation

`etr_recurrence_network()` now accepts native sparse `Matrix` recurrence sources rather than requiring an input dense logical matrix. The source matrix is checked for square shape, compatible strictly increasing time, symmetric edges, no diagonal, no Theiler-band edges, and finite/non-missing nonzero entries. Sparse input plus `adjacency_storage="sparse"` avoids an n-by-n intermediate. Triangle counts, clustering, connected components, and all reported graph statistics retain the source simple-graph definitions and deterministic zero-based component labels. Dense-source default and its 2500-node guard remain unchanged. Sparse sources up to 100000 nodes are supported with sparse output; this is a bounded implementation capacity, not a performance guarantee.

`etr_joint_recurrence_matrix()` now accepts sparse or mixed dense/sparse synchronized auto-recurrence components and performs the elementwise logical intersection sparsely. Its eligible Theiler-excluded unordered-pair denominator is computed exactly without allocating n-by-n masks. `etr_joint_rqa_metrics()` converts sparse joint recurrence matrices to dense only for the existing research-size (<=2500 states) line-RQA domain; larger sparse line-RQA is rejected explicitly rather than silently allocating huge dense arrays.

## Tests, limits, source evidence

`test-native-sparse-recurrence-sources.R` checks dense↔sparse statistics, large 12005-state sparse graph and joint intersection, invalid geometry and Theiler exclusion, small-data line RQA, and a pinned Python 1.2 SciPy CSR source comparison of the joint recurrence matrix, rate, eligible pairs and RQA rate. Batch 22's prior frozen-source graph replay **passed** in the user-provided local qualification log for commit `1e32391`; this new Batch 23 replay is **not executed in R here** and remains a pending gate.

The strict `recurrence_network` source gap remains open because Python uses SciPy CSR and typed dataclasses, R uses Matrix/S3 and existing R-only aliases, and neither complete input/error-domain equivalence nor independent review has been proven. Joint recurrence source-gap status is not changed. The reviewer checklist is unsigned, and no independent scientific approvals are claimed. CRAN package checks must be rerun after these changes.
