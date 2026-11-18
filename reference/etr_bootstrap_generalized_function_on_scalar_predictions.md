# Project retained generalized FoSR bootstrap coefficients to fixed profiles

Projects retained whole-participant bootstrap coefficient draws without
additional resampling, fitting, selection or scientific coverage claims.
Full Python dataclass parity remains uncertified.

## Usage

``` r
etr_bootstrap_generalized_function_on_scalar_predictions(
  bootstrap, profiles, profile_id_column = "profile_id",
  exposure_profiles = NULL, prediction_scale = NULL, python_boundary_mode = FALSE
)
```

## Arguments

- bootstrap:

  Native retained participant coefficient-bootstrap record.

- profiles:

  Fixed target-profile data frame.

- profile_id_column:

  Unique target identifier column.

- exposure_profiles:

  Explicit positive Poisson target exposures, when needed.

- prediction_scale:

  Optional family-compatible prediction scale.

- python_boundary_mode:

  Use pandas-style profile identifier conversion in the fixed-profile
  prediction.

## Value

Source-shaped native record of precomputed B by target by time bootstrap
predictions.
