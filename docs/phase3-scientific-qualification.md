# Phase 3 scientific qualification (experimental)

Phase 3 is committed directly to main at the owner's instruction. No CRAN
release has been made. Version 0.3.2.9000 is a development version and all
advanced methods are experimental until independent validation is completed.

## Scope

Sparse univariate PACE is delegated to the R package fdapace::FPCA using
dataType Sparse and methodXi CE. This is not an independent PACE algorithm
or multivariate/asynchronous sparse FPCA.

Two-level FPCA separates equally weighted participant mean curves from trial
residual curves. This is descriptive variance decomposition, not a REML
functional mixed-effects model.

Mean confidence bands resample independent participants, not correlated
trials. Pointwise percentile and studentized maximum bands are exploratory:
nominal coverage is unverified.

Transfer entropy is plug-in discrete conditional mutual information based
on user-declared finite state sequences and lags. Circular source shifts are
a descriptive sensitivity analysis; directional findings do not imply
causality, and permutation p values are not universally calibrated.

Advanced workflows carry estimator settings and an explicit experimental
scientific status. None adds inferential qualification.

## Independent scientific testing

- tests/testthat/test-advanced-methods.R covers input validation, hierarchical
  decomposition, RNG isolation, deterministic transfer direction and optional
  fdapace integration.
- etr_simulate_sparse_known_truth creates independent rank-one sparse curves.
- etr_evaluate_sparse_pace_recovery measures truth-based reconstruction errors
  and retains failure records.
- etr_simulate_hierarchical creates known-truth participant/trial curves.
- etr_evaluate_multilevel_recovery checks mean curve recovery.
- etr_evaluate_mean_band_coverage measures finite-sample coverage with MC error.
- None of these checks has been confirmed to pass in GitHub Actions; the
  pre-existing Actions infrastructure failure remains unresolved.

## Qualification requirements

Restore R CMD check and integration jobs. Expand sparse PACE simulation across
observation densities and missingness; quantify multilevel estimator biases;
measure mean-band empirical coverage for non-Gaussian and unequal cluster
designs; test transfer-entropy false-positive rates under autocorrelated
nulls. Require Linux, macOS and Windows checks. Do not promote scientific
inference claims until independently replicated.

Methods background:
- https://search.r-project.org/CRAN/refmans/fdapace/html/FPCA.html
- https://stat.ethz.ch/CRAN/web/packages/RTransferEntropy/vignettes/transfer-entropy.html
- https://mirror.linux.duke.edu/pub/cran/web/packages/funbootband/vignettes/funbootband-intro.html
