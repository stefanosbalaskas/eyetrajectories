\name{native-api}
\title{Native R functional trajectories: Phase 2 scientific core}
\description{Explicit, Python-independent functions for common-grid trajectories, preprocessing,
quadrature-weighted dense FPCA, sampled planar kinematics, trajectory distances,
basic recurrence analysis, and base graphics.}
\alias{etr_trajectory_set}
\alias{etr_validate}
\alias{etr_from_long}
\alias{etr_as_long}
\alias{etr_subset}
\alias{etr_dimension}
\alias{etr_summary}
\alias{etr_resample}
\alias{etr_interpolate_gaps}
\alias{etr_normalize_time}
\alias{etr_center}
\alias{etr_smooth}
\alias{etr_scale_channels}
\alias{etr_velocity}
\alias{etr_acceleration}
\alias{etr_speed}
\alias{etr_heading}
\alias{etr_path_length}
\alias{etr_cumulative_path_length}
\alias{etr_tortuosity}
\alias{etr_l2_distance}
\alias{etr_pairwise_l2}
\alias{etr_frechet}
\alias{etr_dtw}
\alias{etr_pairwise_dtw}
\alias{etr_trapezoid_weights}
\alias{etr_fit_fpca}
\alias{etr_fit_mfpca}
\alias{etr_fpca_scores}
\alias{etr_fpca_variance_frame}
\alias{etr_transform_fpca}
\alias{etr_reconstruct_fpca}
\alias{etr_recurrence_matrix}
\alias{etr_cross_recurrence_matrix}
\alias{etr_rqa_metrics}
\alias{etr_plot_trajectories}
\alias{etr_plot_fpca_variance}
\alias{etr_plot_recurrence}
\usage{
etr_trajectory_set(time, values, curve_ids = NULL, dimension_names = NULL,
    metadata = NULL, coordinate_system = "unknown", time_unit = "unknown",
    provenance = list(), python_boundary_mode = FALSE)

etr_validate(x, require_complete = FALSE)

etr_from_long(data, curve_columns, time_column = "time", value_columns = c("x", "y"),
    metadata_columns = NULL, coordinate_system = "unknown", time_unit = "unknown",
    provenance = NULL)

etr_as_long(x)

etr_subset(x, curves, python_boundary_mode = FALSE)

etr_dimension(x, dimension)

etr_summary(x)

etr_resample(x, new_time, max_gap = Inf)

etr_interpolate_gaps(x, max_gap)

etr_normalize_time(x, method = c("unit", "origin"))

etr_center(x, method = c("first", "mean"))

etr_smooth(x, window = 5L)

etr_scale_channels(x, scaling = c("none", "dimension_sd"))

etr_velocity(x)

etr_acceleration(x)

etr_speed(x)

etr_heading(x)

etr_path_length(x)

etr_cumulative_path_length(x)

etr_tortuosity(x)

etr_l2_distance(a, b, time, dimension_weights = NULL,
  python_boundary_mode = FALSE)

etr_pairwise_l2(x, dimension_weights = NULL, python_boundary_mode = FALSE)

etr_frechet(a, b, dimension_weights = NULL, return_coupling = FALSE,
  python_boundary_mode = FALSE)

etr_dtw(a, b, dimension_weights = NULL, window_radius = NULL,
  step_pattern = "symmetric1", normalize = FALSE, return_path = FALSE,
  python_boundary_mode = FALSE)

etr_pairwise_dtw(x, dimension_weights = NULL, dimensions = NULL,
  window_radius = NULL, step_pattern = "symmetric1", normalize = FALSE,
  python_boundary_mode = FALSE)

etr_trapezoid_weights(time, normalize = FALSE,
  python_boundary_mode = FALSE)

etr_fit_fpca(x, n_components = 0.95, scaling = c("none", "dimension_sd"))

etr_fit_mfpca(x, n_components = 0.95, scaling = c("none", "dimension_sd"))

etr_fpca_scores(fit)

etr_fpca_variance_frame(fit)

etr_transform_fpca(fit, x)

etr_reconstruct_fpca(fit, n_components = NULL, scores = NULL)

etr_recurrence_matrix(x, curve = 1L, radius = NULL, theiler = 0L,
  metric = "euclidean", target_recurrence_rate = NULL,
  dimensions = NULL, theiler_window_units = "samples")

etr_cross_recurrence_matrix(a, b, radius = NULL, metric = "euclidean",
  target_recurrence_rate = NULL, curve_a = NULL, curve_b = NULL,
  dimensions_a = NULL, dimensions_b = NULL)

etr_rqa_metrics(recurrence, min_diagonal_length = 2L, min_vertical_length = 2L)

etr_plot_trajectories(x, max_curves = 40L, invert_y = TRUE, ...)

etr_plot_fpca_variance(fit, cumulative = TRUE, ...)

etr_plot_recurrence(recurrence, ...)
}
\arguments{
\item{time}{Strictly increasing finite time vector; in distance
methods, matched observation times. The explicit Python boundary mode
of \code{etr_trapezoid_weights()} additionally casts a complex atomic
time vector to its real part, matching NumPy's complex ndarray
\code{dtype=float} conversion (which discards imaginary components).}
\item{values}{Numeric 3D array ordered curve, time, dimension. NA is allowed in stored objects.}
\item{curve_ids}{Unique identifiers for curves.}
\item{dimension_names}{Unique measurement channel names.}
\item{metadata}{Optional curve-level data frame.}
\item{coordinate_system}{Explicit coordinate semantics, e.g. pixels.}
\item{time_unit}{Explicit temporal units, e.g. ms or s.}
\item{provenance}{Optional JSON-like named native R list of source and preprocessing decisions. For \code{etr_from_long}, the source audit is added by default and user-supplied named keys are applied as shallow overrides.}
\item{x}{Native trajectory set, or a fitted object as documented in the specific function.}
\item{require_complete}{Whether to reject missing samples.}
\item{python_boundary_mode}{If TRUE, enable bounded Python 1.2 TrajectorySet constructor/subset behavior for NaN observations, zero-curve arrays, regular nested numeric-like sequences, complex ndarray-to-real casting, ID-indexed metadata and zero-based/negative subset indices. Default FALSE preserves the native scientific contract. Does not reproduce all NumPy, pandas or dataclass semantics.}
\item{data}{Long-format data frame with individual gaze samples.}
\item{curve_columns}{Names of curve identifier columns.}
\item{time_column}{Name of time variable.}
\item{value_columns}{Names of measurement variables.}
\item{metadata_columns}{Optional curve-constant metadata columns.}
\item{curves}{Unique 1-based integer curve indices or string identifiers by default; opt-in source boundary mode uses 0-based/negative integer indices, including empty selections.}
\item{dimension}{Channel index or channel name.}
\item{new_time}{Target time grid (no extrapolation).}
\item{max_gap}{Maximum allowed observed time interval for explicit interpolation.}
\item{method}{Declared normalization or centering rule.}
\item{window}{Odd integer running-mean window size.}
\item{scaling}{Channel scaling policy: none or dimension_sd.}
\item{a}{Numeric point-by-channel matrix.}
\item{b}{Numeric point-by-channel matrix with matching channels.}
\item{dimension_weights}{Finite, non-negative channel weights.}
\item{return_coupling}{If TRUE, return the 0-based deterministic discrete Fréchet coupling and local costs.}
\item{window_radius}{Optional non-negative integer Sakoe-Chiba index-window radius for DTW.}
\item{step_pattern}{DTW transition weighting: symmetric1 or symmetric2.}
\item{return_path}{If TRUE, return 0-based DTW path, local and weighted costs, and provenance.}
\item{normalize}{For DTW, TRUE normalizes only the symmetric2 step pattern by n_points_a + n_points_b. For trapezoidal weights, a scalar with Python 1.2
truthiness semantics: FALSE, zero, empty string and zero complex keep
original weights. Nonzero numeric scalars, nonempty strings and, in the
explicit Python boundary mode, nonzero, infinite or NaN-valued complex
scalars normalize to unit total. Empty/nonempty lists have container
truthiness only in source-boundary mode. General Python object
truthiness remains outside the qualified domain.}
\item{python_boundary_mode}{For pairwise L2 and DTW, TRUE also
propagates bounded frozen Python 1.2 numeric coercion and nonfinite
L2 semantics; otherwise existing native defaults remain. For Fréchet
and DTW, TRUE also enables
rectangular nested 2D point sequences, numeric-string/Boolean/complex
matrices and weighted NumPy float-domain conversions. Defaults remain
strict scientific numeric matrices. Logical flag requesting a bounded native
Python 1.2 source-input compatibility domain. For trapezoidal weighting
it includes stated exceptional grids, complex ndarray-style time
casting, and Python scalar/container truthiness. For functional L2
distance it permits numeric-string/Boolean/complex matrices and
dimension weights with explicit NumPy-style real conversion. The L2
source mode also allows infinity and NaN-valued weights where Python
propagates the same nonfinite arithmetic; input NaN trajectory
coordinates remain rejected. FALSE uses native R finite validation.
Neither value invokes Python, and full source-domain parity is not
claimed.}
\item{metric}{Distance metric for recurrence and cross-recurrence: \code{euclidean} (L2), \code{cityblock} (L1), or \code{chebyshev} (L-infinity). The default is Euclidean.}
\item{n_components}{Integer component count or, for fitting, a variance fraction strictly between 0 and 1.}
\item{fit}{Native etr_fpca fit.}
\item{scores}{Optional finite numeric FPCA score vector (one external curve) or numeric matrix (curves by fitted components). When supplied, reconstructs these external scores to an unlabelled curve-by-time-by-dimension numeric array. When omitted, fitted curves are returned as the original native trajectory collection.}
\item{curve}{Curve ID or 1-based index.}
\item{radius}{Optional fixed finite non-negative recurrence radius.
Specify exactly one of radius or target_recurrence_rate.}
\item{target_recurrence_rate}{Optional probability strictly between zero
and one, selecting the source-aligned target-density threshold policy.
Distance ties may prevent an exact target rate.}
\item{dimensions}{Optional ordered selected channel names for native
recurrence sources and pairwise DTW; NULL retains all channels.
For pairwise DTW, the order controls dimension-weight alignment.}
\item{theiler_window_units}{Theiler interval units: samples or compatible
physical time on a sufficiently regular observed grid.}
\item{curve_a,curve_b}{Required curve identifiers for trajectory-set
cross-recurrence inputs; NULL for numeric matrices.}
\item{dimensions_a,dimensions_b}{Required matching ordered state-channel
names for trajectory-set cross-recurrence; NULL for numeric matrices or
already embedded state spaces.}
\item{theiler}{Excluded sample lag for auto-recurrence.}
\item{recurrence}{Native etr_recurrence object. For
\code{etr_rqa_metrics()}, native sparse \pkg{Matrix} auto- and cross-
recurrence are supported without dense allocation. Sparse auto-RQA uses
upper-triangle diagonals and full-matrix vertical runs; sparse cross-RQA
uses every diagonal and full-matrix vertical runs. Both include finite-border
runs. Source-style line statistics require approximately regular time grids,
and cross-RQA requires matching step sizes on the two declared axes.
Undefined sparse statistics use \code{NaN}; dense defaults remain unchanged.}
\item{min_diagonal_length}{Minimum counted diagonal line length.}
\item{min_vertical_length}{Minimum counted vertical run length.}
\item{max_curves}{Maximum plotted curves.}
\item{invert_y}{Whether to invert the planar screen Y axis.}
\item{cumulative}{Plot cumulative explained variance.}
\item{...}{Additional base R plotting arguments.}
}
\details{
Phase 2 currently implements dense-grid methods, not sparse or asynchronous
PACE. FPCA returns the same weighted-PCA mathematical target as the Python
backend but makes no guarantee that eigenvector signs are identical. The
recurrence methods use dense matrices and explicit fixed radii and are not
full RQA parity. Input preparation is explicit, without hidden interpolation,
missingness repair, smoothing, or coordinate normalization.
}
\value{Depends on the function: a native trajectory collection, native FPCA
result, numeric matrix/vector, recurrence result, data frame, or base-R plot.}
\seealso{\code{\link{et_fit_mfpca}}, \code{\link{et_call}}}

\examples{
t <- seq(0, 1, length.out = 9)
v <- array(0, c(6L, length(t), 2L))
for (i in seq_len(6L)) {
  v[i, , 1L] <- sin(2*pi*t + i/6)
  v[i, , 2L] <- cos(2*pi*t + i/6)
}
x <- etr_trajectory_set(t, v, paste0("c", 1:6), c("x", "y"))
fit <- etr_fit_mfpca(x, n_components = 1L)
stopifnot(nrow(etr_fpca_scores(fit)) == 6L)
}
