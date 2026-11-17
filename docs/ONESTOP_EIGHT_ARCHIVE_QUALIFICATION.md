# OneStop: eight-archive qualification protocol (R only)

> **Corpus attribution and validation update (17 November 2026):** The two paragraph fixation CSVs and their interest-area exports are from **OneStop**; the 900-file `scanpaths`, `scanpaths_merged` and `fixations` TSV families and the related ASC recordings are from the independent **Potsdam Textbook Corpus (PoTeC)**. The 198,985 PoTeC raw label mismatches are accounted for by the source authors' documented `bio` versus `biology` spellings. This page records an earlier stage of the protocol, not the latest conclusion. See [PoTeC codebook reconciliation](POTEC_CODEBOOK_RECONCILIATION.md) and the [official authors' codebook](https://github.com/DiLi-Lab/PoTeC/blob/main/CODEBOOK.md). No OneStop–PoTeC participant join is justified.

**Status (17 November 2026): validation pipeline prepared; seven source archives not yet independently executed here.** No result in this protocol constitutes completed scientific certification.

## Scope and evidence levels

The local folder shown in the user's Windows screenshot contains the following eight source ZIP archives:

| Source ZIP | Primary intended audit | Initial evidence status |
| --- | --- | --- |
| fixations_Paragraph_repeated.csv.zip | Fixation-level positions, timestamps and trial integrity | Prior 1,000-trajectory benchmark: 21/21 numerical checks; archive-wide scientific qualification incomplete |
| fixations_Paragraph_ordinary.csv.zip | Ordinary-reading fixation positions and timestamp integrity | No inspected source-level qualification report yet |
| ia_Paragraph_repeated.csv.zip | Interest-area event schema, category definitions and event timings | No inspected source-level qualification report yet |
| ia_Paragraph_ordinary.csv.zip | Ordinary-reading interest-area events and consistent identifiers | No inspected source-level qualification report yet |
| scanpaths.zip | Sequences, order, event transitions and derivation lineage | No inspected source-level qualification report yet |
| scanpaths_merged.zip | Merged scanpaths, merge keys, ordering, cross-file identities | No inspected source-level qualification report yet |
| fixations.zip | Generic fixation exports and comparison against paragraph subsets | No inspected source-level qualification report yet |
| asc_files.zip | Original ASC event/sample provenance and recording quality | No inspected source-level qualification report yet |

**Prior benchmark:** Real OneStop repeated-reading fixation CSV, archive MD5 650d93a8c73af6a9b3ca19a7c4e542fb; 144,245 source rows read, 1,944 trials, 1,878 eligible and 1,000 deterministically selected. Both baseline and optimized benchmarks passed 21/21 declared numerical checks. This evidence covers *specified functions and preprocessing contracts*, not all archive representations, raw 1,000 Hz data, calibrated inference or independent external ground truth.

## Run the local evidence intake in RStudio

1. Save [scripts/qualify_onestop_eight_archives.R](../scripts/qualify_onestop_eight_archives.R) to the PC.
2. Check the eight ZIP files are direct children of the Downloads/eyetrajectoriesValidation directory. The script **does not** modify them, extract them to disk, upload them or overwrite old benchmark outputs.
3. Run source(file.choose()) and select the saved R file. The default root is file.path(Sys.getenv("USERPROFILE"), "Downloads", "eyetrajectoriesValidation").
4. For another root, run Sys.setenv(ET_EIGHT_ARCHIVE_ROOT = "C:/your/folder") before sourcing. Set Sys.setenv(ET_EIGHT_ARCHIVE_HASH_LARGE = "true") if desired to compute MD5 of archives larger than 100 MiB (including the large ASC archive); this adds significant local I/O time.
5. Review the new timestamped EYETRAJECTORIES_EIGHT_ARCHIVE_QUALIFICATION_* folder.

Files:

- archive_inventory.csv: source existence, ZIP readability, member counts and source MD5 where computed.
- member_schema.csv: actual sampled member headers, selected participant/trial/time/x/y fields, row cap and parsing outcomes. ASC is event-type count intake only.
- numeric_checks.csv: transparent per-source status, eligible sampled trials, independent L² reference errors, symmetry and independent weighted-SVD explained-variance checks where the fields support them.
- VALIDATION_SUMMARY.md: human-readable coverage matrix and qualifications.
- run_log.txt and R_session_info.txt: process and package provenance.

**Safety and privacy:** The audit emits *aggregated counts and numerical discrepancies only*. It does not export raw participant traces or source samples. No Python is invoked by the native checks.

## Acceptance levels

1. **Available/readable source:** source ZIP exists; manifest and supported members can be enumerated; name and hash recorded where requested.
2. **Input compatibility:** actual fields, data types, unique trial/time semantics, missingness and duplicate timestamps are audited. Limited rows or members must be labelled *sampled*, never full coverage.
3. **Computational numerical contract:** using complete sampled fixation trajectories, compare the package's distance matrix to independently calculated trapezoid L² pairs; compare MFPCA explained-variance ratio with a separately constructed weighted SVD; verify symmetry, exact diagonal and curve IDs. A PASS is limited to these operations and selected sampled curves.
4. **Cross-representation agreement:** requires explicit and verified source crosswalks between original ASC events, fixation exports, interest-area records and the two scanpath forms, without silently assuming sample identity or row order. **Not implemented in the generic first-pass intake** until schemas and event definitions are inspected.
5. **Scientific validation:** evaluate calibration, AOI boundaries, gaze accuracy, independent manual annotations, process-model estimands, participant/trial dependence, missingness mechanisms, robust uncertainty coverage and held-out real recordings. **No full scientific certification without these records and tests.**

## Explicit nonclaims

- A directory listing is not a validated dataset.
- A capped sample is not a full-file quality audit.
- Matching numeric L²/FPCA implementations is not proof of meaningful psychological interpretation or valid inference.
- Interest-area tables are not geometric calibration ground truth unless independently defined and checked.
- A scanpath merge is not proven correct without unique source keys and timestamp/event agreement.
- ASC source presence is not sufficient to claim raw eye-tracking fidelity or 1,000 Hz benchmark results.
- Real-data qualification does not change the frozen Zenodo v0.4.3 archive.

## Next evidence-dependent work

The per-archive schema output determines which scientific comparisons are possible. Once that output is reviewed, construct **archive-specific** crosswalks and full-coverage checks for trial/event correspondence and held-out annotated sources. Do not infer unobserved fields or manufacture validation percentages to fill the matrix.
