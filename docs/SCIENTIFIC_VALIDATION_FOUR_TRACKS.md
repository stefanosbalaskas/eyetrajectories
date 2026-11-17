# Four-track scientific qualification — executable programme (17 November 2026)

**Status:** New reproducible test infrastructure. Synthetic CI is not certification of scientific correctness on the original human data. No original ZIP is uploaded or changed. The published v0.4.3 software archive remains immutable. The default main branch has a different version; local runs must retain R_session_info.txt.

## Primary PoTeC sources

- Jakobi et al. (2025), PoTeC: A German naturalistic eye-tracking-while-reading corpus, Behavior Research Methods. https://doi.org/10.3758/s13428-024-02536-8
- Author preprocessing documentation: https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/PREPROCESSING_SCRIPTS.md
- Author source-format documentation: https://github.com/DiLi-Lab/PoTeC/blob/main/eyetracking_data/EYETRACKING_DATA.md

PoTeC raw ASC sessions, sample-level TSVs, Data Viewer fixation reports, uncorrected fixations, manually corrected fixations and derived scanpaths are distinct stages. Correction can remap the fixation-to-character association, delete an event and reindex fixation records. Therefore corrected fixations are NOT a valid literal oracle for raw ASC coordinates or timings. ASC reader ID 21 may correspond to corrected reader 0. The 905 raw/uncorrected versus 900 corrected trial count is a documented provenance exception, not necessarily an error.

## Four reproducible scripts

### A — Raw ASC event structure: scripts/science_validate_potec_asc.R

Source read-only asc_files.zip, count messages, fixation/saccade/blink markers, extract EFIX timing validity, sample timestamp reversals and trial start/stop markers; label every truncated ASC member. By default all 78 members are selected with a cap of 200,000 lines each; set ET_SCI_ASC_MAX_LINES=0 for complete-file reading. Results: asc_source_events.csv, ASC_SCOPE_REPORT.md, R_session_info.txt. This script does NOT claim independent fixation event truth or ASC-to-corrected-fixation equivalence. The uncorrected Data Viewer report, stage-specific trial/event keys, correction logs and original annotations are required for actual raw-to-derived scientific validation.

### B — Independent model oracles: scripts/science_validate_models.R

Synthetic known-truth dense FPCA on an irregular grid, independent base-R weighted covariance eigenvalues, score projection and reconstruction. Scalar-on-FPCA regression compared to independent QR least squares. Participant-held-out prediction with FPCA trained on training subjects only. Optional sparse PACE adapter comparison with fdapace::FPCA, clearly flagged as same-backend interface parity rather than independently coded PACE. Results: model_oracles.csv, MODEL_SCOPE.md, R_session_info.txt. Refund functional-response mixed model and statistically calibrated sparse PACE uncertainty are NOT covered by this first suite.

### C — Known-truth inferential calibration: scripts/science_inference_calibration.R

Monte Carlo for participant-cluster mean confidence bands and a deliberately invalid naive trial-IID comparator. Design includes complete, MCAR, covariate-driven MAR and latent-subject MNAR trial deletion. Reports simultaneous and pointwise truth coverage, null false-positive rate, exact binomial Monte Carlo intervals, mean bias, precision and observed fraction. Defaults: 100 simulations per scenario, B=199 bootstrap resamples, 30 subjects. No automatic nominal-coverage certification. Results: coverage_calibration_summary.csv, monte_carlo_replicates.csv, INFERENCE_SCOPE.md and R_session_info.txt.

### D — Cross-platform runtime and memory: scripts/science_benchmark_multiplatform.R

Reads local real OneStop repeated fixation ZIP with only five required columns and uses deterministic complete trial trajectories plus explicit normalized-time interpolation. Synthetic data are labeled distinctly. Evaluates 250/500/1000 curves on 64/128 grids for native pairwise L2 and MFPCA, with warmups and timing repetitions. Reports expression-level peak allocation via peakRAM when available. Linux also reads process-wide VmHWM high-water resident memory since process launch; this is NOT per-function peak RSS. Windows/macOS peak process RSS is NOT measured in this iteration. Results: benchmark_repetitions.csv, benchmark_summary.csv, BENCHMARK_SCOPE.md and R_session_info.txt. Do not make cross-platform relative speed claims without matched hardware.

## Local RStudio execution after merge

    root <- file.path(Sys.getenv("USERPROFILE"), "Downloads", "eyetrajectoriesValidation")
    Sys.setenv(ET_SCI_ROOT=root,
               ET_SCI_ASC_NO_AUTORUN="true",
               ET_SCI_MODEL_NO_AUTORUN="true",
               ET_SCI_MC_NO_AUTORUN="true",
               ET_SCI_BENCH_NO_AUTORUN="true")
    base <- "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/"
    for (s in c("science_validate_potec_asc.R",
                "science_validate_models.R",
                "science_inference_calibration.R",
                "science_benchmark_multiplatform.R")) source(url(paste0(base,s)))
    asc <- sci_validate_potec_asc(root=root,max_files=78L,max_lines=200000L)
    models <- sci_validate_models(run_sparse=requireNamespace("fdapace",quietly=TRUE))
    inference <- sci_calibrate_inference(repetitions=100L,B=199L,n_subjects=30L)
    scaling <- sci_benchmark_multiplatform(root=root,source_mode="real",
                        sizes=c(250L,500L,1000L),
                        grids=c(64L,128L),repetitions=3L)

## Evidentiary limitations and follow-up

Synthetic CI passing verifies tested implementation contracts only. Independent scientific certification requires source-stage/event mapping against original uncorrected exports with ground-truth labels, model-wise reference oracles, prespecified Monte Carlo calibration thresholds and adequate simulation sizes, comparable process peak memory on fresh child processes across systems, and exact-release-branch evidence. OneStop and PoTeC should not be joined on guessed participant identifiers.
