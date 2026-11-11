\name{etr_read_python_portable_result}
\alias{etr_read_python_portable_result}
\title{Read a published Python 1.2 scientific-result JSON and NPZ snapshot in native R}
\description{
Reads \pkg{eyetrajectoriespy} 1.2.0
\code{export_portable_result()} bundles in R without executing Python.
Validates the schema, SHA-256 checksum and NumPy archive entries, then
reconstructs the supported safe scientific arrays, tables, mappings and
dataclass-field snapshots. This is an explicitly limited native
\emph{reader}; it does not claim a complete replacement for Python's
\code{load_portable_result()} or serve as a Python-format writer.
}
\usage{
etr_read_python_portable_result(directory,
  max_array_bytes = 64 * 1024^2,
  max_total_bytes = 128 * 1024^2)
}
\arguments{
\item{directory}{Directory containing the published Python v1
\code{manifest.json} and \code{arrays.npz} files.}
\item{max_array_bytes}{Finite positive byte cap (at least 1024 and
at most 1 GiB) for each decoded numeric/Unicode array. Defaults to
64 MiB.}
\item{max_total_bytes}{Finite positive byte cap on the total advertised
uncompressed archive entries. Defaults to 128 MiB.}
}
\value{
An \code{etr_python_portable_snapshot} R list with \code{result_type},
\code{source_package_version}, \code{payload},
\code{units}, \code{environment},
\code{nonportable_fields}, \code{arrays_sha256},
\code{archive_keys} and the original \code{manifest}.

Python dataclasses become R named lists with a
\code{__python_type__} field, not executable or refitted objects.
Python tuples become lists of class \code{etr_python_tuple}.
Native R data.frames may carry an additional \code{python_index}
attribute. R \code{NA}/\code{NaN} values are preserved in decoded arrays.
}
\details{
This function has no Python dependency. Only the optional R packages
\pkg{jsonlite} and \pkg{digest} are needed at call time.
The checksum verifies \code{arrays.npz} before parsing; the Python
manifest itself is not cryptographically signed. Provenance/source
authenticity is not thereby established.

The loader accepts the published version-one Python format with the
exact \code{arrays.npz} filename, including array-free snapshots, and
bounds uncompressed size.
It reads safe NumPy NPY v1-v3 little-endian binary arrays using a
typed subset of floating, integer, bool and UTF-32 Unicode
descriptors, and primitive homogeneous JSON-backed object arrays. JSON
nulls become missing values of the observed type. If every cell is null,
the snapshot carries logical missing values because the source has no
element type information.
Signed and unsigned 64-bit integers must be within the inclusive exact
integer range of base R doubles. Embedded NUL characters in Unicode
arrays are rejected because R strings cannot represent them.
Pickling or backend execution is never attempted. Unsupported dtypes,
heterogeneous object arrays, irregular table schemas and unknown
markers fail closed instead of silently discarding scientific state.

It is \emph{read-only}; the Stage 5 native R snapshot format is
different and is not exchanged through this function. The published
Python portable writer stores backend-native objects as explicit
\code{nonportable} markers and its loader does not reconstruct fitted
estimator objects. Equivalent native-R fitted-estimator reconstruction
is not offered here.

The reader imposes explicit byte caps, dtype restrictions and
representation limitations not imposed identically by upstream
Python. It is therefore an independently implemented
\emph{partial public function candidate}, not proof of exact
one-to-one general contract equivalence or scientific inference
qualification.
}
\examples{
\dontrun{
# Requires a previously exported trusted Python 1.2 portable bundle:
snapshot <- etr_read_python_portable_result("path/to/portable_export")
str(snapshot$payload)
}
}
