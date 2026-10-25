# Phase 1 contract and scope

This development release is a **Python-backed R interface**, not a native
R implementation of eyetrajectories. It does not qualify new statistical
methods or alter Python results.

## Pinned scientific backend

- eyetrajectoriespy==1.2.0 (published stable Python version)
- Python >=3.11,<3.14
- R >=4.2
- reticulate>=1.41 with py_require() declaration in .onLoad()
- R release 0.1.0.9000 (unreleased development version)

The Python version and package requirements are declared when the package
is loaded. Python is **not** initialized when the R namespace loads.
First use can resolve dependencies via reticulate's managed environment,
potentially requiring internet. If an interpreter is selected explicitly
using RETICULATE_PYTHON, install eyetrajectoriespy==1.2.0 there in advance.

## Phase 1 supported entrypoints

- et_python(), et_python_version()
- et_call() for callable names present in Python __all__; root/workflows
- et_from_long() for common-grid long gaze data
- et_simulate_planar() for synthetic demonstrations
- et_fit_fpca(), et_fit_mfpca(), et_scores(), et_explained_variance()
- et_run_fpca_workflow() (typed Python configuration)
- et_plot_planar(), et_plot_fpca_variance(), et_save_plot()
- et_to_r() for explicit conversion

The published Python backend offers additional methods. et_call() exposes
the exports generically, but most are not yet covered by dedicated R
wrappers or bridge-specific integration tests.

## Scientific boundaries

The bridge inherits scientific limitations from the Python backend. In
particular, it does not claim that W3 whole-function inference is generally
calibrated or that observation-dependent missing gaze is identified.
It preserves the backend's explicit common-grid, no-hidden-interpolation
contract for et_from_long().

## Testing tiers

1. **R-only unit tests** must pass in an environment with no Python backend.
2. **Opt-in Python integration tests** must exercise real eyetrajectoriespy
   1.2.0 in Python 3.12, including simulation, FPCA, R data-frame conversion,
   declared workflow execution, and saving a matplotlib figure.
3. **Scientific cross-language parity** compares R dispatch against direct
   Python calls to the *same implementation*. This is an interface check,
   not independent statistical validation or native R-method equivalence.

No CRAN submission or native-method parity is included in Phase 1.
