# Native Monte Carlo recovery evidence — published Python 1.2 source

**Independent source inspection, staged research draft.** Source of truth
published `eyetrajectoriespy==1.2.0` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
frozen 508-public export census SHA
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Five stable, stage-free native R functions; four new mapped Python names

- **Native helper (not a Python root function mapping):**
  `etr_functional_recovery_result(records,metric_definitions)`
  validates successful and failed replicate records, exact metric
  identities, structured source/component information and finite values.
- `etr_functional_recovery_frame(result)` maps to published
  `functional_recovery_frame`. One metric row per successful
  replicate; preserves scenario, zero-based replicate, seed,
  metric, value, reported one-based component, source and the four
  declared semantic metric attributes.
- `etr_functional_recovery_failure_frame(result)` maps to
  `functional_recovery_failure_frame`. One row per declared
  scenario, **all attempted replicates included**: n_total,
  n_success, n_failed, failure proportion, and binomial MCSE
  sqrt(p(1-p)/n).
- `etr_functional_recovery_summary_frame(result)` maps to
  `functional_recovery_summary_frame`. Source group keys
  (scenario, metric, component, source, quantity, direction,
  units, scope), sample SD (ddof 1, zero for one replicate),
  NumPy-linear/type-7 quantiles q05/q25/median/q75/q95, IQR,
  MCSE(mean) and joined failure frequency for each scenario.
  Empty successful recovery produces a header-only summary while
  failure evidence is retained separately.
- `etr_plot_functional_recovery_summary(summary,metric,statistic)`
  maps to `plot_functional_recovery_summary`. Plot selected
  original source Monte Carlo scalar statistic, with IQR only when
  median plus q25/q75 are actually present. No invented uncertainty
  for other statistics, no automatic accept/reject thresholds.

**No publicly exported function contains a development stage
identifier.** The R functions are Python-free, and consume already
obtained recovery observations without re-simulation or fitting
estimator models.

## Direct pinned Python 1.2 typed source oracles

`tests/testthat/test-native-functional-recovery-evidence.R`
builds **real published Python dataclass instances** of
`FunctionalRecoveryMetric`, `FunctionalRecoveryValue`,
`FunctionalRecoveryRecord` and `FunctionalRecoveryResult`
from the exact same successful/failed native scientific records.
It exercises all four public Python functions directly and compares:

1. All 11 columns of the source `functional_recovery_frame`
   against native R, including missingness and first component labels.
2. All six source failure-frame fields against native R, including
   denominator and binomial MCSE.
3. Every available numerical and semantic column in the 23-column
   source recovery Monte Carlo summary, including sample SD,
   NumPy-linear quantiles, MCSE and retained failure frequency.
4. Original Matplotlib recovery scatter/errorbar x and median
   coordinates against the native R base graphics source geometry.

The test also includes a fully failed recovery scenario,
invalid-status/metric validation, mismatched flattened/structured
metric labels, IQR/median checks and prevention of invented
statistical qualification cutoffs. A test passes only if the
installed Python distribution returns published version 1.2.0.

## Boundaries on certification

Published Python returns immutable typed dataclasses, pandas
DataFrames and Matplotlib Axes. Native R returns an explicitly
validated S3 list, data frames and base graphics. Python's complete
duck-typed accepted domains, error classes, structured record
validation, numeric extreme cases and precise graphical return
objects differ and require independent review.

**No targeted numerical match is evidence of complete accepted-domain
parity or independent reviewer approval.** Four new explicit
`source_contract_gap_unresolved=TRUE` entries block false
complete certification in
`inst/extdata/native_source_contract_gaps_stage22.csv`.

### Frozen public Python 1.2 inventory

| Metric | Last owner-tested | New authored branch |
|---|---:|---:|
| Independent native scientific R implementations | 207 | **211** |
| Mapped published public Python function names | 232 / 380 | **236 / 380** |
| Public Python callable source names still unmapped | 148 | **144** |
| Nonfunction class/constant source exports | 128 | 128 |
| Explicit known full-source behavior differences | 53 | **57** |
| Narrow deterministic candidate numerical fixtures | 4 | 4 |
| **Fully independently certified complete public source contracts** | **0 / 508** | **0 / 508** |

The **extra native result constructor** is not counted as a
published Python public source callable implementation. Existing
independent reviewer queue:
[issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).
GitHub Actions runner admission:
[issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39).

## Owner Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-functional-recovery-evidence")
testthat::test_local(".",filter="native-functional-inference-visuals")
testthat::test_local(".",filter="native-functional-registration-plots")
testthat::test_local(".",filter="native-stage22-source-contract-gaps|full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-functional-recovery-evidence"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No merge, release, approval flag changes or scientific
finite-sample qualification claims are authorized by this draft.**
