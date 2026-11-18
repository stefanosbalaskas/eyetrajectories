# Plotting atlas — actual R functions

The [**Interactive Plotting
Atlas**](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas.md)
catalogs the **exported plotting functions in eyetrajectories v0.4.3**
directly from its `NAMESPACE`. It distinguishes native R plotting
functions from optional Python-backed R bridges, and supports search by
function name, method family, and implementation type.

For help selecting a method before browsing its graphics, use the
[Research Workflow
Portal](https://stefanosbalaskas.github.io/eyetrajectories/research-portal.md).
Its ten native workflow references deep-link to the appropriate plotting
function and explain the estimand, observation support and limitations.

## Wave 6 — scientific research interaction and reproducibility

The [interactive
atlas](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas.md)
now supports **side-by-side comparisons of two different native R
plotting functions**, with independent example settings, images, method
labels, exact documentation links and downloadable reproducible R
scripts. The existing *compare all variants* mode remains available for
contrasting different settings of a **single** plotting function.
Comparison is a visual teaching aid: plots may be based on different
synthetic fixtures, axes, input representations, estimands, and model
assumptions, and should **not** be read as a controlled
method-performance benchmark.

Every one of the **81 native plotting exports** now carries a parameter
guide extracted from the exact **v0.4.3 native R function formals**,
including its actual argument names, formal defaults and conservative
methodological explanations. The exact reference pages remain
authoritative for valid units, input structures, numerical conventions
and scientific interpretation. The 79 optional Python-facing entries
remain documentation-only; they do not acquire fictitious native R
signatures or figures.

The method filter now uses **11 nonoverlapping scientific families** for
the version-frozen native R inventory, separating functional regression
from FPCA, mixed effects from inference, nonlinear RQA from
transfer-entropy/surrogate testing, and simulation recovery from
empirical benchmarking. Previously ambiguous automatic assignments are
eliminated by failing the website build when a native function is
unmatched or matches multiple categories.

Each image is paired with a **downloadable .R reproduction script**,
containing the same actual exported R plotting call shown in the
copyable code panel, synthetic fixture setup and a **v0.4.3
package-version guard**. The [Wave 6
audit](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/WAVE6_AUDIT.txt)
records the 81 native exports, 11 categories, image count, and script
count; the [rendering
manifest](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/MANIFEST.txt)
preserves these alongside prior wave evidence.

Qualification now also executes a **headless Chromium browser test**
with desktop and mobile layouts, filtering, keyboard-controlled
comparison, two-function selection, variant changes, primary-function
switching, real .R browser downloads, error/404 monitoring and bounded
decoding of **every generated native PNG**. Screenshots are retained as
CI evidence. This browser test is a check of website behavior and
generated assets, not scientific estimator validation.

\## Coverage and what the previews demonstrate

The atlas **opens in illustrated-only mode**, showing genuine images
produced by the exact native R plotting functions in the qualified
v0.4.3 source. The number of illustrated functions and rendered figures
is computed automatically at every build and displayed at the top of the
[live
atlas](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas.md).

Uncheck **Only functions with real figures** to browse **all 160
exported plotting interfaces** (81 native R and 79 optional
Python-facing). Entries marked **Docs / API only** have no independently
executed preview; this is an honest missing teaching example, not a
broken image. The latest counts and generator provenance are available
in the [machine-generated rendering
manifest](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/MANIFEST.txt)
and [independent fixture
audit](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/EXTENSION_AUDIT.txt).

This expansion extends the original nine previewed functions across:

- **FPCA inference and diagnostics:** reconstruction cross-validation,
  fitted component stability, influence, outlier flags, matched
  component envelopes and bands, score/spectrum uncertainty, subspace
  stability.
- **Regression and mixed effects:** held-out FPCA regression and nested
  CV, fitted mixed-effect coefficients, model variance decomposition,
  residual ACF and variograms.
- **Sparse and irregular functions:** actual irregular observation
  points, native univariate sparse PACE and multivariate joint PACE
  fits, learned covariance surfaces, component modes and score
  conditioning.
- **Nonlinear, trajectory comparison and registration:** embedding
  delay/dimension, recurrence-radius profiles, windowed RQA, joint
  recurrence, Poincaré return maps, parameter-sensitivity diagnostics
  and landmark registration.

These methods have distinct required inputs and fitted outputs. No
generic image is substituted for a failed scientific fixture. The
website-only builds log each candidate result and reject the publication
unless the required minimum number of native functions renders
correctly.

## Wave 3 — advanced inference and uncertainty

This release of the interactive site expands from **48 to a target of 62
of 81 illustrated native R plotting functions**. The generator publishes
the target only when all 14 new preview functions render successfully
from the qualified v0.4.3 source.

The included plots cover native paired-bootstrap FPCR **conditional-mean
uncertainty**, **future-outcome prediction**, **pointwise slope
uncertainty**, and an **observed-grid simultaneous slope band**. These
are different estimands: a future noisy observation interval is not an
interval for its expected conditional mean; pointwise percentiles do not
imply simultaneous functional coverage; observed-grid simultaneous
intervals are not certified between sampling times.

The wild-bootstrap graphics show fixed-target projection intervals, a
fixed-family maximum-studentized simultaneous interval, maxT-adjusted
versus targetwise p-values, exact-binomial **Monte Carlo precision** of
bootstrap tail probabilities, and a shared-draw truncation scan. A
20-draw teaching example does not provide stable inference in extreme
tails. Monte Carlo precision intervals are not effect confidence
intervals, and the fixed-family maxT calculation does not establish
arbitrary-subset strong familywise error protection.

The native split-conformal FPCA illustration uses independent synthetic
training, calibration, and test sets. Its rank-based p-values are
**marginal**, contingent on exchangeability, and are not simultaneous
familywise anomaly guarantees.

**Important source-record distinction:** the covariance-sensitivity
coefficient and band-width ratio plots deliberately use precomputed
synthetic scientific records to exercise their exported plotting
functions. They do **not** report real fitted `nlme` covariance models,
paired calibrated participant-bootstrap bands, or optimizer parity. The
mixed-bootstrap width comparison similarly processes explicitly
synthetic bootstrap-record inputs; the generalized FoSR plot evaluates
real native predictions from declared illustrative coefficients. The
atlas calls these out individually and provides copyable code.

See the [Wave 3 rendering
audit](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/WAVE3_AUDIT.txt).
The v0.4.3 CRAN submission tarball and its Zenodo DOI remain unchanged;
website qualification is distinct from statistical validation.

## Wave 4 — nonlinear dynamics and sensitivity

Wave 4 is a fail-closed **11-function native R preview expansion**,
targeting **73 of 81** illustrated native plotting exports. The
corresponding images are made by calling the qualified v0.4.3 R plotting
exports, not by re-creating the graphics in the browser. The [Wave 4
audit](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/WAVE4_AUDIT.txt)
lists every successful function and blocks publication when any of the
eleven is missing.

**Estimator-driven fixtures:** recurrence-network degree from a native
recurrence matrix; Rosenstein nearest-neighbor local divergence after
native delay embedding; fixed-radius windowed-RQA window/step
sensitivity; discrete transfer-entropy parameter sensitivity; and
unconditional and conditional circular-shift source-null tests. Each
reproduction script exposes its synthetic trajectories or discrete
states, fixed parameter choices, and the direct plot function call.

**Explicit plotting-contract fixtures:** Kantz and Rosenstein/Lyapunov
sensitivity sweeps, a univariate IAAFT-style surrogate-statistic
histogram, multivariate IAAFT spectral-preservation diagnostics, and
multivariate surrogate nonlinearity. These five directly execute the
native plotting functions on declared synthetic scientific records,
**not on fitted sensitivity estimators or completed IAAFT surrogate
procedures**. Their reproducible code makes that distinction visible.

A recurrence network depends on its distance threshold and temporal
exclusion. A positive-looking local divergence slope is not independent
proof of chaos. Transfer entropy quantifies directed predictive
information conditional on the stated histories, not causal effects;
source-only circular shifts are particular null constructions, not
universal safeguards against confounding. Overlapping windowed-RQA
summaries are serially dependent and do not imply an optimal choice of
window or step. Synthetic surrogate histograms provide **no calibrated
p-values, spectral-preservation certification, or independently
validated null model**.

The v0.4.3 submission archive, GitHub source release and [Zenodo
DOI](https://doi.org/10.5281/zenodo.24288857) remain unchanged. Wave 4
changes only the website generator, documentation and qualification
gates.

## Wave 5 — complete native R graphics (81/81)

The final website-only wave adds the **eight previously unillustrated
exported native R functions**, bringing direct illustration coverage to
**81 of 81** native plotting exports. Publication is fail-closed: every
new function must produce genuine PNG output through its own exported
native R plotting call, with copyable reproduction code, a working
documentation route, and the [Wave 5 renderer
audit](https://stefanosbalaskas.github.io/eyetrajectories/plot-atlas/WAVE5_AUDIT.txt)
showing **eight passes and zero missing functions**.

- **Native computed scientific fixtures:** observed-grid
  function-on-scalar regression, fixed-radius whole-curve RQA metric
  bootstrap, aggregation of synthetic simulation-recovery replicate
  records, and FPCA workflow plotting via its actual native result
  dispatcher.
- **Explicit synthetic plotting-contract records:** realized participant
  and nested trial random-effect functions; generalized
  function-on-scalar coefficient and profile-contrast bootstrap records.
  The generalized FoSR plots apply real native interval/contrast
  routines, but those records are not outputs of a fitted GEE or genuine
  participant bootstrap.

The RQA bootstrap resamples whole synthetic curve-level units, not the
serial observations within each curve. Functional recovery metrics are
illustrative recovery records, not independent recovery-performance
benchmarks. Synthetic random effects are not estimated BLUPs.
Generalized coefficients and bands on the link scale are distinct from
response-scale profile differences, and the four illustrative
coefficient draws are insufficient for scientific tail-probability
calibration.

**Full atlas coverage is software-demonstration coverage, not
independent statistical certification** of the underlying R estimators.
All figures remain synthetic. The optional **79 Python-facing plotting
interfaces** remain separate catalogue entries and are **not** included
in the native 81/81 numerator. The frozen package v0.4.3, CRAN archive
and Zenodo DOI are unchanged.

## Figures generated by executing the real plotting functions

The **initial atlas edition** established the following nine
directly-rendered functions and 16 figures; the current catalogue
contains the expanded scientific coverage described above:

| Actual exported R function                                                                                                                   | Preview comparison                                     |
|----------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| [`etr_plot_trajectories()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)                                      | Inverted screen Y versus Cartesian Y                   |
| [`etr_plot_planar_trajectories()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_native_visual_diagnostics.md)            | Two alpha/opacity settings                             |
| [`etr_plot_fpca_variance()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)                                     | Cumulative versus individual components                |
| [`etr_plot_fpca_component()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_native_visual_diagnostics.md)                 | ±1 versus ±2 score standard deviations                 |
| [`etr_plot_recurrence()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/native-api.md)                                        | Two explicit recurrence radii                          |
| [`etr_plot_dynamic_time_warping_alignment()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr_native_visual_diagnostics.md) | Matched versus phase-shifted series                    |
| [`etr_plot_functional_band()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr-advanced-plots.md)                           | Experimental simultaneous versus pointwise bands       |
| [`etr_plot_sparse_support()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr-advanced-plots.md)                            | Observed sparse sample coverage                        |
| [`etr_plot_transfer_surrogates()`](https://stefanosbalaskas.github.io/eyetrajectories/reference/etr-advanced-plots.md)                       | Circular-shift transfer entropy surrogate distribution |

Every image is a **direct result of calling the listed exported
function** in the qualified v0.4.3 R source, not a separately drawn
JavaScript approximation or imitation.

The atlas lets you change between *previously computed* R plot settings
in a browser. It **does not execute R client-side**, make new
statistical estimates, or claim dynamic recomputation. Select any
preview to see exact R source code for reproducing that variant on
synthetic data.

## All the other plotting exports

The full searchable catalogue is generated programmatically from the
qualified package’s actual `NAMESPACE` and `reference/` HTML files at
website build time. An export without an independently rendered preview
is explicitly marked **Docs / API only**. Python-backed plotting
interfaces are catalogued but **never executed** as native R methods.

## Reproducibility and limitations

The [website-only
generator](https://github.com/stefanosbalaskas/eyetrajectories/blob/feat/pkgdown-scientific-site-20261116/scripts/build_plot_atlas.R)
runs the exported functions, writes image files and a machine-readable
catalogue, and verifies each resulting PNG exists.

This is a **teaching and API-discovery atlas**, not an independent
estimator validation study. Gaze data are synthetic; experimental bands
do not imply calibrated interval coverage; transfer-entropy plots do not
show causality. R and Python graphics backends are not considered
pixel-equivalent.

For context, see the [scientific figure
gallery](https://stefanosbalaskas.github.io/eyetrajectories/SITE_GALLERY.md),
[methods](https://stefanosbalaskas.github.io/eyetrajectories/SITE_METHODS.md),
[function
reference](https://stefanosbalaskas.github.io/eyetrajectories/reference/index.md)
and [qualification
boundaries](https://stefanosbalaskas.github.io/eyetrajectories/SITE_VALIDATION.md).
The exact [GitHub v0.4.3 source
release](https://github.com/stefanosbalaskas/eyetrajectories/releases/tag/v0.4.3)
is archived at [Zenodo DOI
10.5281/zenodo.24288857](https://doi.org/10.5281/zenodo.24288857).
