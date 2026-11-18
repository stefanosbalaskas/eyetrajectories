# R Interface to Continuous Eye-Tracking Trajectory Analysis

An experimental interface to the Python package eyetrajectoriespy
(version 1.2.0) for functional and continuous gaze analysis. Phase 1 is
a Python-backed bridge, not an independent R implementation.

## Details

Package load declares Python dependencies with
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html),
but does not initialize Python, download models, or install Python
packages. The first bridge call may initialize the Python environment.
Scientific limitations of the Python backend continue to apply.

## See also

[`et_python`](https://stefanosbalaskas.github.io/eyetrajectories/reference/et_bridge.md),
[`et_from_long`](https://stefanosbalaskas.github.io/eyetrajectories/reference/et_input.md),
[`et_fit_mfpca`](https://stefanosbalaskas.github.io/eyetrajectories/reference/et_fpca.md)
