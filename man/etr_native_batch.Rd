\name{etr_native_batch}
\alias{etr_validate_common_grid}
\alias{etr_validate_simplex}
\alias{etr_validate_no_long_missing_runs}
\alias{etr_irregular_trajectory_set}
\alias{etr_from_irregular_long_native}
\alias{etr_common_overlap_interval}
\alias{etr_make_common_grid}
\alias{etr_resample_irregular_to_grid}
\alias{etr_resample_irregular_to_common_grid}
\alias{etr_irregular_sampling_summary}
\alias{etr_phase_landmark_frame}
\title{Native R batched scientific validation and irregular functional trajectory contracts}
\description{
Independent Python-free R implementations of ten public functions from
the published \pkg{eyetrajectoriespy} 1.2.0 \code{validation.py},
\code{irregular.py} and \code{phase.py} source modules. Also defines
an explicit R native irregular-trajectory representation.
}
\usage{
etr_validate_common_grid(x)
etr_validate_simplex(values, atol = 1e-7,
  python_boundary_mode = FALSE)
etr_validate_no_long_missing_runs(x, max_missing_fraction)
etr_irregular_trajectory_set(time, values, curve_ids, dimension_names,
  metadata = NULL, coordinate_system = "unknown",
  time_unit = "unknown", provenance = list(), allow_infinite_values = FALSE)
etr_from_irregular_long_native(data, curve_columns, time_column,
  value_columns = c("x", "y"), metadata_columns = NULL,
  coordinate_system = "unknown", time_unit = "unknown",
  provenance = NULL)
etr_common_overlap_interval(x)
etr_make_common_grid(x, n_time, domain = "overlap",
  start = NULL, end = NULL)
etr_resample_irregular_to_grid(x, grid, method = "linear",
  max_gap = NULL)
etr_resample_irregular_to_common_grid(x, n_time, domain = "overlap",
  method = "linear", max_gap = NULL)
etr_irregular_sampling_summary(x)
etr_phase_landmark_frame(registration)
}
\arguments{
\item{x}{Native common-grid trajectory collection for validators;
for irregular operations, an \code{etr_irregular_trajectory_set}.}
\item{values}{A numeric three-dimensional simplex array for validation;
a list of curve-specific sample-by-channel matrices for construction.}
\item{atol}{Finite nonnegative absolute sum and negativity tolerance.
NumPy-style sum comparison additionally applies relative tolerance 1e-5.}
\item{python_boundary_mode}{An explicit opt-in to bounded frozen Python
1.2 coercion for validation: numeric-string or Boolean 3D arrays,
complex NumPy-ndarray-style arrays (real component only), regular 3D
nested scalar lists, and vacuous zero-curve/time validation. The
native default keeps strict numeric-array checks; neither mode
claims complete NumPy object/exception parity.}
\item{max_missing_fraction}{Maximum permitted fraction of time points
with at least one missing functional channel per curve, in [0,1).}
\item{time}{List of finite increasing curve-specific time vectors, each
at least two samples long.}
\item{curve_ids,dimension_names}{Distinct nonempty string identifiers
and channel names.}
\item{metadata}{Optional one-row-per-curve native R data frame.}
\item{coordinate_system,time_unit}{Declared spatial and temporal units.}
\item{provenance}{JSON-like named native R source-audit list.}
\item{allow_infinite_values}{Permit infinite sample values for the source
PACE future-prediction boundary. A target forecast uses only finite history
values and calibration requires a finite observation at each forecast time.}
\item{data}{Long-format data frame; rows are samples.}
\item{curve_columns}{One or more identifier columns.}
\item{time_column}{Numeric curve-specific observation-time column.}
\item{value_columns}{Numeric functional-channel columns.}
\item{metadata_columns}{Optional curve-constant metadata columns.}
\item{n_time}{Integer number of desired common-grid locations, at least two.}
\item{domain}{\code{"overlap"} for common support or \code{"union"}
for the full observed domain.}
\item{start,end}{Optional explicit finite grid endpoints, supplied together.}
\item{grid}{Finite strictly increasing target sample times.}
\item{method}{Currently \code{"linear"} only. Python's \code{"pchip"}
is explicitly rejected rather than silently approximated.}
\item{max_gap}{NULL or finite positive maximum spacing that may be
interpolated. Wider internal gaps remain missing.}
\item{registration}{Named native R registration result with an
\code{original} trajectory collection, numeric matrix
\code{observed_landmarks} and numeric vector
\code{reference_landmarks}.}
}
\value{
The three validation functions invisibly return NULL on success and
raise descriptive errors on failure. The constructor/from-long functions
return \code{etr_irregular_trajectory_set}, retaining independent time
vectors, sample matrices, names, metadata and provenance. The overlap
function returns a length-two numeric vector; the grid builder returns
a numeric sample grid. The two resampling functions return a
\code{etr_trajectory_set} with scientific gap/audit provenance.
The sampling summary and landmark deviation functions return native
R data frames with Python-compatible column names.
}
\details{
Native irregular curves retain missing values and their own observation
times until explicit resampling. No time shifting or extrapolation occurs.
An interval longer than max_gap is masked strictly inside its endpoints.
Python's PCHIP resampling method, pandas metadata index behavior and
full IrregularTrajectorySet dataclass schema are not yet qualified for
native R parity.

This batch adds ten identified Python-function native-R candidates,
not ten fully independently certified contracts. Source-level mapping
alone does not prove equivalence for every supported Python input.
The 508-export parity catalog remains fail-closed.

All implementations run without a Python interpreter.
Optional independent Python 1.2 numerical-oracle tests are opt-in.
}
\examples{
times <- list(c(0, 1, 3), c(.5, 1.5, 2.5))
values <- list(matrix(c(0, 1, 3), ncol = 1),
               matrix(c(2, 3, 4), ncol = 1))
x <- etr_irregular_trajectory_set(times, values,
                                  c("A", "B"), "x")
grid <- etr_make_common_grid(x, n_time = 5L)
y <- etr_resample_irregular_to_grid(x, grid)
stopifnot(identical(dim(y$values), c(2L, 5L, 1L)))
}
