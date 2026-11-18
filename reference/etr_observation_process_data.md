# Descriptive diagnostics for an explicit observation process

Construct a candidate-sample denominator and describe retention,
support, and associations with candidate-time variables and past
observations.

## Usage

``` r
etr_observation_process_data(frame, curve_column, time_column,
  observed_column, group_column = NULL, candidate_predictors = character(),
  predictor_sources = NULL, coordinate_columns = character(),
  time_unit = "unknown", coordinate_system = "unknown", provenance = list())

etr_diagnose_observation_process(process, predictors = NULL,
  history_predictors = character(), eccentricity_reference = NULL,
  risk_set = "all_candidates", time_basis = "linear", time_bins = NULL,
  association_bins = 4L, low_support_threshold = 0.10)

etr_observation_process_frame(result, table = "associations")

etr_observation_process_reporting_text(result)
```

## Arguments

- frame:

  Data frame with one row per scheduled or otherwise explicit candidate
  sample. Each curve has a strictly increasing time sequence in the
  supplied rows.

- curve_column, time_column, observed_column:

  Names of the curve identifier, candidate time, and binary observation
  indicator columns.

- group_column:

  Optional metadata column for group summaries.

- candidate_predictors:

  Columns available at every candidate row.

- predictor_sources:

  Named list or vector declaring `"candidate_time"`, `"design"`, or
  `"external_candidate_time"` per predictor.

- coordinate_columns:

  Optional pair of observed coordinate columns with finite values on
  retained rows and missing values on unretained rows after decimal
  numeric conversion.

- time_unit, coordinate_system, provenance:

  Source metadata.

- process:

  An explicit denominator from `etr_observation_process_data()`.

- predictors:

  Subset of declared candidate-time predictors. The default uses every
  declared predictor.

- history_predictors:

  Requested prior-history columns. Available names are
  `previous_observed_x`, `previous_observed_y`,
  `previous_observed_eccentricity`, `previous_observed_speed`,
  `time_since_last_observed`, `preceding_observed_run_length`, and
  `preceding_missing_run_length`.

- eccentricity_reference:

  Optional finite pair of numeric or decimal-text coordinate values.

- risk_set:

  Evaluate all candidate rows or those immediately following an observed
  candidate within a curve, using `"after_observed"`.

- time_basis:

  `"linear"` includes a descriptive time association. `NULL` omits it.

- time_bins, association_bins:

  Number of equal-width bins, increasing edge vector, or `NULL`.

- low_support_threshold:

  Numeric or decimal-text observed fraction threshold in \\\[0,1\]\\.

- result:

  An observation-process diagnostic result.

- table:

  One of `"global"`, `"curves"`, `"groups"`, `"time"`, `"support"`,
  `"associations"`, `"profiles"`, `"failures"`, or `"candidates"`.

## Details

Time summaries use the selected risk set. Regional support uses the full
candidate denominator and identifies empty, zero-observation, and
low-support regions. Predictor associations summarize observed versus
missing rows. History variables use earlier observations within the same
curve. Regional counts use the original bin edges. Displayed interval
endpoints follow the pandas decimal rounding convention on the tested
finite domain. Original candidate columns retain their order and history
columns use a fixed native order.

## Value

The constructor returns an `etr_observation_process_data` record. The
diagnostic function returns an `etr_observation_process_diagnostic`
record with summaries, failure rows, and provenance. The frame and
reporting functions return a data frame and a character string,
respectively.
