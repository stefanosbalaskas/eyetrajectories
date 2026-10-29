# Stage 29 — Python 1.2 transfer-entropy scientific geometry and explicit source gaps

**Research draft stacked on Stage 28 draft PR #40. No merge, release or version bump.**

Frozen published Python source: `eyetrajectoriespy==1.2.0`
(`c1cd95ad718327550f7e55393ff38582872f7a94`).
Frozen 508-symbol source-API inventory:
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Three public source-aligned Python-free native integrations

| Published Python name | Native R export | Scientific output |
|---|---|---|
| `plot_transfer_entropy_sensitivity` | `etr_plot_transfer_entropy_sensitivity` | One exact declared TE multiverse slice with optional explicit parameter filters, no hidden averaging |
| `plot_transfer_entropy_circular_shift_test` | `etr_plot_transfer_entropy_circular_shift_test` | Original analyst-selected surrogate null TE values, observed TE vertical reference, exact integer-bin histogram source geometry |
| `plot_conditional_transfer_entropy_circular_shift_test` | `etr_plot_conditional_transfer_entropy_circular_shift_test` | Original conditional TE source-only shift null, observed conditional TE reference, fixed target and conditioning processes |

The functions use existing independently implemented native R
`etr_transfer_entropy_sensitivity`,
`etr_transfer_entropy_circular_shift_test`, and
`etr_conditional_transfer_entropy_circular_shift_test` results.
There is **no estimator re-execution** inside any plot. A declared
multiverse slice with duplicate x values aborts; no aggregation,
parameter selection or multiplicity adjustment is inferred.

The source plots use **base R graphics** and invisibly return numerical
plot geometry, not Python Matplotlib Axes.

### Direct published Python 1.2 graphical-source oracles

`tests/testthat/test-native-stage29-transfer-entropy-visual.R`
uses the **real published Python 1.2 estimator functions** to generate
valid Python typed TE result objects. It then calls the real published
plotting functions and validates the following using reticulate:
- Transfer-entropy source-shift histogram bin counts and observed TE
  from Matplotlib `Axes.patches` and the observed vertical line;
- Conditional transfer-entropy source-only shift histogram counts and
  observed conditional TE with the identical fixed bin count;
- TE sensitivity plot x/y source points, through the source Matplotlib
  line object. Source values are copied into a native-compatible
  scientific result class to isolate **plot geometry**, not to
  claim estimator equivalence.

The tests also cover invalid metric/parameter, ambiguous grid
slice, explicitly resolved filters, malformed surrogate values,
numeric bins, and source-empty refusal.

**Known source divergence:** NumPy/Matplotlib `bins="auto"` relies on
NumPy's Sturges/FD selection; R's `bins="auto"` uses Sturges in this
native implementation. The fixed-integer-bin tests are not evidence
of equivalent automatic-bin policy. Python type/return classes,
Matplotlib Axes and R base graphics are likewise distinct.
These are **three new machine-readable, fail-closed source gaps**.

Conditional source shifts are a predictive-information null under a
circular wrap-around assumption, **not causal identification**.
The scientific TE estimator, conditioning assumptions and possible
nonstationarity require separate domain qualification.

## Cumulative 508-source inventory

| Quantity | Stage 28 owner verified | Stage 29 authored, runtime pending |
|---|---:|---:|
| Independent Python-free native R implementations | 194 | **197** |
| Public Python callable source names mapped | 219/380 | **222/380** |
| Unmapped public Python callable names | 161 | **158** |
| Other public Python class/constant exports | 128 | 128 |
| Known unresolved source-domain/return differences | 40 | **43** |
| Targeted numerical fixture candidates | 4 | 4 |
| Independently certified complete public source contracts | **0/508** | **0/508** |

Stage 28 owner-run source verification passed 71 native assertions
(1 Python opt-in skip), 39 frozen-ledger assertions and 329 opt-in
published Python 1.2 source assertions. Exact owner local SHA and
independent complete-return-type approval were not supplied.
See [scientific review issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).

Stage 29 source tests are authored, **not yet executed**.
GitHub Actions runners previously failed before any steps;
[CI issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39)
tracks the independent infrastructure blocker.

## Owner Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage29-transfer-entropy-visual")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage29-transfer-entropy-visual"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No independent full public source-contract approval or release is
authorized by these implementation or test files.**
