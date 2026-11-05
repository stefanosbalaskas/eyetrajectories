# Frozen Python 1.2 FPCA score-distance source domain (Batch 10)

Source: `eyetrajectoriespy==1.2.0` at `c1cd95ad718327550f7e55393ff38582872f7a94`, `analysis.py::score_distance_matrix`.

The frozen source reads `fpca.n_components` for the default, validates an integer slice count against that *declared* value, and then evaluates `fpca.scores[:, :n_components]`. **NumPy slicing silently truncates an excessive positive stop index to the actual score matrix width**. The existing native implementation previously required `fpca$n_components <= ncol(fpca$scores)` even for minimal, duck-typed objects in Python boundary mode and would reject legitimate source inputs. That is now relaxed **only** in `python_boundary_mode=TRUE`; the requested integer slice stops at `min(k, ncol(scores))`. Dense and native sparse `Matrix` paths both implement the same finite Euclidean geometry.

The source also permits a finite nonintegral declared component count when the caller explicitly supplies a valid integer `n_components` that passes source comparisons. The native boundary mode now admits that bounded subset, but still rejects an implicit float slice. Strict native R behavior and the source FPCA fit validation remain unchanged.

Direct opt-in pinned source witnesses live in `tests/testthat/test-native-score-overdeclared-source.R`, including Python `types.SimpleNamespace` and SciPy sparse input. The installer does not run R or Python from GitHub.

**Residual scientific boundaries:** NumPy indexing protocols, full Python duck-typing and exact sklearn overflow/exception classes, out-of-domain and nonfinite FPCA metadata, and independent full-contract review. The ledger stays `unresolved_source_gap=TRUE`, with zero independent certifications. The recorded count remains 204, not an implementation percentage. Developer R/Python test passes cannot be represented as signed independent reviewer approval.
