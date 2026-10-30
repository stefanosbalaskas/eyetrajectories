# Source-aligned, strictly numerical FPCA inference-graphics adapters.
# Python plotting.py, eyetrajectoriespy==1.2.0 frozen source:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native base-R plots expose geometry; Matplotlib Axes equivalence is OPEN.

.etr_fpca_visual_prob <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x>0&&x<1,paste(name,"must be a probability in (0,1)"))
  as.numeric(x)
}
.etr_fpca_visual_bounded <- function(x,n,name) {
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&
    length(x)==n&&all(is.finite(x))&&all(x>=0)&all(x<=1),
    paste(name,"must be a finite [0,1] vector of correct length"))
  as.numeric(x)
}
.etr_fpca_visual_count <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x>=1&&x==floor(x)&&x<=.Machine$integer.max,
    paste(name,"must be a positive integer"))
  as.integer(x)
}

#' Visualize matched-bootstrap pointwise FPCA component envelopes
#' @param result A fitted native result and independently computed envelopes.
#' @param component Zero-based retained component index.
#' @param dimension Exact functional coordinate name; defaults to first.
#' @return Invisibly a source-ordered observed-grid geometry frame.
#' @export
etr_plot_fpca_component_envelope <- function(result,component=0L,
    dimension=NULL) {
  .etr_scientific_frame_fields(result,c("reference","lower","median",
    "upper","level"),"component envelope")
  reference<-result$reference
  .etr_scientific_frame_fields(reference,
    c("time","dimension_names","components","time_unit"),
    "FPCA reference")
  time<-.etr_scientific_frame_time(reference$time)
  dims<-.etr_scientific_frame_ids(reference$dimension_names,
    "dimension_names")
  components<-reference$components
  .etr_assert(is.array(components)&&is.numeric(components)&&
    length(dim(components))==3L&&dim(components)[1L]>=1L&&
    identical(dim(components)[-1L],c(length(time),length(dims)))&&
    all(is.finite(components)),
    "reference components must have finite component-by-time-by-dimension values")
  for(name in c("lower","median","upper")){
    obj<-result[[name]]
    .etr_assert(is.array(obj)&&is.numeric(obj)&&
      identical(dim(obj),dim(components))&&all(is.finite(obj)),
      paste(name,"must match reference components dimensions"))
  }
  .etr_assert(all(result$lower<=result$median)&
    all(result$median<=result$upper),
    "component envelope lower/median/upper must be correctly ordered")
  .etr_assert(is.numeric(component)&&length(component)==1L&&
    is.finite(component)&&component==floor(component)&&
    component>=0&&component<dim(components)[1L],
    "component is outside fitted zero-based range")
  if(is.null(dimension))dimension<-dims[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%dims,
    "Unknown dimension")
  confidence<-.etr_fpca_visual_prob(result$level,"level")
  i<-as.integer(component)+1L;d<-match(dimension,dims)
  lower<-as.numeric(result$lower[i,,d])
  median<-as.numeric(result$median[i,,d])
  upper<-as.numeric(result$upper[i,,d])
  estimate<-as.numeric(components[i,,d])
  unit<-.etr_source_text_word(reference$time_unit,"time_unit")
  ylim<-range(c(lower,median,upper,estimate))
  if(ylim[1L]==ylim[2L])
    ylim<-ylim+c(-.05,.05)*max(1,abs(ylim[1L]))
  graphics::plot(time,estimate,type="n",ylim=ylim,
    xlab=paste0("Time (",unit,")"),
    ylab=paste0("FPC loading: ",dimension),
    main=paste0("FPC",i," matched-bootstrap envelope"))
  graphics::polygon(c(time,rev(time)),c(lower,rev(upper)),
    border=NA,col=grDevices::adjustcolor("grey60",alpha.f=.2))
  graphics::lines(time,median,lty=2L,lwd=2L)
  graphics::lines(time,estimate,lwd=2L)
  graphics::legend("topright",legend=c(
    paste0(round(100*confidence),"% pointwise envelope"),
    "bootstrap median","reference FPC"),lty=c(1L,2L,1L),
    bty="n",cex=.75)
  invisible(data.frame(time=time,lower=lower,median=median,
    upper=upper,reference=estimate))
}

# Sparse PACE diagnostics already have an authoritative native implementation
# in native-fpcr-inference-plots.R. Do not redefine it here.

#' Plot fixed-family FPCR wild-bootstrap tail probabilities
#' @param result Precalibrated familywise bootstrap diagnostic result.
#' @param max_targets Positive maximum number of fixed targets to display.
#' @param show_targetwise Whether to show unadjusted targetwise p-values.
#' @return Invisibly the source-ordered displayed numerical p-value frame.
#' @export
etr_plot_fpca_wild_bootstrap_family_test <- function(result,
    max_targets=30L,show_targetwise=TRUE) {
  .etr_scientific_frame_fields(result,
    c("projection_result","adjusted_p_values",
      "targetwise_p_values","significance_level"),"family test")
  .etr_scientific_frame_fields(result$projection_result,
    c("target_curve_ids"),"projection result")
  ids<-.etr_scientific_frame_ids(
    result$projection_result$target_curve_ids,"target_curve_ids")
  n<-length(ids)
  adjusted<-.etr_fpca_visual_bounded(
    result$adjusted_p_values,n,"adjusted_p_values")
  targetwise<-.etr_fpca_visual_bounded(
    result$targetwise_p_values,n,"targetwise_p_values")
  alpha<-.etr_fpca_visual_prob(result$significance_level,
    "significance_level")
  top<-.etr_fpca_visual_count(max_targets,"max_targets")
  .etr_assert(is.logical(show_targetwise)&&
    length(show_targetwise)==1L&&!is.na(show_targetwise),
    "show_targetwise must be boolean")
  count<-min(n,top)
  idx<-seq_len(count)
  x<-idx-1L
  graphics::plot(x,adjusted[idx],type="n",
    ylim=c(-.02,1.02),xaxt="n",
    xlab="Fixed target trajectory",
    ylab="Bootstrap tail probability",
    main="Fixed-family heteroscedastic Gaussian FPCR tests")
  graphics::points(x,adjusted[idx],pch=1L)
  if(show_targetwise)
    graphics::points(x,targetwise[idx],pch=4L)
  graphics::abline(h=alpha,lty=2L)
  graphics::axis(1L,at=x,labels=ids[idx],las=2L,cex.axis=.8)
  graphics::legend("topright",
    legend=c("single-step maxT adjusted",
      if(show_targetwise)"target-wise",
      paste0("alpha=",format(alpha,trim=TRUE))),
    pch=c(1L,if(show_targetwise)4L,NA_integer_),
    lty=c(NA_integer_,if(show_targetwise)NA_integer_,2L),
    bty="n",cex=.75)
  invisible(data.frame(target_index=x,target_curve_id=ids[idx],
    adjusted_p_value=adjusted[idx],
    targetwise_p_value=targetwise[idx],
    significance_level=rep(alpha,count),stringsAsFactors=FALSE))
}
