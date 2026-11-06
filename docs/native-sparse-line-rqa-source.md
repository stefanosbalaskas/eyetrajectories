# Native coordinate-based line RQA over large sparse joint recurrence matrices

Frozen Python 1.2 sources: `recurrence.py` (`_diagonal_lengths`, `_vertical_lengths`, `rqa_metrics`, `_regular_step`), `joint_recurrence.py` (`joint_rqa_metrics`). Source pinned to `c1cd95ad718327550f7e55393ff38582872f7a94`.

## Added scientific computation

Native `etr_rqa_metrics()` now accepts validated auto `Matrix` sparse inputs without dense conversion. Native `etr_joint_rqa_metrics()` no longer densifies sparse joint recurrence and no longer has a 2500-node conversion guard. Edges become sorted COO `(i,j)` coordinates. Diagonal line runs group upper-triangle `j-i` with consecutive row `i` positions; vertical lines group all matrix coordinates by column `j` with consecutive rows `i`. Both include observed finite-matrix border lines and use exact integer line lengths, matching Python 1.2. Missing metrics use `NaN` for sparse input, as Python does.

The source RQA time sampling contract requires an approximately regular index/physical grid (median sample step, `rtol=1e-6`, `atol=max(1e-12, abs(step)*1e-9)`). The full sparse graph remains independently validated for symmetry, self-loops and the Theiler exclusion.

## Bounded scientific evidence and limitations

A 12,005-node sparse example includes one triangle and one 3-node path, 5 unordered edges (10 matrix nonzeros), 2 qualifying diagonal lines of length 2, 2 qualifying vertical runs of length 2, DET=4/5, LAM=4/10, CORM=100*6/(12004*5); direct frozen Python 1.2 replay of all 14 numeric fields is attached as an opt-in R test. The separate SciPy-only geometry check does **not** establish native R execution. The tests must run on the user's local Windows/RStudio checkout. Sparse Matrix/S3 output is not SciPy CSR/Python dataclass identity. Source gap counts and independent full-domain certifications do not change. CRAN on this head remains unverified.

## Empty sparse matrices — source boundary regression (Batch 24 hotfix)

Frozen Python 1.2 accepts zero-edge sparse CSR auto-recurrence results and
returns `NaN` for undefined determinism, laminarity, line means, entropy,
trapping time and center of recurrence mass. Native `Matrix::summary` can
return an atomic zero-length object for empty matrices on the Windows Matrix
versions used in the qualification run; the new native sparse-entry helper
normalizes that case to an empty `(i,j,x)` data frame. This enables empty
network, joint-intersection, and line-RQA paths while retaining sparse
allocation. A previous test incorrectly expected the earlier 2500-node
rejection after the large-sparse implementation made it valid; the assertion
now tests source-compatible numerical results.

This is developer-side bounded evidence, NOT complete export-level parity or
independent certification. All 204 strict source gaps remain recorded.
