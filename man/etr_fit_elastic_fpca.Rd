\name{etr_fit_elastic_fpca}
\alias{etr_fit_elastic_fpca}
\title{Unregistered SRVF FPCA or genuine native R elastic Karcher shape FPCA}
\usage{
etr_fit_elastic_fpca(trajectories, n_components = 3L,
  rotation = FALSE, scale_curves = FALSE, lam = 0,
  method = "identity_only", strict_source_record = FALSE)
}
\arguments{
\item{trajectories}{A complete finite numeric common-grid
\code{etr_trajectory_set} with at least two measured dimensions.
The native R elastic source requires at least three curves and five
observation times.}
\item{n_components}{Positive integer number of principal directions.
In native R elastic source mode, this cannot exceed
\code{n_curves - 1}.}
\item{rotation}{Boolean. Source-scientific mode optionally aligns
rigid rotations in true SRVF shape space. Legacy identity mode
requires \code{FALSE}.}
\item{scale_curves}{Boolean. Source-scientific mode optionally
normalizes SRVF curve shape scale. Legacy mode requires \code{FALSE}.}
\item{lam}{Nonnegative finite elastic reparameterization penalty;
the legacy identity mode requires zero.}
\item{method}{\code{"identity_only"} by default, preserving the original
native unregistered SRVF result. To perform genuine elastic source-
scientific Karcher dynamic programming, explicitly specify
\code{method="DP"} and \code{strict_source_record=TRUE}. R native mode
does not implement Python \code{RBFGS}.}
\item{strict_source_record}{Boolean. \code{FALSE} returns historical
native unregistered SRVF functional principal components with identity
warping. \code{TRUE} calls the independent genuine native R
\code{fdasrvf} (>= 2.5.1) library for Karcher SRVF registration and
geodesic tangent-space shape PCA, with no Python backend.}
}
\description{
The opt-in mathematical-source R path performs genuine nonidentity
elastic phase alignment of multivariate open curves through SRVF
Karcher mean, dynamic-programming time warping and tangent-geodesic
shape PCA. It reports fitted warps, aligned coordinates, PCA scores,
a ten-deformation principal-direction array, and mean curve in the
same scientific axis ordering as frozen Python 1.2
\code{fit_elastic_fpca}. The unchanged default still returns the
historical unregistered/identity-warp native FPCA alternative.
}
\value{
With default parameters, an \code{etr_unregistered_srvf_fpca}
native R scientific alternative retaining identity warping. With
\code{strict_source_record=TRUE, method="DP"}, a typed
\code{etr_native_elastic_karcher_pca_scientific_record} with
\code{aligned} native trajectory (curves x times x channels),
\code{warping_functions} (curves x times),
\code{scores} (curves x components),
\code{principal_directions} (channels x times x components x 10),
\code{mean_curve} (channels x times), source-scientific provenance,
and actual R \code{fdacurve} and \code{curve_pca} under
\code{native_backend_object} and \code{native_pca_object}.
\code{backend_object=NULL} deliberately does NOT fabricate a Python
\code{fdasrsf.fdacurve}.
}
\details{
The source-scientific native R algorithm uses the genuine
\code{fdasrvf} package, which is optional. This is NOT a numerical
clone of Python \code{fdasrsf}: Python starts Karcher iterations from
the first curve and executes a separate \code{srvf_align}, whereas
the independent modern native R implementation starts at a medoid
and returns already aligned reconstructions. The scientific
SRVF/elastic-Karcher/geodesic-PCA objective is implemented, but
exact DP warps, eigenvector signs, backend class identity, Python
exceptions and optional RBFGS behavior remain uncertified.
See \code{docs/native-elastic-fdasrvf-karcher-source-20261113.md}
and \code{inst/extdata/native_scoped_elastic_submethod_gaps_20261113.csv}.
}
