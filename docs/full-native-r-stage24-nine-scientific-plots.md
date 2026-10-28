# Stage 24 — nine native scientific visual integrations and source-contract review

**Research only, stacked on Stage 23 PR #33. No release.**

Source of truth: published `eyetrajectoriespy==1.2.0`
tag `c1cd95ad718327550f7e55393ff38582872f7a94`.
Separate frozen Python public 508-export API snapshot SHA:
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Nine independently implemented Python-free plots

| Published Python 1.2 public name | New native R function | Scientific geometry |
|---|---|---|
| `plot_fpca_stability` | `etr_plot_fpca_stability` | bootstrap matched FPC similarity distributions |
| `plot_fpca_influence` | `etr_plot_fpca_influence` | group-specific declared influence metric |
| `plot_fpca_outlier_diagnostics` | `etr_plot_fpca_outlier_diagnostics` | robust-z / squared Mahalanobis scores and review thresholds |
| `plot_fpca_cross_validation` | `etr_plot_fpca_cross_validation` | held-out integrated RMSE and fold standard errors |
| `plot_fpca_subspace_stability` | `etr_plot_fpca_subspace_stability` | bootstrap eigenspace principal cosine/angle/projector distance |
| `plot_functional_mean_band` | `etr_plot_functional_mean_band` | simultaneous observed-grid mean, lower, upper bounds |
| `plot_joint_recurrence` | `etr_plot_joint_recurrence` | exact recurrence state-index pairs with fail-closed point threshold |
| `plot_windowed_rqa_trajectories` | `etr_plot_windowed_rqa_trajectories` | declared functional windowed-RQA source curves and optional mean |
| `plot_rqa_sensitivity` | `etr_plot_rqa_sensitivity` | one predeclared RQA parameter/metric slice; fails closed when other dimensions vary |

The source public Python plotting APIs return Matplotlib Axes; native R
returns base-graphics plots plus invisible source geometry.
The difference is **material for full public-source return-contract parity**.
All nine are in the auditable known-gap register and are explicitly
**not** fully certified. The native R algorithms do not use reticulate.

The recurrence plot uses the existing native dense logical recurrence
matrix (not a SciPy sparse matrix); `max_points` fails if a requested
result is too large rather than secretly subsampling. The mean-band
plot preserves observed-grid scope and does not claim between-grid
coverage. Cross-validation values and resampling diagnostics remain
descriptive, not causal/probabilistic inference unless separately
qualified.

## Cumulative contract inventory

| Stage | Native R implementation functions | Mapped source functions | Source functions unmapped | Full Python source contracts certified |
|---|---:|---:|---:|---:|
| Stage 23 owner-run, Windows native + pinned Python source PASS | 166 | 191/380 | 189 | 0/508 |
| **Stage 24 authored; execution pending** | **175** | **200/380** | **180** | **0/508** |

There are 128 additional source class/constant exports, accounting for
the 508 full public API inventory. Four target functions have
`numerical_fixture_pass=TRUE` in the individual pilot evidence
register, but all independent full-source approvals remain FALSE.
The known material gap register grows from 12 to **21**. No known-gap
record can be counted as full-source approval until its underlying
difference is resolved and independently reviewed. An absent gap row
does not itself establish complete-contract equivalence.

The first four outstanding full-source review candidates remain:
`alr_transform`, `inverse_alr`, `score_distance_matrix`, and
`functional_trapezoid_weights`. See
[review queue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).
Numeric fixture success, matching plot coordinates and matching
reporting text never imply complete accepted-domain/schema/source
certification or replace an independent reviewer.

## Windows owner-run verification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage24-nine-scientific-plots")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage24-nine-scientific-plots"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No merge, release, version bump or full-source certification
promotion is authorized without independently reproducible evidence.**
