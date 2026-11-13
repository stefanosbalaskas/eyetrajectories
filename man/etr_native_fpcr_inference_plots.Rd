\name{etr_native_fpcr_inference_plots}
\alias{etr_native_fpcr_inference_plots}

\title{Native FPCR inference and sparse PACE source diagnostic plots}
\description{
Six Python-independent, read-only native R diagnostic plots for
already-computed functional principal component regression inference:
wild-bootstrap projection intervals, future-outcome prediction,
conditional-mean uncertainty, simultaneous and pointwise slope bands,
and sparse PACE score-system conditioning.
}
\usage{
etr_plot_fpca_wild_bootstrap_projection(result, max_targets = 30L)
etr_plot_fpca_regression_future_prediction_interval(
  result, max_targets = 30L
)
etr_plot_fpca_regression_mean_prediction_uncertainty(
  result, max_targets = 30L
)
etr_plot_fpca_regression_slope_band(result, dimension = NULL)
etr_plot_fpca_regression_slope_uncertainty(result, dimension = NULL)
etr_plot_sparse_fpca_score_diagnostics(result)
}
\arguments{
\item{result}{Named native record of previously computed source-compatible
FPCR or sparse PACE quantities; no estimator is run.}
\item{max_targets}{Positive integer maximum number of targets shown.}
\item{dimension}{Optional named FPCA dimension, defaulting to the first.}
}
\details{
The published source is \pkg{eyetrajectoriespy} 1.2.0,
\code{src/eyetrajectoriespy/plotting.py}, commit
\code{c1cd95ad718327550f7e55393ff38582872f7a94}.
Native R draws to the active base graphics device and invisibly returns
the numerical source-aligned geometry. Its returned record is not a
Python Matplotlib Axes object. Typed Python result dataclasses, complete
boundary-domain behavior, and graphical return equivalence remain
unresolved certification differences. Target x positions are retained
as Python-style zero-based plot coordinates. The sparse PACE view
distinguishes positive finite conditioning measurements with status
\code{ok} from flagged/failed measurements on a logarithmic y axis.
The plots neither establish coverage nor select an estimator.
}
\value{
An invisible native R list with preserved numerical geometry,
plotting metadata and explicit backend provenance.
}
\keyword{hplot}
