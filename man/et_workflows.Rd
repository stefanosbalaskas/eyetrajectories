\name{et_run_fpca_workflow}
\alias{et_run_fpca_workflow}
\title{Execute a Python FPCA workflow}
\description{
Runs the published Python common-grid FPCA workflow using a declared configuration.
}
\usage{
et_run_fpca_workflow(trajectories, n_components = 0.95,
                     scaling = c("none", "dimension_sd"))
}
\arguments{
\item{trajectories}{Python TrajectorySet object.}
\item{n_components}{Integer component count or variance fraction.}
\item{scaling}{Coordinate channel scaling policy.}
}
\value{Python \code{FPCAWorkflowResult} object with fit, decisions, and reports.}
\details{
No hidden preprocessing is applied. Other public workflows are accessible
through \code{et_call(name, ..., .namespace = "workflows")}.
The R bridge does not claim independent scientific qualification.
}
\examples{
\dontrun{
gaze <- et_simulate_planar()
workflow <- et_run_fpca_workflow(gaze, scaling = "dimension_sd")
fit <- workflow$fit
et_scores(fit)
}
}
