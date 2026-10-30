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
