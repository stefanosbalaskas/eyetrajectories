# Stage 25 — repairing a published-source input contract, not self-certifying it

**Research-only stacked draft on Stage 24. No merge or release.**

Published source: `eyetrajectoriespy==1.2.0` tagged release
`c1cd95ad718327550f7e55393ff38582872f7a94`.

The Python implementation in
`src/eyetrajectoriespy/analysis.py` of
`score_distance_matrix(fpca, n_components=None)` directly reads
`fpca.n_components` and `fpca.scores[:, :n_components]` and invokes
scikit-learn's Euclidean pairwise distances. It does not require a
particular concrete FPCA result class at the entrypoint.

The prior independent native `etr_score_distance_matrix()` first
required a validated `etr_fpca` object. Stage 25 now accepts an
additional native **list(scores = finite numeric matrix, n_components =
positive valid integer)** while retaining full native `etr_fpca`
verification for fitted objects. Default `n_components=NULL`, positive
integer component-range checks, output dimensions, symmetry and
Euclidean score distances remain unchanged.

## Direct source oracle and regression scope

- Python source object: `types.SimpleNamespace(scores=numpy.ndarray,
  n_components=2)`.
- Native R analog: `list(scores=numeric_matrix, n_components=2L)`.
- Direct pinned numerical oracle: `n_components=1L` and `2L`,
  Euclidean score geometry with matrix shape and tolerance.
- Negative tests: missing scores, nonmatrix scores, NA scores,
  component count mismatch or invalid retained count.
- Inherited Stage 21 source oracle has been updated: it now
  **requires numerical equality**, not a previously deliberate error,
  on matching score containers.

**This resolves the demonstrated minimal duck-typed container
difference, not complete source-type equivalence.** The published
Python input domain includes additional object types and
`sklearn.metrics.pairwise_distances` may differ at extreme
values/error/overflow boundaries. Those remain review obligations.
No full-domain claim or reviewer approval is justified.

## Certification inventory

- 508 frozen Python 1.2 public exports (380 functions + 128 other).
- 200 source callable names with independent native counterparts,
  175 Stage 24 implementations, and 180 source callable names
  unmapped.
- Four source-target candidates have **targeted numerical fixture PASS**.
- 21 documented known-source differences remain unresolved in the
  strict hard-gap registry.
- **0 / 508 independently certified full Python source contracts**;
  all four explicit approval booleans remain FALSE in each candidate.

[Independent exact-head complete-source review issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).

## Qualification in owner Windows RStudio

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage25-source-contract-alignment")
testthat::test_local(".",filter="native-stage21-source-boundaries")
testthat::test_local(".",filter="native-stage24-nine-scientific-plots")
testthat::test_local(".",filter="full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",
    filter="native-stage25-source-contract-alignment|native-stage21-source-boundaries|native-stage24-nine-scientific-plots"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No release, merge or independently certified full public source
contract is claimed.**
