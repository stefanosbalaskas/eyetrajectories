\name{etr_native_planar_geometry}
\alias{etr_acceleration_magnitude}
\alias{etr_distance_to_landmark}
\alias{etr_signed_curvature}
\alias{etr_turning_rate}
\title{Native R planar trajectory acceleration, landmark distance and differential geometry}
\description{
Research-stage Python-free counterparts of four public
\pkg{eyetrajectoriespy} 1.2.0 kinematic methods. They use the standalone
\code{etr_trajectory_set} object and no \pkg{reticulate} dependency at
execution time. These are not yet independently validated numerical parity
claims.
}
\usage{
etr_acceleration_magnitude(x)
etr_distance_to_landmark(x, landmark_x, landmark_y,
                         python_boundary_mode = FALSE)
etr_signed_curvature(x, dimensions = NULL, min_speed = 0,
                     undefined_policy = c("nan", "raise"))
etr_turning_rate(x, dimensions = NULL, min_speed = 0,
                 undefined_policy = c("nan", "raise"))
}
\arguments{
\item{x}{Native \code{etr_trajectory_set} collection on one common time grid.}
\item{landmark_x}{Finite scalar or one finite x landmark per curve.}
\item{landmark_y}{Finite scalar or one finite y landmark per curve.}
\item{python_boundary_mode}{Logical; TRUE enables bounded frozen Python 1.2 NumPy dtype=float conversion of finite numeric-string, Boolean or mixed scalar/vector landmark coordinates and preserves the source derived-function provenance. FALSE preserves strict native finite numeric inputs and historical provenance behavior.}
\item{dimensions}{Optional two distinct named channels in x/y order.
Defaults to explicitly named \code{x} and \code{y} channels.
No silent selection when they are absent.}
\item{min_speed}{Nonnegative minimum allowed Euclidean speed.
A sample with speed less than or equal to this threshold is undefined.}
\item{undefined_policy}{\code{"nan"} maps the Python undefined numerical
value NaN to the native R missing-data sentinel \code{NA_real_};
\code{"raise"} fails closed instead of returning a partial result.}
}
\value{
A native \code{etr_trajectory_set} with exactly one resulting functional
channel named \code{acceleration_magnitude}, \code{distance_to_landmark},
\code{signed_curvature}, or \code{turning_rate}.
}
\details{
The acceleration magnitude follows two second-order edge-aware finite
differences on the original irregular common grid followed by the
Euclidean norm of the first two channels. It needs at least three
complete observations. Distance-to-landmark requires only two planar
channels and deliberately propagates missing coordinates as NA.

Signed curvature is
\deqn{\kappa(t)=\frac{x'(t)y''(t)-y'(t)x''(t)}
{(x'(t)^2+y'(t)^2)^{3/2}}.}
Turning rate is
\deqn{\omega(t)=\frac{x'(t)y''(t)-y'(t)x''(t)}
{x'(t)^2+y'(t)^2}.}
Both quantities are undefined under the specified minimum speed,
without an added denominator epsilon or smoothed heading.

The native trajectory class retains a JSON-like provenance mapping.
The explicit landmark-distance Python compatibility mode preserves
incoming provenance and records the source derived_function value.
The Python and R object classes, all supported scalar input domains,
error schemas and serialized-result representations are not fully identical.
A separate independent full-domain Python/R numerical review is still required.
}
\examples{
time <- c(0, 0.25, 0.8, 1.4, 2)
v <- array(0, c(1, length(time), 2))
v[1, , 1] <- time
v[1, , 2] <- time^2
x <- etr_trajectory_set(time, v, dimension_names = c("x", "y"))
a <- etr_acceleration_magnitude(x)
k <- etr_signed_curvature(x)
w <- etr_turning_rate(x)
d <- etr_distance_to_landmark(x, landmark_x = 0, landmark_y = 0)
}
