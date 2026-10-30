# Source qualification dossier: generalized FoSR fixed-profile prediction and mixed reporting

**Published source:** eyetrajectoriespy 1.2.0 at `c1cd95ad718327550f7e55393ff38582872f7a94`.

**Status:** native R candidate implementations with direct published-source numerical
and text oracles; neither has complete behavioral/schema scientific approval
or independent source reviewer sign-off. **FULL certification is 0/508.**

## Native functions (public identifiers contain no numbered stages)

| Python 1.2.0 source | Native R | Supported subset | Unresolved contract |
| --- | --- | --- | --- |
| `generalized_function_on_scalar_predict` | `etr_generalized_function_on_scalar_predict` | Fixed numeric profile predictions on observed grid; binomial probability; Poisson count/rate and explicit target exposures; robust covariance propagation; retained extrapolations | Source typed fit and pandas profile coercion; complete GEE estimator provenance; numerical and error-boundary review |
| `functional_mixed_effects_reporting_text` | `etr_functional_mixed_effects_reporting_text` | Exact source no-band text for declared mixed model, including random-slope, nested trial and correlation descriptions and diagnostic warnings | Bootstrap band paths intentionally fail closed; source dataclass identity and complete numerical string-format boundary |

## Differential evidence

- `tests/testthat/test-native-generalized-fosr-prediction.R`: native validation,
  fixed profile sensitivity, exposure scale separation, direct Python 1.2
  numeric arrays and extrapolation flags across four primary fixtures.
- `tests/testthat/test-native-mixed-model-source-text.R`: native descriptive
  and fail-closed tests plus two exact Python 1.2 output-string oracles.
- Both suites are opt-in for direct Python with `ET_RUN_PYTHON_TESTS=true`.
  The controlled offline and Python modes and file-integrity hashes are saved by
  `scripts/capture_native_source_qualification_evidence.R`.
- Frozen Python 1.2.0 does **not** return R native record classes or base R
  data.frames; a passing numeric oracle is not a complete public API certification.

## Required for fully certified source contracts

1. Independent replay of both local test modes from the exact R commit and the
   pinned published Python release, storing complete logs and environment.
2. Domain-wide evidence for profile ID type coercions, duplicate/missing
   predictors, zero/negative/huge Poisson exposures, covariance PSD and
   near-boundary linear predictors, empty profile frames, extrapolation
   tolerance and Python error class/text.
3. Complete review of generalized model's source fit typing, GEE robust
   covariance, participant clustering and result provenance. Fixed-profile
   predictions must not be presented as independently qualified estimation.
4. For the mixed text function, full trial/random-slope/reml/ML and residual
   correlation branches, Python float formatting, all warnings and both
   bootstrap-band inference pathways, including references to source fit.
5. Signed independent review identifying exact source tag and commit and
   resolving entries in `native_source_contract_gaps_stage22.csv`. Until
   then, all four approval controls remain FALSE and the native catalog's
   `require_complete=TRUE` gate must fail.

No estimator, model-selection rule, bootstrap law or reported scientific
hypothesis-test decision is altered by these two ports.

## Additional native fixed-profile contrast

\`etr_generalized_function_on_scalar_mean_difference_band()\` constructs
one **predeclared** contrast from retained bootstrap predictions, using source
sample standard deviations and NumPy higher quantiles of observed-grid
maximum standardized deviations. It distinguishes binomial probability
difference, Poisson expected-count difference, rate difference and log-scale
rate ratio and never clips physical bounds.

Direct published-Python source numerical oracles are in
\`tests/testthat/test-native-generalized-fosr-contrast-source.R\`.
The unsigned candidate review queue now includes **58** functions; all
remain blocked from FULL certification until complete accepted-domain,
error-schema, upstream-estimator provenance, scientific inference and
independent reviewer evidence are approved.

## Known-truth recovery evaluator source contracts

The new stage-free native functions \`etr_evaluate_hierarchy_truth_recovery()\`
and \`etr_evaluate_registration_recovery()\` read retained simulator truth;
neither simulates, refits, selects a model or alters the observed data.

- The hierarchy audit reproduces Python 1.2.0 population variance (ddof=0)
  across curve, participant and trial score sources. It retains component
  indexes as **zero-based** scientific metadata and omits relative errors
  for declared variances <= 0 as in the source.
- The registration audit compares fitted h(t) to the inverse of source
  generating phase warp w(t) on an **exactly matching grid**, using
  source-equivalent trapezoidal weights, and returns integrated and maximum
  absolute inverse-warp errors.
- Both now carry source-shaped metric metadata, numeric and structure
  fixtures, and direct Python 1.2.0 oracles in
  \`tests/testthat/test-native-recovery-source-evaluators.R\`.
- The explicit Python source-dataclass identity, interpolation boundary
  behavior for nonmonotone/repeated warp positions, accepted input domain,
  Python exceptions and full independent review are unresolved.
  Do **not** report these as FULL certified source contracts.

The dual-mode evidence queue contains **60** candidate scientific contracts.
The frozen API has **334/380** named native function mappings and
**156** registered unresolved source-difference entries.
Every contract remains unsigned pending full-domain independent assessment.

From the PR #48 checkout run:

\`\`\`r
pkgload::load_all(".", quiet = TRUE)
source("scripts/qualify_native_current_contracts.R")
source("scripts/capture_native_source_qualification_evidence.R")
\`\`\`

## Coefficient-band source calibration, frozen Python 1.2.0

- \`etr_generalized_function_on_scalar_simultaneous_bands()\` projects
  retained whole-participant coefficient draws onto observed-grid
  link-scale coefficient bands. For source coefficient SE cells <=
  machine epsilon, the published Python implementation excludes those
  coordinates from standardized maxima; the native code preserves this
  behavior and is explicitly tested for large deviations in zero-width cells.
- \`etr_functional_mixed_effects_simultaneous_bands()\` instead requires
  strictly positive bootstrap standard errors, studentizes about the
  **bootstrap mean**, and centers calibrated endpoints about the original
  fitted coefficient functions. It requires a declared source
  \`bootstrap_type\` representing the fixed-covariance or full-refit
  Python result class; the full-refit provenance flag is not inferred.
- Both use frozen Python's higher empirical quantiles of standardized
  observed-grid coefficient-wise or family-wise maxima. Both have
  opt-in direct published Python 1.2.0 numerical comparison tests.
- Neither path generates new bootstrap replicates or changes estimated
  model coefficients. Source typed-class acceptance, covariance-uncertainty
  interpretation, error schemas and accepted input boundaries remain under
  unsigned independent review.

The review queue has **62** source contracts; **all remain uncertified**.

## Functional mixed-effects known-truth recovery: time-domain source contract

\`etr_evaluate_functional_mixed_effects_recovery()\` adds an explicit
source-shaped evaluator for retained Gaussian functional mixed-effects fits.
The estimator must have no functional random slope, the response dimension
and fixed intercept must be declared, and the time grid must match latent
truth **exactly**.

The evaluator scores the fitted intercept and participant random-intercept
time-domain variance \`diag(B Sigma B^T)\` against the latent generating
variance \`sum_k lambda_k phi_k(t)^2\` with trapezoidal integration. A
declared trial functional intercept is evaluated independently; a truth
with positive trial variance but no fitted trial effect fails closed.

The two source scientific distinctions are retained:

1. Basis-coefficient covariance parameters are **not** treated as directly
   comparable to simulator KL eigenvalues.
2. Curve-level functional KL variation is **not** treated as scalar
   independent residual variance.

Source numerical fixtures and direct pinned Python 1.2 oracle:
\`tests/testthat/test-native-mixed-known-truth-recovery.R\`.

Known Python dataclass, missing-field, full accepted-domain and error-class
differences remain independently uncertified. The unsigned source queue is
now **63**. No evidence/approval flags are promoted by this addition.

## Source mixed-effects variance decomposition

The existing \`etr_functional_mixed_effects_variance_decomposition()\` now
preserves its historical \`etr_functional_mixed_moments\` behavior **while
adding a separate source-shaped frozen Python 1.2 Gaussian mixed-fit
branch**. The latter evaluates participant functional intercept variance,
functional slope variance and signed intercept/slope covariance separately.
If present, a nested trial functional intercept contributes its own
variance curve. Scalar residual variance is reported independently.

There is no automatic ranking, percentage allocation, model fitting or
covariance selection, and a signed cross-covariance is **not clipped** to
a nonnegative variance. The numerical source contract is checked with
direct Python 1.2 row-by-row oracles in
\`tests/testthat/test-native-mixed-variance-decomposition-source.R\`.
These checks do not certify the older restricted moments estimator as
equivalent to Python REML/GLS.

The scientific review inventory now contains **64 unsigned candidates**
and **160 unresolved source contract differences**. Source class identity,
full accepted inputs/errors and independent reviewer approval remain open.

## FPCA known-truth recovery (restricted one-component source domain)

The new \`etr_evaluate_fpca_recovery()\` ports source \`recovery.py\`'s
exact grid, dimension, unit scaling and one-component known-truth checks.
For a single fitted and single generating functional component, it
evaluates population mean and covariance operator ISE, signed weighted
mode similarity, aligned latent score correlation/RMSE, functional subspace
principal angle and mean reconstructed latent curve ISE. Time-major
flattening preserves source NumPy covariance quadrature geometry.

It refuses multi-component inputs rather than manufacturing a
matched-eigenspace claim: the frozen Python general source instead
uses optimal component assignment and SVD principal angles, neither of
which has yet been ported and independently certified for all cases.
The single-mode numerical subset has an opt-in pinned Python 1.2 oracle
for both one-dimensional and two-dimensional functional trajectories.
All type/domain/exception differences remain in the unresolved gap
register. This raises the review queue to 65 **unsigned** contracts.

## Sparse FPCA/PACE known-truth recovery (bounded one-mode source domain)

\`etr_evaluate_sparse_fpca_recovery()\` extends the existing exact-grid
source population recovery audit with a **direct fitted sparse covariance**
operator ISE (rather than implicitly substituting a reconstructed FPCA
operator). It retains sign-aligned score recovery, any recorded score
failure rate, finite score-system condition-number median/q95/max,
explicit covariance PSD-repair evidence, and optional measurement-noise
absolute and relative recovery error.

This port is limited to **one retained and generating mode**, one selected
sparse response dimension, finite scores and source-shaped native lists.
The source \`recovery.py\` general multi-mode and missing-score domain,
Python dataclass identity and full numerical/error contract remain
unresolved. Native fixtures and the frozen Python 1.2.0 oracle in
\`tests/testthat/test-native-sparse-known-truth-recovery.R\` exercise
independent estimated covariance, PACE diagnostics, PSD provenance,
measurement noise and exact scientific metadata.

The scientific review queue now includes **66 unsigned contracts**,
with no certified claims from these source subset fixtures.

## Retained mixed-effects bootstrap width comparison

\`etr_compare_functional_mixed_effects_bootstraps()\` implements the
published Python 1.2 \`functional_mixed_effects_full_refit.py\`
comparison of already retained fixed-covariance and full-refit
participant-cluster bootstrap simultaneous bands. Band maxima and
widths reuse the published-source-aligned native calibration
function, with coefficient-then-observed-time row ordering and
\`Inf\` when the fixed-covariance band has zero width.

There is no full model refit, resampling or covariance structure
selection in this comparison. The oracle checks both coefficient
and family simultaneous scopes directly against pinned Python 1.2.0.
Python requires both bootstrap objects to share the **same reference
fit object by identity**; R source-shaped lists can check structural
equality but cannot certify Python object identity. This remains an
explicit unresolved source gap. The evidence queue now contains
**67 unsigned candidates**, with no certification promotion.

## Sparse bivariate MFPCA known-truth recovery: one-mode source domain

\`etr_evaluate_sparse_mfpca_recovery()\` introduces the frozen
\`recovery.py::evaluate_sparse_mfpca_recovery\` numerical **one-mode**
domain, retaining four named covariance blocks (cxx, cxy, cyx, cyy)
as separate quadrature-weighted operator errors and the exact
joint total cxx+cxy+cyx+cyy. It also preserves single-component sign
alignment, score comparisons, retained sparse-PACE diagnostic rates,
finite condition-number statistics, PSD-repair signals, and the distinction
between measurement-error covariance supplied and recovered.

The source's multi-component Hungarian assignment, near-tied
eigenvalue subspace geometry, Procrustes-aligned score error, all
typed dataclass and error domains remain unresolved; the port
refuses unsupported source modes rather than inventing componentwise
recovery precision. Native tests and an opt-in pinned Python direct
numerical fixture cover the bounded domain. The review queue now
has **68 explicitly unsigned scientific source contracts**.

## Marginal future-outcome FPCR predictive intervals

\`etr_fpca_regression_future_prediction_interval()\` ports the
published \`regression_inference.py\` centered-empirical-residual
**future-outcome** uncertainty calculation from retained Gaussian
FPCR paired-bootstrap conditional-mean predictions, including marginal
per-target linear percentile quantiles, centered training residuals
and sample-standard-deviation predictive uncertainty. It never
substitutes a conditional-mean confidence interval for a noisy future
outcome prediction interval and makes no simultaneous/joint target
coverage or heteroscedastic-robustness claim.

The source independently generates residual indices with
\`SeedSequence(...).spawn(1)[0]\` and NumPy's RNG, whereas R has
a different pseudorandom stream. Optional explicit zero-based
\`residual_indices\` make Python's frozen draws reproducible
numerically in native R without falsely asserting seed stream
identity. Without supplied indices, native R draws independently
from the same centered empirical residual distribution and preserves
the caller RNG state for an explicit R seed. Scientific tests and
opt-in Python 1.2.0 fixed-draw oracles verify the numerical law.
This adds a **69th unsigned contract**, with cross-language RNG and
typed-dataclass source differences still open.
