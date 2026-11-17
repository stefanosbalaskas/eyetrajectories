# Wave 4 — text_domain source/category provenance

Wave 3's local November 17, 2026 audit found 404,420 matched fixation keys in each of 900 reader-file triplets. Among eight shared columns, seven were exactly equal in all comparable records. All 198,985 unequal nonmissing field cells were confined to text_domain in scanpath↔fixation and fixation↔merged comparisons; scanpath↔merged had zero. In 439 of 900 units, all matched records differed on text_domain, and the label was internally constant in both files. The other 461 units agreed.

This supports a systematic file-level label difference, but does not establish which source is correct.

## RStudio use (all data local)

    source(url(
      "https://raw.githubusercontent.com/stefanosbalaskas/eyetrajectories/main/scripts/qualify_wave4_text_domain_provenance.R"
    ))

The script reads the three local ZIPs from Downloads/eyetrajectoriesValidation, matches filenames by normalized stem and rows by (trial, fixation_index), and writes a new EYETRAJECTORIES_WAVE4_DOMAIN_PROVENANCE_* output folder.

Default output files:

- domain_category_transitions.csv — aggregated category-code transitions and matched/disagreeing record counts, grouped by structural filename token B/P/OTHER.
- domain_unit_diagnostics.csv — anonymized ordinal unit indices, source status, category codes and comparison statistics. Does not include actual reader IDs, text IDs or raw text_domain values.
- WAVE4_SUMMARY.md — complete descriptive source-label crosswalk and one-to-one recoding diagnostic.
- R_session_info.txt — software environment.

By default, labels CAT_### preserve value equality across all three archives but do not reveal raw text_domain strings. They are only stable within one run. Filename group B/P/OTHER is a structural file naming token, not a documented scientific interpretation.

To reveal raw category labels for strictly local investigation, explicitly opt in:

    Sys.setenv(ET_WAVE4_SAVE_LOCAL_LABEL_KEY = "true")

The optional file LOCAL_ONLY_DOMAIN_CATEGORY_KEY_DO_NOT_UPLOAD.csv must not be uploaded or committed until data use restrictions are checked.

## Correct interpretation

An apparent one-to-one label mapping cannot establish which label is correct. Adjudication requires an authoritative upstream preprocessing script or data dictionary defining text_domain. Neither source agreement nor a deterministic recoding establishes gaze calibration, empirical fixation truth, model inference validity or complete scientific certification.

No raw participant data, original ZIP, published software release or prior benchmark output is modified.
