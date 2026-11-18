# Research Workflow Portal — Wave 7

[**Open the browser-local Research Workflow
Portal**](https://stefanosbalaskas.github.io/eyetrajectories/research-portal.md)

This website-only navigation layer complements the **immutable native R
0.4.3** release. It does not modify or run package estimators in the
browser. It combines a local CSV structure inspector, a conservative
scientific method-selection wizard and a ten-workflow mapping to actual
exported R functions and plots.

## Local gaze CSV structural preflight

Data are processed entirely in the browser; no upload, network request,
cloud persistence or statistical fitting. It accepts a long-format CSV
with participant_id, trial_id, x, y and exactly one time header: time,
time_s or time_ms. A strict quoted-CSV parser fails on malformed
columns, ambiguous headers, more than 12,000 observations or more than
1.2 million characters. Unit declarations are user-supplied; no
rescaling is performed.

The inspection reports aggregate row/participant/trial counts, repeated
trial structure, absent and nonnumeric coordinates,
missing/duplicate/out-of-order timestamps and common observed-grid
**structural compatibility only**. Exported summary JSON contains no
participant/trial identifiers, raw coordinates, raw timestamps or file
names. Clear local data erases the tab’s inputs and retained summary.

A separate explicit button can propagate an observed common-grid
structure and repeated-participant indicator into the method selector.
Failed common-grid compatibility does **not** automatically classify the
observations as sparse or asynchronously acquired.

## Method-selection wizard

The selector requires declared observed support, objective, sampling
hierarchy and uncertainty ambition. Unsupported combinations produce
**no automatic selection**; it does not silently interpolate, pool
repeated trials or assign a model. Requesting identification of
missing-not-at-random gaze from observed data alone produces a refusal.
Nominal whole-function confidence intervals remain scientifically
restricted even where a useful descriptive method exists. This is a
navigation tool, not statistical model selection, calibrated inference
or a clinical/causal decision.

## Exact ten-route native R mapping

All ten Python entries below come from the supported **Python 1.2.0
W1–W4 module-scoped** workflow layer. All ten matching R orchestration
exports and their R estimator references are verified against the
immutable R 0.4.3 NAMESPACE. Exported names do **not** demonstrate
identical estimators or complete Python source contracts.

| Python 1.2 workflow                   | Native R 0.4.3 orchestration              | Native method                                        |
|---------------------------------------|-------------------------------------------|------------------------------------------------------|
| run_sparse_fpca_workflow              | etr_run_sparse_fpca_workflow              | etr_fit_sparse_fpca_native                           |
| run_sparse_mfpca_workflow             | etr_run_sparse_mfpca_workflow             | etr_fit_sparse_mfpca_native                          |
| run_sparse_mfpca_async_workflow       | etr_run_sparse_mfpca_async_workflow       | etr_fit_sparse_mfpca_async_native                    |
| run_sparse_multilevel_workflow        | etr_run_sparse_multilevel_workflow        | etr_fit_sparse_multilevel_fpca_native                |
| run_sparse_prediction_workflow        | etr_run_sparse_prediction_workflow        | etr_sparse_fpca_partial_trajectory_prediction_native |
| run_fpca_workflow                     | etr_run_fpca_workflow                     | etr_fit_mfpca                                        |
| run_function_on_scalar_workflow       | etr_run_function_on_scalar_workflow       | etr_fit_function_on_scalar_regression                |
| run_functional_mixed_effects_workflow | etr_run_functional_mixed_effects_workflow | etr_fit_functional_mixed_effects_regression          |
| run_generalized_functional_workflow   | etr_run_generalized_functional_workflow   | etr_fit_generalized_function_on_scalar_regression    |
| run_recurrence_workflow               | etr_run_recurrence_workflow               | etr_recurrence_matrix and etr_rqa_metrics            |

Every interactive row provides source methods, documentation links, a
relevant actually rendered native-R example, its reproduction script,
method assumptions and scientific limits. Source-documentation links
fall back to the native reference index only when no generated
individual page exists; they are flagged as such. A related synthetic
graphic is not necessarily a fit from the exact named orchestration
route, especially sparse multilevel and partial-path prediction. Plots
are rendered in R before publishing, not recomputed in browser
JavaScript.

## Evidence and boundaries

The website overlay checks source NAMESPACE exports, the 81-plot native
R catalogue, generated figure PNGs and reproducible scripts, versioned
workflow definitions and internal navigation links. A headless Chromium
browser suite checks desktop/mobile behavior, CSV privacy, malformed
records, local file input, summary downloads, filtering, selection
refusals and figure navigation. The portal page also sets a restrictive
content security policy forbidding network connections. Passing website
tests is **not** evidence of numerical parity, estimator calibration,
correct missingness identification or external scientific validation.

The frozen [R 0.4.3 independent scientific source review
plan](https://github.com/stefanosbalaskas/eyetrajectories/blob/v0.4.3/docs/complete-508-independent-scientific-certification.md)
records **0/508 independently FULL-domain certified Python source
contracts**. The corresponding [Python 1.2
workflows](https://stefanosbalaskas.github.io/eyetrajectoriespy/articles/choosing-the-ten-workflows/)
are documented separately. See [R
Validation](https://stefanosbalaskas.github.io/eyetrajectories/SITE_VALIDATION.md),
[the live Plotting
Atlas](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas.md),
[generated route
JSON](https://stefanosbalaskas.github.io/eyetrajectories/research-workflows.json)
and [build
manifest](https://stefanosbalaskas.github.io/eyetrajectories/research-portal-manifest.txt).

No changes are made to the frozen R 0.4.3 package, Python 1.2 wheel,
Zenodo archive, or CRAN submission status.
