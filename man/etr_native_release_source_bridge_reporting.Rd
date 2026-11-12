\name{etr_native_release_source_bridge_reporting}
\alias{etr_detect_functional_outliers_skfda}
\alias{etr_export_python_portable_result}
\alias{etr_fit_sparse_fpca_fdapy}
\alias{etr_native_source_contract_review_queue}
\alias{etr_to_fdapy_irregular}
\alias{etr_to_skfda_basis}
\alias{etr_to_skfda_grid}
\alias{etr_workflow_audit_result}
\alias{etr_workflow_decisions_frame}
\alias{etr_workflow_reporting_text}
\alias{etr_workflow_steps_frame}
\alias{etr_workflow_summary_frame}
\title{Native reporting, audit and explicit optional Python bridge exports}
\description{
Reference index for exported functions in this scientific domain. The
functions are independently callable; scientific scope and input contracts
vary by estimator, data structure, fitted object, and selected backend.
}
\details{
Bridge functions may require a separate compatible Python installation;
they explicitly expose third-party scikit-fda or FDApy objects and MUST
NOT be described as Python-free numerical native R implementations.
Portable writer and reporting functions serialize or describe provenance,
schema fields, execution steps and scientific decisions, which do not
by themselves prove source parity. The source-contract review queue is
an unsigned author-side review artifact; it does not approve scientific
contracts. All external approvals require genuine independent review.
}
\section{Optional Python FData source-constructor geometry in native R}{
The opt-in \code{etr_to_skfda_grid(trajectories,
strict_source_record=TRUE)} returns a typed R record of the frozen
Python 1.2 scikit-fda constructor arguments: unmodified
curve-by-time-by-coordinate values, source time grid, dataset name and
coordinate names. It retains the one-domain normalized grid and
zero-based source curve positions for scientific inspection.
It does not return a real Python \code{skfda.FDataGrid} instance.

The opt-in \code{etr_to_fdapy_irregular(trajectories,
dimension, strict_source_record=TRUE)} returns separate irregular
\code{input_dim_0} sample-time arrays and observed selected-channel
value arrays under the source zero-based observation keys. Source
mode accepts legitimate two-visit irregular curves and requires
finite selected values; all other channels remain unaltered.
It does not return a real Python \code{FDApy.IrregularFunctionalData}
instance. The original native \code{fdapace} adapter is the default,
with its distinct minimum-observation restrictions.

Both opt-in modes preserve observations without interpolation,
imputation or fitting. Frozen Python source-constructor equivalence
is limited to these scientific arrays and labels. The actual
scikit-fda/FDApy backend class methods, projected bases, PACE
estimators and Python exception objects remain separately unqualified.
Independent full-contract source certification is pending.
See \code{docs/native-skfda-fdapy-source-constructor-records-20261112.md}.
}

\section{Exported entry points}{
\describe{
\item{\code{etr_detect_functional_outliers_skfda}}{\emph{detect functional outliers skfda} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_export_python_portable_result}}{Writes common-grid and
irregular trajectories, dense FPCA and MFPCA fits, and compositional FPCA
fits in the Python 1.2 JSON and NPZ snapshot format. Irregular samples keep
their curve-specific grids and matrix shapes. Metadata columns are ordered
and indexed by curve ID, with numeric, character and logical vectors
supported. Missing character and logical cells are JSON nulls. The dense
fit carries the R component count, scaling and total variance under
\code{provenance$native_r_fpca}. Its Python \code{model} field is null.
Compositional fits retain their zero-based reference dimension, epsilon and
nested dense fit. Exports record the R package version. Both
\code{overwrite} and \code{include_environment} must be false, and the
destination must be new or empty.}
\item{\code{etr_fit_sparse_fpca_fdapy}}{\emph{fit sparse fpca fdapy} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_native_source_contract_review_queue}}{\emph{native source contract review queue} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_to_fdapy_irregular}}{\emph{to fdapy irregular} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_to_skfda_basis}}{\emph{to skfda basis} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_to_skfda_grid}}{\emph{to skfda grid} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_workflow_audit_result}}{\emph{workflow audit result} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_workflow_decisions_frame}}{\emph{workflow decisions frame} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_workflow_reporting_text}}{\emph{workflow reporting text} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_workflow_steps_frame}}{\emph{workflow steps frame} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
\item{\code{etr_workflow_summary_frame}}{\emph{workflow summary frame} -- an explicit exported method; consult its R formal arguments and source-contract restrictions.}
}
}
\section{Source-sampled scikit-fda basis projection}{
An additional opt-in \code{etr_to_skfda_basis(trajectories,
dimension, basis="bspline", n_basis=15L, order=4L,
strict_source_record=TRUE)} computes the frozen Python 1.2
scikit-fda sampled least-squares scientific coefficients on
the original complete observed time grid. The native R QR
solver is used on the actual source-compatible B-spline or
Fourier basis values without interpolation or regularization.

The Fourier mode uses the normalized
\code{1/sqrt(T)}, \code{sqrt(2/T) sin(2*pi*k*t/T)}
and \code{sqrt(2/T) cos(2*pi*k*t/T)} columns, and
automatically expands even requested basis counts to the
next odd count, preserving the originally requested count
separately in the frozen-source scientific result fields.
B-spline mode retains the source uniformly placed interior
knots and endpoint repetition. Strict numerical mode requires
a finite complete grid and full-column-rank basis design;
the broader singular and underdetermined Python backend
domain remains outside the reviewed scientific contract.

The return is a typed native R scientific basis record with
an explicit \code{backend_object=NULL}; it is not a real
Python \code{skfda.FDataBasis} instance. The legacy native
R basis projection remains the default and unchanged.
Independent Python object identity and whole-domain
backend equivalence are not certified. See
\code{docs/native-skfda-basis-sampled-ls-source-20261112.md}.
}

\section{Modified Band Depth source-scientific functional boxplot}{
The opt-in \code{etr_detect_functional_outliers_skfda(trajectories,
dimension, method="boxplot", factor=1.5, random_state=0L,
strict_source_record=TRUE)} implements the frozen Python 1.2
scikit-fda BoxplotOutlierDetector's deterministic default method
through a native R ModifiedBandDepth functional data record.

Each selected observed channel curve receives pointwise
SimplicialDepth based on all distinct pairs of training curves.
The depth profile is integrated using SciPy-compatible composite
Simpson quadrature on the actual (possibly nonuniform) observed
time grid. The deepest \code{ceil(n/2)} curves define the functional
central region, which is expanded by \code{factor} times the
pointwise central-envelope width. A curve is flagged for scientific
review if any point lies outside this functional fence.

Strict source mode is bounded to complete finite input and
untied deepest-half cutoff depths. It returns native R labels,
modified-band depths, Simpson weights and central/non-outlying
envelope diagnostics, never a real Python scikit-fda detector.
The stochastic \code{method="msplot"} requires different
directional-outlyingness and robust MCD calculations and is
explicitly not supported by this scientific review. The
historical marginal pointwise Tukey alternative remains the
default when \code{strict_source_record=FALSE}.
Full Python class/exception and MSPlot-method contract equivalence
is not claimed. See
\code{docs/native-skfda-mbd-functional-boxplot-source-20261112.md}.
}

\section{Fixed-spectrum FDApy PACE numerical source stage}{
Opt-in \code{etr_fit_sparse_fpca_fdapy(trajectories, dimension,
n_components, strict_source_record=TRUE,
source_fit_snapshot=...)} evaluates the native R numerical FDApy
1.0.x \code{UFPCA} conditional PACE score stage, provided a genuine
already fitted FDApy source eigensystem and source-centered irregular
observations in \code{source_fit_snapshot}.

The supplied snapshot must contain \code{mean_grid},
\code{eigenfunctions}, \code{eigenvalues}, \code{noise_variance}
and a \code{centered_observations} list, all in original curve order
and with eigenfunctions on the exact sorted pooled observation times.
The native score estimator follows source FDApy's actual internal
\code{np.interp} pooled-grid interpolation, including constant endpoint
extension, spectral covariance reconstruction and pseudoinverse
\code{(Phi' diag(lambda) Phi + max(tol, noise_variance)*I)^+};
the scores are reconstructed with the supplied eigenfunctions and mean.

This stage does NOT fit FDApy's penalized B-spline or local-polynomial
mean/covariance smoothers or estimate its eigenpairs. \code{normalize=TRUE}
and the source backend Python \code{UFPCA} object and classes are NOT
implemented. Its semantic coverage is specifically restricted to
fixed-source-spectrum PACE scoring and inverse reconstruction; the
native full sparse-FPCA model-fitting source gap remains open in
\code{inst/extdata/native_scoped_fdapy_submethod_gaps_20261112.csv}.
Historical \code{backend="fdapace"} remains unchanged by default.
See \code{docs/native-fdapy-fixed-spectrum-pace-20261112.md}.
}

\value{Each function returns its own documented native R, scientific-model,
bridge, workflow or audit result; no single shared return type is asserted.}
