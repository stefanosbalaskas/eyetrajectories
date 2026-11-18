# Native diagnostic plots for FPCA predictive CV and bootstrap sensitivity

Four independent, read-only R-graphics adapters for published
eyetrajectoriespy 1.2 numerical plot geometry: FPC count predictive
cross-validation, nested outer-fold loss, full-refit versus
fixed-covariance mixed-effects simultaneous band-width ratios, and
target-specific FPCA wild-bootstrap truncation width or center.

## Plotting parameters

- result:

  Explicit native R record of already-computed fold losses, outer-fold
  losses, or FPCA wild-bootstrap scan/selection values.

- comparison:

  Data frame of already-computed bootstrap sensitivity ratios.

- coefficient:

  Nonempty name of the coefficient to visualize.

- target:

  Native one-based target index or named source curve identifier.

- metric:

  Truncation interval `width` or `center`.

## Details

Published Python 1.2 source `plotting.py`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`. Single-fold predictive CV
uncertainty uses `sd_loss = 0`; other sample standard deviations use the
`n - 1` denominator, matching pandas. No cross-validation, bootstrap,
selection or model fitting occurs in these graphics functions. Returned
native R geometry is not a Matplotlib Axes object. Python numeric target
indices are zero-based while native R indices are one-based. Complete
input, output, and error-schema equivalence has not been certified.

## Value

Each function draws to the active base R graphics device and invisibly
returns an auditable list of source numerical plot coordinates and
provenance.
