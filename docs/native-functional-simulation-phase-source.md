# Power-phase variation in native functional simulation

**Frozen scientific Python source:** `eyetrajectoriespy==1.2.0`,
immutable `c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/_functional_simulation.py`:
`_resolve_phase_variation()`,
`_apply_power_warp()` and
`simulate_functional_process_core()`. Public callable:
`simulate_functional_process`.

## Newly integrated scientific behavior

The previously qualified native implementation generated dense
and irregular functional trajectories, including correlated
Gaussian measurement noise and MCAR/contiguous-block dropout,
but rejected non-NULL `phase_variation`. This commit adds
the frozen Python 1.2 **power-phase** mechanism to both
observation designs.

The source parameter `phase_variation=list(kind="power",sd=s)`
requires a finite nonnegative log-exponent standard deviation.
For each simulated curve the source model draws a positive
power exponent independently as `exp(Normal(0,s))`; native R
draws from the corresponding distribution using base-R
random numbers, **not** NumPy PCG64.

For a truth domain `[a,b]`, original sample coordinate
`t` and retained power exponent `q>0`, the exact
source time transform is

`u=(t-a)/(b-a); warped=a+(b-a)*u^q`.

An observation at original time `t` is **recorded at t**,
but the generating mean/eigenfunctions are evaluated at
`warped(t)`. The implementation never labels a warped
observation as a new sample timestamp and never interpolates
the original dense functional signals.

The native `R/native-functional-simulation-phase.R` contains
strict source parameter validation, positive exponent
sampling, optional frozen-source exponent replay and
endpoint-preserving power warp. Frozen Python uses
`np.isclose` for the first and last domain endpoints;
the bounded R implementation applies the equivalent
default numerical tolerance to these endpoints.

## Dense and irregular truth

In the **dense** path, each `truth_grid` time is warped
per curve; the latent signal at `truth_grid` is computed
by calling the declared generating functions at these
warped coordinates. Dense observed times remain unchanged,
and MCAR/block masks still apply to original sample rows.

In the **irregular** path, the previously qualified
explicit/generated schedule is retained as the original
curve time. Each irregular pre-missing time is warped
directly for latent function evaluation. MCAR/block masks
remove the corresponding sample from both the published
original-time schedule and the post-missing warped-time
truth, preserving both pre-missing schedules. No resampling
or alignment to common knots is performed.

Both paths retain `truth$phase_warps_on_truth_grid`
as an n-curves-by-n-grid matrix, with
`truth$warped_pre_missing_observation_times`,
`truth$warped_observation_times`,
`truth$latent_on_truth_grid` and complete pre/post-missing
per-curve latent signals. The output provenance declares
`phase_variation_kind="power"` and one realized
`phase_exponents` vector.

## Exact frozen-source replay

The optional `source_draws` argument retains its four
required draw fields: curve scores, participant scores,
trial scores and measurement noise. When
`phase_variation` is declared, it additionally accepts
`phase_exponents`, a finite positive numeric vector
with one value per curve. For declared `missingness`,
the optional per-curve logical `missingness_mask`
remains available; both optional fields can be supplied
together.

This first-party test boundary injects actual frozen
Python 1.2 realized exponents, scores, noise and masks
into the fully native R evaluator and verifies the
same **conditional source-law numerical values**.
It deliberately does not claim the same NumPy and base-R
random streams or identical public dataclass types.

## Tests and evidence

`tests/testthat/test-native-functional-simulation-phase-source.R`
adds four groups:

1. Dense nonlinear generating functions under four fixed
   exponents, checking exact time warps, latent values,
   original observation timestamps and truth provenance.
2. Irregular nonlinear generating functions with block
   missingness, checking original and warped pre/post-
   missing schedules, direct latent evaluation, masks and
   un-interpolated observed values.
3. Invalid phase kinds/SDs, malformed externally retained
   exponents and finite native generated exponents.
4. Direct frozen Python 1.2 **public**
   `simulate_functional_process` source invocation for
   both dense and irregular designs, with PSD correlated
   noise and missingness, replaying the source's actual
   exponents, scores and noise. The tests compare complete
   grid/curve latent truth, warped times and post-missing
   observations.

Both native offline and frozen Python 1.2 qualification
modes include the source tests. All modified source,
test, documentation and manual files are included in
the author's exact-HEAD integrity manifest. The
preceding irregular-simulator commit passed both suites
on Windows; this new phase commit requires a fresh
Windows RStudio replay before being designated PASS.

## Remaining boundaries

No full-domain scientific equivalence or independent
508-export certification is asserted. Student-t curve
scores, NumPy PCG64 stream identity, all Python dataclass
input/output representations, general Python coercion/
exception behavior and externally signed full-contract
review remain open. The separately checked CRAN 0.4.2
release candidate is unaffected.
