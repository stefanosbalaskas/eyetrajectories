# Known-truth hierarchy score-source variance audit

Compares realized population (ddof zero) score-source variances against
fixed simulator truth. No estimator is fitted. Source dataclass and full
domain certification remain open.

## Usage

``` r
etr_evaluate_hierarchy_truth_recovery(truth)
```

## Arguments

- truth:

  Source-shaped simulator truth with curve, participant and trial score
  matrices and declared eigenvalues.

## Value

Native recovery assessment with labelled absolute and relative source
variances and semantic metric definitions.
