# Construct trajectories using the Python backend

Convert an R long-format data frame to a Python TrajectorySet, or
generate explicitly synthetic planar eye-tracking trajectories.

## Usage

``` r
et_from_long(data, curve_columns, time_column = "time",
             value_columns = c("x", "y"), metadata_columns = NULL,
             coordinate_system = "unknown", time_unit = "unknown")

et_simulate_planar(n_participants = 20L, trials_per_participant = 6L,
                   n_time = 121L, duration = 2, random_state = 42L)
```

## Arguments

- data:

  An R data.frame with one row per sample.

- curve_columns:

  Character vector of trajectory identifiers.

- time_column:

  Name of the time column.

- value_columns:

  Names of numerical measurement columns.

- metadata_columns:

  Optional curve-constant metadata column names.

- coordinate_system:

  Semantics of coordinates, e.g. `"pixels"`.

- time_unit:

  Unit for the time column, e.g. `"ms"`.

- n_participants:

  Number of simulated participants.

- trials_per_participant:

  Simulated trials per participant.

- n_time:

  Time samples per simulated curve.

- duration:

  Simulated duration.

- random_state:

  Seed for deterministic simulation.

## Value

Python `TrajectorySet` object.

## Details

No data cleaning, interpolation, or duplicate-time aggregation occurs.
All curves must share a common time grid in `et_from_long()`. These are
Python bridge functions, not independently implemented R methods.

## Examples

``` r
if (FALSE) { # \dontrun{
gaze <- et_simulate_planar(n_participants = 5L, random_state = 7L)
} # }
```
