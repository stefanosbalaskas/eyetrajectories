\name{et_fit_fpca}
\alias{et_fit_fpca}
\alias{et_fit_mfpca}
\alias{et_scores}
\alias{et_explained_variance}
\title{Functional PCA through eyetrajectoriespy}
\description{Run Python FPCA or multivariate FPCA and read selected results into R.}
\usage{
et_fit_fpca(trajectories, n_components = 0.95,
            scaling = c("none", "dimension_sd"))

et_fit_mfpca(trajectories, n_components = 0.95,
             scaling = c("none", "dimension_sd"))

et_scores(fit, prefix = "FPC")

et_explained_variance(fit, cumulative = FALSE)
}
\arguments{
\item{trajectories}{Python TrajectorySet object.}
\item{n_components}{Integer number of components or fraction of variance.}
\item{scaling}{Scale dimensions or preserve the original units.}
\item{fit}{Python FPCAResult object.}
\item{prefix}{Prefix for component score column names.}
\item{cumulative}{Return cumulative instead of component-level variance fractions.}
}
\value{
\code{et_fit_fpca()} and \code{et_fit_mfpca()} return Python FPCAResult objects.
\code{et_scores()} returns an R data frame;
\code{et_explained_variance()} returns a numeric vector.
}
\details{Inference and numerical guarantees come from the Python implementation.}
\examples{
\dontrun{
gaze <- et_simulate_planar()
fit <- et_fit_mfpca(gaze, scaling = "dimension_sd")
head(et_scores(fit))
et_explained_variance(fit)
}
}
