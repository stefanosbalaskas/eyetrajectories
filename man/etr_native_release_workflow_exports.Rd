\name{etr_native_release_workflow_exports}
\alias{etr_export_workflow_bundle}
\alias{etr_run_fpca_workflow}
\alias{etr_run_function_on_scalar_workflow}
\alias{etr_run_functional_mixed_effects_workflow}
\alias{etr_run_generalized_functional_workflow}
\alias{etr_run_recurrence_workflow}
\alias{etr_run_sparse_fpca_workflow}
\alias{etr_run_sparse_mfpca_async_workflow}
\alias{etr_run_sparse_mfpca_workflow}
\alias{etr_run_sparse_multilevel_workflow}
\alias{etr_run_sparse_prediction_workflow}
\alias{etr_plot_workflow_result}
\alias{etr_save_workflow_figure}
\title{Explicit native functional-data analysis workflow exports}
\description{
Reference index for exported functions in this scientific domain. The
functions are independently callable; scientific scope and input contracts
vary by estimator, data structure, fitted object, and selected backend.
}
\details{
Workflow functions coordinate explicitly declared trajectory collections,
analysis configurations, scientific models and source reporting artifacts.
The fit function actually executed depends on the specific native R
backend; third-party source representations, mixed-effects estimation and
plotting classes may differ from frozen Python 1.2 counterparts.
Check each workflow's explicit required inputs, domain restrictions,
preprocessing policies, and actual fitted estimator. Workflow export and
figure utilities are not substitutes for a complete numerical oracle.
Native backend and source Python backend provenance are not interchangeable.
For \code{etr_run_functional_mixed_effects_workflow}, the legacy explicitly
declared method-of-moments estimator remains the default path.
An opt-in \code{estimator="native_joint_bspline_gaussian"} path dispatches
the already implemented native R/nlme participant-intercept,
participant-slope, nested-trial, and nested-trial-plus-slope likelihood
models. Only IID residuals are supported without a declared nested trial;
IID, AR(1), and exponential residuals are available for nested trial
models. Native \code{method="nlme::lme"} is required; Python's optimizer
is not silently substituted, and the typed Python workflow/result
contract is not certified. The coefficient table uses seven source-ordered
pointwise Wald columns. See \code{docs/native-joint-bspline-source-workflow-wave.md}.

The \code{native_covariance} configurations of \code{etr_run_sparse_fpca_workflow}
and \code{etr_run_sparse_mfpca_workflow} accept \code{score_uncertainty=list()}
to request conditional PACE score uncertainty. The list may specify
\code{condition_limit} and \code{failure_action} (\code{"error"} or
\code{"retain_nan"}). The workflow returns the conditional result and a
per-curve, per-component table. The \code{scores} table retains input
metadata and uses \code{SFPC} or \code{SMFPC} component prefixes.
Input metadata columns that collide with score-table names receive unique
suffixes in the table.
}
\section{Exported entry points}{
\describe{
\item{\code{etr_export_workflow_bundle}}{\emph{export workflow bundle} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_fpca_workflow}}{\emph{run fpca workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_function_on_scalar_workflow}}{\emph{run function on scalar workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_functional_mixed_effects_workflow}}{\emph{run functional mixed effects workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_functional_recovery_scenarios}}{\emph{run functional recovery scenarios} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_generalized_functional_workflow}}{\emph{run generalized functional workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_recurrence_workflow}}{\emph{run recurrence workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_sparse_fpca_workflow}}{\emph{run sparse fpca workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_sparse_mfpca_async_workflow}}{\emph{run sparse mfpca async workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_sparse_mfpca_workflow}}{\emph{run sparse mfpca workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_sparse_multilevel_workflow}}{\emph{run sparse multilevel workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_run_sparse_prediction_workflow}}{\emph{run sparse prediction workflow} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_plot_workflow_result}}{\emph{plot workflow result} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_save_workflow_figure}}{\emph{save workflow figure} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
}
}
\value{Each function returns its own documented native R, scientific-model,
bridge, workflow or audit result; no single shared return type is asserted.}
