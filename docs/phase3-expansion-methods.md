# Phase 3 extension — scientific contracts and simulation evidence

**Package development version 0.3.2.9000.** The expanded methods, including the 3 independent FPCA-spectrum and analytic
variance functions, extend the 20 earlier experimental Phase 3 functions.
There are now 88 native R exports and 14 optional reticulate bridge exports.

All scientific results produced by the supplied examples and audit runner
are **synthetic known-truth outcomes**. They must not be presented as
observations from recorded eye-tracking studies.

## Sparse functional modelling

Sparse input is retained as per-curve sorted time/value vectors. The
\`etr_sparse_design_diagnostics()\` support table reports the fraction of
curves represented in each interval of observed time. Sparse regions and
snippet designs can make covariance estimation unreliable, as warned in
the fdapace documentation. Conditional-expectation scores and reconstruction
remain supplied by fdapace, not a reimplemented PACE estimator.

\`etr_fit_marginal_sparse_pace()\` fits separate univariate PACE models to
each functional channel with identical curve identifiers but possibly
different observation times. **It is not a joint sparse multivariate FPCA,
does not estimate cross-channel covariance or cross-channel eigenfunctions,
and does not establish equivalence with the Python asynchronous model.**

## Functional regression

\`etr_fit_functional_mixed()\` delegates optional functional-response REML
fitting to refund::pffr. An optional participant random functional intercept
can be specified for complete univariate common-grid responses. Only
\`method="REML"\` is enabled in this experimental adapter. The implementation
does not yet qualify estimation uncertainty or prediction intervals under
heterogeneous nested eye-tracking observation processes.

\`etr_fit_scalar_on_fpca()\` fits Gaussian ordinary least squares to retained
native FPCA scores. Its standard errors are conditional on the estimated
scores, not accounting for FPCA measurement error or clustering. Use
\`etr_grouped_fpca_crossval()\` for participant-disjoint holdouts. Crucially,
each training fold fits its own functional principal component basis; no
held-out curves enter the PCA, scales, regression or model-selection process.
The number of components is **fixed in advance**, not tuned on the holdout.

## Experimental functional mean contrasts

\`etr_bootstrap_group_contrast()\` first computes participant-average
functions and then independently resamples participant means within the
two study groups. Group ordering is deterministic (lexicographic);
the returned contrast explicitly states "second group minus first group".
The bootstrap uses percentile pointwise intervals and max-studentized
simultaneous bands with sample-based standard errors. No additional
small-cluster correction or guaranteed finite-sample nominal coverage
is asserted.

\`etr_simulate_group_contrast()\` generates independently randomized
participant treatment allocation with a known vector-valued true contrast.
\`etr_evaluate_group_contrast_coverage()\` reports actual empirical whole-
function inclusion, mean pointwise inclusion, effect RMSE and Monte Carlo
SE. Do not cherry-pick only simulations meeting a target error criterion.

## Transfer entropy and finite-sample bias

Discrete \`etr_transfer_entropy()\` estimates a plug-in conditional mutual
information given explicit source and target history lengths. For continuous
series, \`etr_discretize_states()\` makes equal-width or quantile boundaries
explicit. Quantile ties are not silently merged. In predictive settings,
determine thresholds in a training sample to prevent leakage.

\`etr_effective_transfer_entropy()\` subtracts the mean TE of independently
shuffled source sequences. This is a **bias diagnostic** and shuffling
destroys the source's serial dependence. It is distinct from the earlier
circular-shift sensitivity diagnostic. Neither procedure alone guarantees
exchangeable null surrogates or valid significance for autocorrelated
observational signals.

\`etr_simulate_te_null()\` generates two independent Markov processes with
within-process persistence and **zero generating cross-series effect**.
\`etr_evaluate_te_null()\` reports the fraction of circular-shift surrogates
flagging a predetermined threshold, explicitly labelled as a *diagnostic
flag rate*, not a proven type-I error probability.

## Sign-invariant FPCA spectrum and analytic variance oracle

`etr_bootstrap_fpca_spectrum()` resamples independent participant-mean curves,
refits dense FPCA on every draw, and returns eigenvalue percentile intervals
along with **every failed replicate**. This guards against arbitrary eigenvector
sign flips when comparing spectra. It is not a calibrated eigenfunction or
simultaneous band method.

`etr_analytic_between_variance()` derives the integrated between-participant
variance of the independent hierarchical generator directly from its sine/cosine
basis and known subject/trial/noise variances. The analytic identity is
orthogonal to the FPCA estimation code. The Monte Carlo audit
`etr_evaluate_between_variance()` records integrated covariance-trace bias,
root-mean-square error and Monte Carlo uncertainty. A correct theoretical
trace does not guarantee small-sample coverage or extend to informative gaze
missingness.

## Reproducible validation and plots

Run from the repository root after installing the development package:

~~~sh
ET_PHASE3_SMOKE=true Rscript scripts/run_phase3_validation.R artifacts/phase3
~~~

For a larger Monte Carlo grid and optional sparse PACE:

~~~sh
ET_PHASE3_SMOKE=false ET_PHASE3_INCLUDE_PACE=true \
  Rscript scripts/run_phase3_validation.R artifacts/phase3
~~~

The runner writes failure-inclusive CSV tables and a manifest containing
the package version and available Git SHA. The base R PDF includes known-truth
contrasts, sparse support and a TE surrogate distribution. None of the plots
will exist until the script actually runs.

CI definition: .github/workflows/phase3-simulation.yaml.
Tests: tests/testthat/test-phase3-expansion.R.
**These files are committed, but execution has not been verified.**

## Dependencies, research and evidence

- fdapace FPCA options and sparse-design caveat:
  https://search.r-project.org/CRAN/refmans/fdapace/html/FPCA.html
- refund pffr REML and functional random intercept documentation:
  https://search.r-project.org/CRAN/refmans/refund/html/pffr.html
- RTransferEntropy discussion of finite-sample bias:
  https://stat.ethz.ch/CRAN/web/packages/RTransferEntropy/vignettes/transfer-entropy.html
- CRAN package-check discipline:
  https://r-pkgs.org/R-CMD-check.html

These references motivate the **scope** of the methods, not validated
equivalence with any other implementation.

## Outstanding scientific gates

1. Restore GitHub Actions jobs before interpreting tests as passed.
2. Independently reproduce simulation outputs on multiple R versions/OSes.
3. Verify fdapace and refund adapter output shapes, convergence, warnings,
   residuals and numerical plausibility on genuinely sparse/nested fixtures.
4. Establish coverage under unbalanced clusters, heteroskedasticity, heavy
   tails and observation-dependent missingness; include failures in tallies.
5. Assess time-grid sensitivity and covariance rank/condition-number effects.
6. Test TE null false-signal behaviour under longer histories, different
   bin boundaries, persistence values, time shifts and latent common causes.
7. Validate multiple-person lab eye-tracker fixtures and documented
   coordinate/time-unit standards before claiming production usability.
8. Obtain independent reviewer evidence and a formal release decision.
