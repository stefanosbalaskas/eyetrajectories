# Native familywise simultaneous calibration of fixed-target FPCR projections

Pure native R postcalibration of precomputed Gaussian FPCR
wild-bootstrap studentized roots with one max-absolute statistic over
the complete predeclared family of fixed target trajectories. No model
or multiplier generation is performed.

## Usage

``` r
etr_fpca_wild_bootstrap_projection_simultaneous_interval(
  result, confidence_level = NULL)
```

## Arguments

- result:

  Native scientific list containing the base wild-bootstrap projection
  result, finite B-by-N studentized roots, finite reference projections
  and nonnegative reference standard errors, fixed target identifiers
  and predeclared confidence level.

- confidence_level:

  Numeric probability in (0,1). When NULL, use the base result's
  existing confidence level.

## Value

An R scientific record of per-target critical values, familywise
max-absolute bootstrap statistics, the common simultaneous critical
value and reference projection intervals on exactly the retained
fixed-target family. The source Python 1.2 dataclass output type is not
claimed.

## Details

Quantiles use the published NumPy `method="higher"` rule, selecting
`ceiling((B-1)*confidence_level)+1` in R's one-based sorted bootstrap
order. This differs from some default R quantile rules for finite B. The
function reuses the retained bootstrap data; it does not rerun FPCA,
Gaussian FPCR or residual multipliers, change fixed targets, account for
component-selection uncertainty, calibrate future outcomes, or claim
between-target or between-grid coverage. Source-contract representation
and complete input-domain equivalence remain independently uncertified.
