\name{etr_plot_covariance_sensitivity_coefficients}
\alias{etr_plot_covariance_sensitivity_coefficients}
\title{Plot Gaussian functional mixed-effects coefficient sensitivity against a reference model}
\usage{
etr_plot_covariance_sensitivity_coefficients(
    result, coefficient, strict_source_record = FALSE)
}
\arguments{
\item{result}{Named fitted covariance-sensitivity scientific record. Strict mode requires a source-ordered W3 native R result based exclusively on actual Gaussian B-spline \code{nlme} likelihood fits.}
\item{coefficient}{An exact named fixed functional coefficient to plot.}
\item{strict_source_record}{If true, preserve frozen Python 1.2 Matplotlib source scientific artist data in a typed native R record. This is not a Python \code{Axes} object.}
}
\value{The default returns an invisible model/time/coefficient-difference data frame, while strict mode returns source-ordered plot lines, labels, axes and horizontal zero-reference geometry.}
\description{Plots true fitted native Gaussian fixed coefficient differences under explicitly predeclared covariance sensitivity models without ranking, selecting, or refitting models. Native \code{nlme} and Python \code{statsmodels} optimizer equality, Matplotlib runtime type and exact rendered pixels remain outside this scoped scientific plotting contract.}
