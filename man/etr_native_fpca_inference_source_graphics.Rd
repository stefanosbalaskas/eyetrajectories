\name{etr_native_fpca_inference_source_graphics}
\alias{etr_native_fpca_inference_source_graphics}

\title{Frozen-source FPCA matched-envelope and familywise inference graphics}
\description{
Native base-R visualization of precomputed matched bootstrap FPCA component
envelopes and familywise fixed-target wild-bootstrap tail probabilities
on their declared scientific scopes. Existing PACE score diagnostics retain
separate prior documentation.
}

\arguments{
\item{result}{Declared native R scientific result record with source
geometry, fitted population quantities and precomputed diagnostics.}
\item{component}{Zero-based retained FPCA component index.}
\item{dimension}{Named functional dimension. The first is the default.}
\item{max_targets}{Positive maximum count of prespecified fixed targets.}
\item{show_targetwise}{Whether to include unadjusted targetwise tail p-values.}
}
\value{
R base graphics written to the active device. The exact numeric
geometry displayed is returned invisibly rather than a Matplotlib Axes.
}
\details{
This is visualization only: no source-bootstrap resampling, band
calibration, simultaneous coverage inference, or model fitting is done.
Envelopes are descriptive pointwise, and bootstrap family p-values are
assumed to have been computed upstream for a fixed target family.
The complete Python 1.2.0 source typed-input and Matplotlib backend
contract is not claimed or independently signed off.
}
