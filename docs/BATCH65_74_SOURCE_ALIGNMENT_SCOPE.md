# Batches 65–74 — Native nested mixed-effects source-contract wave

- Native pinned baseline: `aba74f08def45971413f5c8c766831cdd61bd02a` (qualified Batches 60–64).
- Frozen Python 1.2.0: `c1cd95ad718327550f7e55393ff38582872f7a94`, `functional_mixed_effects_nested.py` and the public `functional_trial_random_effect_frame`.
- Wave installs in one guarded operation, with one native/Python qualification and clean-snapshot CRAN-style gate.

## Actual changes

| Batch | Implementation and validation |
|---|---|
| 65 | Residual-correlation eigenvalues sorted to match NumPy `eigvalsh` (ascending); condition number |
| 66 | AR(1) transformed `atanh(rho)` and exponential `log(phi)` source-boundary semantics |
| 67 | Residual optimizer bounds, physical-time units, grid regularity/interval, explicit out-of-source-bound flag |
| 68 | Exact within-curve conditional residual whitening via Cholesky triangular solve |
| 69 | Integrate residual diagnostics into both nested native estimator results |
| 70 | Python-shaped coefficient and covariance matrix aliases, preserving old fields |
| 71 | Python participant random intercept/slope decomposition aliases |
| 72 | Source trial IDs `participant::trial`, preserving collision-safe internal `composite_trial_ids` |
| 73 | New `etr_nested_source_trial_effect_frame` returns eight Python-source ordered scientific dataframe columns (zero-based curve index) |
| 74 | Guarded install, R numerical tests, pinned Python numerical-oracle checks, full qualification and clean Git-snapshot CRAN-style check |

## Scientific boundary

The native `nlme` fitting estimators, optimizers, GLS coefficients and fitted trajectories are **unchanged**. The Python source's optimizer bounds are **reported only**, never imposed on the native estimates. `residual_correlation_outside_python_optimizer_bounds` highlights violations. The Python typed dataclass/Pandas/Matplotlib contract and full-domain covariance optimizer parity remain open.

The existing 204 documented source gaps are historical, not automatically closed by this wave. Independent certification remains 0/508. No source-gap ledger or approval register is modified.
