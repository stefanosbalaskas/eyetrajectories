# Stage 9: native functional diagnostics (research draft)

Target: published Python eyetrajectoriespy 1.2.0. Source modules reviewed: compositional, fpca, analysis, sparse, registration, phase.

## Twelve independently implemented R callables

| Python function | Native R function |
|---|---|
| `alr_transform` | `etr_alr_transform` |
| `inverse_alr` | `etr_inverse_alr` |
| `component_trajectories` | `etr_component_trajectories` |
| `select_n_components` | `etr_select_n_components` |
| `fpca_score_frame` | `etr_fpca_score_frame` |
| `score_distance_matrix` | `etr_score_distance_matrix` |
| `pairwise_functional_distances` | `etr_pairwise_functional_distances` |
| `sparse_dimension_summary` | `etr_sparse_dimension_summary` |
| `warping_displacement` | `etr_warping_displacement` |
| `phase_summary` | `etr_phase_summary` |
| `phase_trajectory_set` | `etr_phase_trajectory_set` |
| `fit_phase_fpca` | `etr_fit_phase_fpca` |

All twelve execute without Python. A native landmark-registration object now also retains original trajectories and reference-to-source warps without changing the registration calculation.

## Conservative inventory

- 508 frozen Python exports: 380 functions and 128 other objects
- Named R callable candidates: 77 (previously 65)
- Unmapped Python functions: 303 (previously 315)
- Independently authored native R functions in Stages 2-9: 47 (previously 35)
- Partial nonfunction objects: 7; fully certified public contracts: 0 of 508

## Qualification and limits

Pure R and opt-in independent Python 1.2 comparison tests were committed but have not been executed. The optional reference tests never run as part of native R algorithms. FPCA sign indeterminacy is handled invariantly. Full Python result dataclasses, unsupported options, broad edge cases, cross-platform execution, inference validation and complete API equivalence remain unqualified.

Run with the Stage 9 branch in RStudio:

```r
pkgload::load_all('.', quiet=TRUE)
testthat::test_local('.', filter='native-stage9-functional-diagnostics')
testthat::test_local('.', filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(), '1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.', filter='native-stage9-functional-diagnostics'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Research draft only; no merge, CRAN submission or release.

## Stage 9 code-head GitHub Actions admission audit (28 October 2026)

[Stage 9 run #40601586058](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/40601586058) completed with a `failure` conclusion for all four jobs (Windows, Ubuntu, macOS native R and Linux pinned Python reference), each with **zero recorded job steps**. This demonstrates failure before any scientific or software test executed, not a failed Stage 9 numerical parity comparison. Subsequent documentation-only commits do not create executed final-head CI evidence. Independent RStudio runtime qualification is outstanding. The 77/380 and 47-implementation figures are code and source-ledger inventory, not test-pass or public-contract certificates.
