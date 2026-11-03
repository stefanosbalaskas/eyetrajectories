# Dense MCAR and block missingness — native R functional simulation

**Frozen Python 1.2 source:** `eyetrajectoriespy` commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`src/eyetrajectoriespy/_functional_simulation.py::_missingness_mask`
and `simulate_functional_process_core` (public
`simulate_functional_process`).

## Material scientific domain integrated

Before this change, native `etr_simulate_functional_process`
rejected all non-NULL `missingness`. This prevented generating
dense functional gaze/pupil trajectories with artificially missing
samples for controlled methodological benchmarking. The frozen
Python source supports two explicit mechanisms:

- **MCAR:** `list(kind="mcar", probability=p)`; a Bernoulli
  missingness indicator per time sample with `0 <= p < 1`.
  Masking is shared by all functional channels in that sample.
- **Contiguous block:** `list(kind="block", fraction=f)` with
  `0 <= f < 1`. Compute `floor(f*n_time)`, but set it to 1
  when `f > 0` and this floor would be zero. Choose one
  uniformly random admissible beginning, then mask that many
  successive samples. No splitting, random replenishment or
  silent reweighting is performed.

The implementation reuses the native R RNG guard, so external
`Random.seed` state is restored on exit; seed equality to
NumPy PCG64 is **not** claimed.

## Preserve observed versus latent truth correctly

At every simulated curve, the native implementation computes:

1. The exact latent signal and separately retained Gaussian
   measurement noise, allowing diagonal or PSD-correlated
   cross-channel covariance.
2. `pre_missing_values = latent + noise`, saved with no gaps to
   `truth$observed_pre_missing` and its curve lists.
3. A logical mask `truth$missingness_mask[[curve]]` in
   original common-grid order, applied simultaneously to all
   output functional channels. Missing samples are **NA** in
   the R `etr_trajectory_set`, the native missing-value
   sentinel; Python uses NumPy NaN.
4. Original full `truth$latent_on_truth_grid`,
   `truth$latent_at_pre_missing_times`,
   `truth$latent_at_observation_times`, source noise draws,
   time grids, score decomposition and metadata unchanged.
5. Provenance `missingness_kind` and
   `missingness_specification` matching the declared source
   parameters when missingness is requested.

The existing default `missingness=NULL` path keeps its
original numerical observations and RNG calls. The new masks
are generated after latent and noise draws, not used to
re-simulate or impute trajectories.

## Direct frozen Python source mask replay

The existing optional `source_draws` list requires exactly
four numerical fields:
`curve_scores`, `participant_scores`,
`trial_scores`, and `measurement_noise`.

For declared missingness only, a fifth field
`missingness_mask` is now accepted as a list of
`n_curves` complete logical vectors with length `n_time`.
This is a **source-test replay boundary**, not a claim of
matching random streams. It allows the actual frozen Python
truth scores, multivariate noise and realized MCAR/block
masks to be injected into pure native R, then compares
unmasked truth and masked published observations at the
same array coordinates. The four-field form remains
supported and produces native random masks.

## Regression evidence

`tests/testthat/test-native-functional-simulation-missingness-source.R`
has four groups:

1. Contiguous blocks, exact lengths, shared channel masking,
   untouched pre-missing truth, seed reproducibility and
   positive-but-small fractions.
2. MCAR empirical Bernoulli probability, full truth retention,
   all-channel synchronized NA and explicit complete-data
   validation rejection.
3. Invalid fractions/probabilities/unknown mechanisms, exact
   external mask replay and malformed replay-mask rejection.
4. **Actual frozen Python public simulator** calls for both
   MCAR and contiguous block with PSD-correlated noise, followed
   by paired curve/participant/trial score, noise and mask replay
   and numerical comparison of all full-grid outputs.

The tests run in both `native_r_offline` and
`python_1_2_direct_source` qualification modes and all
modified source/test files are recorded in the author SHA
evidence inventory.

## Python tuple / R list indexing regression

The first Windows direct-Python qualification run at research HEAD
`93f05011d37e79e8e7adef0ee7cd25d40b4d1b8e` passed its
native-R suite but reported two test-fixture mismatches when
`pt$observed_pre_missing[[1L]]` (a Python tuple access made
through reticulate) was compared to
`native$truth$observed_pre_missing[[1L]]` (a native R list
access). The direct numeric comparison of the **complete**
published observations, source scores, latent truth and source
masks succeeded for both MCAR and block modes, so this
mismatch reflected indexing of different curve elements, not
a discrepancy in the simulated source law.

The source-oracle test now first evaluates
`python_pre_missing <- et_to_r(pt$observed_pre_missing)`
to obtain a native R list, and only then uses native one-based
`[[i]]` indexing. It compares **all** pre-missing curve
matrices plus each curve's unmasked channel samples. The
simulator implementation, source RNG semantics and published
numerical algorithm were not changed by this fixture repair.
The corrected exact HEAD still requires a full Windows
qualification run before being labelled passing.

## Unresolved Python–R source differences

- Explicit and generated irregular sampling schedules now have a
  separate bounded native implementation using direct function
  evaluation and dropout-as-deletion. See
  `docs/native-functional-simulation-irregular-source.md`.
  Power-phase time warps are now available on both observation
  designs, with original and warped schedules retained separately;
  see `docs/native-functional-simulation-phase-source.md`.
  Finite-variance Student-t curve scores are now implemented
  across dense and irregular observation designs; see
  `docs/native-functional-simulation-student-t-source.md`.
  Full Python dataclass/error schemas and many source coercion
  inputs remain unsupported.
- The Python source's PCG64 and native base-R random streams
  differ. Distributional and retained-source-draw equivalence
  is scientifically distinct from draw-by-draw RNG identity.
- This is not complete `simulate_functional_process`
  source-domain parity, independent validation or CRAN
  release. The currently recorded 204 full-domain gaps and
  zero third-party independent certifications remain open.
- The separately qualified CRAN 0.4.2 candidate is untouched.
