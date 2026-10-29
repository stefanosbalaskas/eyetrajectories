\name{etr_plot_function_on_scalar_coefficients}
\alias{etr_plot_function_on_scalar_coefficients}
\alias{etr_function_on_scalar_reporting_text}
\alias{etr_plot_functional_mixed_effects_coefficient}
\alias{etr_plot_conformal_fpca_anomaly}
\alias{etr_conformal_fpca_anomaly_reporting_text}
\alias{etr_plot_rqa_metric_mean_bootstrap}
\alias{etr_plot_functional_variance_decomposition}
\title{Native function-on-scalar, conformal, RQA and mixed-moments reporting and plots}
\description{
Seven scientifically named, Python-free R interfaces for fitted native
functional estimators, published-source reporting and observed-grid
uncertainty visualization. They do not re-estimate underlying
models or generate their own stochastic bootstrap samples.
}
\usage{
etr_plot_function_on_scalar_coefficients(result, coefficient,
  dimension = NULL, band = NULL, ...)
etr_function_on_scalar_reporting_text(result, band = NULL)
etr_plot_functional_mixed_effects_coefficient(result, coefficient, ...)
etr_plot_conformal_fpca_anomaly(result, max_targets = 50L, ...)
etr_conformal_fpca_anomaly_reporting_text(result, n_components,
  digits = 3L)
etr_plot_rqa_metric_mean_bootstrap(result, metrics = NULL, ...)
etr_plot_functional_variance_decomposition(result, ...)
}
\arguments{
\item{result}{Corresponding native functional estimator result. For
conformal methods this is the native split-conformal FPCA screen
with calibration and target scores, rather than a Python object.}
\item{coefficient}{Fitted coefficient name or zero-based component
index, as in the published Python source.}
\item{dimension}{Optional fitted functional response channel.}
\item{band}{Optional separately constructed native simultaneous
function-on-scalar coefficient band, with the identical reference fit.}
\item{max_targets}{Positive integer maximum of marginal conformal
target trajectories to display.}
\item{n_components}{Mandatory declared count of components in the
frozen FPCA training fit; the native screen does not preserve this
information. Do not estimate or infer it from target scores.}
\item{digits}{Decimal precision, integer zero to twelve.}
\item{metrics}{Optional ordered subset of fitted native RQA
bootstrap metrics.}
\item{...}{Additional base graphics parameters.}
}
\value{
Reporting methods return source-aligned scientific text. Plotting
methods draw base R graphics and invisibly return the exact numeric
estimate, observed-grid interval, p-value or component variance
geometry shown. R values and return classes are intentionally not
Python Matplotlib Axes or Python model dataclasses.
}
\details{
Function-on-scalar regression uses native observed-grid OLS and
pointwise HC1 standard errors; whole-function wild bootstrap bands
are explicitly distinguished from pointwise estimates. Native
restricted two-level functional mixed moments are not the
published Python likelihood-optimized mixed effects model; their
fixed-effect 95 percent Wald intervals are pointwise, not simultaneous.

Conformal p-values are reconstructed with the conservative
greater-than-or-equal calibration tie rule:
\eqn{p=(1+\#\{s_{cal}\ge s_{target}\})/(n_{cal}+1)}.
They are marginal under exchangeable independent curve assumptions,
not familywise anomaly discoveries. The reporting method requires
the original source component count explicitly because the native
screen does not store it. No FDR or conditional coverage is claimed.

RQA source bootstrap percentile intervals use independent curve
or participant units declared upstream. No circular-shift or
causal identification claim is implied.

Published Python 1.2 uses different model result classes, bootstrap
engines and Matplotlib return objects. Full public source-contract
equivalence remains blocked pending independent complete-domain,
error-class and scientific evaluation.
}
