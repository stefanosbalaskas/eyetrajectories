# Native public function names, registration plots and strict Python source boundaries

## User-facing API naming convention

**Scientific function names carry no development-stage labels.**
All 225 mapped Python 1.2 public names are exposed in R under the
stable scientific `etr_<python_source_function_name>` style.
Do not publish `stageNN`, `etrNN` or numerical development-stage
prefixes as callable exported function names.

This research branch also replaces 14 stage-numbered internal
R implementation helpers across source files formerly named
`.etr24_*`, `.etr26_*`, `.etr27_*`, `.etr28_*`,
and `.etr29_*` with scientific-purpose helper names.
Test-only numbered fixture helper functions are similarly renamed.
The historical R source filenames, test filters, CI job provenance
and `native_implementation_stage` field remain as internal
research audit markers. These are **not** public function names,
and retaining them preserves existing test/review evidence.

There are **no changes to the public name or estimator behavior**
of any previously exposed native function. No compatibility alias
is required because the renames affect private dot-prefixed helpers.

## Three additional Python-free scientific integrations

| Published Python 1.2 public function | Native R public function | Scientific behavior |
|---|---|---|
| `plot_reconstruction_curve` | `etr_plot_reconstruction_curve` | Plot original observed-grid integrated FPCA reconstruction error against retained FPC count, maintaining row order and reported numerical errors |
| `plot_registration` | `etr_plot_registration` | Two-panel original and landmark-registered functional curves, preserving original curve IDs, times and channel values |
| `plot_warping_functions` | `etr_plot_warping_functions` | Plot source time deformation `h(t)` or displacement `h(t)-t` without re-estimating registration |

These visualizations are independent native R implementations
using existing `etr_fpca_reconstruction_curve` and
`etr_register_landmarks` data structures. Their implementation
does **not** invoke Python, perform fresh FPCA fitting, silently
interpolate data, or alter the scientific source units.

The direct published Python 1.2 source oracle evaluates original
Matplotlib reconstruction line coordinates and full time-warp
curves on deliberately matched source geometry. The Python plotting
functions accept pandas DataFrames and Python trajectory/
registration-style objects; the native R equivalents accept
data frames and `etr_landmark_registration` objects. The original
source returns Matplotlib Axes/figure objects whereas R uses base
graphics and invisibly returns numeric data. These cross-language
return-class differences **remain open source-contract blockers**.

## Cumulative frozen source inventory

| Measure | Owner verified before this branch | Authored current branch |
|---|---:|---:|
| Native R function implementations | 197 | **200** |
| Source public Python callable names mapped | 222/380 | **225/380** |
| Unmapped public Python functions | 158 | **155** |
| Public classes/constants untouched | 128 | 128 |
| Hard-blocked known source contract differences | 43 | **46** |
| Targeted numerical fixture candidates | 4 | 4 |
| Fully independently approved complete public Python contracts | **0/508** | **0/508** |

The four targeted source numerical fixture candidates
(`alr_transform`, `inverse_alr`, `score_distance_matrix`,
`functional_trapezoid_weights`) remain incomplete for
independent complete-domain source signoff. A numerical fixture
match is not a signed source approval. See
[review issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).

Owner Stage 29 RStudio tests previously passed **46 native
assertions**, **39 frozen ledger assertions** and **61 direct
published Python 1.2 oracle assertions**. Current branch refactor and
new source plots are authored **but have not been runtime-tested**.
GitHub Actions zero-step job admission remains a separate
infrastructure blocker:
[issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39).

## Owner Windows RStudio tests

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-functional-registration-plots")
testthat::test_local(".",filter="native-stage24-nine-scientific-plots|native-stage26-functional-rqa-recovery|native-stage27-fpca-bootstrap-source|native-stage28-math-contracts-diagnostics|native-stage29-transfer-entropy-visual")
testthat::test_local(".",filter="native-stage22-source-contract-gaps|full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",filter="native-functional-registration-plots"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No merge, release, public API renaming, or fabricated full source
contract approval has been authorized.**
