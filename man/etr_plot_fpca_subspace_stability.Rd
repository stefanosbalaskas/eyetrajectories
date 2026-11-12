\name{etr_plot_fpca_subspace_stability}
\alias{etr_plot_fpca_subspace_stability}
\title{Plot source-ordered FPCA bootstrap subspace stability statistics}
\usage{
etr_plot_fpca_subspace_stability(
    result, metric = "normalized_projector_distance",
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Genuine native FPCA subspace-stability result with retained components, bootstrap principal cosines, principal angles in degrees, and normalized projector distances.}
\item{metric}{One of \code{"normalized_projector_distance"}, \code{"max_principal_angle_degrees"}, or \code{"min_principal_cosine"}.}
\item{strict_source_record}{If TRUE, emit a one-panel native R source-scientific artist record, preserving source replicate x-values, metric y-values, marker \code{"o"}, no connecting line, scientific axis labels and Python source title. Does not return Python Matplotlib \code{Axes}.}
\item{...}{Native base plotting options.}
}
\value{In default mode, the original bootstrap replicate/value data frame invisibly. In strict mode, native source-scientific line-artist geometry with one marker per retained bootstrap replicate.}
\description{Uses the original estimated principal angles, cosines and projector distances without recomputing bootstrap replicates or changing the selected subspace. Source function expresses component range with a typographic en dash. Matplotlib runtime class and pixel parity are explicitly excluded.}
