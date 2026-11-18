# Research-first scientific architecture and four flagship workflows

**Baseline:** published GitHub eyetrajectories v0.4.3, not development main (0.4.0.9000). **No stable tag, CRAN release, original human dataset, or Zenodo deposit is modified by this project.**

## Methodological tiers are not scientific certificates

| Proposed tier | Intended role | Boundary |
| --- | --- | --- |
| Core | Trajectory representation, validation, preprocessing, distances, dense FPCA/MFPCA and essential plots | Numerical and real-data qualifications apply only to explicitly tested methods and versions |
| Advanced | Sparse estimation, functional regression, mixed and multilevel models, participant bootstrap | Scientific inference can remain experimental until its coverage and assumptions are independently evaluated |
| Experimental | Nonlinear methods, recurrence/entropy, specialty estimators and bridge interfaces | Availability never implies Python source equivalence, causal identification, or calibrated inference |

A tier specifies **intended role**, while a separate evidence_status specifies the **available evidence**. The authoritative curated file is inst/method-registry/curated-evidence.json, covering 41 explicitly reviewed exports. The source-derived generator scripts/generate_scientific_method_registry.py extracts **all 904 exported names from immutable v0.4.3 NAMESPACE** and builds a full JSON/CSV registry. The other entries are clearly marked **provisional lexical classifications** with no curated evidence record; this does not mean they have no tests.

Execution backend is also explicit: native-R, R delegating to fdapace or refund, optional Python bridge, or mixed facade. An interface is not necessarily an independent estimator. In particular, etr_fit_multilevel_fpca is a descriptive participant/within-trial decomposition; etr_fit_functional_mixed delegates to refund::pffr, etr_fit_sparse_pace delegates to fdapace::FPCA, and etr_bootstrap_mean_band has a limited Monte Carlo coverage record.

## Four flagship reproducible research examples

**All data are synthetic.** None of these examples should be presented as human gaze experiments. All scripts are in inst/examples/flagship and use the published R 0.4.3 native API:

| Workflow | Executable R script | What it demonstrates | What it does not establish |
| --- | --- | --- | --- |
| 01 Complete gaze trajectory | 01_complete_gaze_trajectory.R | Source-aware trajectory object, distances, MFPCA, scores, reconstruction | No condition significance or causal inference |
| 02 Multilevel variation | 02_multilevel_functional_variation.R | Participant/trial design and descriptive two-stratum FPCA | Not a REML random-effects model or calibrated component-variance inference |
| 03 Sparse recovery | 03_sparse_irregular_recovery.R | Irregular observation times, known analytic truth, optional fdapace PACE, RMSE | Not an independent PACE implementation or broad sparse/missingness validation |
| 04 Uncertainty-aware comparison | 04_uncertainty_paired_contrast.R | Participant-aggregated paired differences, pointwise/simultaneous bands | One simulation does not establish 95% frequentist coverage |

Each script writes method-specific CSV results, **three vector PDF figures**, a standalone METHODS_AND_LIMITATIONS.md, and sessionInfo.txt. The scripts never fetch or write private source data.

### Run locally after checking out the source and installing v0.4.3

    stopifnot(as.character(packageVersion("eyetrajectories"))=="0.4.3")
    install.packages("fdapace")  # optional R dependency for workflow 03
    Sys.setenv(ET_FLAGSHIP_OUTPUT=file.path(getwd(),"flagship_results"))
    for (script in c(
       "01_complete_gaze_trajectory.R",
       "02_multilevel_functional_variation.R",
       "03_sparse_irregular_recovery.R",
       "04_uncertainty_paired_contrast.R")) {
       source(file.path("inst","examples","flagship",script))
    }

The CI workflow runs all four against a separate exact v0.4.3 checkout on Ubuntu, Windows and macOS. A passing synthetic CI is an execution and contract gate, **not a claim that every scientific estimator in the package is certified**.

## Evidence and limitations

The current empirical evidence includes selected OneStop numerical checks, an optimized-versus-archived L² source-function comparison using matched real fixation trajectories, a source-integrity PoTeC audit, known-truth sparse PACE diagnostics and 400 participant-bootstrap Monte Carlo datasets.

The PoTeC original-index crosswalk has 404,418/404,420 uniquely matched corrected fixations; two rows remain ambiguous without the original Data Viewer source/correction record. The L² fastpath is being ported to a separate v0.4.3-based release candidate and is not yet a published v0.4.4 release.

The bootstrap experiment demonstrated 96% simultaneous coverage for complete data and 90–92% across three tested missingness scenarios (100 simulations each); this is not universal statistical calibration.

See docs/SCIENTIFIC_VALIDATION_RESULTS_20261117.md, docs/POTEC_REAL_SOURCE_AND_L2_RESULTS_20261118.md and docs/POTEC_DUPLICATE_PAIR_AUDIT_20261118.md. Eye-tracking study reports should follow the study-relevant reporting fields of the Minimal reporting guideline for research involving eye tracking: https://doi.org/10.3758/s13428-023-02187-1.

## Website information architecture

Retain the existing ten-route Research Workflow Portal and tested R Plot Atlas. Add a **Methods Atlas** containing the source-verified 904 method records, search and tier/backend/evidence filters, with visibly provisional classifications. Add a **Flagship Workflows** page with explicit synthetic provenance, mathematics, downloadable R source, limitations, and links to reference documentation.

The website build reads the exact stable v0.4.3 NAMESPACE for its method index and reads the curated evidence source from the separate research development branch. No browser R execution or gaze data upload is represented as occurring.

## Scientific and release qualification gates

- Complete 904-export namespace/registry consistency, documented backend and method-specific limitations.
- Actually execute all four end-to-end examples on exact v0.4.3 on the planned OS matrix and check generated PDF/CSV outputs.
- Keep a strict distinction between numerical tests, simulation studies, real-source provenance and external truth.
- Keep any unsupported confidence bands and covariance inference explicitly experimental.
- Qualify release candidate PR #211 with package-wide CRAN-style checks and an independently installed real-input benchmark before a new stable tag or Zenodo release.

**Desired outcome:** researchers first choose a valid analysis for their experimental design, then inspect the exact method, required data, reproducible example, evidence and methodological limitations.
