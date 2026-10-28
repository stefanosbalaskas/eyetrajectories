# Stage 23 — native manuscript reporting and evidence-first source certification

**Draft research work stacked on Stage 22 PR #32, not a release.**

Source of truth: `eyetrajectoriespy==1.2.0`, published release
`c1cd95ad718327550f7e55393ff38582872f7a94`. The frozen
508-public-export inventory is separately pinned to Python development
manifest `7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Eight new native, Python-free descriptive source-name integrations

| Python public callable | Native R export | Native source object |
|---|---|---|
| `dynamic_time_warping_reporting_text` | `etr_dynamic_time_warping_reporting_text` | audited DTW path, cost, window and normalization metadata |
| `trajectory_distance_sensitivity_reporting_text` | `etr_trajectory_distance_sensitivity_reporting_text` | predeclared native distance multiverse |
| `fpca_stability_reporting_text` | `etr_fpca_stability_reporting_text` | matched bootstrap component similarities |
| `fpca_outlier_reporting_text` | `etr_fpca_outlier_reporting_text` | reconstruction/score review flags |
| `fpca_influence_reporting_text` | `etr_fpca_influence_reporting_text` | leave-one-group-out component influence |
| `fpca_subspace_stability_reporting_text` | `etr_fpca_subspace_stability_reporting_text` | principal-angle/eigenspace bootstrap |
| `fpca_cross_validation_reporting_text` | `etr_fpca_cross_validation_reporting_text` | leakage-aware held-out reconstruction CV |
| `multilevel_fpca_reporting_text` | `etr_multilevel_fpca_reporting_text` | descriptive participant/within-participant FPCA |

All eight use **existing native R scientific result objects** and create
descriptive manuscript-ready text without calling Python. The functions
do not recompute underlying estimates, change methods, invent inferred
significance, select a 'best' distance, or turn anomaly flags into
automatic exclusions.

Python and R scientific result containers are **not fully type/schema
equivalent** and some estimators are restricted native implementations.
A matching reporting string is narrower evidence than certification
of the complete public Python callable or its upstream estimator.
The new pinned `eyetrajectoriespy==1.2.0` oracle directly compares
three reporting strings using matching numerical fields, separately
from native R string and error-boundary tests.

## Authored frozen 508-export census

| Stage | Native R implementations | Python function names mapped | Unmapped Python functions | Fully certified source contracts |
|---|---:|---:|---:|---:|
| Stage 21 owner verified | 150 | 175 / 380 | 205 | 0 / 508 |
| Stage 22 owner verified | 158 | 183 / 380 | 197 | 0 / 508 |
| **Stage 23 authored, runtime pending** | **166** | **191 / 380** | **189** | **0 / 508** |

The 128 nonfunction Python exports remain part of the 508 inventory.

## What fully certified actually means

A complete public-source contract cannot be declared by identical
function names, fitted outputs on a handful of synthetic examples,
textual match, or an existing CI file.

The qualification process requires all of:

1. Immutable published tag and source-file/signature/default provenance.
2. Complete accepted-domain numerical outputs, shape, missingness,
   valid/invalid arguments, and error behavior for the *public* API.
3. Direct independent Python-to-R source contract oracles and no
   unresolved known behavior differences.
4. Scientific-domain interpretation/limitations reviewed explicitly.
5. An independent reviewer approval with concrete GitHub evidence
   for the qualified exact head.

The three Stage 20 candidates have green owner-run targeted fixtures
but **still have source-acceptance/overflow/duck-typing gaps**. The
Stage 22 audited known-gap register is fail-closed. Reporting adapters
cannot inherit certification from the underlying estimator or from
their own fixture success. No new approval flags have been set and
`etr_native_parity_catalog(require_complete=TRUE)` must still error.

## Stage 23 qualification in Windows RStudio

```r
pkgload::load_all(".", quiet=TRUE)
testthat::test_local(".",filter="native-stage23-manuscript-reporting")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage23-manuscript-reporting"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))

z<-etr_native_parity_catalog()
c(native=sum(z$native_implementation_started),
  mapped=sum(z$named_native_candidate & z$is_python_function),
  certified=sum(z$one_to_one_native_contract_complete))
```

**No merge, version bump, CRAN publication, PyPI publication or
complete-contract approval** is authorized by this research PR.
