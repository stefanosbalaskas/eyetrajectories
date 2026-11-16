# Plotting atlas — actual R functions

The [**Interactive Plotting Atlas**](plot-atlas.html) catalogs the **exported plotting functions in eyetrajectories v0.4.3** directly from its `NAMESPACE`. It distinguishes native R plotting functions from optional Python-backed R bridges, and supports search by function name, method family, and implementation type.

## Coverage and what the previews demonstrate

The atlas **opens in illustrated-only mode**, showing genuine images produced by the exact native R plotting functions in the qualified v0.4.3 source. The number of illustrated functions and rendered figures is computed automatically at every build and displayed at the top of the [live atlas](plot-atlas.html).

Uncheck **Only functions with real figures** to browse **all 160 exported plotting interfaces** (81 native R and 79 optional Python-facing). Entries marked **Docs / API only** have no independently executed preview; this is an honest missing teaching example, not a broken image. The latest counts and generator provenance are available in the [machine-generated rendering manifest](plot-atlas/MANIFEST.txt) and [independent fixture audit](plot-atlas/EXTENSION_AUDIT.txt).

This expansion extends the original nine previewed functions across:

- **FPCA inference and diagnostics:** reconstruction cross-validation, fitted component stability, influence, outlier flags, matched component envelopes and bands, score/spectrum uncertainty, subspace stability.
- **Regression and mixed effects:** held-out FPCA regression and nested CV, fitted mixed-effect coefficients, model variance decomposition, residual ACF and variograms.
- **Sparse and irregular functions:** actual irregular observation points, native univariate sparse PACE and multivariate joint PACE fits, learned covariance surfaces, component modes and score conditioning.
- **Nonlinear, trajectory comparison and registration:** embedding delay/dimension, recurrence-radius profiles, windowed RQA, joint recurrence, Poincaré return maps, parameter-sensitivity diagnostics and landmark registration.

These methods have distinct required inputs and fitted outputs. No generic image is substituted for a failed scientific fixture. The website-only builds log each candidate result and reject the publication unless the required minimum number of native functions renders correctly.

## Wave 3 — advanced inference and uncertainty

This release of the interactive site expands from **48 to a target of 62 of 81 illustrated native R plotting functions**. The generator publishes the target only when all 14 new preview functions render successfully from the qualified v0.4.3 source.

The included plots cover native paired-bootstrap FPCR **conditional-mean uncertainty**, **future-outcome prediction**, **pointwise slope uncertainty**, and an **observed-grid simultaneous slope band**. These are different estimands: a future noisy observation interval is not an interval for its expected conditional mean; pointwise percentiles do not imply simultaneous functional coverage; observed-grid simultaneous intervals are not certified between sampling times.

The wild-bootstrap graphics show fixed-target projection intervals, a fixed-family maximum-studentized simultaneous interval, maxT-adjusted versus targetwise p-values, exact-binomial **Monte Carlo precision** of bootstrap tail probabilities, and a shared-draw truncation scan. A 20-draw teaching example does not provide stable inference in extreme tails. Monte Carlo precision intervals are not effect confidence intervals, and the fixed-family maxT calculation does not establish arbitrary-subset strong familywise error protection.

The native split-conformal FPCA illustration uses independent synthetic training, calibration, and test sets. Its rank-based p-values are **marginal**, contingent on exchangeability, and are not simultaneous familywise anomaly guarantees.

**Important source-record distinction:** the covariance-sensitivity coefficient and band-width ratio plots deliberately use precomputed synthetic scientific records to exercise their exported plotting functions. They do **not** report real fitted `nlme` covariance models, paired calibrated participant-bootstrap bands, or optimizer parity. The mixed-bootstrap width comparison similarly processes explicitly synthetic bootstrap-record inputs; the generalized FoSR plot evaluates real native predictions from declared illustrative coefficients. The atlas calls these out individually and provides copyable code.

See the [Wave 3 rendering audit](plot-atlas/WAVE3_AUDIT.txt). The v0.4.3 CRAN submission tarball and its Zenodo DOI remain unchanged; website qualification is distinct from statistical validation.

## Wave 4 — nonlinear dynamics and sensitivity

Wave 4 is a fail-closed **11-function native R preview expansion**, targeting **73 of 81** illustrated native plotting exports. The corresponding images are made by calling the qualified v0.4.3 R plotting exports, not by re-creating the graphics in the browser. The [Wave 4 audit](plot-atlas/WAVE4_AUDIT.txt) lists every successful function and blocks publication when any of the eleven is missing.

**Estimator-driven fixtures:** recurrence-network degree from a native recurrence matrix; Rosenstein nearest-neighbor local divergence after native delay embedding; fixed-radius windowed-RQA window/step sensitivity; discrete transfer-entropy parameter sensitivity; and unconditional and conditional circular-shift source-null tests. Each reproduction script exposes its synthetic trajectories or discrete states, fixed parameter choices, and the direct plot function call.

**Explicit plotting-contract fixtures:** Kantz and Rosenstein/Lyapunov sensitivity sweeps, a univariate IAAFT-style surrogate-statistic histogram, multivariate IAAFT spectral-preservation diagnostics, and multivariate surrogate nonlinearity. These five directly execute the native plotting functions on declared synthetic scientific records, **not on fitted sensitivity estimators or completed IAAFT surrogate procedures**. Their reproducible code makes that distinction visible.

A recurrence network depends on its distance threshold and temporal exclusion. A positive-looking local divergence slope is not independent proof of chaos. Transfer entropy quantifies directed predictive information conditional on the stated histories, not causal effects; source-only circular shifts are particular null constructions, not universal safeguards against confounding. Overlapping windowed-RQA summaries are serially dependent and do not imply an optimal choice of window or step. Synthetic surrogate histograms provide **no calibrated p-values, spectral-preservation certification, or independently validated null model**.

The v0.4.3 submission archive, GitHub source release and [Zenodo DOI](https://doi.org/10.5281/zenodo.24288857) remain unchanged. Wave 4 changes only the website generator, documentation and qualification gates.

## Figures generated by executing the real plotting functions

The **initial atlas edition** established the following nine directly-rendered functions and 16 figures; the current catalogue contains the expanded scientific coverage described above:

| Actual exported R function | Preview comparison |
| --- | --- |
| `etr_plot_trajectories()` | Inverted screen Y versus Cartesian Y |
| `etr_plot_planar_trajectories()` | Two alpha/opacity settings |
| `etr_plot_fpca_variance()` | Cumulative versus individual components |
| `etr_plot_fpca_component()` | ±1 versus ±2 score standard deviations |
| `etr_plot_recurrence()` | Two explicit recurrence radii |
| `etr_plot_dynamic_time_warping_alignment()` | Matched versus phase-shifted series |
| `etr_plot_functional_band()` | Experimental simultaneous versus pointwise bands |
| `etr_plot_sparse_support()` | Observed sparse sample coverage |
| `etr_plot_transfer_surrogates()` | Circular-shift transfer entropy surrogate distribution |

Every image is a **direct result of calling the listed exported function** in the qualified v0.4.3 R source, not a separately drawn JavaScript approximation or imitation.

The atlas lets you change between *previously computed* R plot settings in a browser. It **does not execute R client-side**, make new statistical estimates, or claim dynamic recomputation. Select any preview to see exact R source code for reproducing that variant on synthetic data.

## All the other plotting exports

The full searchable catalogue is generated programmatically from the qualified package's actual `NAMESPACE` and `reference/` HTML files at website build time. An export without an independently rendered preview is explicitly marked **Docs / API only**. Python-backed plotting interfaces are catalogued but **never executed** as native R methods.

## Reproducibility and limitations

The [website-only generator](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/build_plot_atlas.R) runs the exported functions, writes image files and a machine-readable catalogue, and verifies each resulting PNG exists.

This is a **teaching and API-discovery atlas**, not an independent estimator validation study. Gaze data are synthetic; experimental bands do not imply calibrated interval coverage; transfer-entropy plots do not show causality. R and Python graphics backends are not considered pixel-equivalent.

For context, see the [scientific figure gallery](SITE_GALLERY.html), [methods](SITE_METHODS.html), [function reference](reference/index.html) and [qualification boundaries](SITE_VALIDATION.html). The exact [GitHub v0.4.3 source release](https://github.com/stefanosbalaskas/eyetrajectories/releases/tag/v0.4.3) is archived at [Zenodo DOI 10.5281/zenodo.24288857](https://doi.org/10.5281/zenodo.24288857).
