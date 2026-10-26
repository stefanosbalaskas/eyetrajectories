# Experimental simultaneous functional-band studentization pilot

**Research only, unexecuted on the author's R environment.**
Source: `scripts/run_studentized_band_pilot.R`. The existing
`etr_bootstrap_mean_band` and `etr_bootstrap_group_contrast`
implementations are deliberately left unchanged.

## Objective

Previous independent known-truth audits exposed severe undercoverage
of 90% simultaneous functional bands at 12–48 independent participants:
group contrast 0.65 / 0.79 / 0.84 and participant mean
0.63 / 0.89 / 0.86 (100 datasets per condition, B=399).
A matched 30-study pilot further showed that a Gaussian Student-t
Bonferroni comparator can deliver higher coverage at the cost of much
wider intervals. These facts motivate a bootstrap-specific-SE approach
without any presumption of its validity.

## Candidate estimator in the new stand-alone script

For independent participant-mean curves, estimate the overall functional
mean and its participant-level pointwise standard errors. Resample
participants as whole units (or independently within the two fixed
treatment groups). Within each bootstrap resample, **re-estimate the
pointwise standard errors** instead of dividing by the original SE.
Compute the maximum absolute studentized deviation over all 41 × 2
grid cells. Take the empirical (1 - alpha) quantile of these bootstrap
maxima and multiply it by the original pointwise standard errors to
construct a simultaneous candidate band.

Contrast with the existing fixed-original-SE max-statistic bootstrap:
the difference lies in the denominator of each bootstrap statistic.
Both methods may remain under-calibrated under small clusters, skew,
high leverage, correlated errors, unequal arms, zero variance or
informative observation mechanisms. Studentization is **not a CR2
correction**, a wild bootstrap, or a small-sample calibration theorem.

Reference packages with methods to compare independently:
[SCBmeanfd](https://CRAN.R-project.org/package=SCBmeanfd)
(functional mean SCBs) and
[clubSandwich](https://CRAN.R-project.org/package=clubSandwich)
(small-sample cluster-robust corrections for supported models).
Neither package's published method automatically qualifies the native
bootstrap's subject structure or functional two-channel max statistic.

## Running the pilot

From the `research/native-parity-stage1` checkout:

```r
Sys.setenv(
  ET_STUDENT_SIMS = "30",
  ET_STUDENT_B = "199",
  ET_STUDENT_SUBJECTS = "12,24,48"
)
source("scripts/run_studentized_band_pilot.R")
```

The script is intentionally stand-alone, without package exports.
Each run creates a timestamped directory in
`artifacts/studentized_band_pilot/` containing:

- `studentized_trials.csv`: every generated dataset × method, seeds,
  exact known-truth inclusion, width, cutoff, errors
- `studentized_summary.csv`: successful fits, fit failures,
  conditional simultaneous coverage, exact 95% binomial Monte Carlo
  confidence bounds, operational coverage, mean width and mean critical
- `studentized_failures.csv`: created only if any method fit fails
- `studentized_coverage_width.pdf`: paired coverage and width comparisons
- `sessionInfo.txt` and `MANIFEST.txt`: runtime and assumptions

**No missingness, heteroskedasticity, varying numbers of trials,
or non-Gaussian participant innovations are included in this first
pilot.** It uses exactly the same two synthetic generators as the
earlier independent R Phase 3 studies. Results are failure-inclusive
and must be compared on the **same generated datasets**.

Recommended next run after examining all failures and the initial
30-study output:

```r
 Sys.setenv(ET_STUDENT_SIMS = "200", ET_STUDENT_B = "399")
 source("scripts/run_studentized_band_pilot.R")
```

Use at least 2,000 independently generated datasets per qualified
design if moving from exploration to precise empirical Type I error
evidence, ideally with independent seeds, variance heterogeneity,
low effective participant counts, unequal/clustered trial counts,
informative missingness and alternative covariance models.

## Scientific interpretation

Report coverage AND average interval width, with the number of
failed/degenerate bootstrap fits. Exact binomial intervals measure
Monte Carlo precision; they do **not** establish true asymptotic or
conditional coverage. No results from this script have yet been
generated or checked in RStudio. A 30-study pilot is too small to
justify changing package estimators or CRAN release claims.

**The current fixed-SE bands remain experimental and the release
qualification remains on HOLD.**
