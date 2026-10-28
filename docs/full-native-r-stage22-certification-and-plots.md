# Stage 22 — native visual scientific integration and strict full-source certification blockers

**Research-only stacked draft on Stage 21 PR #31.** Source of record:
published `eyetrajectoriespy==1.2.0`, tagged commit
`c1cd95ad718327550f7e55393ff38582872f7a94`. The frozen
508-name source inventory comes from a separate development snapshot
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Eight new Python-free, source-aligned visualizations

| Source Python 1.2 public API | New native R export | Audited scientific geometry |
|---|---|---|
| `plot_embedding_delay_diagnostics` | `etr_plot_embedding_delay_diagnostics` | physical-time lags, AMI, ACF and first marked AMI minimum |
| `plot_embedding_dimension_diagnostics` | `etr_plot_embedding_dimension_diagnostics` | dimension versus FNN fraction |
| `plot_recurrence_network_degree` | `etr_plot_recurrence_network_degree` | zero-based state index and raw/normalized degree |
| `plot_recurrence_rate_curve` | `etr_plot_recurrence_rate_curve` | analyst-declared radius versus exact recurrence rate |
| `plot_windowed_rqa` | `etr_plot_windowed_rqa` | source window center times and selected metric columns |
| `plot_local_divergence` | `etr_plot_local_divergence` | mean log-divergence and optional explicitly fitted LLE line; ms → s in fit equation |
| `plot_surrogate_nonlinearity` | `etr_plot_surrogate_nonlinearity` | finite IAAFT-surrogate histogram and observed estimate |
| `plot_poincare_return_map` | `etr_plot_poincare_return_map` | consecutive 1D crossing states, identity line, optional local affine fit |

All use **base R** graphics without executing Python. They avoid hidden
resampling, smoothing, distance-model selection or stochastic inference.
The values returned invisibly facilitate exact source geometry tests.
The Python source returns **Matplotlib Axes** and R returns different
objects, so these eight are **not** exact Python source-contract
replacements. Python and R histogram algorithms do not have identical
break selection; this divergence is explicitly reported.

## Exact source count, not false certification

| Quantity | Stage 21 owner-tested | Stage 22 authored, pending run |
|---|---:|---:|
| Native R implementation entrypoints | 150 | **158** |
| Named Python callable mappings | 175/380 | **183/380** |
| Unmapped Python callable names | 205 | **197** |
| Other API exports | 128 | **128** |
| Stage 20 targeted numerical fixture PASS candidates | 3 | **3** |
| Fully approved source contracts | 0/508 | **0/508** |

**No full source contracts were approved.** Stage 21 passed 55 visual,
39 ledger, 15 opt-in pinned source-boundary assertions in owner RStudio.
Stage 22 has source and tests authored only; it has **not** passed
Windows or cross-platform jobs.

## Twelve fail-closed published-source differences

The new committed registry
`inst/extdata/native_source_contract_gaps_stage22.csv`
lists 12 precisely identified known differences and unresolved review
obligations. The offline `etr_native_parity_catalog()` exposes
`source_contract_gap_known`, `source_contract_gap_unresolved` and
`source_contract_gap_kind`. It now **refuses** to certify any candidate
whose review flags might be manually set TRUE while a matching
source-contract difference remains unresolved.

The 12 known gaps are:

- **3 Stage 20 candidates**: ALR nested input coercion; inverse-ALR
  exponential overflow; FPCA score-distance object duck typing.
- **1 deterministic mathematical primitive**:
  `functional_trapezoid_weights` now accepts common 1-D scalar
  sequences on both Python and native R. Python's broad `normalize`
  truthiness and extreme nonfinite inputs remain full-contract gaps.
- **8 plots**: Matplotlib Axes return/graphics interface differ from R;
  surrogate histogram bins are additionally backend-specific.

This is **not** a complete audit of all 508 APIs. An absent known-gap
row does *not* constitute proof of parity. Full certification still
requires source-exact numerical/domain/oracle and output/error schema,
scientific scope, independent reviewer approval, and GitHub evidence
for the tested exact commit. No automated test may self-sign a human
review or use a numeric fixture PASS as a proxy for full-domain parity.

The first priority for actual full certification is to address
well-defined deterministic public functions such as
`functional_trapezoid_weights` (not plots). A reviewed cross-language
container/boolean policy must be explicit; the three original Stage 20
candidate divergences must also be resolved or appropriately
restricted **without** asserting full unconstrained parity.

## Required owner-run Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage22-scientific-visualization")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage22-source-contract-gaps"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
z<-etr_native_parity_catalog()
c(native=sum(z$native_implementation_started),
  mapped=sum(z$named_native_candidate&z$is_python_function),
  known_unresolved_gaps=sum(z$source_contract_gap_unresolved),
  fully_certified=sum(z$one_to_one_native_contract_complete))
```

**No merge, release, package version change or independent-signoff claim.**
