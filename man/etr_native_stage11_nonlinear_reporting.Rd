\name{etr_native_stage11_nonlinear_reporting}
\alias{etr_joint_recurrence_reporting_text}
\alias{etr_recurrence_network_reporting_text}
\alias{etr_recurrence_radius_profile_reporting_text}
\alias{etr_rqa_reporting_text}
\alias{etr_rqa_metric_mean_bootstrap_reporting_text}
\alias{etr_windowed_rqa_reporting_text}
\alias{etr_windowed_rqa_functional_reporting_text}
\alias{etr_windowed_rqa_sensitivity_reporting_text}
\alias{etr_windowed_rqa_mean_band_reporting_text}
\alias{etr_rqa_parameter_sensitivity_reporting_text}
\alias{etr_kantz_parameter_sensitivity_reporting_text}
\alias{etr_lyapunov_parameter_sensitivity_reporting_text}
\alias{etr_largest_lyapunov_reporting_text}
\alias{etr_surrogate_nonlinearity_reporting_text}
\alias{etr_return_map_stability_reporting_text}
\title{Stage 11 Python-free nonlinear scientific reporting}
\description{Independent R reporting and source-oriented structured-result adapters for published eyetrajectoriespy 1.2.0 nonlinear outputs. These functions do not run nonlinear estimators or import Python.}
\usage{
etr_joint_recurrence_reporting_text(result, metrics = NULL)
etr_recurrence_network_reporting_text(result)
etr_recurrence_radius_profile_reporting_text(result)
etr_rqa_reporting_text(recurrence, metrics)
etr_rqa_metric_mean_bootstrap_reporting_text(result)
etr_windowed_rqa_reporting_text(result)
etr_windowed_rqa_functional_reporting_text(result)
etr_windowed_rqa_sensitivity_reporting_text(result)
etr_windowed_rqa_mean_band_reporting_text(result)
etr_rqa_parameter_sensitivity_reporting_text(result)
etr_kantz_parameter_sensitivity_reporting_text(result)
etr_lyapunov_parameter_sensitivity_reporting_text(result)
etr_largest_lyapunov_reporting_text(result)
etr_surrogate_nonlinearity_reporting_text(result)
etr_return_map_stability_reporting_text(fit, result)
}
\arguments{
\item{result}{A compatible native nonlinear-result object, or a fully specified R result structure with the fields required by the selected report.}
\item{metrics}{Optional explicit RQA line metrics for joint recurrence or required RQA metrics for basic RQA reporting.}
\item{recurrence}{Native R recurrence result whose radius, metric and Theiler specification are recorded.}
\item{fit}{Explicit local return-map fit carrying declared neighborhood and source provenance.}
}
\value{A single descriptive character string; no fitted estimator, new uncertainty interval, or automatic inference is produced.}
\details{Reports require declared source information, including recurrence radius, line thresholds, window or bootstrap unit definitions, where applicable. Some report-only source schemas have no native estimator yet. No reporting statement should be taken as source-contract certification, causal coupling, deterministic chaos, or inferential validity.}