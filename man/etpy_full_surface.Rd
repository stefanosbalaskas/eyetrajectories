\name{etpy_full_surface}
\alias{etpy_full_surface}
\alias{etpy_invoke}
\alias{etpy_attribute}
\alias{etpy_method}
\alias{etpy_signature}
\alias{etpy_full_verify}
\alias{etpy_enable_extras}
\alias{print.etpy_full_surface}
\title{Complete Python 1.2 public capability surface from R}
\description{
Exposes the frozen 508-symbol Python 1.2.0 public API (458 root and
50 workflow symbols) through lazy, read-only R namespace environments,
including 380 named Python function entry points and 128 additional
public classes and constants. Python is optional until a function or
public symbol is accessed; these are Python-backed operations, not
508 native R implementations.
}
\usage{
etpy_full_surface(.convert = FALSE, .verify = FALSE)

etpy_invoke(name, ..., .namespace = c("root", "workflows"),
            .convert = FALSE)

etpy_attribute(object, name, .convert = FALSE)

etpy_method(object, name, ..., .convert = FALSE)

etpy_signature(name, .namespace = c("root", "workflows"))

etpy_full_verify(strict = TRUE)

etpy_enable_extras(extra = c("all", "fda", "sparse", "elastic"))

\method{print}{etpy_full_surface}(x, ...)
}
\arguments{
\item{.convert}{Logical; convert Python results into R objects. Defaults to
FALSE to retain fitted model objects and support chained Python methods.}
\item{.verify}{Logical; eagerly inspect 508 exports and their 1.2.0 version
before creating the R environments.}
\item{name}{Single public exported symbol or method/attribute name.}
\item{...}{Arguments forwarded to Python, or unused print arguments.}
\item{.namespace}{Public Python root or workflows module.}
\item{object}{Unconverted Python model, result, configuration or other proxy.}
\item{extra}{Published Python 1.2.0 optional backend selection: \code{fda},
\code{sparse}, \code{elastic}, or \code{all}. The sparse extra is
only declared on Python 3.11--3.12 when Python has not already started.}
\item{strict}{Logical; fail if a recorded public symbol is missing,
a recorded function is noncallable, or the installed Python distribution
is not exactly 1.2.0.}
\item{x}{An \code{etpy_full_surface} object to print.}
}
\value{
\code{etpy_full_surface()} returns a list of two read-only R namespace
environments and a static export catalog. \code{etpy_invoke()} and
\code{etpy_method()} return the Python result (optionally converted);
\code{etpy_attribute()} returns a public Python attribute.
\code{etpy_signature()} returns a Python callable signature or \code{NA}.
\code{etpy_full_verify()} returns a 508-row structural contract report.
\code{etpy_enable_extras()} invisibly returns the pinned Python requirement.
}
\details{
The existing \code{etpy_*} and \code{etpy_workflow_*} named wrappers
remain available. This surface adds discoverable Python-style namespaces,
constructor calls for public Python classes, and explicit method/attribute
access without requiring new one-by-one R wrappers for class members.
The Python 1.2.0 distribution and its required/optional dependencies
must be installed or resolvable by \pkg{reticulate}. Optional numerical
and plotting backends can have separate version/platform constraints.

Structural symbol parity is distinct from actually executing every
public function, numerical equivalence of independent native-R
algorithms, or inferential/scientific qualification. Unresolved
simultaneous-coverage and missing-data identification boundaries in the
Python backend apply unchanged to Python-backed R calls.
}
\examples{
# Does not initialize Python:
surface <- etpy_full_surface()
names(surface)
length(ls(surface$root))
length(ls(surface$workflows))

\dontrun{
# For optional Python backends, call before first Python import:
# etpy_enable_extras("all")
# Requires Python 3.11--3.13 and eyetrajectoriespy==1.2.0:
report <- etpy_full_verify()
curves <- surface$root$simulate_planar_trajectories(
  n_participants = 4L, trials_per_participant = 2L,
  n_time = 31L, random_state = 2026L
)
fit <- surface$root$fit_mfpca(curves, n_components = 1L)
frame <- surface$root$fpca_score_frame(fit, .convert = TRUE)
config <- surface$workflows$FPCAWorkflowConfig(n_components = 1L)
result <- etpy_invoke("run_fpca_workflow", curves,
                      config = config, .namespace = "workflows")
}
}
