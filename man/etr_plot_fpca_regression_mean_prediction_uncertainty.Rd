\name{etr_plot_fpca_regression_mean_prediction_uncertainty}
\alias{etr_plot_fpca_regression_mean_prediction_uncertainty}
\title{Plot FPCR conditional-mean bootstrap uncertainty with source scientific artists}
\usage{
etr_plot_fpca_regression_mean_prediction_uncertainty(result,
  max_targets = 30L, strict_source_record = FALSE)
}
\arguments{
\item{result}{Native paired-bootstrap FPCR conditional-mean uncertainty result and full-sample reference predictions.}
\item{max_targets}{Positive integer number of fixed targets plotted.}
\item{strict_source_record}{If TRUE, record frozen Python 1.2 scientific Matplotlib errorbar and scatter geometry as a typed R record.}
}
\value{Invisible original base-R numeric interval geometry and provenance by default. A strict native source artist record contains asymmetric bootstrap-mean errorbar and full-sample conditional-mean scatter geometry, source labels and legend. No Matplotlib Axes instance is created.}
\description{Displays pre-estimated paired-bootstrap conditional-mean prediction uncertainty with source-identical scientific plotting coordinates, without refitting any estimation procedure.}
\details{Source coordinates and labels are developer-scoped and distinct from full Python runtime parity, backend pixels, exception classes and independent certification.}
