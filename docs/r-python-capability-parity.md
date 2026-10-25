# R–Python capability and qualification matrix

**Source census:** Python `main` at `22da0659c7934b5a075701b7be0b7173f4c81f18`
(checked 26 October 2026) retains exactly **362 root public functions +
18 workflow functions**; both namespaces additionally declare **128 other
public class/configuration/constant exports** in aggregate. Compared with
the R package's recorded Python snapshot at
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`, there were
**zero additions or removals** in either public function list.

The private R package at 0.4.0.9000 declares **380 named Python-backed
function wrappers** and 3 catalog/verification helpers (`etpy_*`),
88 separate native-R `etr_*` exports and 14 original `et_*` bridge exports.
Unlike a simple function count, this is **not 380 distinct native R
algorithms**, and native function names do not imply mathematical parity.
Root and workflow nonfunction symbols are retrieved through
`etpy_get_export()` rather than individual named R classes.

## Capability tiers

| Python capability family | Native R 0.4.0.9000 status | Python-backed R | Remaining qualification |
|---|---|---|---|
| Trajectory objects, long-form data, basic preprocessing, kinematics, distances | Implemented core, subset of Python options and transformations | Public wrappers available | Numerically compare input constraints, scaling, irregular sampling and edge cases |
| Dense weighted FPCA/MFPCA, scores, reconstruction, plotting | Native common-grid core | Available | Sign/subspace-invariant and weighting parity across designs |
| Basic recurrence, cross recurrence and RQA | Native core | Available | Radius selection, embedding, history and reference formulas |
| Sparse univariate FPCA | `fdapace` adapter (not Python's estimator) | Available | Sparse recovery, observation-process bias and smoothing choices |
| Asynchronous/joint sparse MFPCA, cross-channel covariance, sparse multilevel inference | No complete independent native R counterpart; marginal per-channel adapter only | Available | Very high; numerical oracle, irregular timestamps, covariance and missingness |
| Descriptive multilevel FPCA and integrated variances | Native descriptive decomposition | Available | Does not equal hierarchical functional mixed-effects inference |
| Functional mixed effects, full covariance refitting, residual diagnostics, nested random effects | Limited native `refund` adapter | Available | High; convergence, covariance, coverage and inference |
| Function-on-scalar, generalized regression, future prediction, wild bootstrap | Limited native scalar-on-FPCA and optional functional model | Available | High; coefficient/prediction intervals, selection and CV |
| Group/participant simultaneous functional bands | Experimental native fixed-SE cluster bootstrap | Available | **Failing coverage benchmark**; smallest-cluster undercoverage persists |
| Registration, landmark alignment, phase-aware FPCA, elastic and compositional FPCA | Not independently ported | Available | Alignment/warping correctness, geometry and component invariance |
| Recurrence networks, time-varying RQA, nonlinear Lyapunov/return maps, multivariate surrogates | Basic recurrence only | Available | Nonlinear test sensitivity, null construction and spectral leakage |
| Conditional TE and transfer sensitivity | Discrete plug-in plus circular-shift descriptive diagnostics | Available | Conditioning, autocorrelation, finite-sample bias and inferential null calibration |
| Outlier/conformal anomaly, FPCA subspace/score uncertainty and spectral inference | Selected spectrum bootstrap only | Available | Coverage, stability, calibration and held-out validity |
| Portable result contracts, full recovery scenarios, reporting and complete workflow orchestration | Partial native plotting/workflows; no 1:1 implementation | Available | Schema compatibility, serialization and full pipeline integration |

**'Available' means a corresponding `etpy_*` wrapper is exposed and the
installed Python 1.2.0 public census passed on the author's Windows R
setup. It does not certify that every function has been executed end-to-end.
Individual Python functions can require optional backend dependencies or
have model-status caveats of their own. Scientific validity is not
transferred automatically across implementations.

## Engineering evidence vs scientific evidence

- Author-executed Windows 11 / R 4.6.1 `R CMD check --as-cran`: **0 errors,
  0 warnings, 1 incoming NOTE** (new submission and dev version).
- `etpy_verify_api(strict=TRUE)`: passed for the installed Python backend,
  with all **380/380 functions** available/callable. Only selected wrapper
  functions received behavioral integration tests.
- Five native ggplot2 demonstration figures have now rendered on Windows
  using `ggplot2 4.0.3`, without importing Python.
- Native simultaneous-band Monte Carlo at N=12,24,48 produced group
  coverage .65/.79/.84 and participant mean coverage .63/.89/.86 (100
  studies per cell, B=399), nominal target .90.
- Follow-up paired interval simulations, 30 studies per cell and B=199,
  found fixed-SE bands under-covered. Gaussian Bonferroni reference
  coverage was higher but at materially increased interval width. The
  reference is not a generally validated replacement.
- GitHub Actions private-runner admission unresolved; Linux/macOS checks
  remain unexecuted.

## Prioritized completion paths

### Full hybrid-capability release

Keep native/optional Python implementation labels explicit. Require:

1. Full matrix of dependency-availability and representative end-to-end
   execution for all Python API families (not necessarily 380 individual
   model fits), including data/class/object conversion and workflow I/O.
2. Independent scientific qualification of any inferential methods that
   will be documented as calibrated; avoid claiming universality for
   functions with failed or absent coverage evidence.
3. Portability checks on Windows, Linux and macOS, at least supported R
   release and prior release, plus a defined supported Python range.
4. Public repository and valid package URLs, non-development version,
   CRAN policies, stable documentation and change management.

### Native-only R core release

Scope a first release to scientifically defensible trajectory, preprocessing,
kinematics, weighted dense FPCA, distances, descriptive recurrence and
plots, plus explicitly qualified optional sparse/descriptive methods.
Keep experimental simultaneous bands and unvalidated inference behind
clearly named research-facing interfaces, not as calibrated methods.
Full parity with Python is **not necessary** for a useful R-native release.

### Genuine native parity with all Python 380 functions

This is a separate, multi-stage research and engineering program,
not a cosmetic export exercise. Especially challenging are asynchronous
multivariate sparse covariance, multilevel inference, wild bootstrap
selection/multiplicity, phase/elastic geometry and non-Gaussian function
regression. A one-to-one translation is neither required nor always
desirable; equivalence needs frozen contracts and independent oracles.

## Reproducible structural report

Run from the cloned R project root:

```r
source("scripts/report_python_r_capabilities.R")
```

Outputs in `artifacts/capability_parity/` include all 380 callable
wrappers, 128 additional symbols, all 88 native exports, source SHAs,
candidate R-native analog names, and a summary. Native analogs are
**potential tests**, not verified equivalents. Optional check of the
installed Python export list requires:

```r
Sys.setenv(ET_CAPABILITY_CHECK_PYTHON = "true")
source("scripts/report_python_r_capabilities.R")
```

**Release decision: HOLD.** Full API breadth and a clean Windows package
check alone are insufficient evidence for fully native or scientifically
qualified Python parity.
