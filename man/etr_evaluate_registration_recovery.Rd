\name{etr_evaluate_registration_recovery}
\alias{etr_evaluate_registration_recovery}
\title{Known-truth inverse phase-warp recovery audit}
\usage{etr_evaluate_registration_recovery(result, truth)}
\arguments{
\item{result}{Source-shaped registration warp result and original grid.}
\item{truth}{Simulator truth on an exactly equal grid with generating warps.}
}
\value{Native recovery assessment with integrated squared inverse-warp
error and maximum absolute inverse-warp error.}
\description{Compares fitted reference-to-observed warps with the inverses
of source-generating latent phase warps, without altering latent or fitted
trajectories. Source dataclass and error schema equivalence remain uncertified.}
