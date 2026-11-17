# Four-track scientific qualification — executed evidence (17 November 2026)

> **Author-side full real-source audit (17 November 2026, 23:21–23:33 EET):** All 78 original PoTeC ASC files were read to EOF: 283,565,421 lines, 914,776 correctly parsed EFIX events, and no malformed EFIX durations or reverse sample timestamps. Event count imbalances (20 unmatched fixation starts, 50 extra sentence-stop markers) need trial-aware follow-up; raw-to-uncorrected fixation correspondence remains OPEN. Separately, real OneStop benchmarks on installed **v0.4.3** measured the *older scalar L² loop*, **not** the later vectorized development implementation. Complete de-identified evidence: [local ASC and 0.4.3 qualification](LOCAL_FULL_ASC_043_QUALIFICATION_20261117.md).

## Provenance

This page records executed CI results rather than planned work. The implementation was merged in PRs [#201](https://github.com/stefanosbalaskas/eyetrajectories/pull/201), [#202](https://github.com/stefanosbalaskas/eyetrajectories/pull/202), and [#203](https://github.com/stefanosbalaskas/eyetrajectories/pull/203).

- [Three-OS benchmarking CI](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/44167385889): Windows, macOS and Ubuntu all passed.
- [Deeper Monte Carlo and sparse-PACE CI](https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/44166609796): two scientific jobs passed; both have attached CSV evidence.
- CI loads development main, version 0.4.0.9000, **not the archived and frozen v0.4.3 source**. All CI data are synthetic.

## A. PoTeC raw ASC source-event integrity

The source-event R script reads original ASC line classes, sample timestamps, EFIX start/end/duration and fixation/saccade/blink markers. Synthetic ZIP/parser checks passed on all three platforms.

**Real ASC-to-fixation validation is not complete.** Local historical intake listed 78 original ASC files, with only three previously sampled. The published corrected fixation exports cannot be literally equated to raw EyeLink coordinates because author correction may remap, delete and reindex events. A source-authentic uncorrected fixation report, per-event stage keys and actual correction history are still required.

Author preprocessing: https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/PREPROCESSING_SCRIPTS.md

## B. Independent model and sparse-method checks

| Test | Observed | Scope |
|---|---:|---|
| MFPCA versus independently constructed weighted covariance eigenspectrum | Max error 3.50e-16 | PASS, irregular synthetic grid |
| MFPCA score projection | Error 1.25e-15 | PASS, training projection |
| Scalar-on-FPCA versus independent QR regression | Error 0 | PASS, conditional OLS |
| Subject-held-out synthetic scalar regression | RMSE 5.19e-16; mean baseline 1.7867 | Algebraic low-rank synthetic design |
| Sparse PACE adapter versus direct fdapace backend | Error 0 | PASS, same-backend parity only |
| Sparse known-truth reconstruction | RMSE 0.1921 versus mean-only 0.7479 | MEASURED on a single-factor process |
| Sparse latent score recovery | Absolute correlation 0.99565 | MEASURED, not universal |

Missing: independently coded sparse PACE estimator, varied observation/noise settings, fully qualified functional-response regression and uncertainty.

## C. Known-truth inference

400 generated datasets (100 repetitions per scenario), 30 independent participants, repeated trials, B=199 cluster bootstrap draws, nominal 95% simultaneous band.

| Scenario | Simultaneous coverage | Exact 95% MC confidence interval | Simultaneous null false-positive rate | Cluster midpoint pointwise | Deliberately naive trial-IID midpoint |
|---|---:|---|---:|---:|---:|
| Complete | 96% | 90.1%–98.9% | 4% | 98% | 76% |
| MCAR | 92% | 84.8%–96.5% | 8% | 92% | 78% |
| MAR | 90% | 82.4%–95.1% | 10% | 93% | 77% |
| MNAR | 91% | 83.6%–95.8% | 9% | 88% | 53% |

Simultaneous false-positive rate is 1 minus simultaneous truth-coverage under the generating null. Only the cluster and naive midpoint pointwise columns are directly comparable. Monte Carlo uncertainty remains substantial, and observations under informative missingness show potential bias and undercoverage. No universal nominal-coverage guarantee is claimed.

## D. Three-OS synthetic performance

One thousand curves, 128 grid points, two channels. Warmup plus two timed repetitions per OS.

| System | Native L2 median | Native MFPCA median | L2 expression peak | L2 whole-process RSS high-water | MFPCA whole-process RSS high-water |
|---|---:|---:|---:|---:|---:|
| Ubuntu | 0.2275 s | 0.0480 s | 36.6 MiB | 273.7 MiB | 273.7 MiB |
| Windows | 0.4500 s | 0.1600 s | 36.6 MiB | 277.2 MiB | 277.2 MiB |
| macOS | 0.2005 s | 0.2050 s | INVALID / excluded | 292.5 MiB | 301.4 MiB |

All 36 platform/size/grid/function configurations completed. Cross-OS hardware is unmatched. Whole-process RSS is the **maximum since process start**, not the allocation attributable to an individual function: Linux VmHWM, Windows PeakWorkingSetSize and macOS ru_maxrss. The initial macOS peakRAM expression figures were physically implausible and were excluded by the corrected benchmark. Fresh-process peak-per-call RSS and external package comparisons remain open.

The earlier real-OneStop 104.6–214.9x paired L2 speedups are an entirely separate release-development benchmark; those results cannot be inferred from this cross-OS experiment.

## Qualification verdict

**Verified:** synthetic mathematical oracles, sparse known-truth diagnostics, 400 Monte Carlo datasets, three-platform synthetic performance and memory reporting. **Not yet verified:** full raw ASC-to-uncorrected fixation event reconciliation; independently annotated event/calibration truth; general nominal model coverage; inference for all package estimators; comparable process-isolated peak RSS; broad real-data multi-OS benchmarks. No original data or stable release files were changed.

For complete local RStudio execution instructions and remaining scientific acceptance gates, see [four-track protocol](SCIENTIFIC_VALIDATION_FOUR_TRACKS.md).
