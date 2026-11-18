# Explicit native functional-data analysis workflow exports

Reference index for exported functions in this scientific domain. The
functions are independently callable; scientific scope and input
contracts vary by estimator, data structure, fitted object, and selected
backend.

## Details

Workflow functions coordinate explicitly declared trajectory
collections, analysis configurations, scientific models and source
reporting artifacts. The fit function actually executed depends on the
specific native R backend; third-party source representations,
mixed-effects estimation and plotting classes may differ from frozen
Python 1.2 counterparts. Check each workflow's explicit required inputs,
domain restrictions, preprocessing policies, and actual fitted
estimator. Workflow export and figure utilities are not substitutes for
a complete numerical oracle. Native backend and source Python backend
provenance are not interchangeable. For
`etr_run_functional_mixed_effects_workflow`, the legacy explicitly
declared method-of-moments estimator remains the default path. An opt-in
`estimator="native_joint_bspline_gaussian"` path dispatches the already
implemented native R/nlme participant-intercept, participant-slope,
nested-trial, and nested-trial-plus-slope likelihood models. Only IID
residuals are supported without a declared nested trial; IID, AR(1), and
exponential residuals are available for nested trial models. Native
`method="nlme::lme"` is required; Python's optimizer is not silently
substituted, and the typed Python workflow/result contract is not
certified. The coefficient table uses seven source-ordered pointwise
Wald columns. See `docs/native-joint-bspline-source-workflow-wave.md`.

The `native_covariance` configurations of `etr_run_sparse_fpca_workflow`
and `etr_run_sparse_mfpca_workflow` accept `score_uncertainty=list()` to
request conditional PACE score uncertainty. The list may specify
`condition_limit` and `failure_action` (`"error"` or `"retain_nan"`).
The workflow returns the conditional result and a per-curve,
per-component table. The `scores` table retains input metadata and uses
`SFPC` or `SMFPC` component prefixes. Input metadata columns that
collide with score-table names receive unique suffixes in the table.

To select bandwidths, supply
`bandwidth_selection=list(mean_bandwidths=c(0.5, 0.7), covariance_bandwidths=c(0.8, 1), n_splits=5L)`
in place of the two fixed bandwidth arguments. The workflow refits each
candidate within each training fold, ranks eligible candidates by mean
held-out Gaussian predictive loss, then refits the selected model. The
selection result contains assignments, curve losses, fold outcomes,
candidate summaries, and the selector provenance and reporting text. Use
`resampling_unit="group"` with `group_column` to keep entire groups in
one fold. Supply zero-based `fold_assignments` in input-curve order to
replay an external split. Seeded curve shuffles use the legacy NumPy
permutation law. For grouped selectors, `group_tie_order="numpy_simd"`
or `"numpy_scalar"` replays the chosen NumPy 2.3.5 tie ordering. See
[`etr_cross_validate_fpca_reconstruction`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_native_cv_uncertainty.md)
for supported domains. By default every fold must be valid.
`min_valid_folds` changes this threshold. `failure_action="retain"`
records failed folds, while `"error"` stops at the first failure. If no
candidate is eligible, the `etr_sparse_bandwidth_selection_error`
condition contains the audit in `bandwidth_selection`. Sparse prediction
selects bandwidths using its proper-training curves.

The `native_sparse_partial_conformal` prediction workflow takes a PACE
training configuration, a finite history cutoff, and at least two future
times. Its default `alpha` is `0.05`. The target forecast uses finite
observations through the cutoff. Calibration also requires one finite
response at each declared future timestamp.

The native covariance backends of sparse FPCA, paired and asynchronous
sparse MFPCA, and sparse multilevel FPCA accept descriptive observation
diagnostics. Pass a denominator constructed with
[`etr_observation_process_data`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_observation_process_data.md)
as `observation_process` and an explicit
`config$observation_diagnostics` list. A list with no elements requests
the default settings. The fitted model and the candidate diagnostics are
separate result fields. Workflow tables include global, time, and
association summaries, and the diagnostic record contains the remaining
audit tables.

## Portable dense FPCA workflow bundles

Call `etr_run_fpca_workflow(trajectories, config, measure_time = TRUE)`
to record elapsed R fit time and warnings. Export that result with
`etr_export_workflow_bundle(result, directory, format = "python_1_2")`.
The new destination contains the workflow manifest, configuration and
provenance JSON, audit CSVs, reports and tables, SHA-256 checksums, and
a complete JSON/NPZ snapshot in `result/`. Frozen Python 1.2 can load
the snapshot with `load_portable_result`. The snapshot preserves the
native fit, measured steps, declarations and audit artifacts.
Environment metadata identifies the actual R runtime.

The portable mode covers dense FPCA with empty preprocessing, measured
elapsed times, and primitive data-frame columns. It requires optional
jsonlite, digest, and zip. Artifact names must be simple portable
filenames, and the destination must be new. The default
`format = "native_r"` retains the native RDS bundle. Other workflow
classes and arbitrary Python dataclass and backend objects remain
outside the portable scope.

## W4 seven-route scientific plotting and figure export

The opt-in `etr_plot_workflow_result(..., strict_source_record=TRUE)`
supports seven explicitly named canonical workflows: dense and sparse
FPCA components, sparse multivariate FPCA components,
function-on-scalar, functional mixed-effects, generalized functional
coefficients and recurrence. It returns an R scientific artist-geometry
record, not a Python Matplotlib Axes object or guaranteed
pixel-identical image. The existing three-route native result and
numeric output remain the default.
`etr_save_workflow_figure(..., strict_source_record=TRUE)` writes actual
native R PNG/SVG/PDF files and allows overwrite. Its strict route
requires `close=TRUE` to flush R devices and accepts supported device
DPI values from 1 to 1200. Python `close=FALSE`, arbitrary Python Axes
injection, SVG metadata identity and pathlib object identity remain
unsupported. Neither entry point is an independently certified full
Python 1.2 contract. See
`docs/native-w4-seven-workflow-figure-source-scope.md`.

## Exported entry points

- `etr_export_workflow_bundle`:

  *export workflow bundle* – an explicit exported method; consult its R
  formal arguments and source-contract restrictions.

- `etr_run_fpca_workflow`:

  *run fpca workflow* – an explicit exported method; consult its R
  formal arguments and source-contract restrictions.

- `etr_run_function_on_scalar_workflow`:

  *run function on scalar workflow* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_run_functional_mixed_effects_workflow`:

  *run functional mixed effects workflow* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_run_functional_recovery_scenarios`:

  *run functional recovery scenarios* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_run_generalized_functional_workflow`:

  Fits the declared generalized GEE. With `python_boundary_mode = TRUE`,
  uses source-order design, version-one workflow audit fields, measured
  fit time, resolved input declarations and source-style fit reporting.
  The default retains the existing native workflow record.

- `etr_run_recurrence_workflow`:

  *run recurrence workflow* – an explicit exported method; consult its R
  formal arguments and source-contract restrictions.

- `etr_run_sparse_fpca_workflow`:

  *run sparse fpca workflow* – an explicit exported method; consult its
  R formal arguments and source-contract restrictions.

- `etr_run_sparse_mfpca_async_workflow`:

  *run sparse mfpca async workflow* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_run_sparse_mfpca_workflow`:

  *run sparse mfpca workflow* – an explicit exported method; consult its
  R formal arguments and source-contract restrictions.

- `etr_run_sparse_multilevel_workflow`:

  *run sparse multilevel workflow* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_run_sparse_prediction_workflow`:

  *run sparse prediction workflow* – an explicit exported method;
  consult its R formal arguments and source-contract restrictions.

- `etr_plot_workflow_result`:

  *plot workflow result* – an explicit exported method; consult its R
  formal arguments and source-contract restrictions.

- `etr_save_workflow_figure`:

  *save workflow figure* – an explicit exported method; consult its R
  formal arguments and source-contract restrictions.

## Value

Each function returns its own documented native R, scientific-model,
bridge, workflow or audit result; no single shared return type is
asserted.
