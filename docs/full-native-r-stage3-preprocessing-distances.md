# Native R Stage 3 — preprocessing, geometry and trajectory distances

**Goal:** expand independently implemented R algorithms without a Python runtime. Staged against `research/full-native-r-parity-stage2-20261027`, after that branch's owner-verified **296/296** Python-vs-R kinematics tests. This stage does not replace or merge the earlier branches.

## Exact Python 1.2 public-function contracts implemented

| Python 1.2 function | Native R function | Status / important details |
|---|---|---|
| `normalize_coordinates` | `etr_normalize_coordinates` | New: normalize first two channels by specified width/height, preserve remaining channels/missing values; do not clip coordinates |
| `center_on_landmark` | `etr_center_on_landmark` | Full per-curve or scalar planar landmark centering; replaces the weaker native analogy to `etr_center` |
| `normalize_time` | `etr_normalize_time_interval` | Arbitrary start and end; replaces the unit/origin-only analogy |
| `heading_function` | `etr_heading_function` | Edge-aware irregular-grid derivative, wrapped angle and explicit low-speed NA/error policy |
| `trajectory_tortuosity` | `etr_trajectory_tortuosity_frame` | Per-curve path length, endpoint displacement, ratio, undefined flag and nonconflicting metadata |
| `pairwise_discrete_frechet_distances` | `etr_pairwise_frechet` | New matrix algorithm with named channel subset and weighted discrete Fréchet recurrence |
| `nearest_trajectory_indices` | `etr_nearest_trajectory_indices` | New distance-based neighbor ranking, with **zero-based output** matching Python by default |

Seven real R functions were added. Three were previously unmapped Python function names, while four replace under-specified earlier native analogues. This changes the conservative catalog to **44 named native candidates/analogues** out of **380 Python functions**, with **336 public Python functions without a specific mapped native candidate**. Stages 2 and 3 together introduced **11 independent R implementations**, and **128 additional public classes/constants/configurations still require native representation review**.

**Important:** these counts are a source-contract ledger, **not** a percentage of numerical equivalence. `etr_native_parity_catalog(require_complete=TRUE)` must still fail, with 0 fully certified complete contracts automatically recorded. The stage-2 numeric oracle was verified by the owner; stage-3 source changes are not yet executed in R.

## Data and scientific behavior contracts

The seven methods use only R and internal `etr_trajectory_set`/distance/derivative utilities. `reticulate` is used exclusively in opt-in independent Python-reference tests. A Python-free R user can call all seven without setting `RETICULATE_PYTHON`.

- Partial missing gaze is passed through coordinate/landmark operations; mathematical derivatives, discrete Fréchet and nearest-neighbor distances require complete input trajectories. No hidden interpolation occurs.
- Planar heading requires explicit `x` and `y` channels unless `dimensions` is supplied; stationary points have R `NA`, corresponding to Python NaN, or a fail-closed error.
- Python's `normalize_coordinates` doc mentions `[0,1]` coordinates but the implementation performs division without clipping; R intentionally preserves this behavior.
- Tortuosity is a native R data.frame. It does not claim to reproduce Python pandas `DataFrame.attrs` provenance.
- Native `etr_trajectory_set` does not yet encode Python's full `TrajectorySet.provenance` mapping; this remains a distinct schema parity issue.
- Near-neighbor indices are **zero-based** by design to match Python. Equal-distance ties use a stable original-index rule in R whereas NumPy's default argsort tie order may differ.

## Reproduce tests

In RStudio Terminal, check current work before switching:

```sh
git status --short
git fetch origin
git switch research/full-native-r-parity-stage3-20261027
git pull --ff-only
```

If the branch does not exist locally: `git switch --track origin/research/full-native-r-parity-stage3-20261027`. Do not force-switch or discard uncommitted changes.

Then in the **R Console** (restart R first after checkout):

```r
pkgload::load_all(".", quiet=TRUE)
stopifnot(file.exists("tests/testthat/test-native-stage3-preprocessing-distances.R"))
testthat::test_local(".", filter="native-stage3-preprocessing-distances")
testthat::test_local(".", filter="native-stage3-parity-ledger")
testthat::test_local(".", filter="full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")
```

To execute the independent Python 1.2 numeric oracle (Python is **not** required to run any of the native methods themselves):

```r
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".", filter="native-stage3-preprocessing-distances")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

The optional oracle uses **eight seeded, irregular multi-curve scenarios** plus direct fixture/boundary checks to compare numeric values, missingness masks, time and coordinate units, weighted Fréchet matrices, nearest zero-based indices, and tortuosity tabular fields. It does not establish general numerical correctness on all possible data distributions.

The cross-platform CI matrix and Linux pinned-Python oracle are defined in `.github/workflows/native-r-parity-stage3.yml`, but the parent repository's GitHub Actions jobs have repeatedly failed before executing any steps. **Do not mark CI or the new Stage 3 runtime tests green without actual execution evidence.**

## Next programmes after Stage 3

1. Finish native `TrajectorySet` parity for provenance, metadata and reversible interoperation, without making native execution dependent on Python.
2. Review full discrete Fréchet coupling output, constrained/windowed DTW, per-curve and multi-dimensional distance sensitivity.
3. Add native result classes and workflows for sparse/asynchronous functional estimators, phase registration, hierarchical mixed models, functional regression, nonlinear diagnostics, uncertainty and inference.
4. Qualify each of 380 Python callable contracts individually, and map the remaining 128 public objects to native R representations; preserve the strict completion gate.

**Status:** Research draft only; no CRAN publication, main merge, package release, or inferential calibration claim.


## Stationary heading test correction — owner Windows finding, 27 Oct 2026

The owner's first Stage 3 `testthat::test_local(".", filter =
"native-stage3-preprocessing-distances")` resulted in **PASS 58,
FAIL 2, WARN 0, SKIP 1**. Both failed assertions were in the *same
stationary-path heading fixture*, which assumed that a constant nonzero
coordinate pair (`x=2, y=-3`) yields an **exactly zero** numerical
derivative on a nonuniform time grid. This assumption is false for the
published Python reference's `numpy.gradient(edge_order=2)`: for
`time=c(0,.1,.4,1,2)`, NumPy can return nonzero floating-point
derivatives even on constant-valued paths (speed approximately
`2.5e-16` to `7.3e-15`). Python's exact public default
`min_speed=0` masks **only speed <= 0**, not near-zero positive speed.
Thus the two failed assertions were incorrect expectations about Python,
not proof that R deviates numerically from Python.

**Fix committed:** The native test retains the default R/Python
numerical behavior and explicitly sets `min_speed=1e-12` in the
stationary-undefined example, which reliably masks the finite-precision
residual and causes `undefined_policy="raise"` to raise as intended.
It does **not** change the native implementation, lower-level
gradient, public default, or inject undocumented epsilon
stabilization. A new opt-in independent Python test compares the
*default zero-threshold mask* and the *explicit 1e-12-threshold mask*
with the published Python 1.2 reference on the same fixture.

**Current evidence:** NumPy reference derivative behavior was directly
reproduced, and changed R source/test delimiters were checked
statically. The owner has **not rerun** the corrected R tests yet;
no Stage 3 PASS can be asserted from the previous failure transcript.
Pull the new branch head before retesting:

```r
pkgload::load_all(".", quiet=TRUE)
testthat::test_local(".", filter="native-stage3-preprocessing-distances")

# The Python v1.2 numerical oracle is still opt-in.
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
testthat::test_local(".", filter="native-stage3-preprocessing-distances")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```
