# Stage 27 — seven independent native FPCA uncertainty reporting and graphics contracts

**Unreleased research branch stacked on Stage 26 PR #37.** Published
Python source of truth: `eyetrajectoriespy==1.2.0`, tagged commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.
Frozen public 508-export API manifest:
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## Seven new source-name native R implementations

| Source public Python 1.2 name | New Python-free native R export | Scientific contract |
|---|---|---|
| `fpca_score_uncertainty_reporting_text` | `etr_fpca_score_uncertainty_reporting_text` | matched bootstrap fixed-target basis uncertainty; explicitly excludes target measurement and future-sampling variability |
| `fpca_spectrum_uncertainty_reporting_text` | `etr_fpca_spectrum_uncertainty_reporting_text` | component-matched spectrum and familywise/componentwise studentized intervals, without clipping |
| `functional_mean_band_reporting_text` | `etr_functional_mean_band_reporting_text` | independent-unit simultaneous observed-grid multiplier band provenance |
| `fpca_component_band_reporting_text` | `etr_fpca_component_band_reporting_text` | FPC shape intervals, bootstrap matching and explicit near-tie threshold caveat |
| `plot_fpca_score_uncertainty` | `etr_plot_fpca_score_uncertainty` | fixed target score median, reference and pointwise percentile limits |
| `plot_fpca_spectrum_uncertainty` | `etr_plot_fpca_spectrum_uncertainty` | eigenvalue, explained fraction and cumulative fraction intervals |
| `plot_fpca_component_band` | `etr_plot_fpca_component_band` | observed time-by-dimension FPC loading and simultaneous bootstrap limits |

The native R API calls no Python code. Reporting text reconstructs the
published Python 1.2 wording on matched numerical fixtures; **four direct
published Python output-text oracles** are authored in
`test-native-stage27-fpca-bootstrap-source.R`, using pinned source
exports and explicit matching provenance. Scientific graphics plot the
**original stored bootstrap output**, not newly estimated results.
Zero-based source component choices are preserved.

These four reporting helpers and three plots do not become fully
source-qualified merely because the text and plot coordinates match.
Python uses typed FPCA result classes and Matplotlib Axes while native
R uses independently validated R classes and base graphics. R and
NumPy bootstrap RNGs are different, so running the upstream estimators
under identical seeds is not a valid one-to-one source oracle.
The 7 new source differences are therefore recorded as unresolved
in the machine-readable fail-closed registry.

## Precise cumulative inventory

| Source metric | Stage 26 owner verified | Stage 27 authored, runtime pending |
|---|---:|---:|
| Independent Python-free native implementations | 181 | **188** |
| Unique public Python callable names mapped | 206/380 | **213/380** |
| Source function names not yet mapped | 174 | **167** |
| Public Python class/constant exports | 128 | 128 |
| Known Python/native R source contract differences | 27 | **34** |
| Targeted numerical fixture-qualified source candidates | 4 | **4** |
| Fully independently reviewed, complete public contracts | 0/508 | **0/508** |

As documented in [independent reviewer queue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34),
complete certification needs accepted-domain shape/type and error
equivalence, numerical and scientific source review, and independent
human reviewer evidence tied to a tested exact commit. No approval
flags have been changed.

## Owner-run Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage27-fpca-bootstrap-source")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage27-fpca-bootstrap-source"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))

z<-etr_native_parity_catalog()
c(native=sum(z$native_implementation_started),
  public_mapped=sum(z$named_native_candidate&z$is_python_function),
  source_gaps=sum(z$source_contract_gap_unresolved),
  certified=sum(z$one_to_one_native_contract_complete))
```

**Research draft only.** No merge, version bump, release, or artificial
complete-source certification.
