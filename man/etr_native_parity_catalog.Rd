\name{etr_native_parity_catalog}
\alias{etr_native_parity_catalog}
\title{Audit exact full native-R port coverage against 508 Python public exports}
\description{
Provides a conservative, fully offline inventory of all 508 public
\pkg{eyetrajectoriespy} 1.2.0 symbols (380 functions and 128 other
classes/configurations/constants). Separates existing Python-backed
R wrappers, native R analogues, implemented research candidates and
independently qualified scientific/numerical parity.
}
\usage{
etr_native_parity_catalog(require_complete = FALSE)
}
\arguments{
\item{require_complete}{Logical. Set \code{TRUE} to stop unless every
public Python export has an independently qualified one-to-one native R
equivalent. This intentionally fails during the native-port programme.}
}
\value{
A 508-row data frame with namespace, Python public symbol, R bridge,
native candidate (if any), port status and conservative FALSE qualification
flags. It is a structural progress ledger, not a statistical estimator.
}
\details{
Named native R functions are not considered qualified equivalents merely
because they have similar names. No independent numeric equivalence or
coverage calibration is inferred by this function. Python nonfunction
exports require their own native representation contracts.

\code{etr_native_parity_catalog()} never imports Python and is safe for
Python-free R installations (provided the R package itself is installed).
The existing \code{etpy_catalog()} is the source of frozen Python exports.
}
\examples{
z <- etr_native_parity_catalog()
stopifnot(nrow(z) == 508L)
table(z$status)
\dontrun{
  etr_native_parity_catalog(require_complete = TRUE)
}
}
