# Native first- or second-order functional trajectory differentiation

Pure R numerical analogue of frozen eyetrajectoriespy 1.2.0
`differentiate_trajectories`. Uses the source-compatible second-order
edge-aware gradient on the recorded, potentially nonuniform time grid;
no smoothing, time-grid resampling or Python execution is involved.

## Usage

``` r
etr_differentiate_trajectories(x, order = 1L)
```

## Arguments

- x:

  Complete native `etr_trajectory_set` with at least three distinct time
  samples.

- order:

  Derivative order 1 or 2. Python-like Boolean TRUE is accepted as order
  1; FALSE, non-integral values, missing and out-of-range orders are
  rejected.

## Value

An `etr_trajectory_set` with one derivative channel per original
channel; suffixes `_velocity` (order 1) and `_acceleration` (order 2).
Original curve IDs, time, metadata, coordinate system, time unit and
nonoverwritten provenance keys are preserved. The source
`provenance$derivative` mapping records the order, `numpy_gradient`
numerical method and `smoothing=FALSE`.

## Details

For order 2 the second derivative is obtained by differentiating the
first derivative again using an irregular-grid second-order edge-aware
stencil. There is no hidden smoothing and no measurement uncertainty
correction. This source-aligned method is distinct from the historical R
convenience methods `etr_velocity` and `etr_acceleration`, whose default
output/provenance contracts are left unchanged.

Tests against pinned Python 1.2 are first-party qualification evidence
only; full input-domain parity, all source representations and
independent scientific certification remain open.

## Examples

``` r
t <- c(0, 0.2, 0.7, 1.5)
v <- array(t^2, dim = c(1L, length(t), 1L))
x <- etr_trajectory_set(t, v, dimension_names = "x")
first <- etr_differentiate_trajectories(x, order = 1L)
second <- etr_differentiate_trajectories(x, order = 2L)
```
