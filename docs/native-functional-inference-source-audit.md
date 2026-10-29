# Native functional inference — FOS, conformal, RQA and mixed-model visuals

**Research draft stacked on clean-public-API PR #42; not merged or released.**

Source of truth: published `eyetrajectoriespy==1.2.0` tag
`c1cd95ad718327550f7e55393ff38582872f7a94`;
frozen root API manifest SHA
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Seven stage-free, Python-free native R public function integrations

| Published Python public function | Native R scientific name | Supported native scientific domain |
|---|---|---|
| `plot_function_on_scalar_coefficients` | `etr_plot_function_on_scalar_coefficients` | Observed-grid OLS fixed coefficients with optional separately fitted simultaneous wild-bootstrap bounds |
| `function_on_scalar_reporting_text` | `etr_function_on_scalar_reporting_text` | Published wording about independent curve/participant units, per-grid OLS, HC1 and optional wild bootstrap |
| `plot_functional_mixed_effects_coefficient` | `etr_plot_functional_mixed_effects_coefficient` | Restricted two-level mixed-moments functional coefficient with **pointwise**, not simultaneous, 95% Wald intervals |
| `plot_conformal_fpca_anomaly` | `etr_plot_conformal_fpca_anomaly` | Native split-conformal marginal p-values reconstructed with the **greater-than-or-equal calibration tie rule** |
| `conformal_fpca_anomaly_reporting_text` | `etr_conformal_fpca_anomaly_reporting_text` | Complete marginal prediction qualification text; requires explicitly supplied frozen training FPCA component count |
| `plot_rqa_metric_mean_bootstrap` | `etr_plot_rqa_metric_mean_bootstrap` | Percentile intervals for native whole-curve / whole-participant population mean RQA metrics |
| `plot_functional_variance_decomposition` | `etr_plot_functional_variance_decomposition` | Participant intercept and residual variance components of the restricted native mixed-moments model |

No function name includes “stage”, “stage31”, or numbered prefixes.
Numerical historical-stage metadata is restricted to internal
provenance, not scientific function names. **All seven are native R**;
the published Python package is needed only for opt-in independent
source comparisons, not for their computation.

The native FOS and conformal contracts are attached to already
implemented estimators, and no plot refits coefficients, adjusts
bootstrap uncertainty or silently changes a sensitivity parameter.
The RQA and mixed-effects plots show the original numerical output
and explicitly reject invalid source values.

### Scientific limitations not waived by successful source fixtures

- **Mixed effects:** the native estimator is restricted two-level
  method of moments; published Python uses an optimized mixed model
  with further covariance structures. The restricted native model is
  not renamed or asserted to be a full Python mixed-model port.
- **Conformal:** marginal p-values depend on independent,
  exchangeable inlier curves. The native screen stores calibration
  scores and alpha, but does **not** store fitted FPC count; reporting
  therefore requires `n_components` from the original frozen fit as
  a separate argument, rather than fabricating a value. The
  conservative p-value tie rule is retained; flags are not FDR
  guarantees or grounds for automatic exclusion.
- **FOS:** pointwise HC1 is distinct from separately generated
  whole-function wild-bootstrap simultaneous intervals. Reporting
  counts actual bootstrap coefficient-array draws, not nonexistent
  metadata. Any simultaneous claim is limited to the observed
  time-by-dimension grid.
- **RQA:** percentile intervals summarize independently resampled
  functional units; they are not recurrence uncertainty for a single
  dependent trajectory, nor do they establish causal mechanisms.
- **Cross-language return types:** Python typed classes, pandas
  tables and Matplotlib Axes are not R S3 classes/data frames/base
  graphics. Exact plotted coordinates or report strings qualify
  narrower semantic output aspects, not the complete public call.

### Source evidence

The new test context
`tests/testthat/test-native-functional-inference-visuals.R` covers:

1. Seven public mapping names, NAMESPACE availability, failure-closed
   known source-gap certification flags;
2. Real native FOS OLS fit, zero-based component identity and numeric
   observed-grid coefficient geometry;
3. Real 100-replicate native wild-bootstrap simultaneous coefficient
   band geometry and correct source-wording replicate count;
4. Recalculated native conservative marginal conformal p-values and
   constrained reporting requiring the original component count;
5. Native mixed-moments pointwise 95% Wald geometry and variance
   decomposition; native RQA percentile bootstrap geometry;
6. Opt-in **published Python 1.2** real fitted FOS source text and
   Matplotlib plotted coordinates, and exact conformal reporting plus
   Matplotlib scatter coordinates using a source-shaped Python object.

The native numerical and pinned Python oracles are **authored but have
not yet executed on this new branch**. GitHub Actions remains
separately blocked by zero-step runner admission; see
[issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39).

### Cumulative frozen 508-source inventory

| Source metric | Last locally qualified clean API | Current authored branch |
|---|---:|---:|
| Independent native R mapped implementations | 200 | **207** |
| Public Python callable names mapped | 225 / 380 | **232 / 380** |
| Unmapped public Python callable names | 155 | **148** |
| Other public Python classes/constants | 128 | 128 |
| Explicit unresolved source scientific/type differences | 46 | **53** |
| Targeted numerical-fixture candidate source contracts | 4 | 4 |
| **Fully independently certified public source contracts** | **0 / 508** | **0 / 508** |

The previously tested **four deterministic numerical-fixture
candidates are not independently certified complete public
contracts**. Exact function signature, accepted source domains,
invalid-input/return classes, complete scientific calibration and an
independent reviewer signature are still required. See
[review issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).

## Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-functional-inference-visuals")
testthat::test_local(".",filter="native-functional-registration-plots")
testthat::test_local(".",filter="native-stage22-source-contract-gaps|full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-functional-inference-visuals"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**Draft research only — no merge, release, signed full-public source
contract approval or numerical-stochastic scientific generalization.**
