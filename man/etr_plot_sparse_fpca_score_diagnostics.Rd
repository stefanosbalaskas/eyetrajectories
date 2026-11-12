\name{etr_plot_sparse_fpca_score_diagnostics}
\alias{etr_plot_sparse_fpca_score_diagnostics}
\title{Plot sparse PACE score-conditioning diagnostics with source scientific scatters}
\usage{
etr_plot_sparse_fpca_score_diagnostics(result,
  strict_source_record = FALSE)
}
\arguments{
\item{result}{Source-shaped native sparse FPCA fit with \code{score_diagnostics} containing sample counts, condition numbers and status codes.}
\item{strict_source_record}{If TRUE, return typed scientific Matplotlib source scatter records; if FALSE, preserve the existing base-R log-scatter and invisible numerical-mask return.}
}
\value{Invisibly original base-R numerical source geometry and provenance by default. In strict mode, a typed R scientific record of ordered valid/flagged scatter offsets, source marker shapes and labels, logarithmic y scale and conditional legend. No live Python Axes is returned.}
\description{Visualize the previously computed PACE score-system condition numbers for sparse trajectories, retaining positive finite conditioning masks and source order.}
\details{Strict mode matches a restricted native numeric domain, not the full Python pandas or dataclass protocol, arbitrary Matplotlib Axes injection, Python exception classes, raster output, or independent scientific certification.}
