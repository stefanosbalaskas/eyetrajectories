# eyetrajectories

## Native R scientific core — expanded Phase 3

**Version 0.3.2.9000, private / unreleased.** The package now exposes **88 native R
functions**: 38 Phase 2 core functions and 50 experimental Phase 3 advanced
methods. Native functions do not initialize Python, although sparse PACE requires
the optional R package fdapace.
The Phase 1 Python bridge remains available under the original et_* interface
for methods not yet ported.

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
causal direction, or full Python API parity. CI remains blocked upstream of
test execution; the source is merged to main at the owner's instruction.

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
Python 1.2.0. Both checks remain **unverified** because CI jobs have not
executed successfully. No calibrated
uncertainty inference or native sparse FPCA is claimed.

---


**Optional experimental R interface to [eyetrajectoriespy 1.2.0](https://github.com/stefanosbalaskas/eyetrajectoriespy)** for continuous and functional analysis of eye-tracking trajectories.

**Phase 1 history:** The optional `et_*` interface still delegates to the published Python 1.2.0 backend; the new `etr_*` interface is independently implemented native R. Neither interface has yet completed release qualification.

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
R CMD check eyetrajectories_0.1.0.9000.tar.gz
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
