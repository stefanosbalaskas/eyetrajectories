# Tidy pointwise coefficient intervals for the native REML model

Produces a long data frame of pointwise fixed-effect estimates and
normal-Wald intervals. Does not claim simultaneous confidence coverage
or Python joint-B-spline equivalence.

## Usage

``` r
etr_functional_random_intercept_reml_frame(fit, confidence_level = 0.95)
```

## Arguments

- fit:

  A native etr_functional_random_intercept_reml result.

- confidence_level:

  Scalar nominal pointwise normal-Wald level between zero and one.

## Value

Data frame with term, time, estimate, pointwise_se, lower, upper, and
confidence_level.
