# Native R recurrence networks, joint recurrence and sliding-window RQA

Ten native Python-independent nonlinear-dynamics algorithms and frames
based on the published eyetrajectoriespy 1.2.0 contracts from
`recurrence.py`, `recurrence_networks.py` and `joint_recurrence.py`.
These are research-size native R implementations, not Python
`scipy.sparse` object wrappers. Recurrence-network results can now
optionally use sparse native Matrix adjacency and accept already sparse
native recurrence matrices without materializing a dense square array.
Native joint RQA on sparse sources now counts diagonal and vertical line
runs directly from nonzero coordinates, including large sparse
recurrence systems, without the former 2500-node dense-conversion guard.

## Usage

``` r
etr_recurrence_network(recurrence, adjacency_storage = c("dense", "sparse"),
  python_boundary_mode = FALSE)
etr_recurrence_network_node_frame(result)
etr_recurrence_network_summary_frame(result)
etr_joint_recurrence_matrix(recurrences, labels = NULL)
etr_joint_recurrence_component_frame(result)
etr_joint_rqa_metrics(result, min_diagonal_length = 2L,
                      min_vertical_length = 2L)
etr_cross_rqa_metrics(recurrence, min_diagonal_length = 2L,
                      min_vertical_length = 2L)
etr_recurrence_radius_profile(source, curve = 1L, radii,
  metric = "euclidean", theiler_window = 0L,
  theiler_window_units = "samples", dimensions = NULL)
etr_windowed_rqa(trajectories, curve = 1L, window, step,
  window_units = "samples", step_units = "samples", radius = NULL,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L)
etr_windowed_rqa_trajectory_set(trajectories, metrics, window, step,
  window_units = "samples", step_units = "samples", radius = NULL,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L, undefined_policy = "raise")
```

## Arguments

- recurrence:

  Native `etr_recurrence`, auto for network analysis and cross for
  cross-RQA.

- adjacency_storage:

  `"dense"` keeps the existing native logical adjacency matrix and its
  2500-node cap; `"sparse"` returns a logical sparse Matrix matrix with
  a 10000-node cap for dense source recurrence or 100000 nodes when the
  source is already sparse. The Matrix package is required only for
  sparse input or output.

- result:

  Native recurrence network or joint recurrence result.

- recurrences:

  Two or more native auto-recurrence results on exactly the same time
  grid, temporal unit and Theiler-exclusion contract.

- labels:

  Optional unique component labels.

- min_diagonal_length,min_vertical_length:

  Positive integer minimum qualifying RQA line lengths.

- source,trajectories:

  Complete native `etr_trajectory_set`; the first supplies a
  radius-profile source.

- curve:

  One-based numeric curve index or existing curve identifier.

- radii:

  Prespecified strictly increasing positive finite radius vector.

- metric:

  Source recurrence metric: `"euclidean"`, `"cityblock"`, or
  `"chebyshev"`, including windowed RQA.

- theiler_window:

  Nonnegative excluded sample-index lag.

- theiler_window_units:

  Sample units or convertible physical-time units on an approximately
  regular observed grid.

- dimensions:

  Optional distinct named channel selection.

- window,step:

  Window and step lengths in explicit sample or physical units, resolved
  to whole observed samples; windows need at least three samples and
  `step <= window`.

- window_units,step_units:

  Sample units or convertible physical-time units without resampling or
  interpolation.

- radius:

  Optional positive finite fixed recurrence radius. Specify exactly one
  of radius or target_recurrence_rate.

- target_recurrence_rate:

  Optional target density strictly between zero and one. Uses
  source-aligned inclusive-radius threshold selection, whose achieved
  rate may differ because of distance ties. When this controls the
  density, recurrence_rate cannot be a derived outcome.

- metrics:

  Distinct named RQA metrics forming functional channels.

- undefined_policy:

  `"raise"` to reject undefined RQA metrics or `"keep"` to preserve them
  as explicit missing values.

- python_boundary_mode:

  If TRUE, use the published Python 1.2 boundary conditions; FALSE
  retains native validation defaults.

## Value

`etr_recurrence_network()` returns a native `etr_recurrence_network`
list with undirected adjacency, zero-based connected-component labels,
degree, clustering, transitivity and provenance. Node and summary
functions return native R data frames. Joint functions return a native
`etr_joint_recurrence` or per-component table/line statistics.
`etr_recurrence_radius_profile()` returns an
`etr_recurrence_radius_profile` list with cumulative and shell
recurrence fractions. `etr_windowed_rqa()` returns a native
`etr_windowed_rqa` with one row per complete window and explicit
dropped-tail count. `etr_windowed_rqa_trajectory_set()` returns an
`etr_windowed_rqa_functional` with functional native trajectory,
per-curve windows, overlap fraction and provenance.

## Details

These functions are discrete, not continuous-time estimators.
Recurrence-network transitivity is undefined (NaN) when there are no
connected triples; clustering for degree below two is zero. No automatic
graph threshold or community detection is performed. Joint recurrence
requires strictly synchronized input and does not resample, shift, or
harmonize component thresholds.

Dense recurrence network output is limited to 2500 state nodes; opt-in
sparse output supports up to 10000 native recurrence states, retaining
source topology but not SciPy CSR class identity. Native sparse Matrix
auto-recurrence inputs can be analyzed without dense allocation (with a
separately bounded 100000-node sparse network path); joint recurrence
can intersect synchronized dense/sparse sources. Native line-RQA uses
sparse coordinates for large auto, joint and rectangular cross
recurrence inputs. Python SciPy CSR and typed result identity and full
source error domains remain unresolved. Native radius profiles retain
their separate 2500-node limit. These caps differ from Python's sparse
implementations. Radius profiles accept convertible physical-time
Theiler windows and TrajectorySet input. Windowed RQA supports
fixed-radius or explicitly requested target-density thresholds, all
three source distance metrics, and convertible physical-time
windows/steps on approximately regular grids. Target-density selection
is not an independent parity certificate. The current R objects are
partial scientific-result representations, not certified
binary/serialization equivalents of Python dataclasses.

Windowed functional RQA reuses source samples for overlapping windows
and does NOT treat windows as independent sampling units for downstream
inference. No scientific coverage or inferential calibration is implied.
Optional Python reference tests use a pinned Python 1.2 package and are
entirely separate from the native R algorithms.

Native sparse cross-RQA accepts rectangular sparse Matrix recurrence
inputs with explicitly declared first and second time grids. Cross-line
statistics use all diagonals and vertical lines and require
approximately regular and matching time-step sizes. Native sparse
representations are not identical to Python SciPy CSR or typed dataclass
results.

## Examples

``` r
values <- array(0,c(2L,9L,1L))
values[1L,,1L] <- rep(0:2,3L)
values[2L,,1L] <- rep(c(0,1,0),3L)
x <- etr_trajectory_set(0:8,values,c("A","B"),"x",time_unit="s")
r1 <- etr_recurrence_matrix(x,"A",radius=0.01)
r2 <- etr_recurrence_matrix(x,"B",radius=0.01)
network <- etr_recurrence_network(r1)
joint <- etr_joint_recurrence_matrix(list(r1,r2))
report <- etr_joint_rqa_metrics(joint)
```
