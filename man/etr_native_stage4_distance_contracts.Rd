\name{etr_native_stage4_distance_contracts}
\alias{etr_discrete_frechet}
\alias{etr_dynamic_time_warping}
\alias{etr_pairwise_dtw_full}
\title{Complete native R discrete Frechet and dynamic time warping contracts}
\description{
Independent Python-free implementations of the public
\pkg{eyetrajectoriespy} 1.2.0 methods \code{discrete_frechet_distance},
\code{dynamic_time_warping_distance} and
\code{pairwise_dynamic_time_warping_distances}. They expose explicit
ordered coupling paths, two DTW step patterns, optional Sakoe-Chiba
constraints and deterministic cost audits. Python is only used by
optional external reference tests.
}
\usage{
etr_discrete_frechet(a, b, dimension_weights = NULL,
                      return_coupling = FALSE)
etr_dynamic_time_warping(a, b, dimension_weights = NULL,
                          window_radius = NULL,
                          step_pattern = "symmetric1",
                          normalize = FALSE,
                          return_path = FALSE)
etr_pairwise_dtw_full(x, dimensions = NULL, dimension_weights = NULL,
                      window_radius = NULL,
                      step_pattern = "symmetric1", normalize = FALSE)
}
\arguments{
\item{a,b}{Complete numeric point-by-dimension matrices. Both require
at least one time-ordered point and the same number of channels.}
\item{dimension_weights}{NULL or one finite nonnegative numeric weight per
channel. At least one weight must be strictly positive.}
\item{return_coupling}{Logical: if TRUE return a detailed optimal discrete
Frechet coupling and local distances; otherwise a numeric scalar.}
\item{window_radius}{NULL or a nonnegative integer Sakoe-Chiba window in
sample-index units. It must permit connection between the endpoints.}
\item{step_pattern}{DTW recursion \code{"symmetric1"} (all selected moves
weight one) or \code{"symmetric2"} (diagonal moves weight two,
horizontal/vertical moves weight one).}
\item{normalize}{Logical. Only supported with \code{"symmetric2"}.
If TRUE, return raw cumulative distance divided by \code{n_a+n_b}.}
\item{return_path}{Logical. If TRUE, return the full audited alignment
path, local distances, weighted distances, counts and provenance.}
\item{x}{Complete native \code{etr_trajectory_set}.}
\item{dimensions}{NULL to use all stored channels, or distinct ordered
channel names selecting the comparison dimensions.}
}
\value{
\code{etr_discrete_frechet()} returns a scalar or an
\code{etr_discrete_frechet_result} list with
\code{distance}, \code{coupling}, \code{local_distances},
\code{n_points_a}, \code{n_points_b}, \code{n_dimensions} and
\code{provenance}. \code{coupling} is an integer two-column matrix
with **zero-based** pair indices matching the Python result.

\code{etr_dynamic_time_warping()} returns a scalar or an
\code{etr_dtw_result} list with \code{distance}, zero-based integer
\code{path}, \code{local_distances}, \code{step_weights},
\code{weighted_local_costs}, \code{raw_distance},
optional \code{normalized_distance}, \code{path_length},
\code{mean_local_distance}, dimension counts, \code{window_radius},
\code{step_pattern}, optional \code{normalization_denominator} and
\code{provenance}. Python's None fields are R NULL.

\code{etr_pairwise_dtw_full()} returns a symmetric numeric matrix
without dimension labels; the diagonal is zero.
}
\details{
All algorithms are discrete, not continuous, and never use recorded time,
interpolate missing samples or change spatial coordinate units.
They use weighted Euclidean local costs, retain monotonicity of the
coupled trajectory sample indices, and resolve exactly tied predecessors
in the upstream order: diagonal, then advancing the first trajectory,
then advancing the second.

The upstream Python \code{dynamic_time_warping_distance} implements
\code{symmetric1} as raw path-visit costs, not normalized by path length.
The normalizable \code{symmetric2} recursion uses diagonal costs twice;
when requested, normalization divides raw cumulative cost by the
sequence length sum, not the number of alignment-path nodes.

The native R implementation imposes an explicit resource guard:
at most \code{5e6} point pairs for dense dynamic programming.
The published Python 1.2 function has no equivalent fixed limit.
The complete native R parity register consequently remains unqualified
for full behavioral equivalence, even after fixed numerical test cases
succeed. The R results reproduce documented Python provenance fields
as ordinary R named lists but have not been qualified for Python
serialization/JSON round-trip equivalence.

The older \code{etr_frechet()}, \code{etr_dtw()} and
\code{etr_pairwise_dtw()} remain available unchanged for existing R
users. The new functions express additional Python 1.2 behavior.
}
\examples{
a <- matrix(c(0, 1, 2), ncol = 1)
b <- matrix(c(.1, 1.1, 2.1), ncol = 1)
f <- etr_discrete_frechet(a, b, return_coupling = TRUE)
d <- etr_dynamic_time_warping(a, b, return_path = TRUE)
n <- etr_dynamic_time_warping(a, b, step_pattern = "symmetric2",
                               normalize = TRUE, window_radius = 0L)
}
