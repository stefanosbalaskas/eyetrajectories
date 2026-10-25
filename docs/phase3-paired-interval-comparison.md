# Paired Phase 3 interval study: small-cluster undercoverage

## Motivation and design

Windows R 4.6.1 independent known-truth R audit (25 October 2026):

| N independent participants | Group contrast current band | Mean current band |
|---:|---:|---:|
| 12 | 0.65 | 0.63 |
| 24 | 0.79 | 0.89 |
| 48 | 0.84 | 0.86 |

All 600 study fits completed without error; nominal simultaneous target was
0.90. The existing fixed-SE standardized participant bootstrap is
**not calibrated** by these results. The package's methods are unchanged.

## Independent comparator

`scripts/run_phase3_interval_comparison.R` pairs each identical
synthetic Gaussian generating dataset with:

- Existing fixed-SE cluster bootstrap simultaneous bands (production function)
- **Gaussian Student-t Bonferroni** simultaneous reference intervals:
  apply exact marginal Student t under independent Gaussian participant
  means, with Bonferroni over all 82 time-by-channel cells.
  Group contrasts use equal-variance pooled two-sample t and fixed arm
  sizes; participant means use one-sample t, all at the participant level.

These are deliberately conservative reference bands, not a new proposed
general-use estimator. The joint simultaneous familywise coverage is at
least nominal only under the stated Gaussian/homoskedastic generating
assumptions and if model and trial independence hold; it is not guaranteed
under real missingness, strong heteroskedasticity, non-Gaussian processes
or model selection. The reference may be much wider. Both coverage and
**average functional interval width** must be reported.

## Execute

```r
Sys.setenv(ET_INTERVAL_SIMS = '30', ET_INTERVAL_B = '199',
           ET_INTERVAL_SUBJECTS = '12,24,48')
source("scripts/run_phase3_interval_comparison.R")
```

For a more informative follow-up change to 100+ independent studies
and 399+ bootstrap draws, retaining a separate archive of earlier outputs.
Results are in `artifacts/phase3_interval_comparison/`:
`paired_interval_trials.csv`, `paired_interval_summary.csv`,
`paired_interval_failures.csv` (if needed), `MANIFEST.txt`.
All failures are retained rather than treated as covered outcomes.

**Do not release or change the underlying bootstrap methods** based only
on this study. Further factorial simulation across subject distributions,
unequal variance, missingness, variable trial counts, and seeded repeats
will be needed before selecting an improved general interval constructor.
