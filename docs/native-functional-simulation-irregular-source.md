# Functional simulation with irregular observation schedules — native R

**Frozen source:** `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/_functional_simulation.py`:
`_resolve_sample_counts`, `_sample_irregular_times`,
`_validate_explicit_observation_times`,
`simulate_functional_process_core`; public
`simulate_functional_process`.

## Scientific source domain newly implemented

Previously native `etr_simulate_functional_process` unconditionally
rejected `observation_design="irregular"`. Native R already had
`etr_irregular_trajectory_set`; this new bounded source integration
uses that existing class and keeps the dense simulation path
unchanged.

Source parameter options:

- `observation_times`: explicit list containing exactly one
  curve-specific numeric, finite, strictly increasing vector
  per curve, with at least two samples within the closed
  `truth_grid` support. Distinct curves can have different
  numbers of samples; times need not coincide with truth-grid
  knots and are **not interpolated**.
- `samples_per_curve`: integer count >=2 or a numeric
  two-integer lower/upper range, selected uniformly as an
  integer per curve. This is an R representation of the
  frozen source's Python integer-or-two-integer-tuple law.
- `irregular_time_design="uniform"`: interior samples are
  uniform on the normalized interval [0.01,0.99].
- `"center_clustered"`: interior samples follow
  0.01 + 0.98 Beta(4,4).
- `"boundary_poor"`: interior samples are uniform
  on [0.15,0.85].
- Generated schedules always include the support endpoints;
  interior times are sorted in increasing order. Exactly
  two requested samples result in the two endpoints.

Native base-R random number streams are **not** identical to
NumPy PCG64; the rules/distributions are source-equivalent,
not the exact samples for the same `random_state`.

## Statistical construction and realized truth

The simulator first validates on the truth grid that the
declared generating modes are quadrature-orthonormal.
It draws independent curve, participant and trial score
components, and combines them into the per-curve retained
latent scores. For each declared *irregular* schedule,
the generating mean and each eigenfunction are **evaluated
directly at the observed times**, rather than obtained from
a discretized dense interpolation. This distinction affects
the scientific truth for nonlinear generating functions.

Measurement errors are then drawn independently from the
declared source Gaussian channel covariance at each
observation time; the earlier diagonal noise and PSD
cross-channel covariance rules both remain available.

When `missingness=NULL`, every declared irregular time is
retained. For MCAR or contiguous block missingness, a
complete logical mask is generated over the **pre-missing
schedule**; samples are *removed* from the irregular
output time/value lists, not represented by NA, and at
least two observations must remain for every curve.
The original pre-missing time/value arrays and mask
remain in `truth`, alongside original complete-grid
latent values, source scores, error realizations, and
post-missing latent values on the final schedule.

The native result is an
`etr_functional_simulation_result` containing
`observations` of class `etr_irregular_trajectory_set`
and a source-shaped `truth` scientific record.
`truth$phase_warps_on_truth_grid` remains the identity
when phase variation is NULL.

## Frozen-source replay and testing

For the irregular domain, `source_draws` uses the same
three score matrices as dense replay, but
`measurement_noise` must be a **list of numeric matrices**
matching each curve's pre-missing time count and channel
count. When `missingness` is requested, optional fifth
`missingness_mask` contains one logical vector per
pre-missing curve. This permits a full paired replay of
Python's **actual** scores, observed schedules, noise and
dropout masks while leaving the simulation engine native R.

`tests/testthat/test-native-functional-simulation-irregular-source.R`
adds five groups: direct explicit schedule evaluations,
all three generated schedule distributions/count laws,
irregular block dropout and complete retained truth,
invalid schedule/mask/domain rejection, and actual
pinned-Python 1.2 source invocation paired with
native R and complete pre/post-missing curve comparisons.

Registration in both `native_r_offline` and
`python_1_2_direct_source` qualification filters, plus
test/source/manual/doc SHA evidence, is explicit.
The RStudio Windows run at this exact new research HEAD
is still required before assigning a PASS.

## Explicit limits and release scope

This is not full Python-to-R domain equivalence.
Full typed Python `IrregularTrajectorySet` and
`FunctionalSimulationTruth` dataclass identities,
Python-specific input coercions, exception messages,
NumPy PCG64, power phase warps, Student-t scores and
independently reviewed source certification remain
open. No automatic irregular-to-common-grid interpolation,
silent resampling or synthetic exposure replacement
is permitted. The research branch changes do not modify
the separately staged CRAN 0.4.2 candidate.
