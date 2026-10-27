# Complete Python 1.2.0 public interface in R

**Research branch / draft PR #7 — Python-backed hybrid API, not a full native R port.**

## Exact scope

The Python `eyetrajectoriespy==1.2.0` public `__all__` lists 458 symbols in `eyetrajectoriespy` and 50 symbols in `eyetrajectoriespy.workflows` (508 in total). The R package's committed source snapshot names 380 public functions and 128 other symbols (classes, configurations, constants and other public objects). Upstream current `main` exports were compared to this frozen source manifest in exact order: **508/508 match**.

The R package already exposed 380 explicit `etpy_*` and `etpy_workflow_*` Python-backed function wrappers, plus `etpy_get_export()` for nonfunction Python exports. This PR adds a convenient **complete, discoverable read-only R namespace** and explicit class/method access, without copying 508 Python algorithms into R.

| Surface | In R | Backend | Qualification |
|---|---|---|---|
| Root functions (362) | `etpy_full_surface()$root$function_name(...)` | Exact published Python 1.2.0 | Export list matched; execution depends on Python and dependencies |
| Workflow functions (18) | `etpy_full_surface()$workflows$function_name(...)` | Exact published Python 1.2.0 | Export list matched; selected smoke tests added |
| Classes, configs and constants (128) | `surface$root$Class(...)`, `surface$workflows$Config(...)`, noncallable values | Exact published Python 1.2.0 | Constructors checked for Python callability on access |
| Model/result attributes | `etpy_attribute(python_model,"name")` | Python proxy | Public attributes only |
| Model/result methods | `etpy_method(python_model,"method",...)` | Python proxy | Public callable methods only |
| Existing native R methods (98 exports) | `etr_*` | Standalone R | Scientific equivalence depends on method; separate research programme |

This surface is a **Python-backed full public API bridge**, not 508 independently written native R estimators. Some methods need optional PyPI extras and native numeric/plotting prerequisites. Private Python implementation functions and undocumented third-party methods are not added to the supported public contract.

## Install and choose the backend

```r
# Existing source checkout:
pkgload::load_all(".", quiet=TRUE)

# For the widest optional scientific backend coverage,
# call this BEFORE Python initialization:
etpy_enable_extras("all")

# Declare Python 1.2.0 API contract and check 508 symbols.
verification <- etpy_full_verify(strict=TRUE)
stopifnot(nrow(verification)==508L)
```

The package declares `eyetrajectoriespy==1.2.0` and Python 3.11–3.13 using `reticulate::py_require()` at load time, **without initializing Python**. Calling `etpy_enable_extras("all")` adds the Python distribution's own published `[all]` extra to reticulate requirements. For sparse FDApy support choose Python **3.11 or 3.12**, because the stable 1.2.0 metadata excludes the sparse extra's FDApy dependency on Python 3.13. `reticulate` may prefer an explicitly configured pre-existing environment over its managed environment; for that case install `eyetrajectoriespy[all]==1.2.0` with that interpreter and check `reticulate::py_config()`. A declaration is not proof of availability on every OS.

## R examples

```r
# This statement is lazy: no Python initialization.
py <- etpy_full_surface()

# All 362 root functions are accessible by their original Python names:
data <- py$root$simulate_planar_trajectories(
  n_participants=20L, trials_per_participant=3L,
  n_time=51L, random_state=2026L
)
fit <- py$root$fit_mfpca(
  data, n_components=1L, scaling="dimension_sd"
)
scores <- py$root$fpca_score_frame(fit, .convert=TRUE)
stopifnot(is.data.frame(scores))

# Python classes (not only functions) now have callable R constructors.
cfg <- py$workflows$FPCAWorkflowConfig(
  n_components=1L, scaling="dimension_sd"
)
workflow <- py$workflows$run_fpca_workflow(
  data, config=cfg
)
fit_from_workflow <- etpy_attribute(workflow,"fit")

# Individual calls, signatures, and Python model methods also supported:
etpy_signature("fit_mfpca")
other <- etpy_invoke(
  "FPCAWorkflowConfig",.namespace="workflows",
  n_components=1L,scaling="dimension_sd"
)
```

**Keep Python model objects unconverted** (the default) while performing methods or passing them between workflow functions. Use `et_to_r()` or `.convert=TRUE` only when R data frames, arrays or lists are the desired final outputs. Automatic R/Python conversion may lose Python class-specific metadata; no general serialization-parity guarantee is claimed.

## Complete capability report

```r
# Run only after installing/configuring a supported backend:
source("scripts/qualify_full_python_surface.R")
```

This records one row per all **508 exports**, exact version, availability and structural callability in `artifacts/full_python_surface/run_.../all_508_exports.csv`, after running the opt-in full-surface tests. Test execution includes representative Python FPCA/MFPCA and workflow methods, constructors, attributes and Python proxy method calls. **It does not actually execute every scientific algorithm in all 380 Python functions.** The `execution_tested` and `numeric_parity_qualified` columns deliberately remain FALSE at the symbol level.

## Acceptance and remaining work

The independently checked Python export manifest, full namespace code, new tests, reference documentation and CI matrix are committed in draft PR #7. The author still needs to qualify the new code on their R installation and GitHub Actions. The matrix targets Python 3.11, 3.12, 3.13 on Linux and 3.12 on Windows/macOS.

For genuine, **standalone native R implementation of all Python methods** more engineering remains—sparse asynchronous multivariate PACE, mixed-effects full refitting, regression and uncertainty inference, nonlinear surrogates, phase and elastic FPCA, plotting details, and model-result schema conversion. No number of bridge wrappers proves native numeric equivalence.

The Python scientific inference limitations also remain: W3 nominal 90% functional inference is not generally calibrated (Python issue #289), and outcome-dependent missing gaze is not field-identified (Python issue #296). Full access to a Python API does **not** make invalid intervals scientifically valid. The separate R bootstrap-calibration research holds similarly.

**Release:** research only, no CRAN upload or merge into `main` until the full CI and package-specific release gates are satisfied.


## Live Windows diagnostics and targeted repair (27 October 2026)

The owner ran the draft PR #7 bridge on **Windows / R 4.6.1 / managed Python 3.12.14**. Both diagnostic modes **PASSED**: R loading, draft exports, the lazy 508-symbol namespace, the selected Python interpreter, **508/508 live Python public-export verification**, and a real trajectory simulation. A subsequent full qualification script executed hundreds of assertions but failed **one comparison** at `tests/testthat/test-full-python-surface.R:72`. The values were compared as reticulate-converted pandas data frames: each conversion retained an independent Python `pandas.index` object, whose `pyobj` pointer address naturally differs between runs.

**Code correction:** The test now separately checks both original pandas index **values**, removes only the volatile Python `pandas.index` attachment from the local comparison copies, and then checks all remaining R data-frame values/columns/rows/metadata. It does not change numeric Python estimators or strip index metadata from returned user data.

The user's `etpy_enable_extras("all")` produced a nonfatal `reticulate::py_require` warning because Python was already initialized and `eyetrajectoriespy==1.2.0` was already declared; the attempted `eyetrajectoriespy[all]==1.2.0` requirement uses the same base package. **Code correction:** when Python is already initialized, declare only the **additional** stable 1.2.0 backend packages, matching their published exact constraints (`scikit-fda`, `multimethod`, `FDApy`, `fdasrsf`), after removing package names already declared in reticulate's requirement manifest. This respects reticulate's rule that only *new* package requirements can be added after initialization. Python 3.13 is explicitly refused for the sparse backend, which is not published there. In a fresh session the exact `eyetrajectoriespy[all]==1.2.0` extra is still declared before the first import.

**Superseded by the latest Windows execution evidence below:** both corrections were rerun by the owner and the full qualification now passes. Optional-backend-specific scientific executions and interval calibration remain separate, unverified claims.

Run from the updated feature branch:

```r
pkgload::load_all(".", quiet = TRUE)
# In an already initialized Python session, adding only missing
# published extras is supported by the revised function.
# This step is optional for the core FPCA smoke test.
etpy_enable_extras("all")
testthat::test_local(".",filter="full-python-surface")
source("scripts/qualify_full_python_surface.R")
```

CI runner-admission remains a separate unresolved issue. The R package stays unmerged and unreleased.


## Owner-run Windows hybrid qualification completed — 27 October 2026

**Full qualification: PASS on the corrected draft PR #7 implementation.**

The owner ran `testthat::test_local(".", filter="full-python-surface")`: **FAIL 0, WARN 0, SKIP 4, PASS 27**. The four skips were deliberately gated Python tests (full export inventory; two functional runtime cases; Python reflection). They were **not failures**.

The owner then ran `source("scripts/qualify_full_python_surface.R")`, which sets `ET_RUN_PYTHON_TESTS="true"` and executes the test filter again with the Python backend enabled. Its output reported **no test failures**, **FULL PYTHON 1.2 PUBLIC R SURFACE: STRUCTURAL PASS**, **508/508 public symbols available**, **380 function bridges and 128 other exports**, **all 508 names introspected for runtime type/signature**, and successful selected Python workflow execution.

The local owner-generated audit archive is:

```text
C:/Users/Stefanos-PC/Documents/GitHub/eyetrajectories/artifacts/full_python_surface/run_20261027_172215_pid51684
```

The recorded artifact path is owner-local; its CSV and manifest were **not uploaded or independently read** in this session. The confirmation is therefore grounded in the printed console output. The exact number of successful Python-enabled assertions is not printed by the full qualification transcript and is not invented here.

**Qualification boundary:** Complete structural/public-symbol access from R and the selected executable Python-backed Windows smoke tests are now validated. Full behavior tests for every one of the 380 Python functions, optional scientific backend scenario coverage, all data-shape/serialization conversions, independent *native R* numerical equivalence, and Python 3.11/3.13/Linux/macOS checks remain open. GitHub Actions still has zero-step admission failures in this repository; it has not delivered independent matrix validation.

**Release/merge:** PR #7 remains draft, based on `research/native-parity-stage1`; no release or main merge is authorized by these specific results.
