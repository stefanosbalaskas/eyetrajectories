\name{etr_native_transfer_entropy}
\alias{etr_discrete_transfer_entropy}
\alias{etr_transfer_entropy_local_frame}
\alias{etr_transfer_entropy_circular_shift_test}
\alias{etr_conditional_transfer_entropy}
\alias{etr_conditional_transfer_entropy_local_frame}
\alias{etr_conditional_transfer_entropy_circular_shift_test}
\alias{etr_transfer_entropy_parameter_sensitivity}
\alias{etr_transfer_entropy_reporting_text}
\alias{etr_transfer_entropy_circular_shift_reporting_text}
\alias{etr_conditional_transfer_entropy_reporting_text}
\alias{etr_conditional_transfer_entropy_circular_shift_reporting_text}
\alias{etr_transfer_entropy_parameter_sensitivity_reporting_text}
\title{Native R empirical discrete and conditional transfer entropy}
\description{Independent Python-free plug-in transfer entropy, local information histories, analyst-declared source-only circular shift nulls, Cartesian specification sensitivity and transparent scientific reporting.}
\usage{
etr_discrete_transfer_entropy(source, target, target_history, source_history,
  source_lag)
etr_transfer_entropy_local_frame(result)
etr_transfer_entropy_circular_shift_test(source, target, target_history,
  source_history, source_lag, shifts)
etr_conditional_transfer_entropy(source, target, condition, target_history,
  source_history, condition_history, source_lag, condition_lag)
etr_conditional_transfer_entropy_local_frame(result)
etr_conditional_transfer_entropy_circular_shift_test(source, target, condition,
  target_history, source_history, condition_history, source_lag, condition_lag,
  shifts)
etr_transfer_entropy_parameter_sensitivity(source, target, target_histories,
  source_histories, source_lags, shifts = NULL)
etr_transfer_entropy_reporting_text(result)
etr_transfer_entropy_circular_shift_reporting_text(result)
etr_conditional_transfer_entropy_reporting_text(result)
etr_conditional_transfer_entropy_circular_shift_reporting_text(result)
etr_transfer_entropy_parameter_sensitivity_reporting_text(result)
}
\arguments{
\item{source}{Explicit one-dimensional finite integer-coded source states. No discretization is applied.}
\item{target}{Equally long one-dimensional finite integer-coded target states.}
\item{condition}{Equally long finite integer-coded conditioning-process states.}
\item{target_history}{Positive target history length in samples.}
\item{source_history}{Positive source history length in samples.}
\item{condition_history}{Positive conditioning history length in samples.}
\item{source_lag}{Positive declared source lag in samples.}
\item{condition_lag}{Positive declared conditioning-process lag in samples.}
\item{shifts}{Nonempty, unique integer circular offsets strictly between zero and series length; no shifts are generated.}
\item{target_histories}{Nonempty unique positive target-history grid.}
\item{source_histories}{Nonempty unique positive source-history grid.}
\item{source_lags}{Nonempty unique positive source-lag grid.}
\item{result}{Native discrete or conditional transfer-entropy result, shift-test result or sensitivity table.}
}
\value{A native empirical transfer-entropy result, fixed-surrogate null, sensitivity result, exact-history data frame or transparent reporting text.}
\details{All entropies are empirical plug-in conditional mutual information in bits. No automatic discretization, history/lag tuning, support filtering, shift generation or causal identification. Circular shifts require an explicit defensible stationarity/wrap-around assumption. Test p-values have plus-one Monte Carlo resolution; parameter sensitivity is descriptive, not multiplicity-adjusted inference. The complete Python public API certification gate remains closed.}