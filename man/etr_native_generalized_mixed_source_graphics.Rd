\name{etr_plot_generalized_function_on_scalar_predictions}
\alias{etr_plot_generalized_function_on_scalar_predictions}

\alias{etr_plot_covariance_sensitivity_band_widths}

\title{Native R graphics for generalized function-on-scalar and mixed-effects scientific inference}
\description{Plot fitted generalized function-on-scalar predictions, contrast
bands, coefficient functions, covariance sensitivity and mixed-effects
residual dependence with explicit observed-grid numerical geometry.}
\usage{
etr_plot_generalized_function_on_scalar_predictions(result)
etr_plot_generalized_function_on_scalar_mean_difference(result)
etr_plot_generalized_function_on_scalar_coefficients(result, coefficient)
etr_plot_covariance_sensitivity_coefficients(result, coefficient)
etr_plot_covariance_sensitivity_band_widths(result, coefficient)
etr_plot_functional_mixed_effects_residual_acf(
  result, level = "overall", curve_id = NULL, participant_id = NULL)
etr_plot_functional_mixed_effects_residual_variogram(
  result, level = "overall", curve_id = NULL, participant_id = NULL)
}
\arguments{
\item{result}{An explicitly declared scientific fitted R record or
pre-calibrated band/sensitivity/residual diagnostics R record.}
\item{coefficient}{Exact declared source regression coefficient name.}
\item{level}{One of \code{"overall"}, \code{"participant"} or
\code{"trial"}, preserving the source summary level.}
\item{curve_id}{Required source curve identifier for trial-level plots.}
\item{participant_id}{Required source participant identifier for
participant-level plots.}
}
\value{Base-R graphics on the active device and invisible numeric plot
geometry on the declared time grid. Python Matplotlib Axes output is
not returned and one-to-one backend object equivalence is not claimed.}
\details{The source's link or response scale, covariance sensitivity
reference, simultaneous observed-grid interval labels, zero lines for
differences or ACF and one line for rate ratios are preserved. No
inference, bootstrap refitting, model selection, or calibration is
performed. Physical lag means are not mistaken for regular index lags.
All seven independent source-contract approvals remain unresolved.}
