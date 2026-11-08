\name{etr_reconstruct_compositional_fpca_stable}
\alias{etr_reconstruct_compositional_fpca_stable}
\title{Overflow-stable compositional FPCA reconstruction}
\usage{
etr_reconstruct_compositional_fpca_stable(result, scores = NULL,
  n_components = NULL)
}
\arguments{
\item{result}{Native compositional FPCA fit.}
\item{scores}{Optional replacement scores.}
\item{n_components}{Optional fitted component count.}
}
\description{
Reconstructs fitted ALR score curves and computes their stable inverse ALR
onto the probability simplex. Leaves the original reconstruction unchanged.
}
\value{Numeric array (curves by times by simplex dimensions).}
