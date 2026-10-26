# Native R parity: official R ecosystem review (26 October 2026)

This research branch is NOT a release. The Python root API has 362 public
functions and workflows has 18: 380 Python-backed R wrappers were already
available. The original R package had 88 native scientific exports; this
branch adds 10 narrow methods, giving 98 native exported functions.
The author executed the 0.4.1.9000 full CRAN-style Windows check with
0 errors, 0 warnings, 1 incoming NOTE; all package tests, Rd examples and
both manuals passed. The numerical demonstration ran successfully.
This evidence does not establish scientific equivalence or coverage.
The Python public API inventory remains unchanged.

## Official package audit

The [CRAN Functional Data Task View](https://CRAN.R-project.org/view=FunctionalData)
is a curated overview, not a proof of equivalence. Matching a package name
to a Python capability must not be represented as reproducing its estimator.

| Scientific family | Specialist R packages and boundaries |
| --- | --- |
| Functional data structures | [fda](https://CRAN.R-project.org/package=fda), [fda.usc](https://CRAN.R-project.org/package=fda.usc), [tf](https://CRAN.R-project.org/package=tf), [funData](https://CRAN.R-project.org/package=funData): representation and smoothing, different missing-data contracts |
| MFPCA | [MFPCA](https://CRAN.R-project.org/package=MFPCA): functional domains of different dimensions, not automatic cross-channel asynchronous PACE |
| Sparse FPCA | [fdapace](https://CRAN.R-project.org/package=fdapace): PACE covariance and scores; currently a qualified-interface candidate, numerical qualification incomplete |
| Functional mixed models | [denseFLMM](https://CRAN.R-project.org/package=denseFLMM), [sparseFLMM](https://CRAN.R-project.org/package=sparseFLMM), [refund](https://CRAN.R-project.org/package=refund), [mgcv](https://CRAN.R-project.org/package=mgcv): covariance refit and robust inference remain unverified |
| Functional regression | [refund](https://CRAN.R-project.org/package=refund), [FDboost](https://CRAN.R-project.org/package=FDboost): penalized and boosting estimands differ from Python |
| Registration | [fdasrvf](https://CRAN.R-project.org/package=fdasrvf), [registr](https://CRAN.R-project.org/package=registr): elastic and joint phase/FPCA methods, not the native landmark-only interpolation implemented here |
| Prediction and conformal | [conformalInference.fd](https://CRAN.R-project.org/package=conformalInference.fd): exchangeable functional prediction regions; new native scoring is independent per-curve anomaly screening only |
| Simultaneous means / cluster inference | [SCBmeanfd](https://CRAN.R-project.org/package=SCBmeanfd), [clubSandwich](https://CRAN.R-project.org/package=clubSandwich): valid competitors to audit, not automatic fixes for clustered multivariate simultaneous coverage |
| Recurrence and nonlinear time series | [crqa](https://CRAN.R-project.org/package=crqa), [casnet](https://CRAN.R-project.org/package=casnet), [nonlinearTseries](https://CRAN.R-project.org/package=nonlinearTseries), [rEDM](https://CRAN.R-project.org/package=rEDM): RQA, embeddings, Lyapunov and EDM under distinct conventions |
| Information theory | [RTransferEntropy](https://CRAN.R-project.org/package=RTransferEntropy), [infotheo](https://CRAN.R-project.org/package=infotheo), [entropy](https://CRAN.R-project.org/package=entropy): Shannon/Renyi TE and discrete entropy/bias methods, inferential null validity design-specific |
| Anomaly detection and ML | [fdaoutlier](https://CRAN.R-project.org/package=fdaoutlier), [mlr3fda](https://CRAN.R-project.org/package=mlr3fda): depth outliers and functional ML feature pipelines |

The exported native backend inventory checks the presence/version of 26
candidate packages without installing them. Being installed does not imply
the methods have passed tests or are mathematically equivalent.

Compatibility caution: CRAN fdasrvf 2.5.0 requires R >= 4.3, while
eyetrajectories declares R >= 4.2. MFPCA source builds may require FFTW3.
Keep these as OPTIONAL and document platform constraints before integration.
Consult [CRAN policy](https://CRAN.R-project.org/web/packages/policies.html)
and [Writing R Extensions](https://CRAN.R-project.org/doc/manuals/r-release/R-exts.html)
for conditional Suggests and cross-platform behavior.

## Staged experimental native work

1. Exact, monotone piecewise-linear landmark registration with fixed
   endpoints and retained inverse warps; not learned elastic alignment.
2. Delay embedding and one-dimensional threshold return maps; no
   Lyapunov exponent or causal dynamics claims.
3. Undirected binary auto-recurrence network (density, degree, clustering,
   transitivity, triangles and components), preserving Theiler exclusions.
   Time samples are graph nodes, not independent research participants.
4. Split-conformal FPCA reconstruction anomaly screen using a model
   frozen before disjoint calibration/test curves. Only independent,
   exchangeable per-curve marginal interpretation; no batch-wise or
   within-participant dependence guarantee.
5. Local version/availability catalogue of 26 official R packages.

All are independent native R routines under narrow stated estimands.
They are NOT one-to-one translations of all Python alternatives.

## Still missing from genuine native Python parity

- Sparse joint asynchronous multivariate FPCA with cross-channel covariance,
  informative observation mechanisms, fitted score uncertainty and oracles.
- Functional mixed-effects nested covariance and full-refit inference.
- Generalized functional regression, nonlinear predictions, grouped/nested
  model selection, robust wild bootstrap and prediction bands.
- Data-driven SRVF/elastic amplitude-phase, compositional and selection-safe
  registration, and robust longitudinal phase modelling.
- Nonlinear Lyapunov and recurrence-network spectral null models,
  surrogate methods and conditionally valid transfer entropy.
- Empirically calibrated 90 percent simultaneous functional mean and
  treatment contrast bands at low participant counts. Earlier fixed-SE
  clusters showed serious undercoverage; this stage does not alter them.
- Cross-platform Windows/Linux/macOS R checks, external optional dependency
  version combinations, and per-family Python-R numerical parity tests.
- Public CRAN metadata and publication policy. No release is authorized.

## Qualification command (owner-run, after checking out branch)

Run the narrow offline tests first, then the full existing check script:

    Sys.setenv(ET_RUN_PYTHON_TESTS = "false", MPLBACKEND = "Agg")
    testthat::test_local(".", filter = "native-parity-stage1",
                         reporter = "summary")
    source("scripts/local_qualification.R")
    source("scripts/run_cran_qualification.R")
    pkgload::load_all(".", quiet = TRUE)
    etr_r_backend_catalog()

The author has since executed R 4.6.1 / Windows 11 full --as-cran checks
on this 0.4.1.9000 research branch (0 errors, 0 warnings, 1 incoming NOTE),
including the package test suite. The original native example and capability
audit also executed successfully; this is local engineering evidence, NOT
an independent numerical/coverage qualification. Newly revised noisy
demonstration and extended tests have not yet been rerun. Do not merge or
submit until the revised fixtures, platform checks and independent scientific
methods audit are reviewed.

## Exhaustive 380-function inventory and exercise scripts

The audit includes a committed, reproducible full-API mapping:
[inst/extdata/native_parity_gap_matrix_2026-10.csv](../inst/extdata/native_parity_gap_matrix_2026-10.csv).
It contains **380 rows**, one for every root/workflow callable exported by the
2026-10-25 Python snapshot. For each function it records Python namespace,
its callable R wrapper, method family, officially documented candidate
R packages, validation priority, a manually selected possible native analog
(if one exists), and **not independently qualified** numeric parity status.
The 37 possible analog labels are only investigation leads, not 37
successfully reproduced Python contracts.

The separate five-page native example is available at
[scripts/run_native_parity_stage1_demo.R](../scripts/run_native_parity_stage1_demo.R)
and writes synthetic plots and numerical evidence under the ignored folder
artifacts/native_parity_stage1/. Its original deterministic version ran in the author's Windows R session;
the revised noise-bearing demonstration is pending rerun.

```r
source("scripts/run_native_parity_stage1_demo.R")
source("scripts/report_python_r_capabilities.R")
```

The second command now expects 98 native R exports on this branch and will
report 380 Python-backed wrappers separately. It does not certify numerical
parity. All real-data and simulation-estimator validation remains open.

## Windows engineering evidence and limitations (26 October 2026)

The author successfully ran the native parity research demonstration and the
complete `R CMD check --as-cran` for development version 0.4.1.9000 on
Windows 11 / R 4.6.1. The result was **0 errors, 0 warnings, 1 CRAN incoming
NOTE**, and the standalone native smoke example completed. The resulting
capability inventory correctly reports 98 native functions, 380 Python
wrappers, 14 legacy bridges, 3 catalog utilities, 37 possible analog names
and **zero qualified cross-language estimator contracts**. This run includes
package testthat, Rd examples, and PDF/HTML manuals but does not constitute
an independent methodological oracle or cross-platform check.

The initial supplied demo used a 0.30 recurrence radius that produced only
3 edges among 41 sampled time nodes, and a near machine-precision conformal
cutoff (approximately 1.38e-16) because the rank-one deterministic curves
were almost exactly reconstructed. These are reproducible software outputs,
not informative stochastic calibration benchmarks. The follow-up demo now
shows both 0.30 and 0.70 graph radii and uses seeded independent noise with
19 calibration curves, two ordinary held-out curves and two deliberately
shifted curves. These refinements have **not yet been run in RStudio**.

The test file also adds an independent seeded nondegenerate calibration case.
No estimator's mathematical definition was changed, and the draft PR
remains unmerged pending the updated demonstration and test rerun.

## Revised Windows test evidence and independent deterministic oracles

The owner reran the revised tests on 26 October 2026 (Windows 11,
R 4.6.1): `testthat::test_local(filter="native-parity-stage1")`
completed with **no failures**, the revised native demonstration ran,
the source capability audit returned **98 native functions, 380 Python
callable wrappers, 37 candidate analogs and zero qualified cross-language
contracts**, and `R CMD check --as-cran` completed with **0 errors,
0 warnings, 1 incoming development-version NOTE**, including complete
help examples, package tests and PDF/HTML manuals.

Revised synthetic demonstration: radius 0.30 gives 3 recurrence edges,
while radius 0.70 yields 129 edges, one connected component and
transitivity 0.24818578. The noisy conformal illustration has 19
calibration curves, threshold 0.06175659, no flags among its 2 ordinary
test curves and flags among both deliberately shifted test curves.
This is **not** an estimated false-positive rate, anomaly power,
or proof of an exchangeable coverage guarantee. It only verifies
a single constructed reproducible example.

A new no-dependencies independent calculation was added at
[`scripts/check_native_parity_stage1_oracles.py`](../scripts/check_native_parity_stage1_oracles.py).
Its mathematical references are 3 recurrence edges with radius 0.30;
at 0.70, 129 edges, 57 triangles, 689 connected triples and
transitivity **171/689 = 0.24818577648766327**.
It separately verifies simple registration landmarks, lag embedding,
return-crossing interpolation, and split-conformal order statistics
(n=19, alpha=.10, order-statistic rank 18). It does not invoke
the R implementation and does not qualify covariance inference.

**Decision:** Windows implementation validation is complete for this
development branch. The native methods remain experimental until
other-platform checks and independent behavioral/coverage studies.
This work does not qualify the existing under-covering simultaneous bands
or authorize CRAN publication.
