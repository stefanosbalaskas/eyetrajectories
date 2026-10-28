# Stage 21 — four Python-free visual integrations and source-contract boundary witnesses

**Research branch only; no merge or release.** The published Python source of record is
`eyetrajectoriespy==1.2.0`, tag commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.
The 508-name frozen R API manifest is a different development snapshot
(`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`).

## Implemented public Python-name analogues

| Python plotting entrypoint | Native base-R graphics entrypoint | Underlying scientific geometry |
|---|---|---|
| `plot_planar_trajectories` | `etr_plot_planar_trajectories` | first two complete channels, curve selection, y-axis inversion, equal coordinate aspect |
| `plot_fpca_component` | `etr_plot_fpca_component` | fitted functional mean and exactly ± analyst-specified score standard deviations |
| `plot_dynamic_time_warping_alignment` | `etr_plot_dynamic_time_warping_alignment` | unmodified zero-based monotone DTW path and raw/normalized distance annotation |
| `plot_trajectory_distance_rank_correlations` | `etr_plot_trajectory_distance_rank_correlations` | symmetric Spearman descriptive rank agreement and exact unit diagonal |

They deliberately return native R geometry invisibly, **not a Matplotlib
Axes object**. This is a known Python-vs-R result-container divergence,
so no public output-object contract is certified. No bridge call is made.

## Current conservative source inventory (after Stage 21 implementation)

- **175/380** uniquely mapped public callable source names; **205** unimplemented names.
- **150** independently authored native R implementation entrypoints.
- **3** Stage 20 certification candidates with targeted numerical fixture PASS;
  all complete-contract flags remain FALSE.
- **0/508 fully certified** public Python source contracts (128 nonfunction
  exports remain in the frozen 508 inventory).
- Stage 21 changes are authored; **exact-head local and cross-platform R
  runtime tests remain pending**.

## Blocking direct Python 1.2 source-contract observations

The Stage 21 pinned boundary-test file is
`tests/testthat/test-native-stage21-source-boundaries.R`. It runs against
the public Python functions, not a hand-ported oracle. It verifies:

1. `alr_transform` accepts a nested 3-D Python-compatible sequence
   converted by `np.asarray`; the strict R version rejects a nested list.
2. `inverse_alr` can emit nonfinite normalized entries for overflowed
   log-ratios, whereas native R intentionally fails closed.
3. `score_distance_matrix` accepts a duck-typed Python object carrying
   scores and component count; native R requires a validated `etr_fpca`
   fit.

**These are blocking differences, not failures to hide.** Safety-oriented
R input restrictions can be scientifically defensible while still making
a full unconstrained one-to-one source-contract claim false. Any future
domain-restricted equivalence statement must label its domain and must
not increment the full 508-source certification count.

Full source-contract certification still requires accepted-input and
failure-boundary review, source-exact schema and numerical behavior,
scientific-scope audit, independent reviewer approval with reproducible
evidence, and the same exact commit on which all evidence was collected.

## Owner-run qualification

```r
pkgload::load_all(".", quiet=TRUE)
testthat::test_local(".",filter="native-stage21-visual-diagnostics")
testthat::test_local(".",filter="native-stage21-source-boundaries")
testthat::test_local(".",filter="full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",filter="native-stage21-source-boundaries"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
z<-etr_native_parity_catalog()
c(mapped=sum(z$named_native_candidate & z$is_python_function),
  native=sum(z$native_implementation_started),
  certified=sum(z$one_to_one_native_contract_complete))
```

The research branch is based on the Stage 20 draft rather than `main`.
Both stages remain **unmerged**. All CI and local test claims must be
tagged to their exact head; the Stage 20 owner-run 65/39 assertions
do not certify Stage 21 code.
