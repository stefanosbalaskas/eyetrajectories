\name{etr_capture_environment}
\alias{etr_capture_environment}
\title{Capture a native R scientific reproducibility environment}
\usage{
etr_capture_environment()
}
\value{
Named schema-versioned reproducibility record describing the R runtime,
platform, installed R package versions and numerical-thread settings.
}
\description{
Captures a native R reproducibility environment without requiring Python.
The analogous Python 1.2.0 source function records a Python interpreter and
Python dependency versions instead. This is an explicitly unresolved
cross-language source-contract difference, not a certified one-to-one port.
}
