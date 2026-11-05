\name{etr_windowed_rqa_sensitivity}
\alias{etr_windowed_rqa_sensitivity}
\alias{etr_windowed_rqa_functional_mean_band}
\alias{etr_functional_recovery_metric_catalog}
\alias{etr_functional_recovery_metric_catalog_frame}
\alias{etr_functional_recovery_value_key}
\alias{etr_functional_recovery_reporting_text}
\alias{etr_functional_recovery_assessment_frame}
\title{Native windowed-recurrence functional sensitivity and source-pinned recovery metadata}
\description{
Six mapped public Python-source integrations plus the optional
native value-key helper: fixed-radius
multiscale windowed RQA sensitivity, unit-level simultaneous derived
RQA mean bands, and metadata and recovery-value catalog utilities
pinned to the published Python 1.2.0 source.
}
\usage{
etr_windowed_rqa_sensitivity(trajectories, metrics, window_step_pairs,
  window_units = "samples", step_units = "samples", radius = NULL,
  target_recurrence_rate = NULL, metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L, undefined_policy = "raise")
etr_windowed_rqa_functional_mean_band(trajectories, metrics,
  window, step, unit, participant_column = NULL,
  window_units = "samples", step_units = "samples",
  radius = NULL, target_recurrence_rate = NULL,
  metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  dimensions = NULL, min_diagonal_length = 2L,
  min_vertical_length = 2L, confidence_level = 0.95,
  n_multiplier = 2000L, random_state = 0L,
  gaussian_multiplier_draws = NULL)
etr_functional_recovery_metric_catalog()
etr_functional_recovery_metric_catalog_frame()
etr_functional_recovery_value_key(value)
etr_functional_recovery_assessment_frame(assessment)
etr_functional_recovery_reporting_text(assessment)
}
\arguments{
\item{trajectories}{Complete native functional trajectories, with
analyst-declared scientific coordinate system and time units.}
\item{metrics}{Unique windowed RQA statistic names.}
\item{window_step_pairs}{Nonempty list or two-column numeric matrix
of explicit (window, step) pairs. Each list entry can be an atomic numeric
vector or a two-element list of numeric scalars (for example
\code{list(5L, 2.0)}), as accepted by the pinned Python source.
Boolean, text, nonfinite and malformed scalar entries remain invalid.
Sample-unit counts must be integral; physical-time widths may be
fractional if exactly grid-convertible.}
\item{window,step}{Positive explicit window and step widths in the
declared sample or physical-time units.}
\item{window_units,step_units,theiler_window_units}{Either sample units
or compatible physical time (including s/ms aliases), converted to
whole observed samples on an approximately regular time grid.}
\item{radius}{Optional finite positive fixed recurrence radius; supply
exactly one radius policy.}
\item{target_recurrence_rate}{Optional target density strictly between
zero and one, using a source-aligned inclusive-radius search. The
achieved rate may differ owing to ties.}
\item{metric}{Recurrence distance metric: \code{"euclidean"},
\code{"cityblock"} or \code{"chebyshev"}.}
\item{theiler_window}{Nonnegative Theiler exclusion in the units
declared by theiler_window_units.}
\item{dimensions}{Optional named source dimensions to analyze.}
\item{min_diagonal_length,min_vertical_length}{RQA diagonal and vertical
run-length thresholds.}
\item{undefined_policy}{\code{"raise"} or \code{"keep"} for selected
windowed RQA metrics. The mean-band wrapper requires complete values.}
\item{unit}{Either independent source \code{"curve"} or declared
\code{"participant"} inference units.}
\item{participant_column}{Source metadata column grouping repeated trials
by participant when \code{unit="participant"}.}
\item{confidence_level,n_multiplier,random_state}{Gaussian multiplier
simultaneous mean-band calibration settings. R/NumPy RNGs differ.}
\item{gaussian_multiplier_draws}{Optional finite source-aligned numeric
matrix with one row per Gaussian multiplier replicate and one column per
independent curve or participant. This explicit native extension enables
same-draw numerical replay with frozen Python 1.2, without claiming RNG-stream
or typed-result-class equivalence.}
\item{value}{Native semantic recovery value with \code{metric},
\code{source} and zero-based \code{component} fields.}
\item{assessment}{Native assessment list with a nonempty \code{values}
list of semantic recovery values.}
}
\value{
\code{etr_windowed_rqa_sensitivity} returns native analyses, design
and overlap-reuse table, a descriptive per-curve/metric summary and
pairwise exact shared-center discrepancy table, without interpolation.
\code{etr_windowed_rqa_functional_mean_band} returns a native
whole-unit simultaneous mean band for derived RQA functions.
The recovery catalog returns 27 ordered named S3 definitions or an
auditable six-column native data frame; value-key returns one string,
assessment-frame returns a native semantic value data frame, and
reporting-text returns a compact source-aligned manuscript description.
}
\details{
The native implementation supports explicit sample or convertible
physical-time windows, optional source-aligned target-density threshold
selection, and three distance metrics. When density controls the
threshold, recurrence_rate is not allowed as a derived outcome.
Python dataclasses, pandas schemas and some exceptional input domains
remain scientifically distinct from the native representations.
These capabilities do not establish full Python source parity. Inference
resamples entire derived functions at the declared independent
curve/participant unit, never overlapping time windows independently.
The temporal distance between RQA window centers is not an estimate
of independent information resolution. Full source certification
requires domain-wide oracle qualification and independent review.
}
