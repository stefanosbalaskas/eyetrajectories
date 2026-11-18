# Native R descriptive graphics for source-aligned eye-tracking diagnostics

Plots planar gaze paths, a selected functional principal component, a
zero-based DTW alignment path, or descriptive rank agreement among
distance specifications, without importing Python.

## Usage

``` r
etr_plot_planar_trajectories(trajectories, max_curves = 40L,
  alpha = 0.35, invert_y = TRUE, ...)

etr_plot_fpca_component(result, component = 0L, dimension = NULL,
  sd_multiplier = 2, ...)

etr_plot_dynamic_time_warping_alignment(result, ...)

etr_plot_trajectory_distance_rank_correlations(result, ...)
```

## Arguments

- trajectories:

  Complete native trajectory set with two or more channels.

- max_curves:

  Maximum number of curves; `NULL` selects all.

- alpha:

  Plot line opacity in (0, 1\].

- invert_y:

  Reverse the screen-space vertical axis.

- result:

  Native FPCA, DTW-with-path, or trajectory distance-sensitivity result,
  as appropriate.

- component:

  Zero-based fitted FPCA component index.

- dimension:

  Functional dimension, or `NULL` for the first fitted channel.

- sd_multiplier:

  Positive score standard-deviation multiplier.

- ...:

  Additional base plotting options.

## Value

The plotting function draws using base R graphics and invisibly returns
auditable plot geometry: selected IDs and limits, the mean and SD
curves, the zero-based DTW path, or the symmetric Spearman matrix.

## Details

These are native-R scientific plot-geometry implementations aligned with
public `eyetrajectoriespy` 1.2 names. Python plot functions return
Matplotlib Axes objects whereas these functions draw on an R graphics
device and return native R data invisibly. Therefore this is NOT exact
Python output-object equivalence or a fully certified public source
contract. The source-contract certification ledger remains independent.
