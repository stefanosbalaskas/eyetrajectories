\name{etr_native_stage8_nonlinear_recurrence}
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
\code{joint_recurrence.py}. These functions are research-size dense-R
implementations, not Python \code{scipy.sparse} object wrappers.
}
\usage{
etr_recurrence_network(recurrence)
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
  window_units = "samples", step_units = "samples", radius,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L)
etr_windowed_rqa_trajectory_set(trajectories, metrics, window, step,
  window_units = "samples", step_units = "samples", radius,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L, undefined_policy = "raise")
}
\arguments{
\item{recurrence}{Native \code{etr_recurrence}, auto for network
analysis and cross for cross-RQA.}
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
\item{metric}{Radius-profile source metric:
\code{"euclidean"}, \code{"cityblock"}, or \code{"chebyshev"}.
Windowed RQA currently supports only Euclidean distance.}
\item{theiler_window}{Nonnegative excluded sample-index lag.}
\item{theiler_window_units}{Currently only \code{"samples"}.}
\item{dimensions}{Optional distinct named channel selection.}
\item{window,step}{Window and step lengths expressed in samples; windows
must contain at least three samples, and \code{step <= window}.}
\item{window_units,step_units}{Currently only \code{"samples"}.}
\item{radius}{Fixed finite nonnegative Euclidean recurrence radius.}
\item{target_recurrence_rate}{Must be NULL in this Stage 8 native-R
windowed implementation; automatic target-density selection has not
been numerically qualified.}
\item{metrics}{Distinct named RQA metrics forming functional channels.}
\item{undefined_policy}{\code{"raise"} to reject undefined RQA metrics
or \code{"keep"} to preserve them as explicit missing values.}
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

Dense recurrence network analysis is limited to 750 state nodes;
native radius profiles to 2500. These caps differ from Python's sparse
implementations. Radius profiles accept only sample-based Theiler
windows and TrajectorySet input. Windowed RQA is limited to fixed-radius
Euclidean sample windows; Python has more metrics and threshold policies.
The current R objects are partial scientific-result representations,
not certified binary/serialization equivalents of Python dataclasses.

Windowed functional RQA reuses source samples for overlapping windows
and does NOT treat windows as independent sampling units for downstream
inference. No scientific coverage or inferential calibration is implied.
Optional Python reference tests use a pinned Python 1.2 package
and are entirely separate from the native R algorithms.
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
