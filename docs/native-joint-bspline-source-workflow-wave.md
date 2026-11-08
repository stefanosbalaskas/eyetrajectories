# Native joint B-spline workflow: functional mixed-effects source-family path

Source pin: Python eyetrajectoriespy 1.2.0, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`workflows/_dense_regression.py::run_functional_mixed_effects_workflow`.
Native parent: `a545694e09f722a6d9e424f3088e5fa597c54dfe`.

## Scientific change

The existing `etr_run_functional_mixed_effects_workflow()` previously
offered only the deliberately non-source `two_level_functional_method_of_moments`
estimator, even after the R package acquired participant-level and nested
trial B-spline likelihood estimators (Batches 35–39, 60–74).

There is now an **explicit opt-in** mode:

```r
fit_workflow <- etr_run_functional_mixed_effects_workflow(
  trajectories, design,
  config=list(
    predictors="stimulus", participant_column="participant_id",
    dimension="response", estimator="native_joint_bspline_gaussian",
    fixed_basis_size=6L, random_basis_size=4L, spline_degree=3L,
    reml=TRUE, method="nlme::lme", maxiter=500L
  )
)
```

The source workflow and the legacy moments path remain distinct.
Exactly one estimator is chosen; there is no fallback, backend substitution,
automatic parameter/model selection, or invented elapsed-time measurement.

## Supported model routing

| Declared trial effect | Slope | Correlation | Actual R estimator |
|---|---|---|---|
| none | none | iid | `etr_fit_joint_bspline_functional_mixed_effects` |
| none | one | iid | `etr_fit_joint_bspline_functional_random_slope` |
| functional_intercept | none | iid / ar1 / exponential | `etr_fit_joint_bspline_functional_nested_trial` |
| functional_intercept | one | iid / ar1 / exponential | `etr_fit_joint_bspline_functional_nested_slope` |

To request a slope, supply `random_slope_predictor` naming a declared
predictor. To request a nested trial, supply both `trial_column` and
`trial_random_effect="functional_intercept"`. The source Python default
`trial_random_basis_size=3` does not satisfy the current native cubic
B-spline basis restriction, so **native default is 4**, and this
difference remains explicitly open in the source-gap review.

Serial correlation without a nested trial is **unsupported by this native
workflow** and fails before fitting. Nonempty preprocessing, undeclared
fields, unknown trial effects, alternative optimizers, and unsupported
covariance-family combinations also fail before fitting. If an underlying
`nlme` fit fails, the error propagates; the workflow does not return an
older moments estimator as a substitute.

## Outputs and scientific qualification limits

The workflow returns its original R S3 workflow class, a real native
likelihood-fit record, the **actual** estimator function in `steps`,
analyst-declared decisions, and a 7-column coefficient frame in the
source ordering:
`coefficient`, `time`, `dimension`, `estimate`,
`standard_error`, `lower_95_wald`, `upper_95_wald`.
Intervals are pointwise Wald, not simultaneous.

`source_python_equivalent=FALSE` and
`full_source_contract_certified=FALSE` remain mandatory because:
- R `nlme::lme` is **not** Python's statsmodels/SciPy optimization;
- the Python result is a typed dataclass with source-specific errors;
- covariance boundary, negative AR(1), weak identifiability and
  alternative optimizer behavior require further matched source tests;
- the source Python workflow includes a different reporting-text return
  and its own dataclass-backed result schema.

No recorded source-gap export is marked closed by this change.
Independent certification remains 0/508. This improves implemented
scientific family coverage for `run_functional_mixed_effects_workflow`,
not a full-API equivalence claim.

## Verification

```r
testthat::test_local(".", filter="native-joint-bspline-source-workflow",
  reporter="summary",stop_on_failure=TRUE,stop_on_warning=TRUE)
```

An additional live `nlme` integration case is explicitly opt-in via
`ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION=true`. This case is only a smoke
test, not full numerical Python oracle parity.

Run the standard `scripts/qualify_native_current_contracts.R` and a clean
Git-snapshot `R CMD check --as-cran` before merging. No independent reviewer
decision is represented by these checks.
