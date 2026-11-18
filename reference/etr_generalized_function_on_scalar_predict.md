# Native fixed-profile marginal generalized function-on-scalar prediction

Computes fixed marginal profile predictions without fitting new models
or reselecting predictors. Python dataclass boundaries and full upstream
model estimation parity remain open source-contract differences.

## Usage

``` r
etr_generalized_function_on_scalar_predict(
  result, profiles, profile_id_column = "profile_id",
  exposure_profiles = NULL, prediction_scale = NULL, python_boundary_mode = FALSE
)
```

## Arguments

- result:

  Explicit native generalized function-on-scalar fitted record.

- profiles:

  Data frame containing exactly profile identifiers and declared
  predictors. Numeric-text and Boolean predictor columns are converted
  to finite numeric values.

- profile_id_column:

  Unique identifier column name.

- exposure_profiles:

  Optional positive exposure vector or matrix for Poisson expected
  counts. Numeric text and logical values are converted before
  validating positivity and shape.

- prediction_scale:

  NULL or family-compatible probability, rate or expected_count.

- python_boundary_mode:

  Apply pandas-style string conversion to ordinary Boolean and
  floating-point profile identifiers. FALSE retains the native R
  identifier conversion.

## Value

Source-shaped native prediction record containing observed-grid means,
linear predictors, covariance-based pointwise standard errors,
extrapolation flags, and exposure-dependent fields.
