\name{etr_plot_fpca_regression_cv}
\alias{etr_plot_fpca_regression_cv}
\title{Plot FPCR predictive cross-validation losses with source scientific errorbars}
\usage{
etr_plot_fpca_regression_cv(result, strict_source_record = FALSE)
}
\arguments{
\item{result}{Already computed FPCR cross-validation result with fold_losses, loss name, and family.}
\item{strict_source_record}{If TRUE, return a native typed scientific-artist record representing the frozen Python 1.2 Matplotlib scientific errorbars.}
}
\value{Invisible original R numerical loss summary, line, errorbar and provenance by default; a typed \code{etr_predictive_scientific_artist_record} in strict mode with original candidate counts, means, sample-SD standard errors, source plot labels and errorbar geometry. The strict record is not a live Matplotlib Axes.}
\description{Display the held-out loss against retained FPCA components. Source groupby uses sample SD divided by the square root of fold count, with zero SE for single-fold groups. No model selection or refitting is performed.}
\details{Strict mode records scientific source coordinates only; Python dataclass, Matplotlib runtime and exact error-class equivalence and independent contract certification are outside this bounded review.}
