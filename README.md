# eyetrajectories

**Experimental R interface to [eyetrajectoriespy 1.2.0](https://github.com/stefanosbalaskas/eyetrajectoriespy)** for continuous and functional analysis of eye-tracking trajectories.

**Status:** Phase 1 development (version 0.1.0.9000). Private repository, not on CRAN. This package provides an R-to-Python bridge, **not** an independently implemented or validated R numerical backend.

## What this first version provides

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
