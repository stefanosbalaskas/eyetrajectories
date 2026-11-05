\name{etr_evaluate_hierarchy_truth_recovery}
\alias{etr_evaluate_hierarchy_truth_recovery}
\title{Known-truth hierarchy score-source variance audit}
\usage{etr_evaluate_hierarchy_truth_recovery(truth)}
\arguments{\item{truth}{Source-shaped simulator truth with curve,
participant and trial score matrices and declared eigenvalues.}}
\value{Native recovery assessment with labelled absolute and relative
source variances and semantic metric definitions.}
\description{Compares realized population (ddof zero) score-source
variances against fixed simulator truth. No estimator is fitted. Source
dataclass and full domain certification remain open.}
