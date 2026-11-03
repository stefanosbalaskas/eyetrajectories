# Native scalar-on-function via FPCA scores — frozen Python 1.2

**Source of record:** `eyetrajectoriespy==1.2.0`,
`src/eyetrajectoriespy/analysis.py::fit_scalar_on_function_regression()`,
immutable source commit `c1cd95ad718327550f7e55393ff38582872f7a94`.

## Previously documented functional gap

The mapped native R callable `etr_fit_scalar_on_fpca()` originally
estimated only finite Gaussian least-squares regression of a scalar outcome
on retained FPCA scores, with a fixed minimum independent-curve count and no
covariates. Frozen Python also supports binomial logit GLM and optional
curve-aligned covariates, and returns coefficients, in-sample predictions,
family, retained component indices and provenance. A matching function
name alone never established scientific equivalence.

## New bounded native scientific implementation

`etr_fit_scalar_on_fpca(...,family="gaussian",covariates=NULL,
python_boundary_mode=TRUE)` enables a *Python-free* R source analogue
with: 

- `gaussian`: full-rank ordinary least squares, including an explicit
  intercept and ordered `FPC1`, `FPC2`, ... predictors.
- `binomial`: logit-link GLM with binary (0/1) outcomes and the same
  explicit predictors. Uses native `stats::glm`/IRLS instead of Python
  statsmodels.
- Optional finite numeric or Boolean curve-aligned R `data.frame`
  covariates. Uses their documented order and names, rejects missing
  data, name collisions, malformed identifiers and rank-deficient
  designs in this bounded native scientific mode. Python may accept
  additional pandas dtypes/rank-deficient designs; those differences
  remain open.
- Frozen Python-compatible 0-based `component_indices`, named
  `coefficients` (including `const`), `predictions`, `family`
  and scientific provenance, alongside native `model`, original
  FPCA basis and R curve IDs.
- Optional downstream native
  `etr_predict_scalar_on_fpca(fit,x,covariates=...)`
  with matched numeric covariate names and binomial response-probability
  predictions.

**Existing default remains unchanged:** no new family/covariate choice,
the original minimum sample-size guard, Gaussian `stats::lm`,
`etr_scalar_on_fpca` class and prediction method. No implicit
conversion to Python, no automatic re-fitting of FPCA in regression,
and no silent statistical inference or bootstrap claims.

## Direct source verification

`tests/testthat/test-native-scalar-on-fpca-source-domain.R`
provides four grouped scientific regressions, with frozen Python source
calls to the actual `fit_scalar_on_function_regression` export for
both Gaussian and binomial regressions, comparing coefficients and fitted
values on the identical native FPCA score design and covariate matrix.
Further native tests cover conditional predictions, binary validation,
retained component counts, source Boolean index semantics, invalid
covariates and a rank-deficient design.

The test file is registered in BOTH
`native_r_offline` and `python_1_2_direct_source` filters plus
the source-file evidence inventory. **The new research HEAD must pass
an exact-head Windows RStudio run before this new batch can be treated
as qualified.**

## Explicit source and review boundaries

This is a bounded numerical-estimand analogue, not complete Python
API parity: R `lm`/`glm` class and solver objects differ from
statsmodels, pandas and Python dataclass identities differ from native
R structures, rank-deficient and nonfinite contracts remain restricted,
and separate independent full-domain review remains unsigned.
No evidence here closes one of the 204 source-gap exports or updates
0/508 independently certified contracts. The separately qualified
staged CRAN 0.4.2 candidate is unchanged and does **not** include
these research branch updates.
