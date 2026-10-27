# Native R Stage 4 — audited discrete Fréchet and dynamic time warping

**Source contract:** published `eyetrajectoriespy==1.2.0`, `src/eyetrajectoriespy/analysis.py` (`discrete_frechet_distance`, `dynamic_time_warping_distance`, `pairwise_dynamic_time_warping_distances`) and `types.py` (`DiscreteFrechetResult`, `DynamicTimeWarpingResult`). No external documentation is substituted for the exact upstream source.

**Goal:** enable genuine Python-free R computation of full *discrete* Fréchet coupling and full DTW path information. Stage 3's owner-run **347/347 Windows assertions** passed for seven earlier native operations. Stage 4 builds on that research branch; no upstream scientific estimators or R stage-3 implementations were altered.

## Three independently written public native R methods

| Python 1.2 source function | Native R Stage 4 function | Contract added |
|---|---|---|
| `discrete_frechet_distance` | `etr_discrete_frechet()` | Scalar and `return_coupling=TRUE`: one exact monotone optimal coupling, local weighted Euclidean distances, counts, provenance and deterministic tie-breaking |
| `dynamic_time_warping_distance` | `etr_dynamic_time_warping()` | `symmetric1` and `symmetric2`, sample-index `window_radius`, optional `normalize`, scalar or audited `return_path=TRUE` result |
| `pairwise_dynamic_time_warping_distances` | `etr_pairwise_dtw_full()` | Native unlabeled distance matrix, selected named dimensions and weights, step patterns, index-band windows and symmetric2 normalization |

The first two replace name-level analogues `etr_frechet` and `etr_dtw`, whose public options were narrower. The third introduces a previously unmapped Python method. **The older R methods remain unchanged and available**, avoiding breaking existing R code.

The full `etr_native_parity_catalog()` should now contain **45 named native candidates** out of **380 Python function exports**, **335 functions without specific native candidates**, plus **128 public Python nonfunction objects** whose native representations still need review. Stages 2/3/4 have added **14 independently implemented R functions** (4+7+3). Neither name matches nor the mere existence of new R code establishes full independently qualified source contracts. The 508-export completion gate remains **FAIL** by design.

## Reproducibility and output conventions

The native distance functions do not import Python. Python 1.2 supports returning zero-based path arrays; to match that public API exactly, R returns a two-column **zero-based integer matrix** in `coupling` or `path`. This convention is unusual in R: add one to convert to ordinary R array indices. The returned detailed native R result is a named S3 list with the same scientific fields as the public Python result dataclasses, including a provenance list; Python JSON serialization and cross-language round-trip output-schema equivalence are not yet verified.

Fréchet is **discrete**, not continuous, and uses a bottleneck-max recurrence. DTW is an additive local-cost recurrence. Both use weighted Euclidean distances without smoothing, resampling, recorded timestamps, or dropping missing samples. Predecessors are selected deterministically in the Python source's order: **diagonal, advancing the first trajectory, advancing the second** (ties resolved by first minimum).

DTW step patterns must not be conflated: `symmetric1` weights every alignment node once and has **no path-independent length normalizer**; `symmetric2` weights diagonal moves twice, other moves once. Python's permitted `normalize=TRUE` divides the **raw cumulative cost by `n_a+n_b`** only under symmetric2. The `window_radius` is a Sakoe–Chiba half-width measured in **sample indices**, not physical time. Infeasible endpoint windows are rejected rather than silently widening the band.

**Declared R/Python difference:** To prevent unbounded R memory allocation, Stage 4 imposes an explicit maximum of `5e6` point pairs for dense path calculation. The published Python 1.2 implementation does not have this fixed built-in cap. This remains a documented contract deviation requiring performance/policy review before certification. R `NULL` represents Python `None` for inapplicable optional output fields. Native S3 list representations do not yet constitute verified Python dataclass/serialization parity.

## Owner qualification commands

In RStudio **Terminal**:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage4-20261027
git pull --ff-only
```

If the local branch is not present, use `git switch --track origin/research/full-native-r-parity-stage4-20261027`. Never force-switch through uncommitted research work.

Restart R, then run in the **R Console**:

```r
pkgload::load_all(".",quiet=TRUE)

# Native methods, no Python runtime used by the algorithms:
testthat::test_local(".",filter="native-stage4-distance-contracts")
testthat::test_local(".",filter="native-stage4-parity-ledger")
testthat::test_local(".",filter="full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")

# Independent Python reference oracles, explicitly opted in:
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".",filter="native-stage4-distance-contracts")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

The opt-in tests use **10 seeded unequal-length multivariate sequence scenarios**, exact coupling/path comparisons, `symmetric1/symmetric2` and normalized variants, unconstrained and index-windowed cases, plus **6 seeded multi-curve pairwise DTW cases**. Tests also inspect transition weights, weighted-local-cost audits, R/Python zero-based alignment paths, optional results, invalid inputs and resource constraints. **No Stage 4 R or Python numerical test has been executed as of initial authoring.** Static source balance and exports should be checked separately; CI results cannot be assumed green while GitHub Actions jobs fail with zero steps.

## Remaining native parity programme

Next priorities include native `TrajectorySet` / result schema provenance, additional functional-distance sensitivity and full multivariate FPCA/sparse and irregular methods; the full 508-symbol contract map remains the controlling register. The earlier mean-band coverage and MNAR/identifiability research gates are independent and cannot be made green merely by successful source-level numerical equivalence.

**Release boundary:** Stage 4 is a research-only draft based on Stage 3; no merge, PyPI action, CRAN submission, or complete-native-R parity claim.
