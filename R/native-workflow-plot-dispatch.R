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
#' @export
etr_plot_workflow_result<-function(result,plot,component=NULL,dimension=NULL,
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
#' @export
etr_save_workflow_figure<-function(result,path,plot,dpi=150L,
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
