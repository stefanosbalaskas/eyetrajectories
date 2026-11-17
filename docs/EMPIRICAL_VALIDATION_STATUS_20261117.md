# Real-data empirical qualification evidence — 17 November 2026

**Status:** Author-side real-data evidence reviewed; limited numerical, structural and codebook source-consistency validations completed. **Not a general scientific validation certificate.**

## Distinct corpora and sources

The eight local ZIP archives are from **two different corpora**, not one eight-file eye-tracking dataset.

- **OneStop:** `fixations_Paragraph_repeated.csv.zip`, `fixations_Paragraph_ordinary.csv.zip`, `ia_Paragraph_repeated.csv.zip`, `ia_Paragraph_ordinary.csv.zip`. The two fixation CSVs underwent capped sample numerical validation; the interest-area CSVs underwent capped source-quality checks.
- **Potsdam Textbook Corpus (PoTeC):** `scanpaths.zip`, `scanpaths_merged.zip`, `fixations.zip`, `asc_files.zip`. The first three underwent exhaustive corrected-derived-file correspondence and author-codebook labeling checks. The original ASC recordings have **not** undergone independent raw-to-derived fixation reconstruction.

PoTeC original dataset: Jakobi, D. N., Kern, T., Reich, D. R., Haller, P., & Jäger, L. A. (2025), *PoTeC: A German naturalistic eye-tracking-while-reading corpus*, *Behavior Research Methods*, 57, article 211. DOI: https://doi.org/10.3758/s13428-024-02536-8; original codebook: https://github.com/DiLi-Lab/PoTeC/blob/main/CODEBOOK.md.

## What has actually passed

| Validation gate | Corpus | Verified evidence | Scope / limit |
| --- | --- | --- | --- |
| ZIP intake inventory | Both | 8 / 8 source ZIPs present and enumerable | Presence does not establish scientific validity |
| L²/FPCA numerical sample contracts | OneStop | 64 curves from each of repeated/ordinary fixation CSVs; 16 independent L² comparisons per sample; max L² error 0, FPCA variance-ratio discrepancies at floating-point precision | Capped 30,000-row samples, normalized within-trial time, selected functions only |
| Real-gaze pairwise L² scaling | OneStop | 21/21 declared checks in original and optimized runs; six configurations, observed speedup 104.6×–214.9× | One machine; prepared fixation data; not physical velocity or uncertainty calibration |
| AOI geometry / timing / counts | OneStop | Two IA CSVs, 30,000 rows each; zero violations of checked geometry, negative duration/count and event-order constraints | Row caps reached; external AOI annotation truth not tested |
| File-unit and fixation-key crosswalk | PoTeC | 900 / 900 three-family TSV triplets; 404,420 aligned fixation keys; zero unmatched keys, duplicate-key exclusion, or duration discrepancies | Derived-to-derived correspondence; not raw ASC event truth |
| Shared TSV fields | PoTeC | Seven shared fields equal on all 404,420 comparable fixation records | Limited to inspected fields and three TSV representations |
| Source-label codebook reconciliation (Wave 5) | PoTeC | **PASS**: 900 units read, 404,420 matched records, 198,985 raw text_domain differences resolved by codebook alias `bio` → `biology`, zero canonical disagreements, zero key loss, zero unknown labels, zero filename-domain errors, zero capped units; nine published raw-label frequencies reproduced exactly | Codebook-anchored source consistency, not eye-tracker accuracy |
| Raw ASC events | PoTeC | 78 file members enumerated; 3 recordings sampled up to 100,000 lines in prior Wave 2 | Entire 78-file raw corpus and original event-to-export alignment **not validated** |

## PoTeC Wave 5 exact source counts

| Representation | bio | biology | physics | Total |
| --- | ---: | ---: | ---: | ---: |
| Fixation TSV | 203,667 | 1,032 | 199,721 | 404,420 |
| Scanpaths | 4,682 | 200,017 | 199,721 | 404,420 |
| Merged scanpaths | 4,682 | 200,017 | 199,721 | 404,420 |

Original raw-label differences: 203,667 − 4,682 = **198,985**. This is the exact number of unequal text_domain entries in the local 900-unit audit. Both `bio` and `biology` denote the biology domain in the source-authors' codebook. The 439 affected biology text units account for 198,985 records. The other 11 biology units contain 5,714 internally mixed but cross-representation agreeing records; 450 physics units have 199,721 records and no label disagreement.

**Wave 5 empirical evidence:** Local run at 2026-11-17 21:36:54 Europe/Athens, Windows 11 x64, R 4.6.1, `eyetrajectories` 0.4.3 namespace loaded. The original source ZIPs were not modified. A successful local validation script is not a GitHub Actions execution on private data, nor a rerun independently performed on the public CI infrastructure.

## Next independent scientific validation gates

1. **Source version/provenance.** Record local archive hashes, and confirm source release dates against the authors' repository. The PoTeC README reports a **17 June 2026 correction to surprisal estimates**; this warrants explicit version verification before using those linguistic predictors. The tested domain-label columns alone do not authenticate surprisal values.
2. **Raw-to-derived gaze event validation.** Use PoTeC's documented original ASC, uncorrected fixation and corrected fixation processing pipeline. Do not require literal equality after manual vertical drift correction. The authors also distinguish 905 raw/uncorrected trials from 900 corrected trials for an interrupted session; treat this as a documented provenance difference rather than an unexplained loss.
3. **Independent measurement ground truth.** Validate fixation/saccade segmentation, temporal markers, spatial calibration and AOI annotation against the original annotations or clearly independent external truth, with tolerances and error distributions rather than identity checks alone.
4. **Statistical validity.** Validate FPCA/regression model coverage, participant/trial dependence, inferential calibration, uncertainty diagnostics and domain-specific interpretation using held-out real data and simulation as appropriate.
5. **Package coverage.** Map scientific claims to method-by-method evidence instead of generalizing source-integrity or limited numerical tests to every exported `eyetrajectories` function.

**Release boundaries:** The v0.4.3 GitHub/Zenodo archived source remains frozen; source audit scripts on `main` do not retroactively change that archive. Never join OneStop and PoTeC participants on guessed IDs.
