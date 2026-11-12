# Native W4 workflow plot dispatch and bounded figure export

Source: frozen `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/workflows/_plotting.py`.

## Scope of the new opt-in contract

`etr_plot_workflow_result(..., strict_source_record=TRUE)` now explicitly recognizes all **seven** frozen Python 1.2 canonical plot types, with exact class-family checks and mandatory user-chosen components/coefficient identities. These are: `fpca_component`, `sparse_fpca_component`, `sparse_mfpca_component`, `function_on_scalar_coefficient`, `functional_mixed_effects_coefficient`, `generalized_functional_coefficient`, and `recurrence`. No fallback visualization, fit, calibration or uncertainty scope is selected.

The sparse paths reuse their established source-scientific native PACE component artists. Mixed coefficients reuse the pointwise 95% Wald source artist, including a field-only adapter for the **already fitted** native `nlme` B-spline likelihood; neither covariance nor the optimizer is re-estimated. Generalized coefficients reuse the existing link-scale artist. Ordinary FOS uses its original coefficient grid and native source artist. FPCA and recurrence retain explicit scientific source geometry from their existing native workflows.

The returned object is an R `etr_workflow_scientific_plot_record`, holding the plot name, embedded native artist geometry and an honest `matplotlib_object_identity=FALSE` flag. It is not a Python `matplotlib.axes.Axes`, an `ndarray` of axes, a verified pixel image, or a promise of full result-dataclass and exception-class parity. Source type checks operate on native R classes, not Python runtime objects. Recurrence does not silently decimate or sample a matrix that exceeds the declared `max_points` guard. Source axes injection is explicitly unsupported.

`etr_save_workflow_figure(..., strict_source_record=TRUE)` dispatches through the same seven-route source scientific geometry and writes real PNG, SVG or PDF files using native R devices, ensuring a nonempty output and allowing overwrite of an existing destination as Python's `savefig` does. The format suffix is case insensitive; parent directories are created. It requires a positive native device DPI not exceeding 1200 and `close=TRUE` to guarantee flushing the figure to disk. Python's `close=FALSE` retaining a live Matplotlib figure, arbitrary pixel identity, SVG deterministic `Date=None` metadata identity and Python `pathlib.Path` object identity are **not claimed**. Existing default native R safe no-overwrite and device-close behavior remain unchanged.

## Qualification and review status

Both records are **provisional developer-scoped source-scientific closures** only. Frozen Python signature/source checks and native R scientific geometry regressions are authored. Exact-head executable Linux/macOS/Windows native tests and frozen Python 1.2 differential tests must pass before any CI qualification is stated. **Independent full-contract certifications remain zero**. These changes do not qualify mixed-effects optimizer equivalence, external backends, CRAN release readiness, or full Python object parity.
