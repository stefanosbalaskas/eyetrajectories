\name{etr_frozen_workflow_values}
\alias{etr_frozen_workflow_values}
\title{Frozen Python 1.2 workflow source scalar values}
\description{
Return native R copies of three public scalar values defined by frozen
\pkg{eyetrajectoriespy} 1.2.0 \code{workflows/_core.py}.
The values document Python source metadata; they are not claims of native
bundle-format interoperability or full scientific source equivalence.
}
\usage{
etr_frozen_workflow_values()
}
\value{
A named R list with two integer scalars,
\code{WORKFLOW_SCHEMA_VERSION} and
\code{WORKFLOW_BUNDLE_SCHEMA_VERSION}, and one character scalar,
\code{WORKFLOW_BUNDLE_FORMAT}.
}
\details{
The Python workflow bundle format string is
\code{eyetrajectoriespy-workflow-bundle}. Native R workflow bundles
use a different format. All source-object full-domain certification
decisions remain independent and unapproved.
}
\examples{
values <- etr_frozen_workflow_values()
stopifnot(identical(values$WORKFLOW_SCHEMA_VERSION, 1L))
}
