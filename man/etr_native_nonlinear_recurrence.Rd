\name{etr_native_nonlinear_recurrence}
\alias{etr_recurrence_network}
\alias{etr_recurrence_network_node_frame}
\alias{etr_recurrence_network_summary_frame}
\alias{etr_joint_recurrence_matrix}
\alias{etr_joint_recurrence_component_frame}
\alias{etr_joint_rqa_metrics}
\alias{etr_cross_rqa_metrics}
\alias{etr_recurrence_radius_profile}
\alias{etr_windowed_rqa}
\alias{etr_windowed_rqa_trajectory_set}
\title{Native R recurrence networks, joint recurrence and sliding-window RQA}
\description{
Ten native Python-independent nonlinear-dynamics algorithms and frames
based on the published \pkg{eyetrajectoriespy} 1.2.0 contracts from
\code{recurrence.py}, \code{recurrence_networks.py} and
\code{joint_recurrence.py}. These are research-size native R implementations, not Python
\code{scipy.sparse} object wrappers. Recurrence-network results
can now optionally use sparse native \pkg{Matrix} adjacency and
accept already sparse native recurrence matrices without materializing a
dense square array. Native joint RQA on sparse sources now counts diagonal and
vertical line runs directly from nonzero coordinates, including large sparse
recurrence systems, without the former 2500-node dense-conversion guard.
}
\usage{
etr_recurrence_network(recurrence, adjacency_storage = c("dense", "sparse"),
  python_boundary_mode = FALSE)
etr_recurrence_network_node_frame(result)
etr_recurrence_network_summary_frame(result)
etr_joint_recurrence_matrix(recurrences, labels = NULL)
etr_joint_recurrence_component_frame(result)
etr_joint_rqa_metrics(result, min_diagonal_length = 2L,
                      min_vertical_length = 2L)
etr_cross_rqa_metrics(recurrence, min_diagonal_length = 2L,
                      min_vertical_length = 2L)
etr_recurrence_radius_profile(source, curve = 1L, radii,
  metric = "euclidean", theiler_window = 0L,
  theiler_window_units = "samples", dimensions = NULL)
etr_windowed_rqa(trajectories, curve = 1L, window, step,
  window_units = "samples", step_units = "samples", radius = NULL,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L)
etr_windowed_rqa_trajectory_set(trajectories, metrics, window, step,
  window_units = "samples", step_units = "samples", radius = NULL,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L, undefined_policy = "raise")
}
\arguments{
\item{recurrence}{Native \code{etr_recurrence}, auto for network
analysis and cross for cross-RQA.}
\item{adjacency_storage}{\code{"dense"} keeps the existing native
logical adjacency matrix and its 2500-node cap; \code{"sparse"} returns
a logical sparse \pkg{Matrix} matrix with a 10000-node cap for dense
source recurrence or 100000 nodes when the source is already sparse. The
Matrix package is required only for sparse input or output.}
\item{result}{Native recurrence network or joint recurrence result.}
\item{recurrences}{Two or more native auto-recurrence results on exactly
the same time grid, temporal unit and Theiler-exclusion contract.}
\item{labels}{Optional unique component labels.}
\item{min_diagonal_length,min_vertical_length}{Positive integer minimum
qualifying RQA line lengths.}
\item{source,trajectories}{Complete native \code{etr_trajectory_set};
the first supplies a radius-profile source.}
\item{curve}{One-based numeric curve index or existing curve identifier.}
\item{radii}{Prespecified strictly increasing positive finite radius vector.}
\item{metric}{Source recurrence metric: \code{"euclidean"},
\code{"cityblock"}, or \code{"chebyshev"}, including windowed RQA.}
\item{theiler_window}{Nonnegative excluded sample-index lag.}
\item{theiler_window_units}{Sample units or convertible physical-time units
on an approximately regular observed grid.}
\item{dimensions}{Optional distinct named channel selection.}
\item{window,step}{Window and step lengths in explicit sample or physical
units, resolved to whole observed samples; windows need at least three
samples and \code{step <= window}.}
\item{window_units,step_units}{Sample units or convertible physical-time
units without resampling or interpolation.}
\item{radius}{Optional positive finite fixed recurrence radius.
Specify exactly one of radius or target_recurrence_rate.}
\item{target_recurrence_rate}{Optional target density strictly between
zero and one. Uses source-aligned inclusive-radius threshold selection,
whose achieved rate may differ because of distance ties. When this
controls the density, recurrence_rate cannot be a derived outcome.}
\item{metrics}{Distinct named RQA metrics forming functional channels.}
\item{undefined_policy}{\code{"raise"} to reject undefined RQA metrics
or \code{"keep"} to preserve them as explicit missing values.}
\item{python_boundary_mode}{If TRUE, use the published Python 1.2
boundary conditions; FALSE retains native validation defaults.}
}
\value{
\code{etr_recurrence_network()} returns a native
\code{etr_recurrence_network} list with undirected adjacency, zero-based
connected-component labels, degree, clustering, transitivity and
provenance. Node and summary functions return native R data frames.
Joint functions return a native \code{etr_joint_recurrence} or per-component
table/line statistics. \code{etr_recurrence_radius_profile()} returns
an \code{etr_recurrence_radius_profile} list with cumulative and shell
recurrence fractions. \code{etr_windowed_rqa()} returns a native
\code{etr_windowed_rqa} with one row per complete window and explicit
dropped-tail count. \code{etr_windowed_rqa_trajectory_set()} returns
an \code{etr_windowed_rqa_functional} with functional native trajectory,
per-curve windows, overlap fraction and provenance.
}
\details{
These functions are discrete, not continuous-time estimators.
Recurrence-network transitivity is undefined (NaN) when there are no
connected triples; clustering for degree below two is zero. No automatic
graph threshold or community detection is performed.
Joint recurrence requires strictly synchronized input and does not
resample, shift, or harmonize component thresholds.

Dense recurrence network output is limited to 2500 state nodes;
opt-in sparse output supports up to 10000 native recurrence states,
retaining source topology but not SciPy CSR class identity.
Native sparse \pkg{Matrix} auto-recurrence inputs can be analyzed without
dense allocation (with a separately bounded 100000-node sparse network
path); joint recurrence can intersect synchronized dense/sparse sources.
Native line-RQA uses sparse coordinates for large auto, joint and rectangular
cross recurrence inputs. Python SciPy CSR and typed result identity and full
source error domains remain unresolved. Native radius profiles retain their
separate 2500-node limit. These caps differ from Python's sparse
implementations. Radius profiles accept convertible physical-time
Theiler windows and TrajectorySet input. Windowed RQA supports fixed-radius or explicitly
requested target-density thresholds, all three source distance metrics,
and convertible physical-time windows/steps on approximately regular
grids. Target-density selection is not an independent parity certificate.
The current R objects are partial scientific-result representations,
not certified binary/serialization equivalents of Python dataclasses.

Windowed functional RQA reuses source samples for overlapping windows
and does NOT treat windows as independent sampling units for downstream
inference. No scientific coverage or inferential calibration is implied.
Optional Python reference tests use a pinned Python 1.2 package
and are entirely separate from the native R algorithms.

Native sparse cross-RQA accepts rectangular sparse \pkg{Matrix} recurrence
inputs with explicitly declared first and second time grids. Cross-line
statistics use all diagonals and vertical lines and require approximately
regular and matching time-step sizes. Native sparse representations are not
identical to Python SciPy CSR or typed dataclass results.
}
\examples{
values <- array(0,c(2L,9L,1L))
values[1L,,1L] <- rep(0:2,3L)
values[2L,,1L] <- rep(c(0,1,0),3L)
x <- etr_trajectory_set(0:8,values,c("A","B"),"x",time_unit="s")
r1 <- etr_recurrence_matrix(x,"A",radius=0.01)
r2 <- etr_recurrence_matrix(x,"B",radius=0.01)
network <- etr_recurrence_network(r1)
joint <- etr_joint_recurrence_matrix(list(r1,r2))
report <- etr_joint_rqa_metrics(joint)
}
