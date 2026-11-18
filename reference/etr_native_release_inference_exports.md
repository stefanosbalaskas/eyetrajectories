# Native functional estimation, inference and simulation exports

Reference index for exported functions in this scientific domain. The
functions are independently callable; scientific scope and input
contracts vary by estimator, data structure, fitted object, and selected
backend.

## Details

These functions expose explicit native or alternative functional-data
model fits, projection/score uncertainty, simulation and model
sensitivity. Bootstrap and inference functions require their documented
experimental units, fitted source structures, resampling rules and
supported numerical domains. The existence of a source-name mapping is
not an independent full-domain Python 1.2 parity certificate. Review
estimator-specific technical documentation, assumptions and
corresponding R/source tests before scientific reporting; particular
uncertainty methods may be research-only with no external coverage
validation. For joint mixed-effects bootstrap fits, `random_state`
accepts exactly represented nonnegative integer seeds below \\2^{53}\\.
Explicit seeds use NumPy-compatible PCG64 draws. A supplied zero-based
draw matrix takes precedence. A null seed uses the ambient R stream.

## Exported entry points

- `etr_bootstrap_fpca_component_envelopes`:

  *bootstrap fpca component envelopes* – descriptive matched-bootstrap
  FPC pointwise envelopes. Optional `bootstrap_unit_indices` provides
  zero-based fixed curve/participant unit draws for deterministic source
  replay, without claiming Python NumPy RNG or full-domain parity.

- `etr_bootstrap_fpca_regression_uncertainty`:

  *bootstrap fpca regression uncertainty* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_bootstrap_functional_mixed_effects_coefficients`:

  Whole-participant conditional Gaussian GLS resampling for native joint
  B-spline likelihood fits with complete observed-time covariance and
  fixed variance components; older mixed-moments records retain their
  scientifically distinct timewise approximation. A zero-based
  source-index matrix supports deterministic Python 1.2 replay.

- `etr_bootstrap_functional_mixed_effects_full_refit`:

  Whole-participant full native Gaussian ML/REML refits for joint
  B-spline random-intercept models with iid residuals; estimates
  random-intercept covariance and residual variance in each fitted
  replicate. Structured joint likelihood models additionally support
  native AR1/exponential serial residual, participant random-slope,
  nested functional trial and nested-slope full refits; these additional
  models require slow-gated local validation and remain uncertified.
  Mixed-moments records retain their separate estimator. No Python
  backend parity or external certification is claimed.

- `etr_bootstrap_generalized_function_on_scalar_coefficients`:

  Whole-participant GEE refits. Explicit PCG64 seeds accept exactly
  represented nonnegative integers below \\2^{53}\\. A supplied
  zero-based draw matrix takes precedence.

- `etr_fit_elastic_fpca`:

  *fit elastic fpca* – an explicit exported method; consult its R formal
  arguments and source-contract restrictions.

- `etr_fit_generalized_function_on_scalar_regression`:

  Working-independence clustered GEE with numeric, numeric-text or
  logical predictor columns. The default matches curve IDs. With
  `python_boundary_mode = TRUE`, supplied IDs must already follow
  trajectory order. Designs without a curve ID column must have default
  row names and follow the same order. This mode uses singular-value
  design rank and a separate GLM initialization. The declared `maxiter`
  and `ctol` then control GEE updates and the pre-update score norm.
  Participant coefficient bootstrap refits inherit the solver from the
  fitted model.

- `etr_fit_sparse_mfpca`:

  *fit sparse mfpca* – an explicit exported method; consult its R formal
  arguments and source-contract restrictions.

- `etr_fpca_wild_bootstrap_projection_family_test`:

  *fpca wild bootstrap projection family test* – an explicit exported
  method; consult its R formal arguments and source-contract
  restrictions.

- `etr_functional_mixed_effects_covariance_sensitivity`:

  *functional mixed effects covariance sensitivity* – an explicit
  exported method; consult its R formal arguments and source-contract
  restrictions.

- `etr_scan_wild_bootstrap_fpca_truncations`:

  Shares fixed or seeded wild draws across each candidate truncation.
  The multiplier controls are the same as for
  `etr_wild_bootstrap_fpca_projection`.

- `etr_simulate_functional_process`:

  *simulate functional process* – an explicit exported method; consult
  its R formal arguments and source-contract restrictions.

- `etr_simulate_functional_scenario`:

  *simulate functional scenario* – an explicit exported method; consult
  its R formal arguments and source-contract restrictions.

- `etr_wild_bootstrap_fpca_projection`:

  Wild-bootstrap projection with normal or Mammen multipliers. A
  nonnegative integer seed below \\2^{53}\\ uses NumPy-compatible PCG64
  by default. `random_engine = "base_R"` can replay previous native
  normal draws. A fixed `multiplier_draws` matrix takes precedence.
  `random_state = NULL` uses the current R RNG stream.

## Value

Each function returns its own documented native R, scientific-model,
bridge, workflow or audit result; no single shared return type is
asserted.
