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

## New real-data pair-level metadata (executed 18 November 2026, 00:42:54 EET)

The user ran `profile_potec_ambiguous_pair.R` locally on the unchanged original PoTeC ZIPs and supplied `duplicate_pair_metadata.csv`, `DUPLICATE_PAIR_SCOPE.md` and an R 4.6.1 / installed eyetrajectories 0.4.3 session log.

The source row has exactly **two** corrected rows sharing its preserved original index; their fixation durations are distinct and their nonmissing AOIs are distinct. **One corrected duration** equals the source duration, and **one corrected AOI** equals the source AOI. **Neither** corrected row is flagged as manually adjusted. Both corrected rows are adjacent in the file and the *new corrected indices* remain unique.

**Critical limitation:** The preceding diagnostic exported separate **marginal counts**, not the intersection. It does **not** establish whether the duration-equal row is also the AOI-equal row. Therefore it cannot identify the original source event uniquely and must remain `UNRESOLVED_DO_NOT_AUTO_PAIR`. The new joint-signature fields in `profile_potec_ambiguous_pair.R` record this intersection without exporting original participant IDs, fixation indices, AOI values or durations. A joint duration/AOI signature would be **candidate evidence only**, not authoritative correspondence.

This real-data run is distinguished from the new *synthetic* CI tests, which alone cannot claim how the actual ambiguous rows correspond.

## Joint duration–AOI real-data test (executed 18 November 2026, 00:59:55 EET)

**This result is from the user's actual original PoTeC archives**, not the CI synthetic fixtures. The updated `profile_potec_ambiguous_pair.R` was executed on Windows 11, R 4.6.1 with installed eyetrajectories 0.4.3, and `duplicate_pair_metadata.csv`, `DUPLICATE_PAIR_SCOPE.md`, and `R_session_info.txt` were independently read.

| Unit 182 duplicated-index group | Real-data finding |
| --- | ---: |
| Corrected rows sharing an original-index key | 2 |
| Uncorrected rows with the key | 1 |
| Corrected rows matching source duration | 1 |
| Corrected rows matching source AOI | 1 |
| **Corrected rows jointly matching BOTH duration and AOI** | **1** |
| Duration-match but AOI-mismatch corrected rows | 0 |
| AOI-match but duration-mismatch corrected rows | 0 |
| Distinct corrected durations / AOIs | 2 / 2 |
| Rows flagged as manually adjusted | 0 |
| Corrected rows adjacent / newly assigned indices unique | YES / YES |
| Stage conclusion | `UNRESOLVED_DO_NOT_AUTO_PAIR` |

**Interpretation:** The *same* single corrected row agrees with the unique uncorrected source row on both duration and AOI. The other corrected row differs on both fields. This provides **one candidate original-record continuation** and one additional unexplained corrected record, consistent with an original-index propagation or intermediate export issue. It **does not prove** that the matching row is the same physical fixation event or that the differing record is invalid. The absence of manual adjustment flags is an observed fact, not an independent annotation-integrity oracle. No source row IDs were exported.

The strict original-key crosswalk remains **404,418/404,420 corrected records (99.999505%)**, with two corrected records in one ambiguous group and zero duration disagreements among uniquely linked rows. The joint signature is not promoted to a 404,419th *certified* correspondence. Do not drop, relabel or pair either ambiguous source row without an authoritative original DataViewer report or correction-stage event key.

The uploaded local evidence files have these SHA-256 fingerprints (hashes identify the **reports**, not original PoTeC ZIPs):

- `duplicate_pair_metadata(1).csv`: `cf9c6c24b6e477e1d18fcc4c3fda3c9915c4c0b94cf579ad992e6d787de14d29`
- `DUPLICATE_PAIR_SCOPE(1).md`: `e3cdd67d60cd9d382b39cdf387ae171e945779708dc812cf5df62fad0ac2dee4`
- `R_session_info(20261117-230034).txt`: `090deee758fc445bb89c17f58dd68cc19e9240fb6e677f7d2f14e73e557d9889`

**Decision:** Record the two-row exception and deprioritize any further heuristic matching. Resume archived-versus-optimized release qualification and original ASC-to-DataViewer event provenance only if original report/correction records become available.

## Still open

1. **Completed:** Executed and reviewed the pair-level profile, including the same-row duration–AOI intersection. The exception remains unresolved despite a single matching candidate.
2. Retrieve or inspect the original Data Viewer report and corresponding manual-correction provenance to determine whether the two corrected rows genuinely represent one raw event, a duplicated intermediate record or a source-index collision. The authors list `original_uncorrected_fixation_report.txt` in the corpus layout, but its availability within the user's current eight-plus-one downloaded ZIPs **has not been established**.
3. Preserve the evidence status `PARTIAL_UNAMBIGUOUS_ONLY` for ordinal 182 until identity is established. Do not relabel the full stage as a complete PASS.
4. Raw ASC event-to-report timestamps and calibration accuracy remain independent unfinished validation gates.

**Data policy:** All original PoTeC ZIPs remain local and unmodified. This repository note includes de-identified aggregate counts only. The installed 0.4.3 release and its DOI remain unchanged.
