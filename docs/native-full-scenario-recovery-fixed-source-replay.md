# Batch 20 — deterministic full-scenario recovery replay

Pinned source: `eyetrajectoriespy==1.2.0` at `c1cd95ad718327550f7e55393ff38582872f7a94`, with reference contracts in `simulate.py::simulate_functional_scenario` and `simulate.py::run_functional_recovery_scenarios`.

## Change and scientific purpose

The native scientific simulator already supports Gaussian and finite-variance Student-t score distributions; dense/irregular sampling; participant/trial hierarchy; explicit PSD noise covariance; MCAR/block missingness; and power phase warping. Contrary to an outdated ledger description, these domains were **already implemented** before Batch 20.

Batch 20 addresses the remaining inability to use source-retained stochastic realizations through **whole-scenario recovery orchestration**. `etr_simulate_functional_scenario` now accepts `observation_times` for an irregular scenario, replacing only the scheduled observation-time draws. Its existing `source_draws` argument continues to supply fixed curve, participant, trial, measurement-noise, and optional warp/missingness draws. `etr_run_functional_recovery_scenarios` now accepts `source_draws_by_replicate` and `observation_times_by_replicate`, each an optional list of length equal to the total number of declared scenario replicates, traversed in scenario order then increasing zero-based replicate index. A `NULL` element retains the original R-generated draw for that replicate.

The native runner still supplies only `observations` and the declared `scenario` to the estimator; realized truth remains available **only** to the recovery callback. Failure modes and source-draw validation are retained in the low-level simulator. No default random number generator behavior changes. A pinned Python 1.2 direct public call is tested for the irregular source realization with the exact retained source draws, observation times and truth.

## Verification boundaries

The patch does **not** reproduce NumPy's PCG64 random streams, Python dataclass identity, or complete error-class behaviors. Fixed source draws are a native R verification affordance, not a new Python public parameter. This scientific evidence does not close the recorded 203 callable source gaps or create any independent certification. Run the mandatory R and opt-in pinned Python suites before committing and running full two-mode qualification.
