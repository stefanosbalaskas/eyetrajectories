# Wave 3: resolving real-data shared-field discrepancies

**Observed evidence (Wave 2, 17 November 2026).** Among 900 matched scanpath / merged-scanpath / fixation TSV triplets, all 404,420 (trial, fixation_index) keys matched in all three pairwise comparisons, with no duplicate keys or negative fixation durations. The scanpath-versus-fixation and fixation-versus-merged comparisons each reported 198,985 shared-field differences across 439 units. All 198,985 differences are concentrated in whole units, with exactly one reported differing field-cell per record. Scanpath-versus-merged reported no such difference. The Wave 2 result is an aggregate *across fields*, so it does not identify the field responsible.

**Do not interpret these 198,985 field-cell mismatches as 198,985 invalid fixations or independent subjects.** A systematic representation-level transformation may be correct, but requires documentation of the original values and transformation.

## Run the next focused diagnostic

In RStudio, use:

    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_wave3_field_disagreements.R"
    ))

The runner independently reads the three original ZIPs in Downloads/eyetrajectoriesValidation. It aligns records by (trial, fixation_index) **within normalized filename stems**. It compares exactly the eight explicitly identified shared fields:

- original_fixation_index
- reader_id
- text_id
- text_domain
- aoi
- is_fixation_adjusted
- version
- fixation_duration

Its CSVs report the numbers of comparable observations, unequal **nonmissing** field cells, asymmetric missingness, equality after whitespace trimming, per-unit complete mismatch flags, and whether a wholly discrepant unit is constant on both sides. Numeric fixation-duration agreement is checked separately from raw string equality.

No raw personal IDs, text, field values or trajectories are exported.

## Output files

- field_comparison_summary.csv — **critical:** aggregates for each of three comparisons × eight shared fields.
- comparison_coverage.csv — count of matched keys, unmatched keys, cap status, and rejected comparisons, by anonymized ordinal unit.
- unit_field_diagnostics.csv — per-field per-unit counts (not raw values).
- WAVE3_SUMMARY.md — aggregate table and interpretation guardrails.
- R_session_info.txt — provenance.

Source ZIP archives, the immutable v0.4.3 release, and previous benchmark results remain unchanged. Full scientific validity is **not** established by this code. If the mismatch is localized to an identified variable, locate its upstream construction specification and compare against verified source before changing any underlying observations. Do not silently coerce differences to zero or prefer one archive.

The Wave 2 interest-area CSVs each had zero observed rectangle/dwell/count/time-order violations in their first 30,000 rows; both were capped. The three ASC sample files were each capped at 100,000 lines; event-start/end count imbalances could be clipping rather than recording errors. These remain evidence-dependent and are separate from the 900-file crosswalk issue.
