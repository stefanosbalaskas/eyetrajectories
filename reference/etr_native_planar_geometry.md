# Native R planar trajectory acceleration, landmark distance and differential geometry

Research-stage Python-free counterparts of four public eyetrajectoriespy
1.2.0 kinematic methods. They use the standalone `etr_trajectory_set`
object and no reticulate dependency at execution time. These are not yet
independently validated numerical parity claims.

## Usage

``` r
etr_acceleration_magnitude(x)
etr_distance_to_landmark(x, landmark_x, landmark_y,
                         python_boundary_mode = FALSE)
etr_signed_curvature(x, dimensions = NULL, min_speed = 0,
                     undefined_policy = c("nan", "raise"))
etr_turning_rate(x, dimensions = NULL, min_speed = 0,
                 undefined_policy = c("nan", "raise"))
```

## Arguments

- x:

  Native `etr_trajectory_set` collection on one common time grid.

- landmark_x:

  Finite scalar or one finite x landmark per curve.

- landmark_y:

  Finite scalar or one finite y landmark per curve.

- python_boundary_mode:

  Logical; TRUE enables bounded frozen Python 1.2 NumPy dtype=float
  conversion of finite numeric-string, Boolean or mixed scalar/vector
  landmark coordinates and preserves the source derived-function
  provenance. FALSE preserves strict native finite numeric inputs and
  historical provenance behavior.

- dimensions:

  Optional two distinct named channels in x/y order. Defaults to
  explicitly named `x` and `y` channels. No silent selection when they
  are absent.

- min_speed:

  Nonnegative minimum allowed Euclidean speed. A sample with speed less
  than or equal to this threshold is undefined.

- undefined_policy:

  `"nan"` maps the Python undefined numerical value NaN to the native R
  missing-data sentinel `NA_real_`; `"raise"` fails closed instead of
  returning a partial result.

## Value

A native `etr_trajectory_set` with exactly one resulting functional
channel named `acceleration_magnitude`, `distance_to_landmark`,
`signed_curvature`, or `turning_rate`.

## Details

The acceleration magnitude follows two second-order edge-aware finite
differences on the original irregular common grid followed by the
Euclidean norm of the first two channels. It needs at least three
complete observations. Distance-to-landmark requires only two planar
channels and deliberately propagates missing coordinates as NA.

Signed curvature is \$\$\kappa(t)=\frac{x'(t)y''(t)-y'(t)x''(t)}
{(x'(t)^2+y'(t)^2)^{3/2}}.\$\$ Turning rate is
\$\$\omega(t)=\frac{x'(t)y''(t)-y'(t)x''(t)} {x'(t)^2+y'(t)^2}.\$\$ Both
quantities are undefined under the specified minimum speed, without an
added denominator epsilon or smoothed heading.

The native trajectory class retains a JSON-like provenance mapping. The
explicit landmark-distance Python compatibility mode preserves incoming
provenance and records the source derived_function value. The Python and
R object classes, all supported scalar input domains, error schemas and
serialized-result representations are not fully identical. A separate
independent full-domain Python/R numerical review is still required.

## Examples

``` r
time <- c(0, 0.25, 0.8, 1.4, 2)
v <- array(0, c(1, length(time), 2))
v[1, , 1] <- time
v[1, , 2] <- time^2
x <- etr_trajectory_set(time, v, dimension_names = c("x", "y"))
a <- etr_acceleration_magnitude(x)
k <- etr_signed_curvature(x)
w <- etr_turning_rate(x)
d <- etr_distance_to_landmark(x, landmark_x = 0, landmark_y = 0)
```
