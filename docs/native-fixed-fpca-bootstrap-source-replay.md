# Fixed-unit FPCA bootstrap source replay (native R)

Pinned frozen Python `eyetrajectoriespy==1.2.0` commit `c1cd95ad718327550f7e55393ff38582872f7a94`: `stability.py` functions `bootstrap_fpca_component_envelopes`, `bootstrap_fpca_stability`, `_bootstrap_curves`, `_bootstrap_participants`.

Two preexisting native R methods now accept optional `bootstrap_unit_indices`:

- `etr_bootstrap_fpca_component_envelopes(..., bootstrap_unit_indices = draws)`
- `etr_bootstrap_fpca_stability(..., bootstrap_unit_indices = draws)`

`draws` is a length-`n_bootstrap` list. Each numeric vector contains zero-based indices of **whole source curves** (curve mode) or **whole source participant labels in first-seen order** (participant mode). A valid vector has the corresponding number of units, includes no negative, fractional, missing or out-of-range values, and may repeat units. Participant draws duplicate whole sets of within-participant curves and relabel repeated participant copies to keep them distinct.

This allows a frozen Python 1.2 NumPy `Generator` to provide source-identical bootstrap samples, so R and Python can compare matched component similarities, assignments, pointwise envelope quantiles, and explained variance ratios without confusing RNG engines with estimator behavior. The default remains native R's isolated RNG stream. Supplied draws never change `.Random.seed`.

**Scope:** this native-only audit extension is **not a parameter in Python's public interface**. Its presence does not establish full input/return-class parity, bitwise PCG64 identity, all degenerate FPCA eigenspaces, coverage guarantees, or independent scientific certification. Pointwise envelopes are descriptive, not calibrated confidence intervals. The source gap remains unresolved.
