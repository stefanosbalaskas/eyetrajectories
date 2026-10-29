\name{etr_register_landmarks}
\alias{etr_register_landmarks}
\alias{etr_registration_warp_frame}
\alias{etr_delay_embedding}
\alias{etr_poincare_return_map}
\alias{etr_recurrence_network}
\alias{etr_recurrence_network_nodes}
\alias{etr_split_conformal_threshold}
\alias{etr_fpca_reconstruction_scores}
\alias{etr_split_conformal_fpca_anomalies}
\alias{etr_r_backend_catalog}
\title{Native functional trajectory registration, dynamics, and anomaly diagnostics}
\description{
Narrow, explicitly specified native R methods for prespecified piecewise-linear
landmark registration, delay embeddings, threshold return maps, binary
recurrence-network summaries, and split-conformal anomaly screening.
An offline catalog identifies optional R package backends. No Python is used.
}
\usage{
etr_register_landmarks(x, source_landmarks, target_landmarks)

etr_registration_warp_frame(registration)

etr_delay_embedding(series, dimension = 2L, delay = 1L)

etr_poincare_return_map(series, threshold = 0,
    direction = c("up", "down"), time = NULL)

etr_recurrence_network(recurrence)

etr_recurrence_network_nodes(network)

etr_split_conformal_threshold(calibration_scores, alpha = 0.10)

etr_fpca_reconstruction_scores(fit, x)

etr_split_conformal_fpca_anomalies(fit, calibration, test, alpha = 0.10)

etr_r_backend_catalog()
}
\arguments{
\item{x}{Native common-grid trajectories; must match the FPCA fit when scoring.}
\item{source_landmarks}{Numeric source times, one row per curve, strictly ordered.}
\item{target_landmarks}{Prespecified, increasing interior target times.}
\item{registration}{Native landmark registration output.}
\item{series}{Complete finite numeric sampled series.}
\item{dimension}{Embedding dimension, positive integer.}
\item{delay}{Positive integer sample lag.}
\item{threshold}{Finite scalar crossing threshold.}
\item{direction}{Upward or downward threshold crossing.}
\item{time}{Optional finite strictly increasing measurement times.}
\item{recurrence}{Native symmetric auto-recurrence object.}
\item{network}{Native recurrence-network result.}
\item{calibration_scores}{Nonnegative scores from held-out calibration curves.}
\item{alpha}{Miscoverage fraction strictly between zero and one.}
\item{fit}{FPCA fitted only to independent training curves.}
\item{calibration}{Held-out complete calibration trajectory set.}
\item{test}{Independent complete test trajectory set.}
}
\details{
The registration is a deterministic piecewise-linear inverse time map, with
endpoints fixed. It is not SRVF elastic registration or a Python parity claim.
The recurrence network treats time samples as graph vertices. It does not
regard recurrence nodes as independent research participants. Theiler
exclusions remain ineligible edges. Return maps are scalar threshold-event
maps, not Lyapunov or causal estimates.

Split-conformal calibration uses rank
\code{ceiling((n_calibration+1)*(1-alpha))}; when the rank exceeds the
calibration sample size, the cutoff is infinite. Marginal false-alarm
coverage requires a frozen training fit and exchangeable calibration/test
units. It does not give batch-wide or participant-cluster coverage guarantees,
and must not be used to claim calibrated simultaneous functional bands.
External R backends listed by \code{etr_r_backend_catalog} are optional
and have not been independently validated for equivalence.
}
\value{
\code{etr_register_landmarks} returns a registration object;
\code{etr_registration_warp_frame} returns its tidy warp frame;
\code{etr_delay_embedding} returns a numeric matrix with sample indices;
\code{etr_poincare_return_map} returns crossing times and adjacent pairs;
\code{etr_recurrence_network} returns graph summaries;
\code{etr_recurrence_network_nodes} returns per-node metrics;
\code{etr_split_conformal_threshold} returns threshold/rank metadata;
\code{etr_fpca_reconstruction_scores} returns residual scores per curve;
\code{etr_split_conformal_fpca_anomalies} returns scores, flags and calibration;
\code{etr_r_backend_catalog} returns a local optional-package catalog.
}
\examples{
d <- etr_delay_embedding(1:6, dimension = 3L, delay = 2L)
stopifnot(nrow(d) == 2L, ncol(d) == 3L)
cut <- etr_split_conformal_threshold(1:9, alpha = .1)
stopifnot(cut$rank == 9L, cut$threshold == 9)
head(etr_r_backend_catalog(), 3)
}
