# Native R Stage 7 — fast batch port of ten Python 1.2 contracts

This research batch replaces one-function-at-a-time progression with a
**ten-function native R increment**, drawing directly from the published
Python `eyetrajectoriespy==1.2.0` sources
`validation.py`, `irregular.py`, and `phase.py`.

**No Python is executed by any R algorithm in this batch.**
Optional direct Python numeric comparisons are used solely as
independent reference tests.

## Ten Python public function candidates added

| Python 1.2 root API | Independently written R API |
|---|---|
| `validate_common_grid` | `etr_validate_common_grid` |
| `validate_simplex` | `etr_validate_simplex` |
| `validate_no_long_missing_runs` | `etr_validate_no_long_missing_runs` |
| `from_irregular_long_dataframe_native` | `etr_from_irregular_long_native` |
| `common_overlap_interval` | `etr_common_overlap_interval` |
| `make_common_grid` | `etr_make_common_grid` |
| `resample_irregular_to_grid` | `etr_resample_irregular_to_grid` |
| `resample_irregular_to_common_grid` | `etr_resample_irregular_to_common_grid` |
| `irregular_sampling_summary` | `etr_irregular_sampling_summary` |
| `phase_landmark_frame` | `etr_phase_landmark_frame` |

A separate support constructor
`etr_irregular_trajectory_set()` preserves curve-specific
time vectors, independent numeric sample matrices, curve/channel IDs,
one-row-per-curve metadata, spatial/time units and source provenance.
The Python nonfunction public class `IrregularTrajectorySet`
is therefore **partially represented**, not fully qualified.
The prior Stage 5 `TrajectorySet` representation remains partial.

## Scientific and computational limitations

Source-level mapping must not be confused with full behavior or
scientific inference qualification.

- **Irregular sampling:** finite, strictly increasing per-curve observation
  times; no automatic common-grid projection. Stable grouping in order
  of first appearance, duplicate per-curve times rejected, genuine
  missing observations retained.
- **Native interpolation:** validated **linear** method, no extrapolation,
  gaps masked when the elapsed observed duration exceeds an explicit
  `max_gap`. The upstream Python `method="pchip"` uses SciPy
  `PchipInterpolator`; Stage 7 explicitly rejects it because an exact
  numeric native R equivalent has not been independently tested.
- **Validation:** the simplex sum check reproduces NumPy
  `allclose`'s default `rtol=1e-5` in addition to the declared
  `atol=1e-7`; a curve's missing fraction is the share of samples
  missing in at least one channel. A common grid must be finite and
  strictly increasing.
- **Landmark table:** returns observed-minus-reference timing deviations
  in original curve and landmark order; broader Python
  `RegistrationResult` dataclass equivalence is not represented.
- **Metadata/provenance:** the R object preserves source-audit information
  and metadata, but full pandas index/data-category behavior and Python
  serialization remain a source-contract gap.
- **Python-neutral runtime:** `reticulate` is never invoked by the
  new native functions. The Python reference suite is **opt-in**.

## Progress toward full native R

The frozen Python 1.2 public API still lists 508 exports,
380 callable functions and 128 class/configuration/constant objects.

| Measure | Prior Stage 6 | This Stage 7 branch |
|---|---:|---:|
| Python callable functions with mapped R candidate | 46 | **56** |
| Python callable functions still unmapped | 334 | **324** |
| Independently implemented callable candidate methods, Stages 2/3/4/6/7 | 15 | **25** |
| Partially represented Python nonfunction classes | 1 | **2** |
| Other Python nonfunction objects not reviewed | 127 | **126** |
| Fully qualified 508-source exact contracts | 0 | **0** |

The 25 methods reflect Stages 2/3/4/6/7 only; Stage 5's four
R-only object-infrastructure functions and this stage's irregular
constructor are additional functionality **not counted as newly mapped
Python callable contracts**. The frozen register's strict
`etr_native_parity_catalog(require_complete=TRUE)` call **must fail**.

## Qualify this full batch

In the RStudio Terminal, with no uncommitted research work:

```sh
git fetch origin
git switch research/full-native-r-parity-stage7-batch-20261027
git pull --ff-only
```

If the branch does not exist locally:
`git switch --track origin/research/full-native-r-parity-stage7-batch-20261027`.

Restart R, then execute:

```r
pkgload::load_all(".",quiet=TRUE)

# Native R algorithms, no Python execution:
testthat::test_local(".",filter="native-stage7-batch-irregular-validation")
testthat::test_local(".",filter="native-stage7-parity-ledger")
testthat::test_local(".",filter="full-native-r-parity-ledger")

# Independent reference: Python 1.2 is used ONLY as oracle
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(
  ".",filter="native-stage7-batch-irregular-validation"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

The test matrix covers all 10 source methods analytically and 3
multi-curve irregular numerical comparison scenarios against the
published Python 1.2 `from_irregular_long_dataframe_native`,
`common_overlap_interval`, `make_common_grid`,
`resample_irregular_to_grid`, `irregular_sampling_summary`,
and `validate_simplex` functions. Missing values, union/overlap
domains, max-gap masking and provenance are included.

**Qualification update (supersedes the initial authoring status):**
The owner subsequently executed and passed native R, the Stage 7
parity ledger, and the pinned Python 1.2 opt-in numerical oracle on
Windows. The exact local results are recorded below. Repository-wide
GitHub Actions remains blocked before any recorded job steps, so
independent cross-platform CI is not yet verified.

**Release boundary:** All changes are research-only on a separate
draft PR based on Stage 6. No merge to main, no CRAN/PyPI release,
no 508/508 claim, and no assumptions about posterior coverage,
MNAR identifiability or other inferential scientific gates.


## Owner-executed Stage 7 qualification — Windows PASS, 28 October 2026

After changing the local checkout to the Stage 7 branch, the owner
verified that `tests/testthat/test-native-stage7-batch-irregular-validation.R`
existed and ran all three requested filters. Complete RStudio output:

| Test filter | PASS | FAIL | WARN | SKIP |
|---|---:|---:|---:|---:|
| Native `native-stage7-batch-irregular-validation` | **58** | 0 | 0 | 1 expected Python opt-in test |
| Native `native-stage7-parity-ledger` | **69** | 0 | 0 | 0 |
| Full `native-stage7-batch-irregular-validation`, `ET_RUN_PYTHON_TESTS=true` | **115** | 0 | 0 | 0 |

The owner explicitly verified `identical(et_python_version(),"1.2.0")`
before enabling the Python-reference suite. The full 115-pass run
includes the native test assertions; 115 does not represent 115
independent Python/R function comparisons.

The successful opt-in suite provides actual Windows test evidence
for source-matched irregular import, common overlap/union grid
construction, supported *linear* projection with maximum-gap
missingness masking, selected curve-level sampling summaries and
simplex validation. Pure-R analytic tests also passed for additional
edge conditions and landmark reporting.

**Unqualified boundaries:** Python `pchip` interpolation is
intentionally unsupported; broad input/marshalling variations,
complete Python dataclass and pandas metadata semantics, all
regression suites, and independent Linux/macOS execution remain
open. GitHub Actions
[run #40589428504](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40589428504)
failed with zero recorded steps in each job, which must not be
reported as either successful runtime execution or a numerical
mismatch. Full 508-symbol source-contract certification remains
closed. PR #15 stays DRAFT, with no merge or release.
