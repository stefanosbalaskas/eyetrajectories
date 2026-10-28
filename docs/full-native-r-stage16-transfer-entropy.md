# Stage 16 — independent empirical transfer entropy in native R

Audited against the **published `eyetrajectoriespy==1.2.0`** source (`transfer_entropy.py`, `conditional_transfer_entropy.py`, `transfer_entropy_sensitivity.py`). Twelve Python-free native R source-callable methods are authored. **Eight numerical estimators/audits and four scientific reports**, not a Python bridge.

| Published Python callable | Native R implementation |
|---|---|
| `discrete_transfer_entropy` | `etr_discrete_transfer_entropy` |
| `transfer_entropy_local_frame` | `etr_transfer_entropy_local_frame` |
| `transfer_entropy_circular_shift_test` | `etr_transfer_entropy_circular_shift_test` |
| `conditional_transfer_entropy` | `etr_conditional_transfer_entropy` |
| `conditional_transfer_entropy_local_frame` | `etr_conditional_transfer_entropy_local_frame` |
| `conditional_transfer_entropy_circular_shift_test` | `etr_conditional_transfer_entropy_circular_shift_test` |
| `transfer_entropy_parameter_sensitivity` | `etr_transfer_entropy_parameter_sensitivity` |
| `transfer_entropy_reporting_text` | `etr_transfer_entropy_reporting_text` |
| `transfer_entropy_circular_shift_reporting_text` | `etr_transfer_entropy_circular_shift_reporting_text` |
| `conditional_transfer_entropy_reporting_text` | `etr_conditional_transfer_entropy_reporting_text` |
| `conditional_transfer_entropy_circular_shift_reporting_text` | `etr_conditional_transfer_entropy_circular_shift_reporting_text` |
| `transfer_entropy_parameter_sensitivity_reporting_text` | `etr_transfer_entropy_parameter_sensitivity_reporting_text` |

## Scientific and computational specification

- Empirical plug-in conditional mutual information measured in **bits**, using exact integer-coded source and target states, with optional fixed conditioning-process histories. All n-dimensional continuous signal discretization must happen upstream; nonintegral, nonfinite and malformed inputs fail closed.
- Time indexes and history alignment follow the Python reference's **zero-based** sample-index convention. The source histories begin at `source_lag`, while target histories start at lag 1; conditioning histories use `condition_lag`.
- Both local information and average estimates use exact observed-count ratios. Support fractions and singleton-history diagnostics expose sparse-state risks; no smoothing or pseudocounts are introduced.
- Circular-shift nulls use **only** explicitly declared distinct source shifts; target and conditioning time series remain unchanged. Plus-one upper-tail p-value and attainable resolution are exposed. Circular wrap-around requires a defensible stationarity assumption. **No causal identification follows from predictive information, even when a shift-based p-value is small.**
- The sensitivity Cartesian product preserves every declared target history, source history and source lag. No row drops silently, no automatic ranking or optimal configuration is selected. Descriptive across-specification quantiles are not sampling confidence intervals or multiplicity-corrected tests.
- Python reticulate is used **only** in opt-in tests, never in production R implementations. The pinned Python 1.2 reference compares each deterministic local TE contribution and each declared shift statistic.

## Frozen conservative inventory

| Measure | Stage 15 owner-tested | Stage 16 code authored |
|---|---:|---:|
| Independently authored native R functions including descriptive reports | 115 | **127** |
| Named mapped Python function contracts | 144 / 380 | **156 / 380** |
| Unmapped Python callable names | 236 | **224** |
| Partially represented nonfunction exports | 7 / 128 | **7 / 128** |
| Pending nonfunction source objects | 121 | **121** |
| Fully one-to-one source certified contracts | 0 / 508 | **0 / 508** |

Stage 15 owner-run Windows RStudio qualification passed (native 72, strict frozen ledger 39, Python 1.2 source oracle 80 assertions; no failures). Stage 16 code and R/Python oracle test blocks are **authored but have not run**. The cross-OS GitHub CI jobs may fail before running any steps; such failures must not be presented as numerical parity findings.

## RStudio qualification

```r
pkgload::load_all('.', quiet=TRUE)
testthat::test_local('.', filter='native-stage16-transfer-entropy')
testthat::test_local('.', filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(), '1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.', filter='native-stage16-transfer-entropy'),
  finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Research PR must remain DRAFT. No merge, version bump, CRAN/PyPI release, 508-contract parity certification or causal-inference claim.