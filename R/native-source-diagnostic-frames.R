# Frozen Python 1.2.0 diagnostic table and visualization contracts.
# Source: multivariate_surrogates.py, nonlinear_plotting.py and
# functional_mixed_effects_full_refit.py, frozen c1cd95ad718327550f7e55393ff38582872f7a94.
# Native data frames and base graphics are explicitly NOT pandas/Matplotlib objects.

.etr_diagnostic_matrix <- function(x,n,name) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&nrow(x)==n&&
    ncol(x)>=1L&&all(is.finite(x)),
    paste(name,"must be finite n_surrogates-by-dimension numeric matrix"))
  invisible(TRUE)
}
.etr_diagnostic_number <- function(x,n,name,allow_positive_infinity=FALSE) {
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)==n&&
    all(is.finite(x)|(allow_positive_infinity&x==Inf)),
    paste(name,"must be a numeric vector of required length with valid values"))
  invisible(TRUE)
}
.etr_diagnostic_flag <- function(x,n,name) {
  .etr_assert(is.logical(x)&&is.null(dim(x))&&length(x)==n&&!anyNA(x),
    paste(name,"must be logical vector with one flag per replicate"))
  invisible(TRUE)
}
.etr_diagnostic_covariance <- function(x,n,name) {
  .etr_assert(is.array(x)&&is.numeric(x)&&length(dim(x))==3L&&
    dim(x)[1L]==n&&dim(x)[2L]>=1L&&
    dim(x)[2L]==dim(x)[3L]&&all(is.finite(x)),
    paste(name,"must be a finite replicate-by-square-covariance array"))
  invisible(TRUE)
}
.etr_diagnostic_traces <- function(x) {
  n<-dim(x)[1L];k<-dim(x)[2L]
  vapply(seq_len(n),function(i)
    sum(diag(matrix(x[i,,],nrow=k,ncol=k))),numeric(1L))
}
.etr_diagnostic_frobenius <- function(x) {
  vapply(seq_len(dim(x)[1L]),function(i)
    sqrt(sum(x[i,,]^2)),numeric(1L))
}

#' Per-surrogate multivariate IAAFT convergence and spectrum diagnostics
#' @param result A native R surrogate record with explicit error matrices.
#' @return A source-ordered data frame with 0-based surrogate indices.
#' @export
etr_multivariate_iaaft_diagnostics_frame <- function(result) {
  .etr_scientific_frame_fields(result,c("n_surrogates",
    "convergence_iterations","spectral_errors","cross_spectral_errors"))
  n<-.etr_source_text_int(result$n_surrogates,"n_surrogates",min=0L)
  iter<-result$convergence_iterations
  .etr_assert(is.numeric(iter)&&is.null(dim(iter))&&length(iter)==n&&
    all(is.finite(iter))&&all(iter>=0)&&all(iter==floor(iter)),
    "convergence_iterations must contain one nonnegative integer per surrogate")
  .etr_diagnostic_matrix(result$spectral_errors,n,"spectral_errors")
  .etr_diagnostic_matrix(result$cross_spectral_errors,n,
    "cross_spectral_errors")
  .etr_assert(all(result$spectral_errors>=0)&&
    all(result$cross_spectral_errors>=0),
    "relative spectral errors must not be negative")
  # Python's pd.DataFrame([]) has zero rows and zero columns, not six
  # predeclared empty columns. Keep its exact observed result schema.
  if(n==0L)return(data.frame())
  data.frame(surrogate=seq_len(n)-1L,iterations=as.integer(iter),
    max_spectral_error=apply(result$spectral_errors,1L,max),
    max_cross_spectral_error=apply(result$cross_spectral_errors,1L,max),
    mean_spectral_error=rowMeans(result$spectral_errors),
    mean_cross_spectral_error=rowMeans(result$cross_spectral_errors))
}

#' Full-refit mixed-effects variance diagnostics per participant bootstrap
#' @param bootstrap An explicit native R-list full-refit bootstrap record.
#' @return Source-column-ordered variance and covariance diagnostic frame.
#' @export
etr_functional_mixed_effects_variance_bootstrap_frame <- function(bootstrap) {
  fields<-c("bootstrap_coefficient_functions","residual_variances",
    "log_likelihoods","random_effect_covariance_eigenvalues",
    "random_effect_covariances",
    "random_effect_covariance_condition_numbers",
    "random_effect_boundary_flags","random_effect_singular_flags",
    "random_slope_boundary_flags","convergence_flags","backend_warnings",
    "random_intercept_covariances")
  .etr_scientific_frame_fields(bootstrap,fields,"bootstrap")
  coeff<-bootstrap$bootstrap_coefficient_functions
  .etr_assert(is.array(coeff)&&is.numeric(coeff)&&
    length(dim(coeff))==3L&&dim(coeff)[1L]>=0L&&
    all(dim(coeff)[2L:3L]>0L)&&all(is.finite(coeff)),
    "bootstrap_coefficient_functions must be finite 3D bootstrap array")
  n<-dim(coeff)[1L]
  .etr_diagnostic_number(bootstrap$residual_variances,n,
    "residual_variances")
  .etr_diagnostic_number(bootstrap$log_likelihoods,n,
    "log_likelihoods")
  .etr_diagnostic_number(
    bootstrap$random_effect_covariance_condition_numbers,n,
    "random_effect_covariance_condition_numbers",allow_positive_infinity=TRUE)
  for(name in c("random_effect_boundary_flags",
    "random_effect_singular_flags","random_slope_boundary_flags",
    "convergence_flags"))
    .etr_diagnostic_flag(bootstrap[[name]],n,name)
  eigen<-bootstrap$random_effect_covariance_eigenvalues
  .etr_diagnostic_matrix(eigen,n,
    "random_effect_covariance_eigenvalues")
  .etr_diagnostic_covariance(bootstrap$random_effect_covariances,
    n,"random_effect_covariances")
  .etr_assert(ncol(eigen)==dim(bootstrap$random_effect_covariances)[2L],
    "random_effect_covariance_eigenvalues dimension must match covariance")
  .etr_diagnostic_covariance(bootstrap$random_intercept_covariances,
    n,"random_intercept_covariances")
  .etr_assert(is.list(bootstrap$backend_warnings)&&
    length(bootstrap$backend_warnings)==n&&
    all(vapply(bootstrap$backend_warnings,is.character,logical(1L))),
    "backend_warnings must be list of character vectors per replicate")
  # Source Python builds rows within range(n_bootstrap); the empty typed
  # record returns a truly 0-column pandas frame, not an empty 13-column
  # R dataframe. Optional covariance fields are not accessed in this case.
  if(n==0L)return(data.frame())
  out<-data.frame(
    bootstrap_replicate=seq_len(n)-1L,
    residual_variance=as.numeric(bootstrap$residual_variances),
    log_likelihood=as.numeric(bootstrap$log_likelihoods),
    covariance_min_eigenvalue=apply(eigen,1L,min),
    covariance_max_eigenvalue=apply(eigen,1L,max),
    covariance_trace=.etr_diagnostic_traces(
      bootstrap$random_effect_covariances),
    covariance_condition_number=as.numeric(
      bootstrap$random_effect_covariance_condition_numbers),
    boundary_fit=bootstrap$random_effect_boundary_flags,
    singular_fit=bootstrap$random_effect_singular_flags,
    random_slope_boundary_fit=bootstrap$random_slope_boundary_flags,
    converged=bootstrap$convergence_flags,
    backend_warning_count=vapply(bootstrap$backend_warnings,
      length,integer(1L)),
    random_intercept_covariance_trace=.etr_diagnostic_traces(
      bootstrap$random_intercept_covariances),
    stringsAsFactors=FALSE)
  if(!is.null(bootstrap$residual_correlation_parameters)){
    .etr_diagnostic_number(bootstrap$residual_correlation_parameters,n,
      "residual_correlation_parameters")
    .etr_diagnostic_number(bootstrap$residual_correlation_condition_numbers,n,
      "residual_correlation_condition_numbers",allow_positive_infinity=TRUE)
    for(name in c("residual_correlation_boundary_flags",
      "residual_correlation_independence_flags"))
      .etr_diagnostic_flag(bootstrap[[name]],n,name)
    out$residual_correlation_parameter<-
      bootstrap$residual_correlation_parameters
    out$residual_correlation_condition_number<-
      bootstrap$residual_correlation_condition_numbers
    out$residual_correlation_boundary_fit<-
      bootstrap$residual_correlation_boundary_flags
    out$residual_correlation_independence_limit_fit<-
      bootstrap$residual_correlation_independence_flags
  }
  if(!is.null(bootstrap$trial_random_effect_covariances)){
    .etr_diagnostic_covariance(
      bootstrap$trial_random_effect_covariances,n,
      "trial_random_effect_covariances")
    .etr_diagnostic_matrix(
      bootstrap$trial_random_effect_covariance_eigenvalues,n,
      "trial_random_effect_covariance_eigenvalues")
    .etr_assert(ncol(bootstrap$trial_random_effect_covariance_eigenvalues)==
      dim(bootstrap$trial_random_effect_covariances)[2L],
      "trial covariance eigenvalue dimension must match covariance")
    .etr_diagnostic_number(
      bootstrap$trial_random_effect_covariance_condition_numbers,n,
      "trial_random_effect_covariance_condition_numbers",allow_positive_infinity=TRUE)
    for(name in c("trial_random_effect_boundary_flags",
      "trial_random_effect_singular_flags"))
      .etr_diagnostic_flag(bootstrap[[name]],n,name)
    te<-bootstrap$trial_random_effect_covariance_eigenvalues
    out$trial_covariance_trace<-.etr_diagnostic_traces(
      bootstrap$trial_random_effect_covariances)
    out$trial_covariance_min_eigenvalue<-apply(te,1L,min)
    out$trial_covariance_max_eigenvalue<-apply(te,1L,max)
    out$trial_covariance_condition_number<-
      bootstrap$trial_random_effect_covariance_condition_numbers
    out$trial_boundary_fit<-bootstrap$trial_random_effect_boundary_flags
    out$trial_singular_fit<-bootstrap$trial_random_effect_singular_flags
  }
  if(!is.null(bootstrap$random_slope_covariances)){
    .etr_diagnostic_covariance(bootstrap$random_slope_covariances,n,
      "random_slope_covariances")
    .etr_diagnostic_covariance(
      bootstrap$random_intercept_slope_covariances,n,
      "random_intercept_slope_covariances")
    out$random_slope_covariance_trace<-.etr_diagnostic_traces(
      bootstrap$random_slope_covariances)
    out$intercept_slope_cross_covariance_frobenius<-
      .etr_diagnostic_frobenius(
        bootstrap$random_intercept_slope_covariances)
  }
  out
}

#' Visualize maximum per-surrogate multivariate spectrum errors
#' @param result Explicit native R IAAFT ensemble record.
#' @param ... Additional base graphics plot arguments.
#' @return Invisibly, the source-ordered numerical frame plotted.
#' @export
etr_plot_multivariate_iaaft_diagnostics <- function(result,...) {
  frame<-etr_multivariate_iaaft_diagnostics_frame(result)
  .etr_scientific_frame_fields(result,c("reference_dimension"),
    "surrogate_result")
  reference<-.etr_source_text_word(result$reference_dimension,
    "reference_dimension")
  x<-frame$surrogate
  a<-frame$max_spectral_error
  b<-frame$max_cross_spectral_error
  y_limits<-range(c(a,b),finite=TRUE)
  if(identical(y_limits[1L],y_limits[2L]))
    y_limits<-y_limits+c(-.05,.05)*max(1,abs(y_limits[1L]))
  graphics::plot(x,a,type="o",pch=1L,ylim=y_limits,
    xlab="Surrogate index",ylab="Relative mismatch",
    main=paste0("Multivariate IAAFT preservation diagnostics: ",
      reference," reference"),...)
  graphics::lines(x,b,type="o",pch=1L,lty=2L)
  graphics::legend("topright",legend=c("Max power-spectrum error",
    "Max cross-spectrum error"),lty=c(1,2),pch=c(1,1),
    bty="n")
  invisible(frame)
}

#' Visualize a multivariate surrogate null statistic distribution
#' @param result A native nonlinearity result with observed and simulated
#'   statistics, declared statistic identifier and plus-one p-value.
#' @param bins Predeclared integer histogram-bin count (at least two).
#' @param python_boundary_mode When TRUE, use NumPy's exact equally spaced
#'   integer-bin histogram boundaries, fixed 0.5 constant-data expansion and
#'   left-inclusive counts (with rightmost edge included). This aligns the
#'   source histogram numerics, not Matplotlib Axes or Python dataclass types.
#'   The default FALSE retains the previous R histogram implementation.
#' @param ... Additional base graphics histogram arguments.
#' @return Invisibly, histogram geometry and observed statistic.
#' @export
etr_plot_multivariate_surrogate_nonlinearity <- function(result,
    bins=20L,python_boundary_mode=FALSE,...) {
  .etr_scientific_frame_fields(result,c("surrogate_statistics",
    "observed_statistic","statistic","p_value"))
  values<-.etr_source_text_vector(result$surrogate_statistics,
    "surrogate_statistics")
  observed<-.etr_source_text_number(result$observed_statistic,
    "observed_statistic")
  p<-.etr_source_text_number(result$p_value,"p_value",min=0,max=1)
  name<-.etr_source_text_word(result$statistic,"statistic")
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  if(isTRUE(python_boundary_mode)) {
    # Python nonlinear_plotting.py checks an integer count, then
    # Matplotlib delegates exact bin boundaries/counts to NumPy.
    .etr_assert(is.integer(bins)&&length(bins)==1L&&
      !is.na(bins)&&bins>=2L&&bins<=10000L,
      "bins must be a Python integer >= 2 within native 10000-bin limit")
    b<-as.integer(bins)
  } else b<-.etr_source_text_int(bins,"bins",min=2L)
  limits<-range(values)
  if(limits[1L]==limits[2L]){
    half<-if(isTRUE(python_boundary_mode))0.5 else
      if(limits[1L]==0)0.5 else abs(limits[1L])*0.5
    limits<-limits+c(-half,half)
  }
  breaks<-seq(limits[1L],limits[2L],length.out=b+1L)
  h<-graphics::hist(values,breaks=breaks,plot=FALSE,
    right=FALSE,include.lowest=TRUE)
  if(isTRUE(python_boundary_mode)){
    # R's histogram uses fuzzy endpoint tolerance; NumPy uses
    # [left,right) bins, with only the final right edge inclusive.
    # Replace both counts and plot densities with exact source values.
    h$counts<-as.integer(tabulate(
      findInterval(values,breaks,rightmost.closed=TRUE),nbins=b))
    h$density<-h$counts/(length(values)*diff(h$breaks))
    h$intensities<-h$density
  }
  graphics::plot(h,main=paste0(
    "Multivariate IAAFT surrogate test (p=",sprintf("%.3g",p),")"),
    xlab=name,ylab="Surrogate count",col="grey75",border="grey45",...)
  graphics::abline(v=observed,lty=2L,lwd=2L)
  graphics::legend("topright","Observed",lty=2L,lwd=2L,bty="n")
  invisible(list(histogram=h,observed_statistic=observed,p_value=p))
}
