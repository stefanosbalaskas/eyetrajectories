\name{etr_native_mixed_random_effects_plots}
\alias{etr_native_mixed_random_effects_plots}

\title{Native participant and trial functional random-effect plots}
\description{
Read-only base R plotting of the realized participant-level functional random
intercepts or slopes and nested-trial functional random intercepts. The native
plots expose ordered numerical line data for source qualification and do not
fit a mixed model, bootstrap observations or select a scientific threshold.
}
\usage{
etr_plot_functional_random_effects(
  result, effect = "intercept", max_participants = NULL, alpha = 0.35
)
etr_plot_functional_trial_random_effects(
  result, participant_id = NULL, max_trials = 12L
)
}
\arguments{
\item{result}{Explicit realized mixed-model source-compatible native
record including random-effect arrays, names, time and time unit.}
\item{effect}{Participant random functional effect: intercept or slope.}
\item{max_participants}{Positive integer participant limit, or NULL.}
\item{alpha}{Line opacity within (0, 1].}
\item{participant_id}{Optional named source participant; NULL for all.}
\item{max_trials}{Positive integer number of unique retained trial IDs.}
}
\details{
The published scientific source is \pkg{eyetrajectoriespy} 1.2.0,
commit \code{c1cd95ad718327550f7e55393ff38582872f7a94},
\code{plotting.py} and
\code{functional_mixed_effects_nested.py}. Matplotlib Axes returns and
Python frozen result dataclass type constraints are not equivalent to native
R base graphics and named-list inputs; these are explicit unresolved
source-contract differences.
}
\value{
An invisible R list with numeric source-ordered plotting lines, selected
source identities and conservative backend provenance.
}
\keyword{hplot}
