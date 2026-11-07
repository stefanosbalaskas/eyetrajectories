# Batch 36: joint functional B-spline participant random slope

Source: frozen `eyetrajectoriespy` 1.2.0, commit `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/functional_mixed_effects.py`.

This adds an explicitly declared, native-R Gaussian joint mixed model:

- fixed coefficient functions fitted on the observed common time grid with clamped B-splines;
- one participant random intercept function AND exactly one participant random slope function;
- a single **unstructured** covariance over the two concatenated random-effect spline coefficient blocks (including intercept–slope covariance);
- independent, homoscedastic Gaussian observation residuals;
- `nlme::lme` ML or REML optimization, with strict failure on nonconvergence;
- independently checked full marginal covariance identity, GLS fixed coefficients and fitted/residual reconstruction.

This version requires the selected slope predictor to vary within **each** participant, and the number of participants to exceed the number of free unstructured covariance parameters. These constraints mirror the source's guarded random-slope model. It does **not** add nested trial effects, structured residual correlation, multiple random slopes, exact statsmodels optimizer settings or Python dataclass API.

The existing pointwise REML and joint random-intercept methods are **not replaced**. The random-slope implementation is a separate public R function, using its own class with a compatible coefficient reporting interface. R and Python RNG differences are irrelevant to deterministic fitting but optimizer conventions and variance estimates can differ numerically. No 508-contract gap is closed by this batch without full-domain developer evidence and independent certification remains 0.
