# Author-side real-data qualification — full ASC intake and v0.4.3 performance (17 November 2026)

**Evidence type:** independently re-aggregated author-side RStudio report bundle; not original raw gaze files. Windows 11, R 4.6.1, installed `eyetrajectories` **0.4.3**, verified in the included session records. A separate 14-file aggregated evidence archive was reviewed; no raw participant data or source ZIP is uploaded here.

## PoTeC original ASC — full source-event intake

The run used `sci_validate_potec_asc(root, max_files=78L, max_lines=0L)`, reading all 78 of 78 original ASC source files **to EOF**.

| Source-event diagnostic | Result |
| --- | ---: |
| ASC file lines | 283,565,421 |
| Sample lines | 279,651,816 |
| Fixation starts SFIX | 914,796 |
| Fixation ends EFIX | 914,776 |
| Successfully parsed EFIX | 914,776 |
| Malformed EFIX timing intervals | 0 |
| Backward raw-sample timestamp transitions | 0 |
| SSACC / ESACC | 914,054 / 914,054 |
| SBLINK / EBLINK | 58,982 / 58,982 |
| START / END | 918 / 918 |
| Pattern-matched sentence starts / stops | 917 / 967 |
| Files at source read cap | 0 |

**Two audit flags, not automatic scientific failures:** 17 source recordings have fixation start/end count differences (net 20 more SFIX), and 50 have extra sentence-stop markers (net 50 more stops). The audit counts event/message tokens, not trial-aware event pairing. Practice, interrupted trials, or recording conventions may explain the excess. 918 START/END tokens are not necessarily 918 corrected valid trials. This does **not** establish raw ASC-to-uncorrected Data Viewer fixation correspondence, manual drift correction truth or pixel-level calibration.

## Selected model oracles: local installed release v0.4.3

The uploaded `model_oracles.csv` had **7/7 executable PASS** and two separate `MEASURED_NOT_CERTIFIED` diagnostics.

| Selected check | Result |
| --- | ---: |
| Weighted MFPCA spectrum vs independent base-R eigendecomposition | max abs 5.005e-16 |
| MFPCA train-projection consistency | 1.554e-15 |
| Scalar-on-FPCA regression vs independent QR least squares | 0 |
| Held-out-subject synthetic low-rank regression RMSE | 5.918e-16 |
| Sparse PACE wrapper vs its direct `fdapace` backend | 0 |
| Sparse known-truth RMSE vs mean-only comparator | 0.1921 vs 0.7479 |
| Sparse latent-score absolute correlation | 0.99565 |

The nearly exact held-out prediction is a **low-rank generator algebraic check**, not evidence of real-world prediction precision. Sparse parity compares the adapter with its delegated estimator, not with an independently implemented PACE algorithm.

## Statistical inference: 400 local Monte Carlo datasets

The uploaded 400 replicate rows independently reproduce the report summaries (100 per condition, 30 participants, B=199 participant-cluster bootstrap replicates, 95% nominal coverage).

| Condition | Simultaneous coverage | Exact 95% MC uncertainty | Simultaneous null rejection | Naive trial-IID midpoint pointwise coverage |
| --- | ---: | ---: | ---: | ---: |
| Complete | 96% | 90.1–98.9% | 4% | 76% |
| MCAR | 92% | 84.8–96.5% | 8% | 78% |
| MAR | 90% | 82.4–95.1% | 10% | 77% |
| MNAR | 91% | 83.6–95.8% | 9% | 53% |

The performance across missingness mechanisms is not sufficient to claim universally calibrated nominal bands; Monte Carlo uncertainty remains material.

## Real OneStop scaling — important implementation-version mismatch

The local OneStop benchmark read the complete eligible input without the configured row cap (**1,878 eligible curves**) from `fixations_Paragraph_repeated.csv.zip` (source MD5 `650d93a8c73af6a9b3ca19a7c4e542fb`). All **36 repetitions** (12 configurations × 3) were present and the median/min/max summaries were independently reproduced.

| Curves | Time grid | Median archived v0.4.3 L² | Median archived v0.4.3 MFPCA |
| ---: | ---: | ---: | ---: |
| 250 | 64 | 4.91 s | 0.03 s |
| 250 | 128 | 4.82 s | 0.06 s |
| 500 | 64 | 21.27 s | 0.03 s |
| 500 | 128 | 19.79 s | 0.14 s |
| 1000 | 64 | 76.61 s | 0.05 s |
| 1000 | 128 | 31.11 s | 0.09 s |

**Critical distinction:** the immutable `v0.4.3` tag `R/native-distances.R` implements `etr_pairwise_l2()` with nested scalar per-pair R loops. The subsequent optimized development `main` implementation uses centered weighted vectors and `stats::dist`. Therefore these Windows measurements **do not benchmark the optimized fastpath** reported in earlier branch-specific real-OneStop work. Do not combine the 31.11-second v0.4.3 measurement and the earlier 0.305-second optimized-branch measurement as though they were a version-paired, controlled experiment. The 1,000-curve 64-grid case was unexpectedly slower (76.61 s) than the 128-grid case (31.11 s); repeat in isolated processes with randomized order and explicit version-source identifiers before drawing complexity conclusions.

All expression peak-RAM results were **NOT_MEASURED** because `peakRAM` was absent on the author's Windows installation. The available Windows process RSS high-water values (approximately 744–780 MiB) describe the entire R process since launch, not the memory cost of `etr_pairwise_l2` or MFPCA individually.

## What can be closed, and what remains open

- **PASS, within scope:** 78/78 ASC file source enumeration and supported event/timestamp syntax; 7 selected numerical checks; exact consistency of local Monte Carlo CSV summaries; complete 36-run OneStop benchmark record.
- **FLAGGED:** 20 fixation start/end imbalances, 50 sentence-message imbalances; missingness-sensitive coverage; old-versus-optimized L² version confounding; missing operation-specific peak memory.
- **OPEN:** event-by-event correspondence with the *original uncorrected* Data Viewer fixation report, original correction-stage provenance/annotation truth, independent gaze calibration and full statistical-method validation.

The [PoTeC author preprocessing description](https://github.com/DiLi-Lab/PoTeC/blob/main/preprocessing_scripts/PREPROCESSING_SCRIPTS.md) distinguishes raw ASC, raw TSV, uncorrected fixation report and manually corrected/reindexed fixation exports. The [eyetracking data guide](https://github.com/DiLi-Lab/PoTeC/blob/main/eyetracking_data/EYETRACKING_DATA.md) explains why corrected fixation labels cannot be treated as a literal raw spatial oracle.

**No original source archives, participant observations, frozen v0.4.3 tarball or Zenodo deposit were modified.**
