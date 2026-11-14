# Frozen Python 1.2 workflows/_plotting.py, strictly bounded native R
# graphics dispatch. Matplotlib Axes, figure bytes and rendering backend do
# not have portable R equivalents. These contracts remain independently unsigned.

#' Plot a specifically declared native scientific workflow result
#' @param result Native R FPCA, function-on-scalar, or recurrence workflow.
#' @param plot One of fpca_component, function_on_scalar_coefficient, recurrence.
#' @param component Explicit zero-based FPCA component index.
#' @param dimension Explicit dimension name for multichannel results.
#' @param coefficient Explicit fitted FOS coefficient name or zero-based index.
#' @param sd_multiplier Positive finite FPCA perturbation multiplier.
#' @param max_points Maximum dense recurrence matrix points.
#' @param ax,axes Must be NULL; Matplotlib axes cannot be used in R.
#' @return Invisibly the plotted scientific source geometry (not Matplotlib axes).
#' @noRd
.etr_workflow_legacy_plot<-function(result,plot,component=NULL,dimension=NULL,
    coefficient=NULL,sd_multiplier=2,max_points=200000L,
    ax=NULL,axes=NULL){
  .etr_assert(is.character(plot)&&length(plot)==1L&&
    !is.na(plot)&&plot%in%c("fpca_component",
      "function_on_scalar_coefficient","recurrence"),
    "plot must be a supported explicit native workflow plot; no fallback")
  .etr_assert(is.null(ax)&&is.null(axes),
    "Matplotlib ax/axes are unsupported in native R graphics")
  if(plot=="recurrence"){
    .etr_assert(inherits(result,"etr_recurrence_workflow"),
      "recurrence plot requires native recurrence workflow")
    .etr_assert(is.numeric(max_points)&&length(max_points)==1L&&
      is.finite(max_points)&&max_points==floor(max_points)&&
      max_points>=1L,"max_points must be a positive integer")
    z<-result$recurrence$matrix
    .etr_assert(length(z)<=max_points,
      "recurrence matrix exceeds requested max_points; no silent downsampling")
    return(invisible(etr_plot_recurrence(result$recurrence)))
  }
  .etr_assert(is.null(max_points)||is.numeric(max_points),
    "max_points must be NULL or numeric")
  if(plot=="fpca_component"){
    .etr_assert(inherits(result,"etr_fpca_workflow"),
      "fpca_component requires native FPCA workflow")
    fit<-result$fit
    .etr_assert(is.numeric(component)&&length(component)==1L&&
      is.finite(component)&&component==floor(component)&&
      component>=0L&&component<fit$n_components,
      "component must be an explicit zero-based retained index")
    if(is.null(dimension)){
      .etr_assert(length(fit$dimension_names)==1L,
        "dimension must be supplied for multivariate FPCA")
      d<-1L
    }else{
      .etr_assert(is.character(dimension)&&length(dimension)==1L&&
        !is.na(dimension)&&dimension%in%fit$dimension_names,
        "dimension must identify one known FPCA channel")
      d<-match(dimension,fit$dimension_names)
    }
    .etr_assert(is.numeric(sd_multiplier)&&
      length(sd_multiplier)==1L&&is.finite(sd_multiplier)&&
      sd_multiplier>0,"sd_multiplier must be finite positive")
    k<-as.integer(component)+1L
    deviation<-as.numeric(sd_multiplier*sqrt(fit$explained_variance[k])*
      fit$components[k,,d])
    mean_value<-as.numeric(fit$mean[,d])
    frame<-data.frame(time=fit$time,mean=mean_value,
      lower=mean_value-deviation,upper=mean_value+deviation)
    graphics::matplot(frame$time,frame[,c("mean","lower","upper")],
      type="l",lty=c(1L,2L,2L),lwd=2,
      xlab=paste0("Time (",fit$time_unit,")"),
      ylab=fit$dimension_names[d],
      main=paste0("FPC ",component,": ",fit$dimension_names[d]))
    return(invisible(frame))
  }
  .etr_assert(inherits(result,"etr_function_on_scalar_workflow"),
    "function_on_scalar_coefficient requires native FOS workflow")
  fit<-result$fit
  if(is.character(coefficient)){
    .etr_assert(length(coefficient)==1L&&!is.na(coefficient)&&
      coefficient%in%fit$coefficient_names,
      "coefficient must be an explicitly known coefficient")
    k<-match(coefficient,fit$coefficient_names)
  }else{
    .etr_assert(is.numeric(coefficient)&&length(coefficient)==1L&&
      is.finite(coefficient)&&coefficient==floor(coefficient)&&
      coefficient>=0&&coefficient<length(fit$coefficient_names),
      "coefficient must be an explicit zero-based index or name")
    k<-as.integer(coefficient)+1L
  }
  if(is.null(dimension)){
    .etr_assert(length(fit$dimension_names)==1L,
      "dimension must be supplied for multivariate function-on-scalar fit")
    d<-1L
  }else{
    .etr_assert(is.character(dimension)&&length(dimension)==1L&&
      !is.na(dimension)&&dimension%in%fit$dimension_names,
      "dimension must identify a known function-on-scalar channel")
    d<-match(dimension,fit$dimension_names)
  }
  frame<-data.frame(time=fit$time,
    estimate=as.numeric(fit$coefficients[k,,d]),
    standard_error=as.numeric(fit$standard_errors[k,,d]))
  graphics::plot(frame$time,frame$estimate,type="l",lwd=2,
    xlab=paste0("Time (",fit$time_unit,")"),
    ylab=fit$coefficient_names[k],
    main=paste0(fit$coefficient_names[k],": ",fit$dimension_names[d]))
  invisible(frame)
}

#' Export an explicit native workflow figure on the current R graphics backend
#'
#' @param result Native workflow result.
#' @param path Output .png, .svg, or .pdf path.
#' @param plot Required explicit plot type.
#' @param dpi Positive raster resolution for PNG.
#' @param close Must be TRUE; R devices are always closed after output.
#' @param ... Explicit options forwarded to etr_plot_workflow_result().
#' @return Existing normalized file path, not Python pathlib.Path.
#' @noRd
.etr_workflow_legacy_save<-function(result,path,plot,dpi=150L,
    close=TRUE,...){
  .etr_assert(is.character(path)&&length(path)==1L&&!is.na(path)&&
    nzchar(trimws(path)),
    "path must be a nonempty single file path")
  .etr_assert(is.character(plot)&&length(plot)==1L&&!is.na(plot),
    "plot must be explicitly declared")
  .etr_assert(is.numeric(dpi)&&length(dpi)==1L&&is.finite(dpi)&&
    dpi==floor(dpi)&&dpi>=1L&&dpi<=1200L,
    "dpi must be a positive supported integer <=1200")
  .etr_assert(identical(close,TRUE),
    "native R figure export always closes devices; close=FALSE unsupported")
  ext<-tolower(tools::file_ext(path))
  .etr_assert(ext%in%c("png","svg","pdf"),
    "workflow figure path must end in .png, .svg, or .pdf")
  .etr_assert(!file.exists(path),
    "existing figure is not overwritten by native workflow export")
  folder<-dirname(path)
  if(!dir.exists(folder))dir.create(folder,recursive=TRUE,
    showWarnings=FALSE)
  .etr_assert(dir.exists(folder),"cannot create output directory")
  if(ext=="png")grDevices::png(path,width=7,height=5,units="in",
    res=as.integer(dpi))
  else if(ext=="svg")grDevices::svg(path,width=7,height=5)
  else grDevices::pdf(path,width=7,height=5)
  opened<-TRUE
  on.exit(if(opened)grDevices::dev.off(),add=TRUE)
  etr_plot_workflow_result(result,plot=plot,...)
  grDevices::dev.off()
  opened<-FALSE
  invisible(normalizePath(path,winslash="/",mustWork=TRUE))
}

# Source-scientific W4 extension (frozen Python 1.2, c1cd95ad).
# The historical native plotting and safe-no-overwrite file behavior above
# remain the exact default. Source mode is an explicit, bounded extension.

.etr_workflow_required_component <- function(x) {
  .etr_assert(!is.null(x),
    "component must be supplied explicitly for this plot")
  .etr_assert(typeof(x)=="integer"&&length(x)==1L&&!is.na(x),
    "component must be an integer")
  x
}
.etr_workflow_required_coefficient <- function(x) {
  .etr_assert(!is.null(x),
    "coefficient must be supplied explicitly for this plot")
  .etr_assert(length(x)==1L&&!is.na(x)&&
    ((is.character(x)&&nzchar(x))||typeof(x)=="integer"),
    "coefficient must be a name or integer index")
  x
}
.etr_workflow_source_record <- function(plot,artist) {
  structure(list(
    source_export="plot_workflow_result",canonical_plot=plot,
    renderer="native_R_base_graphics",
    python_return_kind=if(identical(plot,"sparse_mfpca_component"))
      "numpy.ndarray[matplotlib.axes.Axes]" else "matplotlib.axes.Axes",
    artist=artist,matplotlib_object_identity=FALSE,
    independently_certified=FALSE),
    class=c("etr_workflow_scientific_plot_record","list"))
}

#' Source-aligned seven-route workflow plot dispatch
#' @param strict_source_record Opt-in frozen Python 1.2 scientific dispatch
#'   returning typed R artist geometry, never Matplotlib Axes.
#' @inheritParams etr_plot_workflow_result
#' @export
etr_plot_workflow_result <- function(result,plot,component=NULL,
    dimension=NULL,coefficient=NULL,sd_multiplier=2,max_points=200000L,
    ax=NULL,axes=NULL,strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(!isTRUE(strict_source_record))
    return(.etr_workflow_legacy_plot(result,plot,component,dimension,
      coefficient,sd_multiplier,max_points,ax,axes))
  choices<-c("fpca_component","sparse_fpca_component",
    "sparse_mfpca_component","function_on_scalar_coefficient",
    "functional_mixed_effects_coefficient",
    "generalized_functional_coefficient","recurrence")
  .etr_assert(is.character(plot)&&length(plot)==1L&&!is.na(plot)&&
    plot%in%choices,
    "plot must be one of the seven declared source workflow plots; no automatic fallback")
  .etr_assert(is.null(ax)&&is.null(axes),
    "native R cannot accept or return Python Matplotlib ax/axes")
  .etr_assert(is.numeric(sd_multiplier)&&length(sd_multiplier)==1L&&
    !is.logical(sd_multiplier)&&is.finite(sd_multiplier)&&
    sd_multiplier>0,"sd_multiplier must be a finite positive scalar")
  .etr_assert(is.null(max_points)||
    (typeof(max_points)=="integer"&&length(max_points)==1L&&
     !is.na(max_points)&&max_points>=1L),
    "max_points must be NULL or a positive integer")
  if(plot=="fpca_component"){
    .etr_assert(inherits(result,"etr_fpca_workflow"),
      "fpca_component requires an FPCAWorkflowResult-compatible native workflow")
    component<-.etr_workflow_required_component(component)
    fit<-result$fit
    if(is.null(dimension)&&length(fit$dimension_names)>1L)
      stop("dimension must be supplied explicitly for multivariate FPCA",
        call.=FALSE)
    frame<-.etr_workflow_legacy_plot(result,plot,component,dimension,
      coefficient,sd_multiplier,max_points,NULL,NULL)
    artist<-list(
      time=as.numeric(frame$time),
      lines=list(list(label="mean",y=as.numeric(frame$mean)),
        list(label="mean - SD mode",y=as.numeric(frame$lower)),
        list(label="mean + SD mode",y=as.numeric(frame$upper))),
      source_component=component,sd_multiplier=sd_multiplier,
      source_time_unit=fit$time_unit)
  }else if(plot=="sparse_fpca_component"){
    .etr_assert(inherits(result,"etr_sparse_fpca_workflow"),
      "sparse_fpca_component requires a SparseFPCAWorkflowResult-compatible native workflow")
    component<-.etr_workflow_required_component(component)
    artist<-etr_plot_sparse_fpca_component(result$fit,
      component=component,sd_multiplier=sd_multiplier,
      strict_source_record=TRUE)
  }else if(plot=="sparse_mfpca_component"){
    .etr_assert(inherits(result,"etr_native_sparse_mfpca_workflow"),
      "sparse_mfpca_component requires a SparseMFPCAWorkflowResult-compatible native workflow")
    component<-.etr_workflow_required_component(component)
    artist<-etr_plot_sparse_mfpca_component(result$fit,
      component=component,sd_multiplier=sd_multiplier,
      strict_source_record=TRUE)
  }else if(plot=="function_on_scalar_coefficient"){
    .etr_assert(inherits(result,"etr_function_on_scalar_workflow"),
      "function_on_scalar_coefficient requires a FunctionOnScalarWorkflowResult-compatible native workflow")
    coefficient<-.etr_workflow_required_coefficient(coefficient)
    fit<-result$fit
    if(is.null(dimension)&&length(fit$dimension_names)>1L)
      stop("dimension must be supplied explicitly for a multivariate function-on-scalar fit",
        call.=FALSE)
    artist<-etr_plot_function_on_scalar_coefficients(fit,
      coefficient=coefficient,dimension=dimension,
      strict_source_record=TRUE)
  }else if(plot=="functional_mixed_effects_coefficient"){
    .etr_assert(inherits(result,"etr_functional_mixed_effects_workflow"),
      "functional_mixed_effects_coefficient requires a FunctionalMixedEffectsWorkflowResult-compatible native workflow")
    coefficient<-.etr_workflow_required_coefficient(coefficient)
    fit<-result$fit
    # Joint nlme spline likelihood and legacy moments store coefficient
    # statistics under different names; never refit either estimator.
    if(inherits(fit,"etr_joint_bspline_mixed")){
      fit<-list(time=fit$time,time_unit=fit$time_unit,
        dimension_name=fit$dimension_name,
        coefficient_names=fit$coefficient_names,
        coefficient_functions=fit$fixed_coefficient_functions,
        coefficient_standard_errors=fit$fixed_standard_errors)
    }
    artist<-etr_plot_functional_mixed_effects_coefficient(fit,
      coefficient=coefficient,strict_source_record=TRUE)
  }else if(plot=="generalized_functional_coefficient"){
    .etr_assert(inherits(result,"etr_generalized_functional_workflow"),
      "generalized_functional_coefficient requires a GeneralizedFunctionalWorkflowResult-compatible native workflow")
    coefficient<-.etr_workflow_required_coefficient(coefficient)
    .etr_assert(is.character(coefficient),
      "generalized functional coefficient plots require an explicit coefficient name")
    artist<-etr_plot_generalized_function_on_scalar_coefficients(
      result$fit,coefficient=coefficient,strict_source_record=TRUE)
  }else{
    .etr_assert(inherits(result,"etr_recurrence_workflow"),
      "recurrence requires a RecurrenceWorkflowResult-compatible native workflow")
    .etr_assert(inherits(result$recurrence,"etr_recurrence"),
      "recurrence workflow must retain an actual native recurrence result")
    z<-result$recurrence$matrix
    .etr_assert(is.matrix(z)&&!is.null(z)&&
      (is.null(max_points)||length(z)<=max_points),
      "recurrence matrix exceeds max_points; source geometry cannot be silently truncated")
    etr_plot_recurrence(result$recurrence)
    artist<-list(matrix=z,nrow=nrow(z),ncol=ncol(z),
      observed_points=length(z),max_points=max_points)
  }
  invisible(.etr_workflow_source_record(plot,artist))
}

#' Source-scientific native workflow image export
#' @param strict_source_record Opt-in seven-route source-scientific R figure
#'   dispatch with destination overwrite, not Matplotlib byte identity.
#' @inheritParams etr_save_workflow_figure
#' @export
etr_save_workflow_figure <- function(result,path,plot,dpi=150L,
    close=TRUE,...,strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(!isTRUE(strict_source_record))
    return(.etr_workflow_legacy_save(result,path,plot,dpi,close,...))
  .etr_assert(is.character(path)&&length(path)==1L&&!is.na(path)&&
    nzchar(trimws(path)),"path must be a nonempty single file path")
  .etr_assert(typeof(dpi)=="integer"&&length(dpi)==1L&&
    !is.na(dpi)&&dpi>=1L&&dpi<=1200L,
    "dpi must be an integer in 1..1200 for a native graphics device")
  .etr_assert(identical(close,TRUE),
    "native R file devices must close to flush figures; close=FALSE is not a supported Matplotlib equivalent")
  ext<-tolower(tools::file_ext(path))
  .etr_assert(ext%in%c("png","svg","pdf"),
    "workflow figure path must end in .png, .svg, or .pdf")
  folder<-dirname(path)
  if(!dir.exists(folder))
    dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  .etr_assert(dir.exists(folder),"cannot create output directory")
  opened<-FALSE
  completed<-FALSE
  existed<-file.exists(path)
  on.exit({
    if(opened)grDevices::dev.off()
    if(!completed&&!existed&&file.exists(path))unlink(path)
  },add=TRUE)
  if(ext=="png")
    grDevices::png(path,width=7,height=5,units="in",res=dpi)
  else if(ext=="svg")grDevices::svg(path,width=7,height=5)
  else grDevices::pdf(path,width=7,height=5)
  opened<-TRUE
  etr_plot_workflow_result(result,plot=plot,...,
    strict_source_record=TRUE)
  grDevices::dev.off()
  opened<-FALSE
  .etr_assert(file.exists(path)&&
    is.finite(file.info(path)$size)&&file.info(path)$size>0,
    "native workflow figure was not written")
  completed<-TRUE
  invisible(normalizePath(path,winslash="/",mustWork=TRUE))
}
