# Python 1.2 bridge

The R package exposes optional interoperability with the published
[eyetrajectoriespy
1.2.0](https://pypi.org/project/eyetrajectoriespy/1.2.0/) backend
through reticulate. These interfaces are distinct from the Python-free
native R implementation.

## Configure the Python environment

Select the Python interpreter **before** importing the bridge.

``` r
# Install eyetrajectoriespy==1.2.0 into your chosen Python environment
# using that interpreter's pip, then restart R.
Sys.setenv(
  RETICULATE_PYTHON = "path/to/your/python"
)

library(eyetrajectories)
et_python_version()
```

Use a real absolute Python interpreter path for your operating system,
with the pinned Python package already installed. Python installation
and environment selection are separate steps; the above placeholder is
not an executable interpreter path.

## Documented bridge example

``` r
library(eyetrajectories)

# Synthetic observations only; not real participant data.
gaze <- et_simulate_planar(
  n_participants = 5L,
  trials_per_participant = 2L,
  random_state = 7L
)

fit <- et_fit_mfpca(gaze, scaling = "dimension_sd")
head(et_scores(fit))
et_explained_variance(fit)
```

The returned fit is backed by Python. R helpers can extract selected
outputs, but this does not make the Python algorithm a native R
implementation.

## Compatibility is not equivalence

A mapping from an R wrapper to a Python callable documents interface
availability. It does not by itself verify identical boundary behavior,
numeric output, estimator assumptions, uncertainty, statistical coverage
or scientific interpretation. Check
[Validation](https://stefanosbalaskas.github.io/eyetrajectories/SITE_VALIDATION.md)
and the native-method documentation for distinct implementations.

For authoritative Python API details see the [Python package
documentation](https://stefanosbalaskas.github.io/eyetrajectoriespy/).
