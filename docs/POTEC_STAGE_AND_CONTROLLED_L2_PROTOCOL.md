# PoTeC correction-stage provenance and paired v0.4.3 L2 benchmark

**Date:** 17 November 2026. The prior local audit read all 78 ASC recordings and flagged 20 extra fixation starts and 50 extra sentence-stop markers. These are not automatic errors, and ASC-to-DataViewer event truth is not yet established.

## A. Official uncorrected fixation source

The source-author [PoTeC download script](https://github.com/DiLi-Lab/PoTeC/blob/main/download_data_files.py) lists the original **fixations_uncorrected** ZIP under OSF ID **d8pyg**.

Official URL: https://osf.io/download/d8pyg

Put the downloaded ZIP under the existing Windows folder Downloads/eyetrajectoriesValidation with the name **fixations_uncorrected.zip**. Or explicitly opt in to obtaining it within RStudio:

    Sys.setenv(ET_POTEC_FETCH_UNCORRECTED="true")
    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/validate_potec_uncorrected_stage.R"
    ))

The script does not overwrite existing files. It validates archive structure, reads only the needed columns, leaves original ZIPs untouched and writes anonymized aggregation outputs.

**Critical correct join:** uncorrected (trial, fixation_index) to corrected (trial, original_fixation_index) within the same reader/text member stem. The authors' [correction script](https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/correct_fixations.py) saves ORIGINAL_CURRENT_FIX_INDEX before reindexing, may delete marked fixations and drops original gaze X/Y after correction.

Outputs: stage_unit_audit.csv, STAGE_PROVENANCE.md, R_session_info.txt. Metrics: matching original indices, source-only potentially deleted events, corrected-only unexpected IDs, preserved fixation durations, AOI differences and manual-correction flags. AOI changes are expected under drift correction and do not by themselves prove error.

**Current boundary:** this original uncorrected ZIP does NOT contain the source EFIX start/end timestamps after the authors split the DataViewer report; original stage-to-ASC timing requires the upstream full fixation report with event timestamps and exact session/trial markers. The reader 21/0 identifier exception must be honored. No source-to-corrected timing parity is claimed by this audit.

## B. Archived versus optimized algorithm on exactly the same input

Run in RStudio:

    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/benchmark_paired_l2_versions.R"
    ))

The script uses original OneStop fixation data locally, selects eligible trajectories and places them on explicitly interpolated normalized-time grids. It compares n=250/500/1000 curves at grid 64/128 with randomized method order and three paired repetitions after warmup.

Sources pinned to exact GitHub history:

- Archived v0.4.3 R/native-distances.R blob SHA-1: acc135d35133e07c1fd32e947aaa0c9a6d45be8b
- Vectorized development commit 8920ec907677b994078720bdb5ecd2afbcc832bb; corresponding R/native-distances.R blob SHA-1: 8d243b0736da7bdc5d964678b17412baa24b9a13

Exact original pairwise function bodies are evaluated on the **same R trajectory object**, using common native numerical helpers and a backward-compatibility argument shim for archived python_boundary_mode=FALSE. This is a **source-algorithm controlled comparison**, not simultaneous installation of two independent package namespaces.

For each condition the benchmark requires full pairwise numerical agreement within 1e-8 and an independent trapezoidal reference check for selected pairs, failing before it records speedups on incorrect outputs.

Outputs: paired_l2_repetitions.csv, paired_l2_summary.csv, PAIRED_BENCHMARK_PROTOCOL.md and R_session_info.txt. Source ZIPs and raw participant records are never exported.

CI executes reduced **synthetic** versions of both validation suites. It cannot certify the full real PoTeC stage correspondence or real OneStop speedup until the local files are processed.

## Remaining scientific gates

Full stage-appropriate ASC to original DataViewer event-time correspondence, external eye-tracking calibration ground truth, statistical-model uncertainty calibration, and comparable per-call isolated peak process memory remain open. No source archives, frozen releases, benchmark histories or Zenodo DOI are modified.
