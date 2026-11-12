\name{etr_capture_environment}
\alias{etr_capture_environment}
\title{Capture native R scientific reproducibility with optional frozen Python source attestation}
\usage{
etr_capture_environment(strict_source_record = FALSE,
  python_source_snapshot = NULL)
}
\arguments{
\item{strict_source_record}{FALSE (default) preserves the original native
R environment record. TRUE builds a source-scientific
R-versus-Python reproducibility schema crosswalk without importing or
running a Python interpreter.}
\item{python_source_snapshot}{Optional genuine independently captured
Python 1.2 \code{eyetrajectoriespy.capture_environment()} record. It
must match the eight version-one frozen source fields and all nested
interpreter, platform, dependency, optional backend and thread names
exactly. A source snapshot is never fabricated and is accepted only
when \code{strict_source_record=TRUE}.}
}
\value{
By default a named, version-one native R runtime and installed R package
reproducibility record. Under strict source mode a
\code{etr_native_environment_scientific_record} with separately measured
native R facts, the exact frozen Python 1.2 environment schema
crosswalk, an optional validated externally captured Python source
environment, and explicit full-source difference/certification flags.
}
\description{
Scientific reproducibility environment capture using actual R interpreter,
platform, package version and numerical thread settings. This is a
native-R source-scientific purpose analogue of the frozen Python 1.2
\code{capture_environment} export, not a Python interpreter capture,
not a Python package distribution inventory and not a Python-native
backend object. Optional genuine Python source environment records
can be validated and paired for auditing without invoking Python.
The default return shape remains unchanged.
}
\details{
The frozen Python capture reports interpreter version, implementation,
executable, operating system/platform, package and Git commit, versions
of six Python dependencies and three optional backend packages, UTC time
and four numerical thread environment variables. Native R records
corresponding actual R runtime, OS and R dependency facts. Source
Python dependency versions remain unknown to the native R capture
unless a genuine external Python source snapshot is provided.
No full Python-runtime source parity or independent scientific source
certification is claimed. See
\code{docs/native-reproducibility-source-environment-20261112.md}.
}
