# Complete native R discrete Frechet and dynamic time warping contracts

Independent Python-free implementations of the public eyetrajectoriespy
1.2.0 methods `discrete_frechet_distance`,
`dynamic_time_warping_distance` and
`pairwise_dynamic_time_warping_distances`. They expose explicit ordered
coupling paths, two DTW step patterns, optional Sakoe-Chiba constraints
and deterministic cost audits. Python is only used by optional external
reference tests.

## Usage

``` r
etr_discrete_frechet(a, b, dimension_weights = NULL,
                      return_coupling = FALSE,
                      python_boundary_mode = FALSE)
etr_dynamic_time_warping(a, b, dimension_weights = NULL,
                          window_radius = NULL,
                          step_pattern = "symmetric1",
                          normalize = FALSE,
                          return_path = FALSE,
                          python_boundary_mode = FALSE)
etr_pairwise_dtw_full(x, dimensions = NULL, dimension_weights = NULL,
                      window_radius = NULL,
                      step_pattern = "symmetric1", normalize = FALSE,
                      python_boundary_mode = FALSE)
```

## Arguments

- a,b:

  Complete numeric point-by-dimension matrices. Both require at least
  one time-ordered point and the same number of channels. In
  `python_boundary_mode=TRUE`, finite numeric-looking character or
  logical matrices and regular nested scalar point rows are also
  accepted.

- dimension_weights:

  NULL or one finite nonnegative numeric weight per channel. At least
  one weight must be strictly positive. In source-boundary mode,
  numeric-compatible character or logical weights are also accepted.

- return_coupling:

  Logical: if TRUE return a detailed optimal discrete Frechet coupling
  and local distances; otherwise a numeric scalar.

- window_radius:

  NULL or a nonnegative integer Sakoe-Chiba window in sample-index
  units. It must permit connection between the endpoints.

- step_pattern:

  DTW recursion `"symmetric1"` (all selected moves weight one) or
  `"symmetric2"` (diagonal moves weight two, horizontal/vertical moves
  weight one).

- normalize:

  Logical. Only supported with `"symmetric2"`. If TRUE, return raw
  cumulative distance divided by `n_a+n_b`.

- return_path:

  Logical. If TRUE, return the full audited alignment path, local
  distances, weighted distances, counts and provenance.

- python_boundary_mode:

  Logical. Explicitly opt in to bounded Python 1.2
  `np.asarray(..., dtype=float)` point and weight conversion. Defaults
  to FALSE, preserving strict native R input validation. For pairwise
  DTW, TRUE allows NumPy-compatible finite dimension weights; the
  trajectory values must still be a native complete trajectory set.

- x:

  Complete native `etr_trajectory_set`.

- dimensions:

  NULL to use all stored channels, or distinct ordered channel names
  selecting the comparison dimensions.

## Value

`etr_discrete_frechet()` returns a scalar or an
`etr_discrete_frechet_result` list with `distance`, `coupling`,
`local_distances`, `n_points_a`, `n_points_b`, `n_dimensions` and
`provenance`. `coupling` is an integer two-column matrix with
\*\*zero-based\*\* pair indices matching the Python result.

`etr_dynamic_time_warping()` returns a scalar or an `etr_dtw_result`
list with `distance`, zero-based integer `path`, `local_distances`,
`step_weights`, `weighted_local_costs`, `raw_distance`, optional
`normalized_distance`, `path_length`, `mean_local_distance`, dimension
counts, `window_radius`, `step_pattern`, optional
`normalization_denominator` and `provenance`. Python's None fields are R
NULL.

`etr_pairwise_dtw_full()` returns a symmetric numeric matrix without
dimension labels; the diagonal is zero.

## Details

All algorithms are discrete, not continuous, and never use recorded
time, interpolate missing samples or change spatial coordinate units.
They use weighted Euclidean local costs, retain monotonicity of the
coupled trajectory sample indices, and resolve exactly tied predecessors
in the upstream order: diagonal, then advancing the first trajectory,
then advancing the second.

The upstream Python `dynamic_time_warping_distance` implements
`symmetric1` as raw path-visit costs, not normalized by path length. The
normalizable `symmetric2` recursion uses diagonal costs twice; when
requested, normalization divides raw cumulative cost by the sequence
length sum, not the number of alignment-path nodes.

With `python_boundary_mode=TRUE`, the native R implementation also
performs finite numeric-string and Boolean input conversion before
computing the distance. This is a source-backed \*subset\* of NumPy's
coercion domain; it does not assert acceptance of arbitrary Python
objects, scientific equivalence for all floating-point overflow
boundaries, or identity of Python dataclasses versus native R S3 result
records.

The native R implementation imposes an explicit resource guard: at most
`5e6` point pairs for dense dynamic programming. The published Python
1.2 function has no equivalent fixed limit. The complete native R parity
register consequently remains unqualified for full behavioral
equivalence, even after fixed numerical test cases succeed. The R
results reproduce documented Python provenance fields as ordinary R
named lists but have not been qualified for Python serialization/JSON
round-trip equivalence.

The older
[`etr_frechet()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md),
[`etr_dtw()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
and
[`etr_pairwise_dtw()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)
remain available unchanged for existing R users. The new functions
express additional Python 1.2 behavior.

## Examples

``` r
a <- matrix(c(0, 1, 2), ncol = 1)
b <- matrix(c(.1, 1.1, 2.1), ncol = 1)
f <- etr_discrete_frechet(a, b, return_coupling = TRUE)
d <- etr_dynamic_time_warping(a, b, return_path = TRUE)
n <- etr_dynamic_time_warping(a, b, step_pattern = "symmetric2",
                               normalize = TRUE, window_radius = 0L)
```
