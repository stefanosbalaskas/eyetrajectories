# Stage 21 — multivariate IAAFT integration and source-contract reviewer package

Reference: published `eyetrajectoriespy==1.2.0` (annotated tag resolves to `c1cd95ad718327550f7e55393ff38582872f7a94`). Source modules: `multivariate_surrogates.py`, `nonlinear_types.py`, `compositional.py`, `analysis.py`. The independent native development branch is stacked on Stage 20 draft PR #28.

## Two new substantial Python-free numerical R implementations

1. `generate_multivariate_iaaft_surrogates` → `etr_generate_multivariate_iaaft_surrogates`: reference-anchored **multivariate IAAFT**, preserving each channel's observed empirical sample distribution exactly under stable rank remapping, and fitting original auto-Fourier amplitudes plus relative interchannel phases through iterative constrained Fourier adjustments.
2. `multivariate_iaaft_diagnostics_frame` → `etr_multivariate_iaaft_diagnostics_frame`: per-surrogate iteration, relative auto- and cross-spectral approximation errors, summarized without concealing actual retained errors.

The exact source-aligned error formulas use two-sided FFT reconstruction, with real DC and (when present) Nyquist bins preserved. The reference channel is specified rather than chosen automatically. Separate R RNG streams **do not** reproduce the source NumPy seed's stochastic draws, and the method fails closed if the requested iterations do not achieve the declared error-change threshold.

## Cumulative research inventory

| Item | Stage 20 locally qualified | Stage 21 authored |
|---|---:|---:|
| Python-free native R authored scientific methods | 146 | **148** |
| Unique mapped Python callable names | 171 / 380 | **173 / 380** |
| Unmapped Python callables | 209 | **207** |
| Numerical source-contract certification fixture pilots | 3 / 3 | **3 / 3** |
| Fully certified public source contracts | 0 / 508 | **0 / 508** |

Three Stage 20 numerical source fixtures passed under the corrected Windows RStudio verification: Stage 9 **114 PASS**, Stage 20 native **63 PASS**, frozen ledger **39 PASS**, pinned Python 1.2 oracle **84 PASS**; all zero failures and zero warnings. The latest evidence-ledger branch state also passed Stage 20 native **65** and frozen ledger **39**, showing three numeric fixture flags TRUE with full-certification FALSE. Stage 21 numerical tests are **not yet executed**, and no model was released.

## Full-contract independent reviewer checklist

Review [the Stage 20 evidence audit](full-native-r-stage20-certification-edge-audit.md) and the exact Python 1.2 tagged source. For each function, compare the entire typed valid-input domain, outputs, deterministic values, error/overflow behavior, and R-native class boundary, not merely one curve or one seed. In particular:

| Candidate | Previously passed fixtures | Open independent-review questions | Status |
|---|---|---|---|
| `alr_transform` | Reference index loop, epsilon/zero and one-channel simplex | Python `np.asarray` input acceptance, malformed arrays, NaN epsilon and negative allowable simplex tolerance | Numeric-fixture passed; full contract pending |
| `inverse_alr` | ALR roundtrips and zero-logratio one-channel shape | Source `np.exp` overflow and nonfinite outputs versus intentional native fail-closed guard; coercion/shape edge behavior | Numeric-fixture passed; full contract pending |
| `score_distance_matrix` | Published Python scikit-learn Euclidean distances on the same fitted FPC scores and component subsets | Source `FPCAResult` typed input versus Python duck-typed equivalent, zero/one-row matrices, invalid/non-finite scores and equivalent error behavior; floating error tolerances | Numeric-fixture passed; full contract pending |

**Independent reviewer signature is not present** in PR #28 at Stage 21 authoring. The GitHub review endpoint returned `[]`. No author may substitute an unreviewed TRUE flag. The machine-readable registry requires all numerical **full-domain** parity, schema/boundary, scientific-scope and independent review approvals and a GitHub evidence URL. Do not conflate an owner's validated numerical fixture PASS with a complete contract signoff.

### Reviewer evidence to provide when approval is earned

The independent reviewer should submit a GitHub PR review documenting: source release SHA; R branch/commit SHA; fixture and boundary tests executed; accepted-input/error differences and whether any remain; output numerical and schema confidence; reproducible evidence link and explicit **approve/reject** for each of the three contracts. Only approved rows can have all four gates TRUE. The registry deliberately does not automatically infer approval from numeric CI alone. If a source difference remains, retain **0/508 certified**, though restricted-domain mathematical parity may be stated separately.

## Windows RStudio qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage21-miaaft-certification")
testthat::test_local(".",filter="native-stage20-certification")
testthat::test_local(".",filter="full-native-r-parity-ledger")
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",filter="native-stage21-miaaft-certification"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

No merge, release, CRAN/PyPI publication, version bump or claim of full 508-contract equivalence.
