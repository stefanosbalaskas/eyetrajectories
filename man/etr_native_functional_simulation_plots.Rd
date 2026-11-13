\name{etr_native_functional_simulation_plots}
\alias{etr_native_functional_simulation_plots}

\title{Native functional simulation truth and score-source audit plots}
\description{
Three source-pinned Python-independent R graphics methods for realized
functional-simulation truth records: a latent-versus-observed curve with
optional removed measurements, retained phase warps, and declared-versus-realized
score-source variances. They do not simulate data, fit models, or calibrate
statistical uncertainty.
}
\usage{
etr_plot_functional_simulation_curve(
  result, curve = 1L, dimension = 1L, show_pre_missing = FALSE
)
etr_plot_functional_simulation_phase_warps(
  result, max_curves = 20L, alpha = 0.35
)
etr_plot_functional_simulation_score_variances(result)
}
\arguments{
\item{result}{Named native R record containing observations with curve IDs and
fully specified realized simulation truth, measurement schedules, score sources,
phase warps and observation arrays.}
\item{curve}{R one-based curve index or recorded curve identifier.}
\item{dimension}{R one-based dimension index or declared dimension name.}
\item{show_pre_missing}{Logical: mark measurements removed by design.}
\item{max_curves}{Positive number of curves to show, or NULL for all curves.}
\item{alpha}{Opacity of phase-warp curves in the interval (0, 1].}
}
\details{
The scientific source is published \pkg{eyetrajectoriespy} 1.2.0,
\code{plotting.py}, commit
\code{c1cd95ad718327550f7e55393ff38582872f7a94}.
Population variance uses a denominator equal to the number of observations,
matching NumPy \code{ddof=0}, not R's sample variance.
Matplotlib Axes objects, Python dataclass acceptance and all source
validation/error boundaries are not native R contracts, and remain unresolved
in the source-contract register. Native curve/dimension indices are one-based.
}
\value{
Each function draws to the active base R graphics device and invisibly returns
a list of source-aligned numerical geometries and conservative provenance.
No Python graphics backend is invoked.
}
\keyword{hplot}
