\name{etr_native_bootstrap_inference}
\alias{etr_multiplier_functional_mean_band}
\alias{etr_bootstrap_fpca_score_uncertainty}
\alias{etr_bootstrap_fpca_spectrum_uncertainty}
\alias{etr_bootstrap_fpca_component_bands}
\alias{etr_fpca_component_band_frame}
\title{Native R observed-grid simultaneous mean and FPCA bootstrap uncertainty}
\description{Python-free Gaussian multiplier mean bands, fixed-target sign-aligned FPCA score bootstrap, matched-spectrum bootstrap, FPC shape simultaneous bands and an auditable component band frame.}
\usage{
etr_multiplier_functional_mean_band(trajectories, confidence_level = 0.95,
  n_multiplier = 2000L, unit = "curve", participant_column = NULL,
  random_state = 0L, gaussian_multiplier_draws = NULL,
  random_engine = "numpy")
etr_bootstrap_fpca_score_uncertainty(trajectories, targets = NULL,
  n_bootstrap = 500L, n_components = 3L, scaling = "none",
  resample_unit = "curve", participant_column = NULL, level = 0.95, random_state = 0L)
etr_bootstrap_fpca_spectrum_uncertainty(trajectories, n_bootstrap = 500L,
  n_components = 3L, scaling = "none", resample_unit = "curve",
  participant_column = NULL, confidence_level = 0.95,
  simultaneous_scope = "component", random_state = 0L)
etr_bootstrap_fpca_component_bands(trajectories, n_bootstrap = 500L,
  n_components = 3L, scaling = "none", resample_unit = "curve",
  participant_column = NULL, confidence_level = 0.95,
  simultaneous_scope = "component", relative_gap_threshold = NULL,
  on_near_tie = "error", random_state = 0L)
etr_fpca_component_band_frame(result)
}
\arguments{
\item{trajectories}{Complete common-grid native trajectories. Probability-simplex mean bands require explicit log-ratio transformation.}
\item{targets}{Optional fixed external target trajectories with the exact training representation.}
\item{confidence_level}{Nominal observed-grid confidence fraction in (0,1).}
\item{level}{Two-sided fixed-target percentile level in (0,1).}
\item{n_multiplier}{At least 100 Gaussian multiplier draws.}
\item{n_bootstrap}{At least 20 bootstrap FPCA basis refits.}
\item{unit}{Curve or equal-weight participant-level independent mean units.}
\item{resample_unit}{Curve or whole-participant bootstrap resampling.}
\item{participant_column}{Required participant metadata field when participant-level inference is selected.}
\item{n_components}{Positive retained FPC count.}
\item{scaling}{Native FPCA dimension scaling.}
\item{simultaneous_scope}{Component-wise or within-metric family-wise maximum calibration.}
\item{relative_gap_threshold}{Optional component identifiability screen threshold [0,1).}
\item{on_near_tie}{Error, warn or ignore an explicitly detected near tie.}
\item{random_state}{For mean bands, a nonnegative integer seed below
\eqn{2^{53}} or \code{NULL} for the current R RNG stream. FPCA bootstrap
methods on this page use isolated base-R seeds. Fixed Gaussian draws
take precedence over the mean-band seed.}
\item{gaussian_multiplier_draws}{Optional finite numeric matrix of shape
\code{n_multiplier} by number of independent curve or participant units,
used as exact Gaussian multiplier realizations. Bypasses the R RNG for
numerical source replay; this native R parameter does not exist in the
frozen Python 1.2 public interface.}
\item{random_engine}{Seeded mean-band RNG. \code{"numpy"} uses native
NumPy-compatible PCG64 normal draws. \code{"base_R"} reproduces previous
native seeded mean bands.}
\item{result}{Native FPC component band for tidy conversion.}
}
\value{A native uncertainty result or long-form component-band data frame.}
\details{These descriptive/bootstrap-calibrated procedures operate over the observed time-by-dimension grid, not a continuum. They do not establish exact frequentist coverage. Matched individual eigenvalues/ratios use shape alignment, whereas cumulative explained variance always retains descending-rank meaning. Zero-variance cells are not silently imputed. The 508-source certification gate remains closed.}
