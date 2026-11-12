# Four mixed-effects source scientific plot artists from frozen Python 1.2.
# Pinned commit c1cd95ad718327550f7e55393ff38582872f7a94;
# sources functional_mixed_effects_diagnostics.py and
# functional_mixed_effects_covariance_sensitivity.py.
#
# Native drawing uses base R. The returned scientific record only
# preserves Matplotlib-source geometry, never runtime Axes identity,
# Python exception types, or optimizer equivalence.

.etr_mixed_artist_check<-function(strict,source,kind){
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(!isTRUE(strict))return(invisible(TRUE))
  if(identical(kind,"residual")){
    .etr_assert(inherits(source,"etr_functional_mixed_residual_diagnostics")&&
      identical(source$provenance$residual_model,
        "native_joint_nlme_likelihood_not_python_optimizer"),
      "strict residual source plots require genuine native joint-likelihood diagnostics")
  }else if(identical(kind,"sensitivity")){
    .etr_assert(inherits(source,"etr_mixed_w3_sensitivity_source_record")&&
      length(source$fits)>0L&&
      all(vapply(source$fits,function(z)
        inherits(z,"etr_joint_bspline_mixed")&&
        identical(z$backend,"nlme::lme"),logical(1L))),
      "strict source sensitivity requires fitted native Gaussian likelihood models")
  }else if(identical(kind,"variance")){
    .etr_assert(inherits(source,"etr_joint_bspline_mixed")||
      inherits(source,"etr_mixed_w3_sensitivity_source_record"),
      "strict source variance plotting requires a real fitted Gaussian model or sensitivity")
  }else stop("invalid mixed scientific artist kind",call.=FALSE)
  invisible(TRUE)
}

.etr_mixed_artist_record<-function(source_export,axis,options=list()){
  .etr_assert(is.list(axis)&&
    is.character(axis$title)&&length(axis$title)==1L&&
    is.character(axis$xlabel)&&length(axis$xlabel)==1L&&
    is.character(axis$ylabel)&&length(axis$ylabel)==1L&&
    is.list(axis$lines),
    "source scientific Matplotlib artist must declare plot labels and lines")
  structure(list(
    source_export=source_export,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),
    axes=list(axis),
    source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_mixed_diagnostic_artist_source_record","list"))
}

.etr_mixed_artist_sensitivity<-function(coefficient,width,curves,labels,unit){
  .etr_assert(is.list(curves)&&length(curves)>0L&&
    identical(length(labels),length(curves)),
    "sensitivity artist requires nonempty ordered scientific curves")
  nm<-as.character(coefficient)
  lines<-lapply(seq_along(curves),function(i)
    list(label=labels[[i]],marker="none",
      xdata=as.numeric(curves[[i]]$time),
      ydata=as.numeric(curves[[i]]$value)))
  baseline<-if(isTRUE(width))1 else 0
  lines[[length(lines)+1L]]<-list(
    label="_child_baseline",linestyle="-",linewidth=1,
    xdata=c(0,1),ydata=rep(baseline,2L),
    is_horizontal_reference=TRUE)
  axis<-list(
    title=if(width)
      paste0("Covariance sensitivity of band width: ",nm) else
      paste0("Covariance sensitivity: ",nm),
    xlabel=paste0("Time (",unit,")"),
    ylabel=if(width)"Band-width ratio to reference" else
      "Coefficient difference from reference",
    lines=lines,legend=TRUE,
    legend_labels=labels)
  .etr_mixed_artist_record(
    if(width)"plot_covariance_sensitivity_band_widths" else
      "plot_covariance_sensitivity_coefficients",
    axis,options=list(coefficient=nm,
      numerical_scientific_source="native_nlme_joint_likelihood"))
}

.etr_mixed_artist_residual<-function(df,metric,level,curve_id,
    participant_id,scale,unit){
  y<-as.numeric(df[[metric]])
  x<-as.numeric(df$lag_time_mean)
  nonuniform<-any(df$lag_time_min!=df$lag_time_max)
  prefix<-if(scale=="whitened")"Whitened residual" else "Residual"
  lines<-list(list(label="_child0",marker="o",
    xdata=x,ydata=y))
  if(identical(metric,"autocorrelation"))
    lines[[2L]]<-list(label="_child_reference",
      linestyle="-",linewidth=1,
      xdata=c(0,1),ydata=c(0,0),
      is_horizontal_reference=TRUE)
  axis<-list(
    title=if(nonuniform)
      "Index-lag diagnostic (x = mean physical lag; inspect min/max or pair frame)"
      else "",
    xlabel=paste0("Physical lag (",unit,")"),
    ylabel=paste0(prefix," ",metric),
    lines=lines,legend=FALSE,
    nonuniform_physical_lag=nonuniform,
    lag_time_min=as.numeric(df$lag_time_min),
    lag_time_max=as.numeric(df$lag_time_max))
  .etr_mixed_artist_record(
    if(identical(metric,"autocorrelation"))
      "plot_functional_mixed_effects_residual_acf" else
      "plot_functional_mixed_effects_residual_variogram",
    axis,options=list(level=level,curve_id=curve_id,
      participant_id=participant_id,residual_scale=scale))
}

.etr_mixed_artist_variance<-function(result,model=NULL){
  .etr_mixed_artist_check(TRUE,result,"variance")
  if(inherits(result,"etr_joint_bspline_mixed")){
    .etr_assert(is.null(model),
      "model is only accepted for a covariance sensitivity result")
    .etr_assert(identical(result$backend,"nlme::lme"),
      "source variance requires real fitted Gaussian likelihood model")
    frame<-etr_functional_mixed_effects_variance_decomposition(result)
    unit<-result$time_unit
    title_label<-"model"
  }else{
    .etr_mixed_artist_check(TRUE,result,"sensitivity")
    .etr_assert(is.character(model)&&length(model)==1L&&
      !is.na(model)&&nzchar(model),
      "model must be declared when plotting a sensitivity result")
    if(!model%in%names(result$fits)){
      if(model%in%names(result$failures))
        stop(paste("model",model,"failed and has no variance decomposition"),
          call.=FALSE)
      stop(paste("Unknown model",model),call.=FALSE)
    }
    frame<-result$variance_decomposition
    .etr_assert(is.data.frame(frame)&&"model"%in%names(frame),
      "source sensitivity variance decomposition requires model labels")
    frame<-frame[frame$model==model,,drop=FALSE]
    unit<-result$fits[[model]]$time_unit
    title_label<-model
  }
  .etr_assert(is.data.frame(frame)&&nrow(frame)>0L&&
    all(c("time","component","value")%in%names(frame))&&
    all(is.finite(frame$time))&&all(is.finite(frame$value))&&
    all(nzchar(as.character(frame$component))),
    "source variance frame must contain finite original component functions")
  ids<-unique(as.character(frame$component))
  curves<-lapply(ids,function(id)
    frame[as.character(frame$component)==id,,drop=FALSE])
  yr<-range(c(0,frame$value))
  if(diff(yr)==0)yr<-yr+c(-.5,.5)
  graphics::plot(NA_real_,NA_real_,type="n",
    xlim=range(frame$time),ylim=yr,
    xlab=paste0("Time (",unit,")"),
    ylab="Variance / cross-covariance",
    main=paste0("Functional variance decomposition: ",title_label))
  for(i in seq_along(curves))
    graphics::lines(curves[[i]]$time,curves[[i]]$value)
  graphics::abline(h=0)
  graphics::legend("topright",legend=ids,lty=1,bty="n")
  lines<-lapply(seq_along(ids),function(i)
    list(label=ids[[i]],
      xdata=as.numeric(curves[[i]]$time),
      ydata=as.numeric(curves[[i]]$value)))
  lines[[length(lines)+1L]]<-list(
    label="_child_baseline",xdata=c(0,1),ydata=c(0,0),
    linewidth=1,is_horizontal_reference=TRUE)
  axis<-list(
    title=paste0("Functional variance decomposition: ",title_label),
    xlabel=paste0("Time (",unit,")"),
    ylabel="Variance / cross-covariance",
    lines=lines,legend=TRUE,legend_labels=ids)
  .etr_mixed_artist_record(
    "plot_functional_variance_decomposition",axis,
    options=list(model=model,
      numerical_scientific_source="native_nlme_joint_likelihood"))
}
