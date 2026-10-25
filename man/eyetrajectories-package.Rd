\name{eyetrajectories-package}
\alias{eyetrajectories}
\alias{eyetrajectories-package}
\docType{package}
\title{R Interface to Continuous Eye-Tracking Trajectory Analysis}
\description{
An experimental interface to the Python package \pkg{eyetrajectoriespy}
(version 1.2.0) for functional and continuous gaze analysis. Phase 1 is a
Python-backed bridge, not an independent R implementation.
}
\details{
Package load declares Python dependencies with
\code{reticulate::py_require()}, but does not initialize Python, download
models, or install Python packages. The first bridge call may initialize
the Python environment. Scientific limitations of the Python backend
continue to apply.
}
\seealso{\code{\link{et_python}}, \code{\link{et_from_long}},
\code{\link{et_fit_mfpca}}}
