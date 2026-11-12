\name{etr_plot_fpca_component_band}
\alias{etr_plot_fpca_component_band}
\title{Plot bootstrap-simultaneous functional principal-component shape bands}
\usage{
etr_plot_fpca_component_band(
    result, component = 0L, dimension = NULL,
    strict_source_record = FALSE, ...)
}
\arguments{
\item{result}{Genuine native FPCA component-shape bootstrap band with retained reference FPCs and observed-grid lower/upper uncertainty arrays.}
\item{component}{Python-source zero-based fitted FPC index.}
\item{dimension}{Exact fitted functional channel; defaults to the original first channel.}
\item{strict_source_record}{Draw natively and return a typed source-scientific record with Python fill-between alpha 0.2, original observed-grid uncertainty bounds, confidence label, reference FPC line and source legend. Does not produce live Python \code{Axes}.}
\item{...}{Native R graphical parameters.}
}
\value{Default invisible time, reference FPC, lower and upper source-data frame. Strict mode emits native R source-scientific fill-band and line artist geometry for the selected component/channel.}
\description{Plots the existing matched and sign-aligned component-shape uncertainty without re-estimating bootstrap FPCs or substituting pointwise intervals. Familywise versus component-wise titles and confidence labels follow frozen public Python 1.2 plotting semantics; Matplotlib pixel and runtime class identities are explicitly outside scope.}
