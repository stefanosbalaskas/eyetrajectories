# Pointwise coefficient table from a joint B-spline functional mixed model

Return native R pointwise estimates and normal-Wald intervals for fitted
functional fixed coefficients. Intervals are not simultaneous.

## Usage

``` r
etr_joint_bspline_mixed_coefficient_frame(fit, confidence_level = 0.95)
```

## Arguments

- fit:

  Result from
  [`etr_fit_joint_bspline_functional_mixed_effects()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_fit_joint_bspline_functional_mixed_effects.md).

- confidence_level:

  Pointwise nominal confidence level, strictly between zero and one.

## Value

A data frame with `coefficient`, `time`, `estimate`, `se`, `lower`, and
`upper` columns.
