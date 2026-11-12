\name{etr_plot_functional_variance_decomposition}
\alias{etr_plot_functional_variance_decomposition}
\title{Plot variance and cross-covariance components from genuine functional mixed-effects likelihood}
\usage{
etr_plot_functional_variance_decomposition(
    result, ..., model = NULL, strict_source_record = FALSE)
}
\arguments{
\item{result}{Existing restricted R moment estimator for legacy default plotting, or a genuine native fitted Gaussian joint B-spline likelihood model or W3 sensitivity scientific record in strict mode.}
\item{...}{Native base R plotting arguments retained for the legacy moments renderer.}
\item{model}{Named converged sensitivity model to plot in strict mode, required for sensitivity result and prohibited for a direct fitted likelihood model.}
\item{strict_source_record}{Draw real native Gaussian variance components and return source-ordered Matplotlib scientific line, reference and axes geometry as a native R record.}
}
\value{In default mode, native source time/component frame. In strict mode, a typed source-scientific one-panel plot record containing the actual fitted participant/trial/residual covariance component curves, zero line and declared model label.}
\description{Direct native R \code{nlme} spline-Gaussian covariance components are used without refitting, source identity substitution or automatically selecting models. A sensitivity model must be explicitly named; failed models have no variance decomposition. This scientific geometry review excludes independent Python \code{statsmodels} optimizer and Matplotlib object/pixel identity.}
