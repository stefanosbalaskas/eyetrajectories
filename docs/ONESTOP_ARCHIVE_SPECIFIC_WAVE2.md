# Wave 2: archive-specific integrity checks for real gaze and reading exports

> **Corpus attribution and validation update (17 November 2026):** The two paragraph fixation CSVs and their interest-area exports are from **OneStop**; the 900-file `scanpaths`, `scanpaths_merged` and `fixations` TSV families and the related ASC recordings are from the independent **Potsdam Textbook Corpus (PoTeC)**. The 198,985 PoTeC raw label mismatches are accounted for by the source authors' documented `bio` versus `biology` spellings. This page records an earlier stage of the protocol, not the latest conclusion. See [PoTeC codebook reconciliation](POTEC_CODEBOOK_RECONCILIATION.md) and the [official authors' codebook](https://github.com/DiLi-Lab/PoTeC/blob/main/CODEBOOK.md). No OneStop–PoTeC participant join is justified.

**Purpose:** extend the eight-archive OneStop audit beyond coordinate-based L2/MFPCA checks, according to actual observed file schemas on 17 November 2026.

## Evidence from Wave 1

Eight out of eight source ZIPs were present and listable. The two OneStop fixation CSVs passed selected 64-curve sample-level L2 and FPCA numerical tests, with sixteen independent pairs each and no numerical failures. Both were capped at 30,000 read rows. The two interest-area CSVs each contained 157 columns. Scanpaths, merged scanpaths, and fixation TSVs each included 900 members (31/119/20 observed columns). The ASC ZIP contained 78 members, three of which were sampled.

The original first-wave ASC summary erroneously reported "Source archive missing or could not be parsed" even though the archive existed and three ASC members were read. This was a misleading non-applicability fallback, not an actual source error.

## Running locally

Use the new source script:

https://github.com/stefanosbalaskas/eyetrajectories/blob/main/scripts/qualify_archive_specific_wave2.R

In RStudio execute:

    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_archive_specific_wave2.R"
    ))

Default root: Downloads/eyetrajectoriesValidation. Set ET_WAVE2_ROOT if needed.

The default enumerates all three 900-member TSV manifests and inspects at most 900 matched triples. Each input TSV is capped at 30,000 rows. For a smaller preflight set ET_WAVE2_MAX_UNITS=20 in the R environment before running. Data are inspected sequentially and only aggregate quality metrics are written. No raw participant IDs, text strings or scanpaths are exported.

The two interest-area CSVs are each sampled up to 30,000 rows for AOI geometry, negative dwell duration, fixation count and event-order checks. Up to 3 ASC files are sampled by default with a limit of 100,000 lines per file; adjust ET_WAVE2_ASC_FILES and ET_WAVE2_ASC_LINES only after reviewing the initial output. No claim about full ASC event balance is possible if any sample is truncated.

## Expected outputs

Each run creates a new EYETRAJECTORIES_ARCHIVE_SPECIFIC_WAVE2_* folder, containing:

- family_manifest.csv: full member counts, normalized stem correspondence and unmatched stem counts.
- unit_crosswalk.csv: per-unit sequential IDs (not raw reader IDs); record counts, within-record trial/fixation-index overlap, shared field disagreement, duration disagreement, duplicate keys and row-cap indicators.
- ia_quality.csv: tested denominators and violations for geometry, dwell duration, count and event-time consistency.
- asc_event_samples.csv: sampled ASC event marker counts, with truncation marker.
- WAVE2_SUMMARY.md: descriptive report with explicit nonclaims.
- R_session_info.txt: R runtime information.

## Correctness boundaries

The three TSV families share a reader-style filename convention, and their sampled headers contain trial, fixation_index and fixation_duration. Wave 2 compares only these three representations by matching normalized member stems and using (trial, fixation_index) within each file. Missing or duplicated keys produce NOT_COMPARABLE, never guessed row alignment. Shared-field disagreements are recorded without choosing which representation is correct.

The OneStop paragraph-level CSV families and the 900-member reading datasets have not been demonstrated to share participants or trials. Wave 2 **does not join them** or infer cross-corpus identity.

The interest-area aggregate tables are not continuous XY trajectory streams. AOI and timing constraints can be assessed from exported fields, but passing these checks does not independently validate AOI annotations.

ASC event marker samples establish only provenance and basic event structure, not source-acquisition resolution, tracking calibration, spatial accuracy, complete fixation detection or independent ground truth. The ASC ZIP is large and default sampling is intentionally bounded.

Scientific qualification still requires independently annotated events, source-to-export event correspondence where explicit keys are established, calibration records, participant-level design support, and model-specific validation of uncertainty and inference. Do not describe successful schema or source-agreement checks as full scientific certification.

No existing benchmark results, published version archive, Zenodo DOI or original ZIP inputs are changed.
