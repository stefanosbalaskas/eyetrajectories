# Score distances: frozen Python 1.2 numerical boundary

Source: `eyetrajectoriespy==1.2.0` (`c1cd95ad718327550f7e55393ff38582872f7a94`), `analysis.py::score_distance_matrix`, which calls `sklearn.metrics.pairwise_distances(..., metric="euclidean")`.

## Implemented numerical domain

The **opt-in** `etr_score_distance_matrix(..., python_boundary_mode=TRUE)` computes dense and sparse Euclidean distances from squared row norms and a Gram product, clamps negative squared distances to zero, then resets the diagonal. Python/scikit-learn applies essentially the same numerical recurrence; source-style overflow of large finite score coordinates can yield `Inf`, and `Inf - Inf` can yield `NaN` off diagonal. A small genuine score separation can disappear under cancellation at large offsets. This is a **numerical compatibility mode**, not a claim of more accurate scientific distances.

Without `python_boundary_mode`, native dense `stats::dist` remains the stable, science-oriented calculation, including on extreme inputs. For sparse source inputs, a native 5-million-output-cell resource bound remains (as do stricter input and metadata-domain limitations). The dense source-compatible branch uses the same bound; strict dense mode does not. No interpolation, imputation, or stochastic calculation was introduced.

## Evidence and limitations

The new mandatory tests compare the finite normal-score domain and the extreme source numerical categories: distinct large orthogonal scores produce infinite off-diagonal distances, whereas coincident very large scores can produce indeterminate off-diagonal distances in the squared-norm/Gram calculation. Direct frozen-Python oracles are run only when `ET_RUN_PYTHON_TESTS=true`; the native offline tests run without Python. Tests also verify native default preservation and that the source-gap ledger is still unresolved.

**Do not infer full-domain numerical or software-class parity.** Exact last-bit results for ill-conditioned finite inputs depend on BLAS precision, sklearn implementation, overflow order and platform. Full scikit-learn dtype/coercion, error classes, all object inputs and unbounded memory behavior are outside this bounded native implementation. Independent GPG-attested external review is still absent. The ledger remains unresolved and the full-contract certification count is unchanged.
