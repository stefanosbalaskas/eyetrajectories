# Prespecified missing-gaze and observation-process qualification protocol

**Research-only protocol — staged 27 October 2026. No missingness experiment has been executed.**

This protocol extends the [completed full-data four-distribution study](native-band-robustness-expanded-2026-10-27.md). Its purpose is to determine what can and cannot be inferred about the *full-population trajectory* and its simultaneous confidence band when gaze measurements, trials, or participants are not observed. It **does not** certify the existing fixed-SE or experimental studentized bootstrap. Existing package estimators are unchanged.

## 1. Data-generating unit and primary estimands

Generate independent participants `i = 1,...,N`, repeated trials `j = 1,...,J_i`, channels `c in {x,y}`, and a fixed population-time grid `t in [0,1]` with 41 common evaluation points. Use at least `N in {12,24,48}`, and initial `J_i=3`, with a separately prespecified unequal-trials scenario. Simulations need independent generating seeds, per-study trial records, failure reasons and nonoverlapping archives.

- **Primary full-population participant-balanced mean**: `mu_c(t) = E_i[ E_j{Y_ijc(t) | i} ]`. Participants receive equal weight **regardless of their number of observed trials or gaze samples**. For the full-data generator `mu_x(t)=sin(2*pi*t)`, `mu_y(t)=cos(2*pi*t)`. This is an unconditional population estimand, defined *before* any observation mask.
- **Primary full-population between-group contrast**: `Delta_c(t) = E[Y_c(t) | G=1] - E[Y_c(t) | G=0]`. In the null-control scenarios, the true contrast is exactly zero at every time/channel; balanced allocation and any observation-conditioned target must be recorded.
- **Secondary observed-participant estimand**: `mu_obs,c(t) = E[Y_c(t) | S=1]` where `S` explicitly identifies selected/retained participants. This generally differs from the full-population mean when attrition is informative.
- **Secondary observed-sample estimand**: conditional on observation indicator `R_ijc(t)=1`, clearly label `E[Y_ijc(t) | R=1]`. This is not equivalent to the participant-balanced full-population mean and must not be presented as such.

Under MNAR the full-population estimands are generally **not identified from the observed-data law without additional assumptions**. In simulations the generating truth is known; a reported *oracle* correction using latent unobserved quantities is a **diagnostic bound**, never a deployable estimator.

## 2. Distinct observation/selection mechanisms

All mechanisms are generated after a complete latent dataset, whose known truth is retained in the sealed simulation record. Distinct seeds govern the latent process, mask, and candidate fitting. Construct observed baseline covariate `Z_i` before missingness that predicts both participant effects and selection, ensuring MAR is nontrivial. Define `pi` explicitly and retain its realized values and clipping rules.

| Condition | Unit affected | Rule and observed information | Interpretation |
|---|---|---|---|
| Complete-data reference | None | All `R=1,S=1` | Isolates uncertainty-method behavior |
| MCAR gaze | Observation/channel/time | Bernoulli with prespecified constant probability, independent of all latent curves and covariates | Ignorable missingness under suitable assumptions |
| MAR gaze | Observation/channel/time | Retention probability depends on fully observed baseline `Z_i`, recorded time, and/or an actually observed previous measurement, never a censored future value | Identifiable only under modeled positivity and observation assumptions |
| MNAR gaze | Observation/channel/time | Retention additionally depends on the current *unobserved* latent `Y_ijc(t)`, or unrecorded latent participant effect | Nonidentifiable from observed data alone without sensitivity restrictions |
| MAR dropout | Entire participant cluster | Retention `S_i` depends on baseline `Z_i`, measured for all eligible participants | Cluster selection; do not treat missed trials as independent |
| MNAR dropout | Entire participant cluster | `S_i` depends on latent trajectory contribution not observable for dropouts | Population target needs a sensitivity analysis |
| Unequal observation density | Trial/channel/time | Prespecified time-dependent thinning and unequal valid sample counts by participant | Avoids inadvertent length-biased participant weighting |
| Sparse asynchronous | Participant/trial-specific times | Irregular independent observation grids, potentially concentrated in short windows | Sampling support and interpolation assumptions differ from MCAR/MAR |

Prespecify **mild, moderate and severe** observation rates, positivity/clipping (for simulated probability-based comparisons), empty participant–channel–time support, and the minimum number of independent observed participant clusters. Record realized missingness, not just requested probabilities. **Do not combine dropout, missing single gaze points, and asynchronous sampling as if they were interchangeable.**

## 3. Separately labeled analysis strategies

1. **Complete-data oracle benchmark:** Analyze unmasked complete curves as a diagnostic of the native method's intrinsic coverage in each generated dataset. It is **not a valid observed-data estimator**.
2. **Available-observation naive benchmark:** If pointwise cell means are possible, compute the mean *within participant* first and then across represented participants, retaining NA where support is absent. This prevents overweighting participants with longer recordings but does **not** correct informative missingness.
3. **Complete-trajectory-only estimator compatibility:** The current `etr_bootstrap_mean_band` and `etr_bootstrap_group_contrast` accept complete common-grid trajectories. Never insert unmarked interpolated values or silently replace missing gaze with zero. Record explicit incompatibility as **unsupported input**, not a statistical failure. If complete-case analysis is attempted, label its selected-cohort estimand and compare it with the original full-population truth; avoid claiming the full-population band covers by construction.
4. **Observed-covariate inverse-probability weighting sensitivity:** Under *known* MCAR/MAR probabilities with adequate positivity and participant-level clustering, compare properly specified probability-weighted estimates with naive observed estimates. Use a prespecified variance/interval method rather than transferring complete-case bootstrap intervals without proof. Estimated propensity weights require an additional estimation-uncertainty study.
5. **MNAR oracle diagnostic only:** Any inverse selection probability using the latent current unobserved `Y` is not observable and must be explicitly marked an infeasible oracle; include a sensitivity/tipping-point analysis rather than claiming recoverability.
6. **Asynchronous sparse-trajectory model:** Require an explicit observation/interpolation/smoothing model and evaluation on an independent common truth grid. Unsupported regions must be marked as such; extrapolation is not equivalent to frequentist coverage.

## 4. Prespecified metrics and denominator rules

Each generated dataset, observation mechanism, N, and estimand is the **unit of Monte Carlo independence**. Mean/contrast and alternative estimator results sharing a dataset are paired; no pseudoreplicated binomial precision from method counts, observed gaze points, or repeated trials.

Record at minimum: actual observed participants per group, observed trials/participant distribution, percent observed gaze per channel/time, effective sample size for weighting, positivity, full-population known-truth error, absolute and signed bias over coordinates, root mean squared functional error, simultaneous coverage **against the declared true population curve**, average simultaneous-band width, coordinate inclusion *within the same simultaneous band* (NOT marginal CI coverage), CI failures, numerical degeneracy, unsupported input and fraction of datasets with unidentified/unsupported regions. For MCAR/MAR also evaluate bias when their assumptions are deliberately violated.

**Failure-inclusive reporting:** retain *every* requested dataset and all attempted analyses; distinguish `success`, `unsupported`, `numerical_failure`, `no_observation_support`, and `scientifically_unidentified`. Report conditional-on-success coverage alongside failure/unsupported rates, not as a replacement for them. Never turn failed fits into false negatives, zero-width intervals or covered curves.

For each prespecified cell, calculate binomial exact Monte Carlo intervals on the number of independent successful generating datasets, plus interval width/bias uncertainty using *paired dataset-level* resampling. At minimum, a 20-study engineering smoke test followed by a **new-seed** higher-precision design (e.g. 200 studies/cell) is required before interpreting trends. Declare a separate confirmatory performance gate only after independent development and validation designs; avoid tuning to these initial observed outcomes.

## 5. Acceptance and release conditions

- **Engineering gate:** no silent imputation, no undocumented cross-participant pooling, deterministic independent seeds with collision prevention, complete manifests, and reproducible summary/raw-trial reconciliation.
- **Target-validity gate:** estimand remains the unconditional participant-balanced full-population target unless an explicit observed-cohort target is requested; MNAR nonidentifiability and data-support limitations are surfaced.
- **Statistical gate:** evaluate coverage and width jointly by mechanism, N and estimand, with Monte Carlo intervals and *predeclared* acceptable coverage/width trade-off. More conservative intervals are not automatically better.
- **Generalization gate:** use independent generating families (Gaussian, t(3), skewed, unequal variance), different mask strengths, group imbalances, and irregular support, preserving trials and participants as clusters.
- **Release gate:** no native estimator replacement, PR merge, calibrated 90% promise or CRAN publication based solely on complete-data study or an unqualified missingness-corrected simulation.

**Status: design document only. No MCAR/MAR/MNAR simulations, missingness-corrected interval fits or MNAR identification claims have yet been made.**
