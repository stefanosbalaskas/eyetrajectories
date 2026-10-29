\name{etr_native_trajectory_provenance}
\alias{etr_trajectory_provenance}
\alias{etr_with_values}
\alias{etr_trajectory_snapshot}
\alias{etr_restore_trajectory_snapshot}
\title{Native R provenance-preserving trajectories and versioned snapshots}
\description{
Python-independent handling of \code{TrajectorySet}-like scientific
provenance, nonmutating transformations and native R snapshot restore.
The source of the \code{with_values} semantics is the published Python
\pkg{eyetrajectoriespy} 1.2.0 \code{types.py} definition. Native R snapshots
are not Python portable-scientific-result JSON and NPZ bundles.
}
\usage{
etr_trajectory_provenance(x)

etr_with_values(x, values = x$values, time = NULL,
                provenance_update = NULL, time_unit = NULL,
                coordinate_system = NULL)

etr_trajectory_snapshot(x)

etr_restore_trajectory_snapshot(snapshot)
}
\arguments{
\item{x}{A native R \code{etr_trajectory_set}, including objects created
before the provenance field was added.}
\item{values}{A numeric three-dimensional trajectory array with compatible
curve/time/channel shape. Explicit R \code{NA_real_} means missing gaze.}
\item{time}{Optional strictly increasing finite time vector. NULL retains
the original grid.}
\item{provenance_update}{Optional JSON-like named R list with unique,
nonempty keys. Updated top-level keys replace existing entries; unlike
\code{utils::modifyList}, nested dictionaries are not recursively merged.}
\item{time_unit,coordinate_system}{Optional single nonempty character
scalars; NULL retains the corresponding existing unit.}
\item{snapshot}{A version-one \code{etr_trajectory_snapshot} list.
Only use untrusted serialized files after separate input-security review.}
}
\value{
\code{etr_trajectory_provenance()} returns an independent JSON-like named
list, with an empty list for legacy native trajectory objects.

\code{etr_with_values()} returns a new native R trajectory collection
without modifying \code{x}; existing curve IDs, channel names and
one-row-per-curve metadata are retained.

\code{etr_trajectory_snapshot()} returns an
\code{etr_trajectory_snapshot} S3 list with the exact R numeric array,
time vector, IDs, metadata and factors, coordinate/time units, provenance,
format label, schema version and array shape.

\code{etr_restore_trajectory_snapshot()} validates the snapshot and
reconstructs a native \code{etr_trajectory_set}.
}
\details{
The \code{etr_trajectory_set()} constructor now accepts optional
\code{provenance=list()} as the last formal argument, preserving every
older positional argument. \code{etr_validate()} checks provenance,
\code{etr_subset()} retains it and \code{etr_from_long()} appends source
audit defaults. Stage 3 normalization/centering operations preserve
earlier provenance and append documented Python preprocessing keys.

Python's \code{TrajectorySet} is a frozen dataclass, whose
\code{with_values()} method uses a shallow top-level dictionary update.
This R-native implementation follows those audit semantics without
reticulate. For some unrelated older native R transforms, provenance
retention is not yet fully implemented or verified.

A native snapshot can be saved with \code{saveRDS()} and read back
with \code{readRDS()}; it is meant for trusted native R environments.
It is NOT the cross-language, audited \code{eyetrajectoriespy}
\code{export_portable_result()} scientific-result schema, which stores
JSON and NPZ and has different manifest/array hash requirements.
Do not imply compatible Python loading, cryptographic verification,
execution sandboxing, or full public API parity.
}
\examples{
time <- c(0,.2,1,2)
values <- array(1:16,c(2,4,2))
x <- etr_trajectory_set(time,values,curve_ids=c("A","B"),
                        dimension_names=c("x","y"),
                        provenance=list(source="recording"))
y <- etr_with_values(x,values=values+1,
                     provenance_update=list(preprocessing="offset"))
stopifnot(identical(y$provenance$source,"recording"))
snapshot <- etr_trajectory_snapshot(y)
restored <- etr_restore_trajectory_snapshot(snapshot)
stopifnot(identical(restored,y))
}
