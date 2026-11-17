# PoTeC ordinal 182 — author-side duplicate-index diagnostic (18 November 2026)

## Source evidence reviewed

The user executed `diagnose_potec_duplicate_original_keys.R` using the original PoTeC uncorrected and corrected ZIPs on Windows 11, R 4.6.1 with `eyetrajectories` 0.4.3 attached. The uploaded `ambiguous_index_diagnostics.csv` and `AMBIGUITY_DIAGNOSTIC.md` were reopened and cross-checked.

Exactly **one** problematic source unit remains in 900 matched corrected/uncorrected file sets: **ordinal 182**, originally 1,306 uncorrected rows and 1,301 corrected rows.

| Local file-set measure | Evidence |
| --- | ---: |
| Uncorrected original-index duplicate groups | 0 |
| Corrected original-index duplicate groups | **1** |
| Corrected extra rows introduced by duplicate-key multiplicity | 1 |
| Corrected rows in duplicated original-index group | **2** |
| Uncorrected rows sharing that same original index | 1 |
| Source key missing / corrected key missing | 0 / 0 |
| Strictly unique cross-stage pairs | **1,299** |
| Strictly unique uncorrected-only keys | **6** |
| Strictly unique corrected-only keys | 0 |
| Duration checks in unique matched pairs | 1,299 |
| Duration disagreements in unique matched pairs | **0** |
| AOI comparisons in unique pairs | 1,259 |
| AOI differences in unique pairs | 241 |
| Missing AOI comparisons in unique pairs | 40 |

## Consolidated across all 900 matched source units

The previous 899 clean original-index units had 403,119 matched corrected rows and 5,196 uncorrected-only unique keys. Adding the 1,299 unambiguous pairs from ordinal 182 gives **404,418 unique matched corrected rows** out of the 404,420 corrected PoTeC rows (**99.999505%**). The uncorrected-only unique-key total becomes **5,202**, while the single original source row sharing the duplicated corrected key stays *ambiguous*. Two corrected rows share that one original index; neither can be assigned unique event identity from the current source fields.

These counts are evidence for near-complete **stage key/duration consistency**, not evidence for complete raw ASC event accuracy. Five uncorrected-only file stems outside the matched 900 remain separately documented in the source authors' interrupted-recording exception.

## Why we must not auto-resolve the two corrected rows

The source authors' [correction code](https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/correct_fixations.py) saves an original fixation index, removes marked events, reindexes the retained corrected rows and applies manual AOI corrections. The [source-stage documentation](https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/PREPROCESSING_SCRIPTS.md) lists the original Data Viewer report and the split uncorrected exports as distinct stages. Therefore a duplicate preserved original index requires additional source evidence; simply matching the first of two rows, choosing the closest duration, or dropping an apparent duplicate would be speculative.

The new [privacy-preserving pair-level profile](../scripts/profile_potec_ambiguous_pair.R) reports whether the two corrected rows share the same duration, AOI and adjustment status, whether each equals the original duration, whether they are consecutive, and whether the corrected *newly assigned* fixation indices remain unique. These are **diagnostic flags only**; the script always marks the pair `UNRESOLVED_DO_NOT_AUTO_PAIR`.

## Still open

1. Execute the pair-level profile locally; review `duplicate_pair_metadata.csv` and `DUPLICATE_PAIR_SCOPE.md`, without uploading raw participant IDs.
2. Retrieve or inspect the original Data Viewer report and corresponding manual-correction provenance to determine whether the two corrected rows genuinely represent one raw event, a duplicated intermediate record or a source-index collision. The authors list `original_uncorrected_fixation_report.txt` in the corpus layout, but its availability within the user's current eight-plus-one downloaded ZIPs **has not been established**.
3. Preserve the evidence status `PARTIAL_UNAMBIGUOUS_ONLY` for ordinal 182 until identity is established. Do not relabel the full stage as a complete PASS.
4. Raw ASC event-to-report timestamps and calibration accuracy remain independent unfinished validation gates.

**Data policy:** All original PoTeC ZIPs remain local and unmodified. This repository note includes de-identified aggregate counts only. The installed 0.4.3 release and its DOI remain unchanged.
