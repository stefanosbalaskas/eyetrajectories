# Python matplotlib plot helpers

Produce and export eye-trajectory and FPCA figures using matplotlib.

## Usage

``` r
et_plot_planar(trajectories, max_curves = 40L,
               alpha = 0.35, invert_y = TRUE)

et_plot_fpca_variance(fit, cumulative = TRUE)

et_save_plot(axes, file, dpi = 150L)
```

## Arguments

- trajectories:

  Python TrajectorySet object.

- max_curves:

  Number of paths to plot; `NULL` means all.

- alpha:

  Path opacity.

- invert_y:

  Invert screen Y axis.

- fit:

  Python FPCAResult object.

- cumulative:

  Plot cumulative component variance.

- axes:

  Python matplotlib Axes object.

- file:

  Output file path with supported image extension.

- dpi:

  Resolution of raster output.

## Value

Plotting functions return matplotlib Axes proxies, not native R plots.
`et_save_plot()` invisibly returns the destination file name.

## Examples

``` r
if (FALSE) { # \dontrun{
gaze <- et_simulate_planar()
ax <- et_plot_planar(gaze)
et_save_plot(ax, "paths.png")
} # }
```
