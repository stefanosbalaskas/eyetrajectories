# Stage 26 — functional RQA sensitivity, whole-unit inference and Python-pinned recovery semantics

**Research draft stacked on Stage 25 PR #36; no release or merge.**

Published Python source: `eyetrajectoriespy==1.2.0`, frozen tag
`c1cd95ad718327550f7e55393ff38582872f7a94`.
The 508 exported symbol census is frozen separately to catalog SHA
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Six new Python-free native public integrations

| Source Python name | Native R name | Scientific contribution |
|---|---|---|
| `windowed_rqa_sensitivity` | `etr_windowed_rqa_sensitivity` | Explicit multiscale/window-step RQA sensitivity with source-sample reuse, exact shared-window-center comparison, no resampling or preferred-window selection |
| `windowed_rqa_functional_mean_band` | `etr_windowed_rqa_functional_mean_band` | Gaussian multiplier simultaneous mean band for derived RQA functions at **curve or participant**, never independent overlapping-window rows |
| `functional_recovery_metric_catalog` | `etr_functional_recovery_metric_catalog` | Immutable-source-pinned ordered metadata for all **27** published Python 1.2 recovery metrics |
| `functional_recovery_metric_catalog_frame` | `etr_functional_recovery_metric_catalog_frame` | Complete 27-row recovery schema with names, quantities, directions, units, scopes and descriptions |
| `functional_recovery_reporting_text` | `etr_functional_recovery_reporting_text` | Compact, source-aligned known-truth recovery description retaining metric family and estimator provenance |
| `functional_recovery_assessment_frame` | `etr_functional_recovery_assessment_frame` | Native semantic recovery metrics in a tidy table, with metadata validation and no invented recovery values |

The metadata file
`inst/extdata/native_recovery_metric_catalog_py120.csv` reproduces
**every one** of the 27 ordered `_metric()` definitions from published
Python `src/eyetrajectoriespy/recovery.py`. A direct pinned
`eyetrajectoriespy==1.2.0` source oracle compares the full 27-row
frame cell-by-cell and the generated component/source flat key.
The value-key utility is provided as an additional R helper and comes
from the Python `eyetrajectoriespy.recovery` internal module; it is
**not** a public root callable among the frozen 380 Python names.

The numerical RQA sensitivity functions invoke pre-existing native
`etr_windowed_rqa_trajectory_set` and
`etr_multiplier_functional_mean_band` estimators, preserving their
scientific limitations and **R/NumPy RNG non-equivalence**.
All window-step pairs are analyst specified; the pairwise metrics
compare only **exact shared center times** and return NaN if none exist.
Design reuse reflects deterministic window overlap and is **not** a
measure of independent information resolution.
Inference requires independent source curves or declared participant
units. Native R allows only fixed-radius Euclidean, integer sample-time
window contracts, not all Python 1.2 threshold/time-unit alternatives.

## Cumulative frozen 508-source inventory

| Measure | Stage 25 owner-tested | Stage 26 authored and NOT yet runtime-qualified |
|---|---:|---:|
| Native R implementation entrypoints | 175 | **181** |
| Mapped public Python callable names | 200/380 | **206/380** |
| Unmapped callable names | 180 | **174** |
| Other class/constant exports | 128 | 128 |
| Targeted numerical fixture-qualified candidates | 4 | 4 |
| Known unresolved published-source contract differences | 21 | **27** |
| Fully independently certified public Python contracts | 0/508 | **0/508** |

**No fully certified contracts have been approved.** Four preliminary
candidate contracts (`alr_transform`, `inverse_alr`,
`score_distance_matrix`, `functional_trapezoid_weights`) have
targeted numerical fixture PASS evidence, but each still fails the
independent complete-domain schema, numerical and scientific review
threshold. [Open independent review #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).
Six Stage 26 known source divergences are explicitly hard-blocked in
the 27-row register, including native class versus Python dataclass /
pandas outputs and stochastic inference engine mismatch.

## Required Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage26-functional-rqa-recovery")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage26-functional-rqa-recovery"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**Publication and certification gate remain closed** until exact-head
tests pass, public acceptance domains and error/schema behavior are
independently audited, and the full source reviewer approves a concrete
committed evidence link. No release, version bump or merge.
