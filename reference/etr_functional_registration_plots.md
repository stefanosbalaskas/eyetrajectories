# Native functional reconstruction and landmark registration visualization

Three stable, unnumbered Python-free public scientific plotting methods:
integrated FPCA reconstruction error against retained component count,
original versus registered complete functional curves, and source
landmark time warping/displacement curves.

## Plotting parameters

- reconstruction_summary:

  An FPCA reconstruction result data frame with numeric `n_components`
  and `mean_integrated_rmse` columns.

- result:

  A complete native `etr_landmark_registration` object with original and
  registered trajectories on a common time grid.

- dimension:

  Optional registered physical/functional channel name.

- max_curves:

  Positive integer maximum number of original and registered curves to
  show.

- displacement:

  If `TRUE`, show \\h(t)-t\\ instead of the warped source time \\h(t)\\.

- ...:

  Additional base graphics arguments.

## Value

Plots are rendered on an R graphics device, and exact source numerical
geometry is returned invisibly in data-frame or list form.

## Details

Original and registered functions appear on distinct panels, as in the
published Python 1.2 source. Identity warping is plotted for reference
without changing original scientific time units. No smoothing, numerical
integration or FPCA refit is undertaken by these plotting functions.
Python's public source returns Matplotlib Axes or figures; these R
functions use base graphics and return native numerical geometry
instead. Full public Python source-contract certification is therefore
not implied by numeric fixture parity.
