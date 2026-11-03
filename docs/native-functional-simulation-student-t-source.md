# Finite-variance Student-t curve scores in native functional simulation

**Frozen Python 1.2 reference:** `eyetrajectoriespy==1.2.0`,
source commit `c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/_functional_simulation.py::_sample_curve_scores`
and `simulate_functional_process_core`, public
`simulate_functional_process`.

## Material scientific integration

The previously qualified R simulator supported dense and irregular
observation designs, independent or correlated Gaussian measurement
noise, MCAR/contiguous-block dropout and power-phase variation.
However, it rejected `score_distribution="student_t"`, a source
functionality needed to evaluate estimation robustness against
heavy-tailed curve scores.

Frozen Python permits
`score_distribution="student_t",score_df=nu` only when
`nu` is finite and **strictly greater than 2**. This
restriction matters: ordinary Student-t with <=2 degrees of
freedom has infinite variance and cannot be calibrated to
finite functional component eigenvalues.

For each curve `i` and functional component `j`:

```
T_ij ~ Student_t(nu)
curve_score_ij = T_ij * sqrt(lambda_j * (nu - 2) / nu)
Var(curve_score_ij) = lambda_j
```

The `(nu-2)/nu` factor matches the frozen source exactly.
The target `lambda_j` is the **curve-score variance only**;
additional independent participant and trial effects increase
the variance of the combined latent score beyond that
component's curve variance.

Native R uses `stats::rt()` (base R) and multiplies by
the source scale factor, separately for every component.
The existing native `stats::rnorm()` sampling expression
for `score_distribution="normal"` is preserved, including
its seed and random-consumption order. Participant and
trial scores continue to use Gaussian distributions,
**even when** the curve scores follow Student-t: frozen
Python does not apply Student-t to the hierarchy effects.

## Scientific truth and source-draw replay

Dense and irregular source simulator paths use the same
pure-R helper `R/native-functional-simulation-student-t.R`:
`.etr_functional_simulation_score_spec` validates the
requested distribution and degrees of freedom;
`.etr_functional_simulation_sample_curve_scores` performs
the variance-corrected stochastic draw. The source truth
fields `score_distribution="student_t"` and
`score_distribution_parameters=list(kind="student_t",df=nu)`
are written by both simulation paths and agree with the
published Python source data contract.

All previously integrated observation geometry remains
compatible: explicit/generated irregular schedules,
PSD-correlated observation-noise covariance, MCAR/block
missingness and power-phase exponents. The complete
pre-missing and latent truth records remain available.

Optional four-field `source_draws` preserves actual
frozen-Python realized curve/participant/trial score
matrices and measurement noise, with optional missingness
mask and phase exponent fields. Exact paired numerical
replays use **Python's realized Student-t curve scores**
and check the resulting latent/observed values without
claiming base-R and NumPy PCG64 generate equal raw
draws from a common seed.

## Regression evidence

`tests/testthat/test-native-functional-simulation-student-t-source.R`
adds four groups:

1. **Stochastic finite-variance law** — exact native
   `stats::rt` formula replay at a fixed R seed, large-sample
   means and component variances near their specified
   values; exact Gaussian helper RNG regression.
2. **Realized scientific schema** — public dense and
   irregular Student-t simulations, hierarchy score
   identity, truth/report distribution fields and
   deterministic seeding.
3. **Source-domain validation** — reject nonfinite,
   invalid or `nu<=2` degrees of freedom and
   unsupported distribution names. Normal mode
   deliberately ignores invalid unused score_df.
4. **Direct frozen Python 1.2 public calls** — source
   Student-t scores in both dense and irregular
   observations. The irregular case combines power-phase
   variation, block missingness and correlated Gaussian
   measurement noise. Frozen Python's scores, noise,
   masks and phase exponents are replayed into native R
   for paired complete curves/observations and truth.

Both native offline and frozen Python 1.2 direct-source
qualification filters include the new test, source,
manual and scientific record in the author's exact-HEAD
integrity manifest. **A new exact-HEAD Windows RStudio run
is required before this change can be marked passing.**

## Boundaries

This is developer qualification for a scientifically
defined subdomain; **not** independent certification
of the public Python function over all valid inputs.
The R and NumPy random streams remain different, Python
dataclass and exact coercion/exception contracts are not
fully reproduced, and independent certification of all
508 public Python exports remains unsigned. The
separately qualified CRAN 0.4.2 release candidate is
not modified by this research branch integration.
