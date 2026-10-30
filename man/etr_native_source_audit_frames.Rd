\name{etr_native_source_audit_frames}
\alias{etr_functional_random_effect_frame}
\alias{etr_functional_trial_random_effect_frame}
\alias{etr_functional_mixed_effects_full_refit_audit_frame}
\alias{etr_functional_mixed_effects_full_refit_trial_audit_frame}
\alias{etr_fpca_wild_bootstrap_truncation_scan_frame}
\alias{etr_fpca_wild_bootstrap_truncation_selection_frame}
\title{Native source-ordered mixed-effects and wild-bootstrap audit frames}
\description{
Six Python-independent, read-only native R adapters for realized
participant and nested-trial functional random effects, whole-participant
and nested-trial bootstrap identity audits, FPCA wild-bootstrap truncation
scans, and target-specific truncation selections. No model fitting,
automatic tuning, bootstrap resampling, or statistical qualification is performed.
}
\usage{
etr_functional_random_effect_frame(result, effect = "intercept")
etr_functional_trial_random_effect_frame(result)
etr_functional_mixed_effects_full_refit_audit_frame(bootstrap)
etr_functional_mixed_effects_full_refit_trial_audit_frame(bootstrap)
etr_fpca_wild_bootstrap_truncation_scan_frame(result)
etr_fpca_wild_bootstrap_truncation_selection_frame(result)
}
\arguments{
\item{result}{Native named record of already-realized mixed-effects
functions or FPCA truncation scan/selection outputs. Source-required
numerical fields and matrix dimensions are validated.}
\item{effect}{Participant-level random functional intercept or slope.}
\item{bootstrap}{Native named record of full-refit source and bootstrap
participant or trial identity histories.}
}
\details{
Frozen source: published \pkg{eyetrajectoriespy} 1.2.0,
commit \code{c1cd95ad718327550f7e55393ff38582872f7a94},
including \code{functional_mixed_effects.py},
\code{functional_mixed_effects_nested.py},
\code{functional_mixed_effects_full_refit.py}, and
\code{wild_selection.py}. Candidate-major and participant-major
row ordering, zero-based source/bootstrap indices, and missing selection
components are retained. Python dataclass and pandas return types are
not reproduced and remain an explicit unresolved source-contract gap.
}
\value{Native R data frame, one row per source-defined audit unit.
The functions never invoke the Python runtime.}
\keyword{datasets}
