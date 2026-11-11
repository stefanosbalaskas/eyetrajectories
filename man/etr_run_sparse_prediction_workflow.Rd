\name{etr_run_sparse_prediction_workflow}
\alias{etr_run_sparse_prediction_workflow}
\title{Native sparse future split-conformal workflow with optional Python W2 scientific record}
\usage{
etr_run_sparse_prediction_workflow(proper_training, calibration,
    target, config, strict_source_record = FALSE)
}
\arguments{
\item{proper_training}{An explicit native irregular proper-training trajectory set.}
\item{calibration}{A separate native irregular calibration trajectory set.}
\item{target}{Exactly one native irregular target trajectory.}
\item{config}{Named sparse prediction configuration with explicit \code{training}, \code{history_cutoff}, and finite \code{prediction_grid}. The \code{backend="native_sparse_partial_conformal"} computes source-scientific PACE conditional predictions and calibration bands; \code{native_mean_curve_split_conformal} is a distinct alternative.}
\item{strict_source_record}{If TRUE, require native sparse PACE training, preserve its nested frozen W2 scientific record, and emit the eleven canonical source result fields, nine configuration fields, scientific decisions and explicit disjoint-role provenance. Reject R-only selector fold replay. Default FALSE retains native extended diagnostic results.}
}
\value{A native scientific workflow recording training FPCA/PACE, calibration, a single target prediction band, measured steps, scientific decisions, reports and tables.}
\description{Split-conformal coverage applies only to future observed measurements on the explicitly declared finite grid, not continuous-time latent trajectories. The process performs no random role allocation or raw interpolation. Python runtime classes, full error semantics and independent certification remain outside the R source-scientific record.}
