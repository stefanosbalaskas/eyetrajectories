# Local PoTeC correction-stage and controlled L² validation — audited 18 November 2026

**Evidence type:** user-supplied RStudio results independently re-aggregated from original CSVs. The source ZIPs are retained locally; the current repository only stores aggregate, de-identified evidence. **Do not describe a partial stage key crosswalk as full source-stage certification.**

## Controlled archived 0.4.3 vs optimized L²: matched real OneStop data

OneStop repeated-reading fixation archive MD5: `650d93a8c73af6a9b3ca19a7c4e542fb`; **1,878** eligible fixation trajectories; the input row cap was not reached. The installed package was `eyetrajectories 0.4.3` on Windows 11 / R 4.6.1.

The script compares **exact source function bodies**, with a single shared helper implementation. These are *not two installed package namespaces*. The source identities are pinned to the v0.4.3 release (blob `acc135d35133e07c1fd32e947aaa0c9a6d45be8b`) and optimized development source (blob `8d243b0736da7bdc5d964678b17412baa24b9a13`). Both use the **same normalized-time interpolated OneStop trial objects** and algorithm execution order is randomized within each paired repetition.

| Curves | Grid | Median old L² (seconds) | Median optimized L² (seconds) | Ratio of medians |
| ---: | ---: | ---: | ---: | ---: |
| 250 | 64 | 1.970 | 0.020 | 98.5× |
| 250 | 128 | 2.060 | 0.010 | 206.0× |
| 500 | 64 | 7.810 | 0.050 | 156.2× |
| 500 | 128 | 8.260 | 0.060 | 137.7× |
| 1,000 | 64 | 30.750 | 0.140 | 219.6× |
| 1,000 | 128 | 33.230 | 0.300 | 110.8× |

Independent recomputation of all **36 individual timing rows** agrees with the six supplied summary rows. Matrix errors ≤ **1.13686837721616 × 10⁻¹²** across all configurations; independent reference errors ≤ **3.41060513164848 × 10⁻¹³**. The optimized algorithm retains agreement with the declared trapezoidal L² oracle.

**Cautions:** These are measured wall times on one Windows machine, not a two-release end-to-end package comparison or an OS-normalized cross-platform benchmark. Optimized measurements of 0.01–0.02 s are near the clock resolution, so the 250-curve ratios are less stable. The 1,000 × 128 old method has a 51.78-second timing outlier, but its three-run median is 33.23 seconds. The archived v0.4.3 code is not retroactively optimized; only the separately pinned development algorithm is fast.

## PoTeC original uncorrected to corrected fixation crosswalk

Source-author uncorrected ZIP **MD5** `ecd9a998d07158922bb9b8cdd52f5688`; corrected ZIP **MD5** `df1b34fd053531ed9d481093b5c5befc`. The original uncorrected archive has 905 file stems; 900 corrected stems are present and matched; five uncorrected-only stems remain separate and are not necessarily missing valid corrected trials.

| Corrected stage QA | Local evidence |
| --- | ---: |
| Source file sets inspected | 900 |
| Strictly comparable source stage sets | **899** |
| Ambiguous duplicate original-index file sets | **1** (ordinal 182) |
| Total uncorrected rows across 900 shared sets | **409,621** |
| Total corrected rows across 900 shared sets | **404,420** |
| Validated original-index correspondences, 899 sets | **403,119** |
| Uncorrected-only original IDs in 899 comparable sets | **5,196** |
| Corrected-only original IDs in 899 comparable sets | **0** |
| Duration disagreements in 899 comparable sets | **0** |
| Directly compared AOI labels in 899 sets | **395,932** |
| AOI disagreements among comparable nonmissing labels | **14,750** |
| Flags marking adjusted fixations in 899 sets | **21,937** |
| Records with missing AOI comparability in 899 sets | **7,187** |

The AOI count identity holds **separately for all 899 comparable sets**:

`flagged_corrections - aoi_differences = duration_tested - aoi_tested`

Summed across the comparable sets: `21,937 - 14,750 = 403,119 - 395,932 = 7,187`.

This is consistent with corrections to originally unassigned AOI values and changes between nonmissing labels. It is **not** independent truth about whether the human annotation was correct.

### Exactly why the stage state is PARTIAL

The only non-pass unit is **ordinal 182**, where both inputs were read in full, with **1,306 uncorrected** and **1,301 corrected** rows. Its corrected data contain duplicate `(trial, original_fixation_index)` keys; the existing strict join correctly rejects those ambiguous keys. This explains why the otherwise 404,420 corrected records produce only **403,119** strict successful crosswalks: precisely 1,301 records are excluded in that single unit, not declared failed.

The new [duplicate-key diagnostic](../scripts/diagnose_potec_duplicate_original_keys.R) targets ordinal 182 without exporting IDs. It counts duplicate keys, identifies any *strictly unique* pairs that can be safely validated, and leaves repeated keys **unresolved** until an independent source index, trial/session marker or original report is available. It never guesses based on row order, AOI or fixation duration.

**Do not mark the entire 900-set stage as PASS** merely because 899 units reconcile. A matching duration is not sufficient to disambiguate repeated original IDs, and the original uncorrected ZIP still lacks timestamp fields for ASC-to-DataViewer event timing.

## RStudio command for the remaining blocked unit

After this PR merges:

    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/diagnose_potec_duplicate_original_keys.R"
    ))

Required existing local ZIPs in Downloads/eyetrajectoriesValidation:

- fixations_uncorrected.zip
- fixations.zip

The output folder `POTEC_ORIGINAL_INDEX_DIAGNOSTIC_*` contains `ambiguous_index_diagnostics.csv`, `AMBIGUITY_DIAGNOSTIC.md` and `R_session_info.txt`.

Original source files and released v0.4.3 software remain unchanged. Independent ASC event correspondence, gaze calibration, and advanced inference validity remain separate open scientific milestones.
