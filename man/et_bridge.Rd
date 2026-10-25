\name{et_call}
\alias{et_call}
\alias{et_python}
\alias{et_python_version}
\alias{et_to_r}
\title{Bridge to the Python eyetrajectoriespy API}
\description{Access public Python exports while keeping fitted Python objects intact.}
\usage{
et_python()

et_python_version()

et_call(name, ..., .namespace = c("root", "workflows"), .convert = FALSE)

et_to_r(x)
}
\arguments{
\item{name}{Single public exported callable name.}
\item{...}{Arguments passed to the Python callable.}
\item{.namespace}{Python export namespace: \code{"root"} or \code{"workflows"}.}
\item{.convert}{Convert returned Python objects to R, where supported.}
\item{x}{A Python object to convert explicitly.}
}
\value{
\code{et_python()} returns a Python module object;
\code{et_python_version()} returns a version string;
\code{et_call()} returns the Python result unless \code{.convert = TRUE};
\code{et_to_r()} requests reticulate conversion.
}
\details{
Only names in the selected Python module's \code{__all__} are accepted.
Python objects that are not representable as ordinary R objects remain
Python proxies. Loading the R package does not initialize Python.
}
\examples{
\dontrun{
library(eyetrajectories)
et_python_version()
et_call("simulate_planar_trajectories", n_participants = 4L,
        trials_per_participant = 2L, random_state = 7L)
}
}
