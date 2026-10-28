# Stage 17 — native nonlinear divergence and RQA bootstrap

Audited against published **eyetrajectoriespy==1.2.0**: `embedding.py`, `nonlinear_dynamics.py`, `rqa_inference.py`. Six Python-free numerical R methods are implemented on a new research branch stacked above Stage 16.

| Python public name | Independent R function |
|---|---|
| `delay_embed_trajectory` | `etr_delay_embed_trajectory` |
| `local_divergence_curve` | `etr_local_divergence_curve` |
| `kantz_divergence_curve` | `etr_kantz_divergence_curve` |
| `estimate_largest_lyapunov_rosenstein` | `etr_estimate_largest_lyapunov_rosenstein` |
| `estimate_largest_lyapunov_kantz` | `etr_estimate_largest_lyapunov_kantz` |
| `bootstrap_rqa_metric_means` | `etr_bootstrap_rqa_metric_means` |

## Exact and restricted methodological contracts

- Multivariate delay reconstruction selects explicit input dimensions and concatenates lag blocks without smoothing, missing-data imputation, automatic scaling or automatic lag selection. Samples-only delay is currently implemented. The Python source's time-unit delay conversion is not qualified, and requests error.
- Rosenstein local divergence uses nearest **strictly positive-distance temporally separated states**, explicit 0-based sample horizons and logs of forward distances; zero forward distances are excluded and counted, never replaced by pseudocounts. Nearest-state ties use deterministic first-index R ordering; SciPy cKDTree may differ. The native exact algorithm caps dense nearest-neighbor states at 1600.
- Kantz uses explicit fixed positive Euclidean radius, Theiler window and minimum neighbors. No radius expansion, neighbor-count repair, automatic radius choice or fit interval selection. Horizon-specific eligible pair, reference and zero-mean counts remain observable.
- Explicit Rosenstein and Kantz slope fits require at least three finite divergence points in the stated inclusive sample-index interval. `s` and `ms` are converted to inverse seconds. **A positive slope alone does not establish chaos, let alone causality in eye-tracking behavior.**
- Curve/participant RQA bootstrap computes per-curve RQA summaries under an explicitly fixed Euclidean radius and once-per-curve recurrence contract. Equal-weight participant means use all trials of the participant, then resample **participants**, not timepoints or trial rows. Within-curve recurrence uncertainty is outside scope.
- RQA adaptive target-rate threshold, non-Euclidean metric, and time-based lag options are **explicit unsupported subsets**, not source-equivalent substitutions. Metrics whose native RQA implementation produces undefined values abort rather than impute or drop.
- Identical R seeds do not reproduce NumPy/SciPy random draws or tie choices. Descriptive uncertainty is not coverage qualification. The Stage 17 Python oracle compares deterministic embedding matrices, local log-divergence curves, pair counts, and explicit slope coefficients/SEs.

## Frozen cumulative inventory

| Measure | Stage 16 owner-run | Stage 17 authored |
|---|---:|---:|
| Authored native R implementation functions | 127 | **133** |
| Unique Python public function-name mappings | 154 / 380 | **159 / 380** |
| Unmapped Python callable names | 226 | **221** |
| Other public exports partially represented | 7 / 128 | **7 / 128** |
| Pending nonfunction exports | 121 | **121** |
| Fully certified public source contracts | 0 / 508 | **0 / 508** |

The `delay_embed_trajectory` Python name already existed as a candidate mapping. Its new native R multichannel implementation **replaces** the older candidate; it is counted as one newly authored R method but **not** an additional unique mapped Python name. The remaining five methods are new source-name mappings.

Stage 16 owner-run RStudio verification passed 72 native, 39 full ledger and 84 pinned Python 1.2 source oracle assertions, zero failures. **Stage 17 numerical tests are authored, not yet executed**. GitHub Actions job admission is independently checked; zero-step CI failures are not scientific test results.

## Windows RStudio qualification

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage17-divergence')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage17-divergence'),
  finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Research-only draft. No merge, package version bump, CRAN/PyPI release, fully certified source-contract claim or empirical chaos classification.