# Methods and mathematical scope

This package represents eye-tracking observations as trajectories over
time. Each analysis is conditional on the available observation
structure, coordinate units, preprocessing choices and sampling design.
The list below is an orientation to documented functionality, not a
claim that every method has full Python source parity.

For structured research decisions, use the [Research Workflow
Portal](https://stefanosbalaskas.github.io/eyetrajectories/research-portal.md),
which links ten source-defined Python workflow concepts to actual native
R estimators and synthetic plots without claiming full Python parity.

## Common-grid trajectories

Native R tools cover trajectory construction and validation, explicit
preprocessing, channel-wise kinematics, time-weighted distances and
descriptive plots. Keep original time and coordinate units explicit.
Interpolation, regridding and normalization require documented choices
rather than hidden defaults.

## Functional principal components

Dense common-grid FPCA/MFPCA represents smooth time-varying processes by
a mean function and orthogonal components. Document the integration
rule, number of components, scaling method, treatment of repeated trials
and preprocessing. Sparse FPCA/PACE methods may rely on optional R
packages and impose additional observation-grid and covariance
assumptions.

## Recurrence, nonlinear and sequence methods

Fixed-radius recurrence and RQA characterize geometric revisits in state
space. Results depend on the metric, Theiler window, embedding and
sampling contract. Transfer entropy concerns conditional predictive
information and must not be presented as proof of causality. Some
nonlinear and elastic methods are experimental.

## Multilevel and functional regression

The package includes research-stage functional regression, multilevel
analyses and selected bootstrap and validation diagnostics. Inference
for participants and repeated trials must reflect the experimental unit
and clustering. Confidence-band coverage and prediction calibration
cannot be inferred merely from a successful function call.

## Documentation and source restrictions

The [reference
index](https://stefanosbalaskas.github.io/eyetrajectories/reference/index.md)
contains the actual R help topics. For detailed scientific scope, read
the versioned repository evidence:

- [Experimental native R release
  scope](https://github.com/stefanosbalaskas/eyetrajectories/blob/fix/package-wide-qualification-20261113/docs/experimental-release-scope.md)
- [Scientific functionality versus Python source
  parity](https://github.com/stefanosbalaskas/eyetrajectories/blob/fix/package-wide-qualification-20261113/docs/SCIENTIFIC_VS_SOURCE_PARITY.md)
- [Qualification runbook and provisional 508-export
  ledger](https://github.com/stefanosbalaskas/eyetrajectories/blob/fix/package-wide-qualification-20261113/docs/QUALIFICATION_RUNBOOK_20261113.md)

See [Validation and
limitations](https://stefanosbalaskas.github.io/eyetrajectories/SITE_VALIDATION.md)
for what passing CI does, and does not, establish.
