# Frozen-source FPCA matched-envelope and familywise inference graphics

Native base-R visualization of precomputed matched bootstrap FPCA
component envelopes and familywise fixed-target wild-bootstrap tail
probabilities on their declared scientific scopes. Existing PACE score
diagnostics retain separate prior documentation.

## Plotting parameters

- result:

  Declared native R scientific result record with source geometry,
  fitted population quantities and precomputed diagnostics.

- component:

  Zero-based retained FPCA component index.

- dimension:

  Named functional dimension. The first is the default.

- max_targets:

  Positive maximum count of prespecified fixed targets.

- show_targetwise:

  Whether to include unadjusted targetwise tail p-values.

## Value

R base graphics written to the active device. The exact numeric geometry
displayed is returned invisibly rather than a Matplotlib Axes.

## Details

This is visualization only: no source-bootstrap resampling, band
calibration, simultaneous coverage inference, or model fitting is done.
Envelopes are descriptive pointwise, and bootstrap family p-values are
assumed to have been computed upstream for a fixed target family. The
complete Python 1.2.0 source typed-input and Matplotlib backend contract
is not claimed or independently signed off.
