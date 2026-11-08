# Batch 39 — one joint native participant slope + nested trial + serial covariance model

Frozen Python reference: `eyetrajectoriespy` 1.2.0, `functional_mixed_effects_nested.py`, pinned SHA `c1cd95ad718327550f7e55393ff38582872f7a94`.

## Scientific target

The new **additive** function `etr_fit_joint_bspline_functional_nested_slope()` fits one joint Gaussian B-spline mixed-effects model:

- Fixed smooth functions for the intercept and declared scalar predictors.
- Participant-specific **random intercept and random slope functions**, with one unrestricted covariance over the stacked B-spline coefficients, including their cross-covariances.
- Trial-specific functional random intercepts, using their **own** unrestricted B-spline coefficient covariance. One source curve represents one trial; a trial label can recur across different participants, but not within one participant.
- Within-trial observation errors are homoscedastic Gaussian with either `iid`, index-lag `ar1` on an equally spaced time grid, or physical-time `exponential` on regular or irregular grids. Residual correlation never crosses trial boundaries.
- Joint `nlme::lme` ML or REML estimation of covariance components and fixed basis coefficients, conditional Gaussian BLUP reconstruction for each random level, fixed function pointwise SEs from fitted coefficient covariance.

### Domain restrictions

A known finite numeric predictor must vary within every participant; one named random slope only. Participant count must exceed the number of freely estimated participant covariance parameters (guard inherited from Batch 36). Each participant has at least two trials; trial-level covariance dimension must be identifiable. Complete common-grid data only, non-simplex Gaussian response, B-spline degree 1–5. The `nlme` backend must converge; **no optimization fallback** and no fabricated values. A participant-only preliminary fit is used for input/design validation and may reject some cases before the more complex joint optimizer is attempted.

The default trial random basis size is **4**, not 3, because the default cubic B-spline degree requires at least degree+1 basis functions.

### Limitations and evidence

The native R optimizer, covariance parameterization, finite-tolerance convergence diagnostics, output representation, and boundary/error behavior are *not* bitwise or full-contract identical to Python's profiled Gaussian `L-BFGS-B` backend. This function is a bounded **scientific analogue**. Neither a source gap closure nor third-party certification is claimed.

The bundled independent numerical Python tests check spline and random-effect design, block-diagonal physical-time and AR(1) residual kernels, nested participant/trial Gaussian covariance, and exact GLS/BLUP normal equations. The bundled R tests reconstruct the **estimated** marginal covariance from R's fitted variance components, then check GLS, BLUP, prediction identity, and fail-closed domains. These R tests require actual execution in the user's RStudio environment; they have not been executed during author-side preparation.

### Preservation and release

The guarded installer requires **`8d17c18`** (Batch 38), adds one new R source/test/Rd/scope file and one `NAMESPACE` export, preserves previously qualified scientific files, and does not modify the frozen-source gap ledger. Existing R qualification and CRAN results remain valid only for Batch 38 until Batch 39 is separately tested, committed and checked.
