# Native dense functional simulation — correlated Gaussian measurement noise

**Frozen Python source of record:** `eyetrajectoriespy==1.2.0`, immutable
commit `c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/_functional_simulation.py::_resolve_noise_covariance`
and `simulate_functional_process_core`, public
`simulate_functional_process`.

## Previously unsupported scientific domain

Native `etr_simulate_functional_process` reproduced dense
Gaussian functional trajectories with independent curve/participant/
trial scores, diagonal channel noise and complete latent source-truth
arrays; it unconditionally rejected `measurement_noise_covariance`.
Python 1.2 supports a full channel-by-channel PSD covariance and
draws multivariate Gaussian errors for each recorded sample. This
matters for joint eye-tracking/pupillometry and multimodal functional
simulation: independent-channel noise cannot represent correlated
sensor errors.

## Source-grounded implementation

The new `R/native-functional-simulation-noise.R` validates:

- The covariance matrix is square with exactly
  `n_dimensions` rows and columns and contains finite numbers.
- Symmetry under frozen Python's `atol=1e-12, rtol=0` criterion.
- Positive semidefiniteness using a symmetric eigenvalue
  decomposition with source minimum-eigenvalue threshold
  `-1e-12`.
- Positive `measurement_noise_sd` and explicit
  `measurement_noise_covariance` cannot be specified together.
- Channel noise SDs are derived from the source covariance diagonal.
  The *declared* covariance matrix, including off-diagonal entries,
  is retained in both scientific truth and observation provenance.

Native Gaussian draws use a symmetric positive-semidefinite
matrix square root `Q diag(sqrt(max(eigenvalues,0))) Q^T`; if
`Z` has independent unit-normal channels, `Z A` has the
declared cross-channel covariance `A^T A`.
This handles strictly positive, singular PSD and zero covariance
without Cholesky failure and without substituting diagonal noise.
The pre-existing diagonal `measurement_noise_sd` random
sampling path is left unchanged.

**R and NumPy do not share an RNG stream.** This implementation
establishes the same covariance estimand, not identical draws
for identical seeds. The already implemented `source_draws`
argument allows frozen Python's actual curve scores,
participant scores, trial scores, and multichannel measurement
noise draws to be injected into the R simulator. Pairing the
realized draws isolates exact law and latent reconstruction
alignment from differences between NumPy PCG64 and base R RNG.

## Tests

`tests/testthat/test-native-functional-simulation-correlated-noise-source.R`
adds four grouped contracts: covariance provenance and exact
observation = latent + noise; singular and zero covariance,
mutual-exclusion and malformed PSD inputs; observed empirical
cross-channel covariance for reproducible native draws;
and **direct frozen Python 1.2** public simulator execution
with correlated covariance and retained Python noise/score
replay, comparing covariance, scores, latent curves and
complete observations.

The previously passing
`tests/testthat/test-native-functional-process-simulation.R`
now expects an actual negative-semidefinite rejection instead
of treating every non-NULL covariance as unsupported.

Both native and Python 1.2 direct-source qualification modes
include the new tests. Source, test, manual and evidence
documentation paths are in the exact-HEAD author SHA
inventory. The source-gap CSV description is updated but
`unresolved_source_gap=TRUE` is deliberately retained.

## Remaining source and CRAN boundaries

- Only complete-grid dense Gaussian functional simulations
  currently run in native R; irregular observation schedules,
  missingness mechanisms, time-phase warps, Student-t
  scores and complete Python dataclass/exception parity remain
  scientific integration work.
- Gaussian draws depend on base R and therefore differ from
  NumPy's PCG64 samples for identical random_state.
- The supported R input representation is finite numeric
  arrays/matrices, not arbitrary NumPy-coercible Python objects.
- No independent 508-export review decisions are earned by
  successful first-party numerical tests.
- This change is on the research branch only and does not
  modify the separately qualified CRAN 0.4.2 candidate.
