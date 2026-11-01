\name{etr_frozen_workflow_schema}
\alias{etr_frozen_workflow_schema}
\alias{etr_frozen_workflow_record}
\alias{etr_native_workflow_result_view}
\title{Source-backed native R record schemas for 28 Python 1.2 workflow dataclasses}
\description{
A Python-free, frozen-source description of 28 public Python workflow
dataclasses and their 303 ordered declared fields. Native record containers
preserve field names and values but do not reproduce Python's constructors,
defaults, validation, immutability, scientific estimators, or result formats.
They are not independent full-domain source parity certifications.
}
\usage{
etr_frozen_workflow_schema(class_name = NULL)
etr_frozen_workflow_record(class_name, fields)
etr_native_workflow_result_view(result)
}
\arguments{
\item{class_name}{One of the 28 frozen Python 1.2 public workflow dataclass names,
or NULL when listing all source schemas.}
\item{fields}{Uniquely named native R list supplying every declared source
field explicitly, including fields with Python defaults. Entries may be NULL.}
\item{result}{A native \code{etr_fpca_workflow} or
\code{etr_function_on_scalar_workflow} result already fitted in R.}
}
\value{
\code{etr_frozen_workflow_schema()} returns the source-pinned field schema
as a data frame. \code{etr_frozen_workflow_record()} returns a native
\code{etr_frozen_workflow_record} S3 list in Python declaration field order,
with explicit FALSE flags for source scientific and independent certification.
\code{etr_native_workflow_result_view()} returns a field-ordered read-only
conceptual view (not an immutable R object) of an existing native workflow.
}
\details{
The manifest records Python annotations and default expressions as inert
strings; it never evaluates Python source, runs external software, or
automatically executes a workflow. Required-field and default semantics
are descriptive only. The class source commit is
\code{c1cd95ad718327550f7e55393ff38582872f7a94}.
}
\examples{
schema <- etr_frozen_workflow_schema("ScoreUncertaintyConfig")
record <- etr_frozen_workflow_record("ScoreUncertaintyConfig",
  list(condition_limit = NULL, failure_action = "error"))
stopifnot(identical(names(record), schema$field_name))
}
