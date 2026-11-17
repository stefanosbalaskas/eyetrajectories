# PoTeC source-author codebook reconciliation (Wave 5, 17 November 2026)

## Executed Wave 5: source-consistency qualification complete

The author-side **17 November 2026, 21:36:54 EET** local R run reported `POTEC_CODEBOOK_SOURCE_LABEL_RECONCILIATION_PASS`. Its four uploaded outputs were independently reopened and cross-checked:

- **900/900** TSV member triplets `READ`, with no row caps or unsupported domain labels.
- **404,420** matched fixation records; no key losses or discrepancies in canonical domain labels.
- **198,985** raw `text_domain` label differences, all resolved after in-memory `bio` → `biology` canonicalization.
- **9/9** exact author-codebook raw-frequency matches, **0** filename biology/physics classification errors.
- **450** biology text units (204,699 records) and **450** physics text units (199,721 records).
- Raw ZIP files remain unchanged; this is an author-run source consistency check, **not** an independently certified validation of gaze calibration, event truth or all package inference.

These findings upgrade the **source-label reconciliation** from a prepared protocol to a **documented local PASS**. See the [full empirical validation status matrix](EMPIRICAL_VALIDATION_STATUS_20261117.md). The detailed earlier protocol below is preserved for reproducibility.

The PoTeC README (reviewed 17 November 2026) also warns that surprisal estimates were updated on **17 June 2026**. Researchers using linguistic surprisal predictors should check their data version independently; the present domain-label validation does not establish surprisal currency.

## Dataset provenance: critical distinction

The 900-file families named scanpaths.zip, scanpaths_merged.zip and fixations.zip are the **Potsdam Textbook Corpus (PoTeC)**, not the OneStop corpus used in the separate paragraph-level fixation CSV benchmarks.

Primary source: Jakobi, D. N., Kern, T., Reich, D. R., Haller, P., & Jäger, L. A. (2025). *PoTeC: A German naturalistic eye-tracking-while-reading corpus.* Behavior Research Methods, 57, article 211. https://doi.org/10.3758/s13428-024-02536-8.

Author-maintained source and explicit field frequencies:
https://github.com/DiLi-Lab/PoTeC/blob/main/CODEBOOK.md

PoTeC comprises 75 readers × 12 texts (b0–b5 biology, p0–p5 physics). The source authors document text_domain values as including both bio and biology for biological materials.

## Actual locally measured Wave 3 and Wave 4 evidence

- Exactly 900 three-way source-unit filenames matched, representing 404,420 (trial, fixation_index) fixation records. No unmatched keys, duplicate keys, missing domain values or row caps in the three inspected TSV families.
- Seven of eight compared shared fields, including fixation_duration, matched exactly across all comparable records.
- Exactly 198,985 unequal raw text_domain cells occurred in the scanpath-versus-fixations and fixations-versus-merged comparisons; scanpath-versus-merged had zero.
- 439 B-group units (198,985 records) differ systematically on their labels: scanpaths and merged use CAT_002 while fixations use CAT_001.
- 450 P-group units (199,721 records) show complete label agreement.
- 11 additional B-group units (5,714 records) are **not constant in their original labels** but agree record for record across the three representations. Wave 4 correctly excluded these from its unit-constant transition table; they are not missing.

The upstream codebook assigns the following **exact raw frequencies**:

| Representation | bio | biology | physics |
| --- | ---: | ---: | ---: |
| Fixations | 203,667 | 1,032 | 199,721 |
| Scanpaths | 4,682 | 200,017 | 199,721 |
| Scanpaths merged | 4,682 | 200,017 | 199,721 |

The 198,985 differences reconcile exactly as both 203,667 - 4,682 and 200,017 - 1,032. This independently published label-frequency evidence explains the observed mismatch as the representation-level spelling of one category, rather than a biology-versus-physics misclassification.

The published codebook provides source-level semantic authority; actual local files still require the record-wise normalized-label test to complete the result. Do not claim an executed canonical test simply because totals match.

## Local R-only Wave 5 independent check

Download and execute scripts/qualify_potec_codebook_domains.R from this repository's main branch, or source its raw GitHub URL in RStudio. The script uses a pinned, already-tested Wave 4 ZIP reader with execution explicitly disabled, then reads the three local source archives without extracting or changing them.

It tests:
1. Every comparable record after in-memory canonicalization bio → biology (biology and physics unchanged).
2. Filename text category b0–b5 / p0–p5 against the canonical label, without assuming original file-order equivalence.
3. Missing/unexpected labels, duplicate/lost record keys, row caps, and complete 900-unit coverage.
4. All nine published raw-label frequencies against the source authors' codebook.

A PASS is permitted **only** when the full 900-unit audit, all three record comparisons and all published frequency totals are reconciled exactly. Otherwise it reports CHECK_INCOMPLETE_OR_DIFFERING_INPUTS.

Default outputs contain only counts, ordinary category names and ordinal unit indices:
- potec_unit_contracts.csv
- potec_codebook_frequencies.csv
- POTEC_CODEBOOK_RECONCILIATION.md
- R_session_info.txt

Data remain local and original source ZIPs are unchanged. Source commits and the archived v0.4.3 software remain separate.

## Scientific validation boundaries

This would support source-provenance and categorical-label consistency, not independent gaze accuracy, calibration, fixation event ground truth, AOI annotation correctness, participant-level inference validity, robustness or confidence-interval coverage. The user-provided OneStop repeated/ordinary CSV analyses address separate real data and numerical functions; they do not validate PoTeC's raw gaze positions.

Never merge OneStop paragraph CSV trial identifiers with PoTeC reader identifiers without an independently established participant/recording crosswalk.

The PoTeC README also documents a nontrivial data provenance exception: participant 9 has 5 additional interrupted raw trials, so original raw/uncorrected material can contain 905 trials even though corrected/scanpath sets contain 900. This is **not** itself evidence of missing matched corrected records.
