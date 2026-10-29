# Stage 28: byte-preserving published Python 1.2 mathematical-contract
# metadata and three native nonlinear visualizations.
# These are source-aligned scientific data contracts, not Python classes
# or Matplotlib Axes, and no Python interpreter is initialized.

.etr_read_math_contract_source_frame <- function() {
  file <- system.file("extdata",
    "native_mathematical_contract_frame_py120.csv",
    package="eyetrajectories")
  .etr_assert(nzchar(file), "pinned mathematical contracts source is missing")
  t <- utils::read.csv(file,stringsAsFactors=FALSE,check.names=FALSE,
    fileEncoding="UTF-8",na.strings=character(),comment.char="")
  expected<-c("contract_key","title","function","latex","site_anchor","scope")
  .etr_assert(identical(names(t),expected)&&nrow(t)==88L&&
    all(vapply(t,function(x)is.character(x)&&
      all(!is.na(x)&nzchar(x)),logical(1L)))&&
    length(unique(t$contract_key))==41L&&
    !anyDuplicated(t[["function"]]),
    "published Python 1.2 mathematical contract frame has changed")
  t
}

#' Return all pinned published Python 1.2 mathematical contracts
#' @return Ordered list of 41 named native metadata structures.
#' @export
etr_list_mathematical_contracts <- function() {
  t<-.etr_read_math_contract_source_frame()
  keys<-unique(t$contract_key)
  ans<-lapply(keys,function(key) {
    x<-t[t$contract_key==key,,drop=FALSE]
    .etr_assert(length(unique(x$title))==1L&&
      length(unique(x$site_anchor))==1L&&
      length(unique(x$scope))==1L&&
      length(unique(x$latex))==1L,
      "published mathematical contract contains conflicting metadata")
    structure(list(key=key,title=x$title[1L],
      public_api=as.character(x[["function"]]),
      equations=strsplit(x$latex[1L],"\n\n",fixed=TRUE)[[1L]],
      site_anchor=x$site_anchor[1L],scope=x$scope[1L]),
      class="etr_mathematical_contract")
  })
  names(ans)<-keys
  ans
}

#' Find one frozen mathematical source contract by key or public API name
#' @param name Exact source contract key or public API function name.
#' @return Native semantic mathematical metadata structure.
#' @export
etr_get_mathematical_contract <- function(name) {
  .etr_assert(is.character(name)&&length(name)==1L&&
    !is.na(name),"name must be a single string")
  contracts<-etr_list_mathematical_contracts()
  if(name%in%names(contracts))return(contracts[[name]])
  found<-which(vapply(contracts,function(x)name%in%x$public_api,
    logical(1L)))
  .etr_assert(length(found)==1L,
    paste("No mathematical contract is registered for",name))
  contracts[[found]]
}

#' Full mathematical registry frame in published Python 1.2 order
#' @return Auditable 88-row six-column native data.frame.
#' @export
etr_mathematical_contract_frame <- function() .etr_read_math_contract_source_frame()

.etr_select_nonlinear_sensitivity_slice <- function(result,kind,parameter,response,
    allowed,filters) {
  .etr_assert(inherits(result,kind)&&is.data.frame(result$table)&&
    nrow(result$table)>=1L,"result must be a native sensitivity analysis")
  t<-result$table
  .etr_assert(is.character(parameter)&&length(parameter)==1L&&
    !is.na(parameter)&&parameter%in%names(t),
    "parameter must identify a source sensitivity column")
  .etr_assert(is.character(response)&&length(response)==1L&&
    !is.na(response)&&response%in%allowed&&response%in%names(t),
    "response is not a supported source sensitivity measure")
  if(!is.null(filters)){
    .etr_assert(is.list(filters)&&!is.null(names(filters))&&
      all(nzchar(names(filters)))&&
      !anyDuplicated(names(filters))&&
      all(names(filters)%in%names(t)),
      "filters must name existing distinct sensitivity columns")
    for(f in names(filters)){
      .etr_assert(length(filters[[f]])==1L&&!is.na(filters[[f]]),
        "filter values must be single nonmissing values")
      t<-t[!is.na(t[[f]])&t[[f]]==filters[[f]],,drop=FALSE]
    }
  }
  .etr_assert(nrow(t)>0L,"filters leave no sensitivity specifications")
  .etr_assert(!anyDuplicated(t[[parameter]]),
    "slice contains multiple rows per parameter value; add filters")
  .etr_assert(is.numeric(t[[parameter]])&&is.numeric(t[[response]])&&
    all(is.finite(t[[parameter]]))&&all(is.finite(t[[response]])),
    "sensitivity plot requires finite numeric parameter and response")
  t[order(t[[parameter]]),c(parameter,response),drop=FALSE]
}

#' Plot native Kantz Lyapunov sensitivity for an unambiguous grid slice
#' @param result Native Kantz sensitivity result.
#' @param parameter One independently varied specification parameter.
#' @param response Source response name.
#' @param filters Optional list of fixed parameter values.
#' @param ... Base R graphics options.
#' @return Invisible exact source pairwise coordinates.
#' @export
etr_plot_kantz_sensitivity <- function(result,parameter,
    response="exponent",filters=NULL,...) {
  allowed<-c("exponent","r_squared","standard_error",
    "n_fit_points","minimum_reference_count_in_fit",
    "minimum_pair_count_in_fit","initial_supported_reference_fraction",
    "total_zero_mean_neighborhood_count_in_fit")
  t<-.etr_select_nonlinear_sensitivity_slice(result,"etr_kantz_parameter_sensitivity",
    parameter,response,allowed,filters)
  graphics::plot(t[[parameter]],t[[response]],type="o",pch=1,
    xlab=parameter,ylab=if(response=="exponent")
      sprintf("exponent (%s)",result$exponent_unit) else response,
    main=sprintf("Kantz sensitivity: %s",result$curve_id),...)
  if(response=="exponent")graphics::abline(h=0,lty=3)
  invisible(t)
}

#' Plot native Rosenstein/LLE sensitivity for unambiguous source grid slice
#' @param result Native Lyapunov sensitivity analysis.
#' @param parameter One independently varied specification parameter.
#' @param response Source response name.
#' @param filters Optional list of fixed parameter values.
#' @param ... Base R graphics options.
#' @return Invisible exact plotted numeric coordinates.
#' @export
etr_plot_lyapunov_sensitivity <- function(result,parameter,
    response="exponent",filters=NULL,...) {
  allowed<-c("exponent","r_squared","standard_error",
    "n_fit_points","minimum_pair_count_in_fit",
    "total_zero_distance_count_in_fit")
  t<-.etr_select_nonlinear_sensitivity_slice(result,"etr_lyapunov_parameter_sensitivity",
    parameter,response,allowed,filters)
  graphics::plot(t[[parameter]],t[[response]],type="o",pch=1,
    xlab=parameter,ylab=if(response=="exponent")
      sprintf("exponent (%s)",result$exponent_unit) else response,
    main=sprintf("Rosenstein sensitivity: %s",result$curve_id),...)
  if(response=="exponent")graphics::abline(h=0,lty=3)
  invisible(t)
}

#' Plot declared native windowed RQA multiscale profiles without averaging
#' @param result Native Stage 26 windowed RQA sensitivity result.
#' @param curve Zero-based source curve index or exact curve_id.
#' @param metric Source-defined functional RQA metric.
#' @param ... Base R graphics options.
#' @return Invisible list of per-specification time and response profiles.
#' @export
etr_plot_windowed_rqa_sensitivity <- function(result,curve,metric,...) {
  .etr_assert(inherits(result,"etr_windowed_rqa_sensitivity")&&
    is.list(result$analyses)&&length(result$analyses)>=1L&&
    is.character(metric)&&length(metric)==1L&&!is.na(metric)&&
    metric%in%result$metrics,
    "result and metric must identify a native RQA sensitivity profile")
  ids<-result$analyses[[1L]]$trajectories$curve_ids
  if(is.character(curve)&&length(curve)==1L&&!is.na(curve)){
    .etr_assert(curve%in%ids,"unknown curve_id")
    i<-match(curve,ids)
  } else {
    .etr_assert(is.numeric(curve)&&length(curve)==1L&&
      !is.logical(curve)&&is.finite(curve)&&
      curve==as.integer(curve)&&curve>=0L&&curve<length(ids),
      "curve must be a valid zero-based integer or curve_id")
    i<-as.integer(curve)+1L
  }
  profiles<-lapply(seq_along(result$analyses),function(k){
    x<-result$analyses[[k]]
    tr<-x$trajectories
    .etr_assert(identical(tr$curve_ids,ids)&&
      metric%in%tr$dimension_names,
      "RQA source analyses must share curve IDs and metric dimensions")
    j<-match(metric,tr$dimension_names)
    v<-as.numeric(tr$values[i,,j])
    .etr_assert(length(v)==length(tr$time)&&any(is.finite(v)),
      "windowed RQA sensitivity profile has no finite values")
    data.frame(specification_id=result$provenance$specification_ids[k],
      time=tr$time,value=v,window=x$window_samples,
      step=x$step_samples)
  })
  xy<-do.call(rbind,profiles)
  xy_good<-xy[is.finite(xy$value),,drop=FALSE]
  .etr_assert(nrow(xy_good)>=1L,
    "windowed RQA sensitivity profiles must contain finite values")
  graphics::plot(NA_real_,NA_real_,
    xlim=range(xy$time),ylim=range(xy_good$value),
    xlab=sprintf("Window center (%s)",
      result$analyses[[1L]]$time_unit),
    ylab=metric,main=sprintf("Window/step sensitivity: %s / %s",
      ids[i],metric),...)
  for(k in seq_along(profiles)){
    t<-profiles[[k]]
    graphics::lines(t$time,t$value,type="o",pch=1,col=k)
  }
  graphics::legend("topright",bty="n",
    legend=vapply(profiles,function(z)
      sprintf("%s: W=%s, S=%s",z$specification_id[1L],
        z$window[1L],z$step[1L]),character(1L)),
    col=seq_along(profiles),lty=1,pch=1)
  invisible(profiles)
}
