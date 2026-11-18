# Native source-ordered mixed-effects and wild-bootstrap audit frames

Six Python-independent, read-only native R adapters for realized
participant and nested-trial functional random effects,
whole-participant and nested-trial bootstrap identity audits, FPCA
wild-bootstrap truncation scans, and target-specific truncation
selections. No model fitting, automatic tuning, bootstrap resampling, or
statistical qualification is performed.

## Usage

``` r
etr_functional_random_effect_frame(result, effect = "intercept")
etr_functional_trial_random_effect_frame(result)
etr_functional_mixed_effects_full_refit_audit_frame(bootstrap)
etr_functional_mixed_effects_full_refit_trial_audit_frame(bootstrap)
etr_fpca_wild_bootstrap_truncation_scan_frame(result)
etr_fpca_wild_bootstrap_truncation_selection_frame(result)
```

## Arguments

- result:

  Native named record of already-realized mixed-effects functions or
  FPCA truncation scan/selection outputs. Source-required numerical
  fields and matrix dimensions are validated.

- effect:

  Participant-level random functional intercept or slope.

- bootstrap:

  Native named record of full-refit source and bootstrap participant or
  trial identity histories.

## Details

Frozen source: published eyetrajectoriespy 1.2.0, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`, including
`functional_mixed_effects.py`, `functional_mixed_effects_nested.py`,
`functional_mixed_effects_full_refit.py`, and `wild_selection.py`.
Candidate-major and participant-major row ordering, zero-based
source/bootstrap indices, and missing selection components are retained.
Python dataclass and pandas return types are not reproduced and remain
an explicit unresolved source-contract gap. For full-refit trial audits,
pass the generated native refit object directly or provide the
equivalent four-identifier rows per replicate. Repeated draws of a
source participant receive distinct bootstrap participant and trial
identifiers. For the participant random-effect and nested-trial effect
frames, callers may now also pass the corresponding native joint
B-spline Gaussian mixed fit records directly. Their fitted random-effect
functions are adapted without any statistical refit, preserving
source-order rows and the prior named-list interface. The result is
still an R data frame, not a Python pandas frame or a certified Python
result-type contract.

## Value

Native R data frame, one row per source-defined audit unit. The
functions never invoke the Python runtime.
