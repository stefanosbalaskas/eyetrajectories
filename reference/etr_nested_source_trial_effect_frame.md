# Source-order nested-trial functional random-effect frame

Create one row per trial and time point in the frozen Python 1.2 source
ordering; no plotting, refitting, or averaging.

## Usage

``` r
etr_nested_source_trial_effect_frame(result)
```

## Arguments

- result:

  Native nested trial or nested random-slope mixed-effects result.

## Value

Data frame with columns curve_index (zero-based), curve_id,
participant_id, source_trial_id, trial_id, time, effect and value. This
aligns the Python 1.2 scientific output data schema but does not return
a Python pandas DataFrame or require a Python typed result.
