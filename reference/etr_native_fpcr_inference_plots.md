# Native FPCR inference and sparse PACE source diagnostic plots

Six Python-independent, read-only native R diagnostic plots for
already-computed functional principal component regression inference:
wild-bootstrap projection intervals, future-outcome prediction,
conditional-mean uncertainty, simultaneous and pointwise slope bands,
and sparse PACE score-system conditioning.

## Plotting parameters

- result:

  Named native record of previously computed source-compatible FPCR or
  sparse PACE quantities; no estimator is run.

- max_targets:

  Positive integer maximum number of targets shown.

- dimension:

  Optional named FPCA dimension, defaulting to the first.

## Details

The published source is eyetrajectoriespy 1.2.0,
`src/eyetrajectoriespy/plotting.py`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`. Native R draws to the active
base graphics device and invisibly returns the numerical source-aligned
geometry. Its returned record is not a Python Matplotlib Axes object.
Typed Python result dataclasses, complete boundary-domain behavior, and
graphical return equivalence remain unresolved certification
differences. Target x positions are retained as Python-style zero-based
plot coordinates. The sparse PACE view distinguishes positive finite
conditioning measurements with status `ok` from flagged/failed
measurements on a logarithmic y axis. The plots neither establish
coverage nor select an estimator.

## Value

An invisible native R list with preserved numerical geometry, plotting
metadata and explicit backend provenance.
