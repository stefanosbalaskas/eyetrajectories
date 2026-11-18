# Native participant and trial functional random-effect plots

Read-only base R plotting of the realized participant-level functional
random intercepts or slopes and nested-trial functional random
intercepts. The native plots expose ordered numerical line data for
source qualification and do not fit a mixed model, bootstrap
observations or select a scientific threshold.

## Plotting parameters

- result:

  Explicit realized mixed-model source-compatible native record
  including random-effect arrays, names, time and time unit.

- effect:

  Participant random functional effect: intercept or slope.

- max_participants:

  Positive integer participant limit, or NULL.

- alpha:

  Line opacity within (0, 1\].

- participant_id:

  Optional named source participant; NULL for all.

- max_trials:

  Positive integer number of unique retained trial IDs.

## Details

The published scientific source is eyetrajectoriespy 1.2.0, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`, `plotting.py` and
`functional_mixed_effects_nested.py`. Matplotlib Axes returns and Python
frozen result dataclass type constraints are not equivalent to native R
base graphics and named-list inputs; these are explicit unresolved
source-contract differences.

## Value

An invisible R list with numeric source-ordered plotting lines, selected
source identities and conservative backend provenance.
