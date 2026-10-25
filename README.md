# eyetrajectories

## Full CRAN-style checks and examples

The pre-submission local test runner is
[scripts/run_cran_qualification.R](scripts/run_cran_qualification.R):

~~~r
source("scripts/run_cran_qualification.R")
~~~

It performs source-build `R CMD check --as-cran` including the PDF manual
(requires a working TeX installation), exercises the package Rd examples
and test suite, and runs a separate native example that creates numerical
outputs and a three-figure PDF. Generated qualification reports go to a
timestamped directory beside the repository rather than into the package.
For the standalone example, PDF and CSV outputs are now saved in
`artifacts/cran_native_example/` under the project root.
The CRAN-facing stage disables opt-in Python tests and is offline-safe;
Python integrations are tested separately. See
[the qualification runbook](docs/cran-qualification-runbook.md).

***
## Complete Python-backed function API — 380 explicit R wrappers

**Development version 0.4.0.9000 (private; unreleased).** The
eyetrajectoriespy GitHub main snapshot on 25 October 2026 defines 362
root public functions and 18 module-scoped workflow functions.
All **380 Python callables** now have named R wrappers:

- `etpy_fit_fpca(...)` and the other 361 `etpy_*` root wrappers
- `etpy_workflow_run_fpca_workflow(...)` and 17 other workflow wrappers
- `etpy_catalog()` gives the exact 380-function manifest without initializing Python
- `etpy_catalog(include_nonfunctions = TRUE)` catalogs 508 symbols:
  458 root and 50 workflow exports; 128 are classes or constants
- `etpy_verify_api(strict = TRUE)` verifies that your installed Python
  distribution actually provides every recorded callable
- `etpy_get_export("FPCAWorkflowConfig", .namespace = "workflows")`
  retrieves an exported Python class or constant without invoking it

~~~r
library(eyetrajectories)
nrow(etpy_catalog())  # 380 recorded root + workflow functions
gaze <- etpy_simulate_planar_trajectories(
  n_participants = 6L, trials_per_participant = 2L,
  n_time = 41L, random_state = 7L
)
fit <- etpy_fit_mfpca(gaze, n_components = 0.95,
                      scaling = "dimension_sd")
head(et_to_r(etpy_fpca_score_frame(fit)))
etpy_verify_api(strict = TRUE)
~~~

**Scientific scope:** The new 380 functions are thin Python-backed wrappers,
not 380 independently implemented R estimators. The existing 88 native
`etr_*` functions remain available without Python. The named wrappers
require `reticulate` and the declared `eyetrajectoriespy==1.2.0` runtime;
a GitHub source snapshot may differ from the installed PyPI artifact.
Scientific assumptions, optional Python dependencies, and experimental
uncertainty/calibration limitations are inherited from the Python backend.

**Local qualification, 25 October 2026: PASS (user-executed).**
On Windows 11 / R 4.6.1, development version **0.4.0.9000** passed
`testthat` and `R CMD check --no-manual` with **0 errors, 0 warnings,
0 notes**, with opt-in Python bridge and generated-wrapper integration
tests enabled (`ET_RUN_PYTHON_TESTS=true`, `MPLBACKEND=Agg`).
A separate strict installed-runtime census confirmed **380/380**
recorded Python functions were exported and callable. This does **not**
mean every Python function was individually exercised or scientifically
validated. Linux/macOS checks remain pending; GitHub-hosted runners are
still blocked before allocation for this private repository.
[Qualification evidence and open risks](docs/phase3-qualification-status.md).

**Independent known-truth coverage grid:** 100 studies per design
at 12, 24, 48 independent participants had group-contrast simultaneous
coverage 65%, 79%, 84% and participant-mean coverage 63%, 89%, 86%
at a 90% nominal target, with no fit failures. These results do not
qualify the experimental uncertainty procedures; see
[coverage-grid evidence](docs/phase3-coverage-grid-2026-10-25.md).

Source inventory: `inst/extdata/python_api_2026-10-25.csv`.
Call documentation: `?etpy_python_functions`.

***
## Native R scientific core — expanded Phase 3

**Current development version 0.4.0.9000, private / unreleased.** The native R core exposes **88 native R
functions**: 38 Phase 2 core functions and 50 experimental Phase 3 advanced
methods. Native functions do not initialize Python, although sparse PACE requires
the optional R package fdapace.
The Phase 1 Python bridge remains available under the original et_* interface
for methods not yet ported.

**Current qualification:** [Evidence matrix and remaining work](docs/phase3-qualification-status.md). The local Windows 11 / R 4.6.1 suite passed for 0.4.0.9000, including the 380-function API census and opt-in Python integration tests. Hosted GitHub Actions remains unavailable before runner allocation.

### Advanced R methods (experimental)

The new Phase 3 functions add: fdapace-backed univariate sparse PACE,
two-level descriptive participant/trial FPCA, participant-cluster bootstrap
mean bands, plug-in discrete transfer entropy with circular-shift sensitivity
diagnostics, auditable workflow wrappers and known-truth simulation audits.

~~~r
library(eyetrajectories)
sim <- etr_simulate_hierarchical(n_subjects = 20L, seed = 12L)
multi <- etr_run_multilevel_workflow(sim$trajectories, sim$participant)
print(multi$diagnostics$variances)

bands <- etr_run_mean_band_workflow(sim$trajectories, sim$participant,
                                    B = 199L, alpha = 0.10, seed = 99L)
print(bands$diagnostics)

# Independent synthetic recovery and coverage diagnostics (not validation claims):
coverage <- etr_evaluate_mean_band_coverage(simulations = 10L, B = 99L)
print(coverage$simultaneous_coverage)
~~~

Univariate sparse PACE requires an optional R dependency:

~~~r
install.packages("fdapace")
sparse <- etr_simulate_sparse_known_truth(n_subjects = 45L, seed = 5L)
fit_sparse <- etr_fit_sparse_pace(sparse$curves, max_components = 2L)
head(etr_sparse_pace_scores(fit_sparse))
~~~

The expanded toolkit also includes **participant-stratified treatment contrasts**,
**independently simulated coverage diagnostics**, **participant-grouped FPCA
cross-validation** (rebuilding the PCA on each training fold), marginal sparse
PACE support diagnostics, an optional `refund::pffr` functional mixed-effects
adapter, and explicit transfer-entropy bias/null diagnostics and plots.
All are experimentally scoped rather than qualified inference.

Read the [Phase 3 scientific qualification note](docs/phase3-scientific-qualification.md)
and the [expansion methods article](docs/phase3-expansion-methods.md).
These estimators do **not** yet establish generalized inference calibration,
causal direction, or full Python API parity. Hosted CI remains blocked before runner allocation; local RStudio checks of version 0.4.0.9000 passed.

### Native R quick start (no Python)

~~~r
library(eyetrajectories)

time <- seq(0, 1, length.out = 81)
values <- array(0, c(8, length(time), 2))
for (i in seq_len(8)) {
  values[i, , 1] <- sin(2 * pi * time + i / 10)
  values[i, , 2] <- cos(2 * pi * time + i / 10)
}
gaze <- etr_trajectory_set(
  time, values, curve_ids = paste0("trial_", seq_len(8)),
  dimension_names = c("x", "y"),
  coordinate_system = "normalized", time_unit = "s"
)
fit <- etr_fit_mfpca(gaze, n_components = 0.95,
                     scaling = "dimension_sd")
print(etr_fpca_variance_frame(fit))
print(head(etr_fpca_scores(fit)))
print(etr_pairwise_l2(gaze))
rqa <- etr_rqa_metrics(
  etr_recurrence_matrix(gaze, curve = "trial_1",
                        radius = 0.15, theiler = 2L)
)
print(rqa)
etr_plot_trajectories(gaze)
~~~

The example uses only deterministic synthetic mathematical trajectories.
For reproducible PDF figures, see
[the native Phase 2 example](inst/examples/native_phase2_demo.R)
and the [native methods article](docs/native-methods.md).

**Qualification notice:** This is a draft implementation, not an independently
validated scientific release. The R tests assert 17 frozen mathematical
reference targets, and CI is configured to verify them against published
Python 1.2.0. The original native numerical fixtures passed locally on Windows; cross-platform verification remains outstanding. No calibrated
uncertainty inference or native sparse FPCA is claimed.

***


**Optional experimental R interface to [eyetrajectoriespy 1.2.0](https://github.com/stefanosbalaskas/eyetrajectoriespy)** for continuous and functional analysis of eye-tracking trajectories.

**Phase 1 history:** The optional `et_*` interface still delegates to the published Python 1.2.0 backend; the new `etr_*` interface is independently implemented native R. Neither interface has completed full cross-platform or scientific release qualification.

## Python-backed Phase 1 interface (optional)

- Declare Python 3.11–3.13 and eyetrajectoriespy 1.2.0 using reticulate::py_require().
- Import common-grid gaze data from R data frames without hidden interpolation.
- Simulate reproducible planar gaze trajectories using the Python backend.
- Fit FPCA and MFPCA, extract score tables and explained variance into R.
- Run the published typed Python common-grid FPCA workflow.
- Create matplotlib trajectory/variance figures and save them as PNG or PDF.
- Reach other Python public exports through et_call(), without implying that they have dedicated R interface tests.

Loading the R package **does not initialize Python**. The first bridge function does.

## Installation (authenticated private repository)

Using an authenticated GitHub client, for example pak:

~~~r
install.packages("pak")
pak::pak("stefanosbalaskas/eyetrajectories")
library(eyetrajectories)
~~~

If reticulate manages Python, the declared Python requirement may be downloaded when first needed. For a manually managed Python environment, install the matching Python package first:

~~~sh
python -m pip install "eyetrajectoriespy==1.2.0"
~~~

Select your existing interpreter **before** Python is initialized in the R session (e.g. set RETICULATE_PYTHON to the full path of that interpreter before starting R). See the official [reticulate package guidance](https://rstudio.github.io/reticulate/articles/package.html).

## Quick start: synthetic gaze, MFPCA, scores

~~~r
library(eyetrajectories)

# Synthetic examples only, not human-subject observations.
gaze <- et_simulate_planar(
  n_participants = 20L,
  trials_per_participant = 6L,
  random_state = 7L
)

fit <- et_fit_mfpca(
  gaze, n_components = 0.95, scaling = "dimension_sd"
)

head(et_scores(fit))
et_explained_variance(fit)
et_explained_variance(fit, cumulative = TRUE)

ax <- et_plot_planar(gaze, max_curves = 20L)
et_save_plot(ax, "synthetic-gaze.png")
~~~

## R data frame to Python trajectories

~~~r
gaze_long <- data.frame(
  participant = rep(c("p1", "p2"), each = 8L),
  time = rep(seq(0, 1, length.out = 8L), times = 2L)
)
gaze_long$x <- gaze_long$time + as.numeric(gaze_long$participant == "p2")
gaze_long$y <- gaze_long$time^2

gaze <- et_from_long(
  gaze_long,
  curve_columns = "participant",
  time_column = "time",
  value_columns = c("x", "y"),
  coordinate_system = "normalized",
  time_unit = "s"
)
fit <- et_fit_mfpca(gaze, n_components = 1L)
head(et_scores(fit))
~~~

Every trajectory must share a common time grid; duplicate timestamps and hidden interpolation are intentionally not accepted. Missingness, preprocessing, and coordinate semantics require deliberate treatment upstream.

## Declared Python workflow

~~~r
gaze <- et_simulate_planar(random_state = 7L)
run <- et_run_fpca_workflow(gaze, scaling = "dimension_sd")
head(et_scores(run$fit))
~~~

Other public Python functions and workflow constructors remain accessible using:

~~~r
et_call("fit_fpca", gaze, n_components = 0.95)
# Advanced workflows are module-scoped:
et_call("FPCAWorkflowConfig", n_components = 0.95,
        .namespace = "workflows")
~~~

The default is to retain Python objects as Python proxies. Convert supported results explicitly with et_to_r().

## Check and integration tests

~~~sh
R CMD build .
R CMD check --as-cran eyetrajectories_0.4.0.9000.tar.gz
~~~

R-only tests do not need an installed Python backend. Real bridge integration tests are opt-in:

~~~sh
ET_RUN_PYTHON_TESTS=true Rscript -e 'testthat::test_local(".", filter = "python-integration")'
~~~

The integration environment must already have Python 3.11–3.13 and eyetrajectoriespy 1.2.0, or allow reticulate to resolve the managed environment. GitHub Actions defines separate R-only checks and real Python integration tests.

## Scientific scope and roadmap

The Python implementation is the numerical source of truth during Phase 1. Interface parity with Python does **not** establish independent R implementation, estimator calibration, or scientific validity. Existing Python research limitations, particularly for W3 inference calibration and observation-dependent missing gaze, remain in force.

See [Phase 1 design and boundaries](docs/phase1-scope.md). Planned Phase 2 work is a separately validated native R core; no CRAN release is authorized by this development branch.

Copyright (c) 2026 Stefanos Balaskas. MIT License.
