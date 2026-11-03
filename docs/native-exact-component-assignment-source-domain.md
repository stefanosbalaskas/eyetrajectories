# Unrestricted exact native FPCA component matching

**Python source of record:** `eyetrajectoriespy==1.2.0`, pinned
`c1cd95ad718327550f7e55393ff38582872f7a94`;
`src/eyetrajectoriespy/stability.py::match_fpca_components`.

## Scientific gap addressed

The frozen Python library uses `scipy.optimize.linear_sum_assignment`
on the **negative absolute integrated component-cosine matrix**. The
native R analogue `etr_match_fpca_components()` previously solved the
same exact maximum-sum assignment using subset dynamic programming
only through 12 fitted components. Attempting `k=13` or larger
unconditionally raised an error. That was a genuine scientific and
algorithmic domain gap, not merely a documentation or input-coercion
difference.

## Exact native algorithm

- New `R/native-exact-component-assignment.R` contains a dependency-free
  primal-dual Hungarian assignment solver, with cubic asymptotic
  complexity in the fitted component count.
- The original exact subset DP and its historical behavior are retained
  for `k <= 12`. For `k > 12`, `etr_match_fpca_components`
  transforms the SciPy maximum-absolute-similarity problem into the
  equivalent nonnegative minimum-cost assignment:
  `max(abs(sim)) - abs(sim)`, then runs the Hungarian solver.
- Returns Python-style zero-based candidate assignments and original
  signed similarities. Does not use SciPy, Python, reticulate, greedy
  component matching or approximate ordering in the native path.
- Tied optima may have different permutations between SciPy and R;
  numerical objective agreement, rather than exact tie identity,
  is the valid contract in those cases. Nonfinite similarity is
  still rejected. Inputs must satisfy the existing native FPCA-fit
  and common-grid/domain contract.

## Source and mathematical verification

`tests/testthat/test-native-exact-component-assignment-source.R`
contains: a planted 13x13 assignment for which greedy matching is
strictly suboptimal; unique-optimum sign/permutation checks at
13, 16 and 24 components; retention of the native 12-component DP
contract; and (with `ET_RUN_PYTHON_TESTS=true`) direct calls to
the **actual frozen Python** `match_fpca_components` export,
providing two compatible FPCA-like score/component sources with
identical, uniquely matched geometry.

The test file is registered under both `native_r_offline` and
`python_1_2_direct_source` qualification filters and is included
with both source files in the evidence inventory.

### Follow-up: frozen Python fixture ndarray correction

The Windows qualification at the original Hungarian research commit
`d945569e0040d17742556a55456570b4f3fe236a` completed the native
R suite without failures but surfaced one Python-source fixture error
at `test-native-exact-component-assignment-source.R:96`:
`TypeError: list indices must be integers or slices, not tuple`.

The Python `component_similarity_matrix` function needs **NumPy
arrays** (not ordinary Python lists) for its
`weights[:, None]` and `scale[None, None, :]` indexed operations.
The existing source helper had explicitly converted `scale` but did
not force `weights` and `components` to NumPy arrays. In the R
reticulate bridge those R values can be passed as Python lists.
The source-oracle helper now coerces `time`, `weights`,
`components` and `scale` via
`numpy.asarray(...,dtype="float64")` and checks their dimensions
**before** calling the frozen Python export.

This is strictly a test-fixture repair, not a change to the Hungarian
algorithm or native FPCA matching. It requires a fresh exact-HEAD
RStudio run; a Python list-index TypeError does not constitute an
R-versus-Python scientific discrepancy.

**Status:** Source changes committed. A Windows RStudio exact-HEAD
qualification must still run; a static delimiter scan is not a
runtime test. This work neither upgrades the 204 recorded source-gap
exports nor creates any of the 508 independent scientific approvals.
The separately Windows-qualified CRAN v0.4.2 candidate is unchanged.
