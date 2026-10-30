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
