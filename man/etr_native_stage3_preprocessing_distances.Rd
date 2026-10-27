\name{etr_native_stage3_preprocessing_distances}
\alias{etr_normalize_coordinates}
\alias{etr_center_on_landmark}
\alias{etr_normalize_time_interval}
\alias{etr_heading_function}
\alias{etr_trajectory_tortuosity_frame}
\alias{etr_pairwise_frechet}
\alias{etr_nearest_trajectory_indices}
\title{Stage 3 native R preprocessing, kinematics and trajectory distances}
\description{
Seven independently implemented R functions, corresponding to published
\pkg{eyetrajectoriespy} 1.2.0 public functions.
These implementations do not execute Python. Independent Python numerical
oracles are provided separately as optional tests; numerical/generalized
equivalence is not automatically certified by installation.
}
\usage{
etr_normalize_coordinates(x, width, height)
etr_center_on_landmark(x, landmark_x, landmark_y)
etr_normalize_time_interval(x, start = 0, end = 1)
etr_heading_function(x, dimensions = NULL, min_speed = 0,
                     undefined_policy = c("nan", "raise"))
etr_trajectory_tortuosity_frame(x, dimensions = NULL, min_displacement = 0,
                                undefined_policy = c("nan", "raise"))
etr_pairwise_frechet(x, dimensions = NULL, dimension_weights = NULL)
etr_nearest_trajectory_indices(x, index, n_neighbors = 5L)
}
\arguments{
\item{x}{An \code{etr_trajectory_set} with common, strictly increasing time
values. Derivative and distance functions may require complete observations.}
\item{width, height}{Strictly positive finite coordinate extents.}
\item{landmark_x, landmark_y}{Finite scalars or numeric vectors with one
landmark per curve.}
\item{start, end}{Finite new time interval endpoints, with \code{end>start}.}
\item{dimensions}{Optional ordered distinct named channel selection.
Planar methods default to channels \code{x} and \code{y} only if explicitly
present. Pairwise Frechet defaults to all stored channels.}
\item{min_speed}{Non-negative lower speed limit (undefined when
\code{speed<=min_speed}).}
\item{undefined_policy}{\code{"nan"} maps undefined Python numeric results
to \code{NA_real_}; \code{"raise"} stops on undefined samples/curves.}
\item{min_displacement}{Nonnegative endpoint displacement threshold.}
\item{dimension_weights}{Optional finite non-negative channel weights,
containing at least one strictly positive value.}
\item{index}{Zero-based integer target curve index, matching Python's
\code{nearest_trajectory_indices()}.}
\item{n_neighbors}{Positive integer number of nearest distinct curves.
Requesting more than exist returns all available distinct curves.}
}
\value{
The first four functions return a native \code{etr_trajectory_set};
\code{etr_trajectory_tortuosity_frame()} returns a base R data.frame;
\code{etr_pairwise_frechet()} returns a symmetric numeric distance matrix
without dimnames; \code{etr_nearest_trajectory_indices()} returns
zero-based integer indices.
}
\details{
Coordinate normalization divides only the first two stored channels
by width/height without clipping out-of-bounds gaze or modifying other
channels. Centering subtracts explicitly supplied per-curve landmarks,
not a trajectory's mean or first location. Time normalization accepts
arbitrary valid endpoints and does not alter values.

Heading is wrapped \code{atan2(v_y,v_x)} computed using the same
second-order edge-aware nonuniform-grid derivative as the Python reference.
Tortuosity reports sampled path length divided by endpoint displacement
with the same inclusive zero-denominator rule as the Python reference.
Pairwise Frechet uses ordered point sequences, not elapsed time, in the
discrete dynamic-programming recurrence.

Unlike the Python \code{TrajectorySet} class, the current native R
trajectory object does not yet store equivalent JSON-like provenance.
The native tortuosity data frame omits the Python pandas
\code{DataFrame.attrs} provenance field. These differences remain open
for full behavioral and schema parity.
For nearest-neighbor distance ties, the native R version uses ascending
original index; Python NumPy's default argsort tie ordering may differ.
}
\examples{
tt <- c(0,.2,.6,1,2)
a <- array(0,c(2,length(tt),2))
a[1,,1] <- tt
a[1,,2] <- tt^2
a[2,,1] <- tt+1
a[2,,2] <- tt^2+1
x <- etr_trajectory_set(tt,a,dimension_names=c("x","y"),
                        coordinate_system="pixels")
y <- etr_normalize_coordinates(x,1920,1080)
z <- etr_center_on_landmark(x,1,1)
p <- etr_pairwise_frechet(x)
}
