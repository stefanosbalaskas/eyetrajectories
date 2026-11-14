\name{etr_plot_generalized_function_on_scalar_coefficients}
\alias{etr_plot_generalized_function_on_scalar_coefficients}
\title{Plot generalized FoSR link-scale coefficient scientific source geometry}
\usage{
etr_plot_generalized_function_on_scalar_coefficients(result, coefficient,
  strict_source_record = FALSE)
}
\arguments{
\item{result}{A precomputed generalized function-on-scalar coefficient fit or simultaneous coefficient-band record.}
\item{coefficient}{Exact name of the fitted link-scale coefficient.}
\item{strict_source_record}{If TRUE, return typed R source scientific artists for the coefficient line, conditional simultaneous band, link-scale label and horizontal zero reference.}
}
\value{Default invisibly returns original fitted link-scale values and any available interval. Strict mode returns the source line/optional alpha-0.2 fill and reference line with labels and declaration of the original link scale.}
\description{Represent scientific plotting geometry from frozen eyetrajectoriespy 1.2.0 without changing native statistical estimators, default base graphics or native numerical outputs.}
\details{Only bounded native R scientific geometry is represented, not an actual Python Matplotlib Axes, Python dataclass/pandas acceptance, pixel-identical rendering, Python exception-class identity or independently certified full API parity.}
