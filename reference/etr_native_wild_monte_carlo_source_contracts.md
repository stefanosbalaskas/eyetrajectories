# Native fixed-family FPCR Monte Carlo precision and simultaneous graphics

Read-only, source-derived Monte Carlo precision from precomputed
wild-bootstrap roots and fixed-family maxT statistics. Exact
Clopper-Pearson binomial intervals quantify numerical finite-resample
uncertainty. Base-R graphics display fixed-family probabilities and
projection intervals.

## Usage

``` r
etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
  result, confidence_level = 0.95)
```

## Arguments

- result:

  Explicit source-shaped native scientific list with retained bootstrap
  projections, studentized roots, observed family statistics, rejection
  decisions and precomputed intervals where required.

- confidence_level:

  Diagnostic confidence level strictly inside (0,1).

## Value

The numerical function returns an R scientific list of source-named raw
exceedance counts, exceedances/B probabilities, Monte Carlo standard
errors, exact binomial intervals, decision stability flags and
provenance. Both plots return the displayed numeric geometry invisibly,
not a Matplotlib Axes object.

## Details

The source calculation reuses the exact observed roots and maximum
statistics; no bootstrap multipliers are redrawn and no models are
refitted. Decision-stability flags only indicate whether the entire
binomial Monte Carlo interval lies on the previously reported decision
side of alpha. They do not change reported hypothesis-test decisions.
These are Monte Carlo precision intervals, not confidence intervals for
scientific effects, improved FWER control or between-grid guarantees.
The Python 1.2.0 dataclass and Matplotlib result contracts remain
independently unqualified.
