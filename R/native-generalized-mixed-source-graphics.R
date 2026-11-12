# Frozen Python 1.2.0 generalized FoSR and functional mixed-effects
# scientific source graphics. These are native base-R outputs, NOT
# Matplotlib axes, and preserve data/uncertainty only on declared grids.
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_source_plot_vector <- function(x,n,name,allow_na=FALSE) {
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)==n&&
    !any(is.infinite(x))&&(!anyNA(x)||allow_na),
    paste(name,"must have declared numeric grid length"))
  as.numeric(x)
}
.etr_source_plot_rows <- function(x,n,k,name) {
  .etr_assert(is.matrix(x)&&is.numeric(x)&&
    identical(dim(x),c(n,k))&&all(is.finite(x)),
    paste(name,"must be finite source-rows by observed-time matrix"))
  invisible(TRUE)
}
.etr_source_plot_grid <- function(x) {
  .etr_scientific_frame_time(x)
}
.etr_source_plot_ymax <- function(values) {
  span<-range(values[is.finite(values)])
  .etr_assert(length(span)==2L&&all(is.finite(span)),
    "plot requires finite scientific values")
  if(span[1L]==span[2L])span<-span+c(-.05,.05)*max(1,abs(span[1L]))
  span
}
.etr_source_plot_band <- function(time,estimate,lower=NULL,upper=NULL,
  xlab,ylab,main,reference=NULL,labels=NULL) {
  .etr_assert(length(estimate)==length(time)&&all(is.finite(estimate)),
    "estimate must be finite on observed grid")
  if(!is.null(lower)||!is.null(upper)) {
    .etr_source_plot_vector(lower,length(time),"lower")
    .etr_source_plot_vector(upper,length(time),"upper")
    .etr_assert(all(lower<=upper),"band lower must not exceed upper")
  }
  ylim<-.etr_source_plot_ymax(c(estimate,lower,upper,reference))
  graphics::plot(time,estimate,type="l",lwd=2L,
    xlab=xlab,ylab=ylab,main=main,ylim=ylim)
  if(!is.null(lower)){
    graphics::polygon(c(time,rev(time)),c(lower,rev(upper)),
      col=grDevices::adjustcolor("grey65",alpha.f=.25),border=NA)
    graphics::lines(time,estimate,lwd=2L)
  }
  if(!is.null(reference))graphics::abline(h=reference,lty=3L)
  if(!is.null(labels))graphics::legend("topright",legend=labels,
    lty=1L,bty="n")
  invisible(data.frame(time=time,estimate=estimate,
    lower=if(is.null(lower))rep(NA_real_,length(time))else lower,
    upper=if(is.null(upper))rep(NA_real_,length(time))else upper))
}
.etr_source_plot_fit <- function(x) {
  .etr_scientific_frame_fields(x,c("time","time_unit","family",
    "link","coefficient_names","coefficient_functions"),"fit")
  time<-.etr_source_plot_grid(x$time)
  names<-.etr_scientific_frame_ids(x$coefficient_names,
    "coefficient_names")
  .etr_source_text_word(x$time_unit,"time_unit")
  .etr_source_text_word(x$link,"link")
  .etr_source_text_word(x$family,"family")
  .etr_source_plot_rows(x$coefficient_functions,length(names),
    length(time),"coefficient_functions")
  list(time=time,names=names)
}

#' Plot fixed-profile generalized FoSR marginal mean predictions
#' @param result Prediction fit or prediction-band record.
#' @return Invisible source-aligned per-profile numerical drawing geometry.
#' @export
etr_plot_generalized_function_on_scalar_predictions <- function(result,
    strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  .etr_assert(is.list(result) && !is.data.frame(result),
    "result must be a native prediction or prediction-band record")
  # A native band record nests the prediction in result$prediction.
  if("prediction"%in%names(result)){
    band<-result
    p<-result$prediction
  } else {band<-NULL;p<-result}
  .etr_scientific_frame_fields(p,c("reference","profile_ids",
    "mean_functions","extrapolation_flags","prediction_scale"),
    "prediction")
  .etr_scientific_frame_fields(p$reference,
    c("time","time_unit","family"),"prediction reference")
  time<-.etr_source_plot_grid(p$reference$time)
  ids<-.etr_scientific_frame_ids(p$profile_ids,"profile_ids")
  n<-length(ids)
  .etr_source_plot_rows(p$mean_functions,n,length(time),
    "mean_functions")
  .etr_assert(is.logical(p$extrapolation_flags)&&
    length(p$extrapolation_flags)==n&&!anyNA(p$extrapolation_flags),
    "extrapolation_flags must retain one flag per profile")
  scale<-.etr_source_text_word(p$prediction_scale,"prediction_scale")
  family<-.etr_source_text_word(p$reference$family,"family")
  unit<-.etr_source_text_word(p$reference$time_unit,"time_unit")
  if(!is.null(band)){
    .etr_scientific_frame_fields(band,
      c("mean_lower","mean_upper"),"prediction band")
    .etr_source_plot_rows(band$mean_lower,n,length(time),"mean_lower")
    .etr_source_plot_rows(band$mean_upper,n,length(time),"mean_upper")
    .etr_assert(all(band$mean_lower<=band$mean_upper),
      "prediction mean_lower must not exceed mean_upper")
  }
  labels<-ifelse(p$extrapolation_flags,
    paste0(ids," (extrapolation)"),ids)
  ylabel<-if(family=="binomial")"Marginal probability" else
    if(scale=="rate")"Marginal exposure-adjusted rate" else
      "Marginal expected count"
  ylim<-.etr_source_plot_ymax(c(p$mean_functions,
    if(!is.null(band))band$mean_lower,
    if(!is.null(band))band$mean_upper))
  graphics::plot(NA_real_,NA_real_,type="n",
    xlim=range(time),ylim=ylim,xlab=paste0("Time (",unit,")"),
    ylab=ylabel,main="Generalized FoSR fixed-profile marginal predictions")
  colors<-grDevices::hcl.colors(n,"Dark 3")
  rows<-lapply(seq_len(n),function(i){
    if(!is.null(band)) {
      graphics::polygon(c(time,rev(time)),
        c(band$mean_lower[i,],rev(band$mean_upper[i,])),
        col=grDevices::adjustcolor(colors[i],alpha.f=.2),border=NA)
    }
    graphics::lines(time,p$mean_functions[i,],col=colors[i],lwd=2L)
    data.frame(profile_id=ids[i],time=time,
      estimate=as.numeric(p$mean_functions[i,]),
      lower=if(is.null(band))rep(NA_real_,length(time)) else
        as.numeric(band$mean_lower[i,]),
      upper=if(is.null(band))rep(NA_real_,length(time))else
        as.numeric(band$mean_upper[i,]),
      extrapolation=p$extrapolation_flags[i],
      stringsAsFactors=FALSE)
  })
  graphics::legend("topright",legend=labels,lty=1L,col=colors,
    bty="n",cex=.75)
  out<-do.call(rbind,rows)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_gfos_predictions_source_artist(result,out)))
  invisible(out)
}

#' Plot response-scale generalized FoSR profile contrast and band
#' @param result One predeclared difference/ratio and its simultaneous band.
#' @return Invisible estimate and band geometry.
#' @export
etr_plot_generalized_function_on_scalar_mean_difference <- function(result,
    strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  .etr_scientific_frame_fields(result,c("prediction_bootstrap",
    "estimate","lower","upper","confidence_level",
    "contrast_scale","profile_a","profile_b"),"contrast")
  p<-result$prediction_bootstrap
  .etr_scientific_frame_fields(p,c("prediction"),"prediction_bootstrap")
  .etr_scientific_frame_fields(p$prediction,c("reference"),"prediction")
  .etr_scientific_frame_fields(p$prediction$reference,
    c("time","time_unit"),"reference")
  grid<-.etr_source_plot_grid(p$prediction$reference$time)
  estimate<-.etr_source_plot_vector(result$estimate,length(grid),"estimate")
  lower<-.etr_source_plot_vector(result$lower,length(grid),"lower")
  upper<-.etr_source_plot_vector(result$upper,length(grid),"upper")
  .etr_assert(all(lower<=upper),"contrast lower must not exceed upper")
  scale<-.etr_source_text_word(result$contrast_scale,"contrast_scale")
  labels<-c(probability_difference="Marginal probability difference",
    rate_difference="Marginal rate difference",
    rate_ratio="Marginal rate ratio",
    expected_count_difference="Marginal expected-count difference")
  .etr_assert(scale%in%names(labels),"unknown contrast_scale")
  level<-.etr_source_text_number(result$confidence_level,
    "confidence_level",min=0,max=1)
  .etr_assert(level>0&&level<1,"confidence_level must be in (0,1)")
  a<-.etr_source_text_word(result$profile_a,"profile_a")
  b<-.etr_source_text_word(result$profile_b,"profile_b")
  unit<-.etr_source_text_word(p$prediction$reference$time_unit,
    "time_unit")
  out<-.etr_source_plot_band(grid,estimate,lower,upper,
    paste0("Time (",unit,")"),labels[[scale]],
    paste0("Generalized FoSR ",gsub("_"," ",scale),": ",a," - ",b),
    reference=if(scale=="rate_ratio")1 else 0,
    labels=c("estimate",paste0(round(level*100),
      "% simultaneous band")))
  if(isTRUE(strict_source_record))
    return(invisible(.etr_gfos_mean_difference_source_artist(result,out)))
  invisible(out)
}

#' Plot a generalized FoSR coefficient on its declared link scale
#' @param result Source-aligned fitted result or coefficient band record.
#' @param coefficient Exact predeclared coefficient name.
#' @return Invisible source-aligned coefficient geometry.
#' @export
etr_plot_generalized_function_on_scalar_coefficients <- function(result,
    coefficient,strict_source_record=FALSE) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if("reference"%in%names(result)&&
    "lower"%in%names(result)&&"upper"%in%names(result)){
    fit<-result$reference
    band<-result
  } else {fit<-result;band<-NULL}
  v<-.etr_source_plot_fit(fit)
  name<-.etr_source_text_word(coefficient,"coefficient")
  .etr_assert(name%in%v$names,"Unknown coefficient")
  i<-match(name,v$names)
  low<-upper<-NULL
  if(!is.null(band)) {
    .etr_source_plot_rows(band$lower,length(v$names),
      length(v$time),"band.lower")
    .etr_source_plot_rows(band$upper,length(v$names),
      length(v$time),"band.upper")
    low<-as.numeric(band$lower[i,])
    upper<-as.numeric(band$upper[i,])
  }
  out<-.etr_source_plot_band(v$time,
    as.numeric(fit$coefficient_functions[i,]),low,upper,
    paste0("Time (",fit$time_unit,")"),
    paste0(name," coefficient (",fit$link," scale)"),
    paste0("Generalized function-on-scalar coefficient: ",name),
    reference=0,labels="estimate")
  if(isTRUE(strict_source_record))
    return(invisible(.etr_gfos_coefficients_source_artist(
      result,name,out)))
  invisible(out)
}

.etr_source_plot_sensitivity <- function(result,coefficient,width=FALSE,
    strict_source_record=FALSE) {
  .etr_mixed_artist_check(strict_source_record,result,"sensitivity")
  fields<-c("specifications","reference_label","fits",
    if(width)"band_width_frame" else "coefficient_frame")
  .etr_scientific_frame_fields(result,fields,"covariance sensitivity")
  frame<-if(width)result$band_width_frame else result$coefficient_frame
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L,
    if(width)"result does not contain simultaneous-band sensitivity information"
    else "coefficient_frame must contain source estimates")
  value<-if(width)"band_width_ratio_to_reference" else
    "difference_from_reference"
  required<-c("coefficient","model","time",value)
  if(width&&isTRUE(strict_source_record))
    required<-c(required,"band_width","reference_band_width")
  .etr_assert(all(required%in%names(frame)),
    "sensitivity frame missing required source columns")
  if(width&&isTRUE(strict_source_record)) {
    .etr_assert(is.numeric(frame$band_width)&&
      is.numeric(frame$reference_band_width)&&
      is.numeric(frame[[value]])&&
      all(is.finite(frame$band_width))&&
      all(is.finite(frame$reference_band_width))&&
      all(frame$band_width>=0)&&
      all(frame$reference_band_width>=0),
      "strict source width plot requires finite nonnegative calibrated band widths")
    positive<-frame$reference_band_width>0
    .etr_assert(
      all(is.finite(frame[[value]][positive]))&&
      isTRUE(all.equal(as.numeric(frame[[value]][positive]),
        as.numeric(frame$band_width[positive]/
          frame$reference_band_width[positive]),
        tolerance=1e-12,check.attributes=FALSE))&&
      all(is.nan(frame[[value]][!positive])),
      "source band width ratios must equal paired widths; zero reference width must yield NaN")
  }
  nm<-.etr_source_text_word(coefficient,"coefficient")
  .etr_assert(any(frame$coefficient==nm),"Unknown coefficient")
  label<-.etr_source_text_word(result$reference_label,"reference_label")
  .etr_assert(is.list(result$fits)&&label%in%names(result$fits),
    "fits must include the named reference model")
  .etr_scientific_frame_fields(result$fits[[label]],
    c("time_unit"),"reference fit")
  unit<-.etr_source_text_word(result$fits[[label]]$time_unit,
    "time_unit")
  specs<-result$specifications
  .etr_assert(is.list(specs)&&length(specs)>=1L,
    "specifications must be source-ordered record list")
  spec_ids<-vapply(specs,function(s){
    .etr_scientific_frame_fields(s,c("name"),"specification")
    .etr_source_text_word(s$name,"specification name")
  },character(1L))
  .etr_assert(!anyDuplicated(spec_ids),
    "specification names must be unique")
  source_frame<-frame[frame$coefficient==nm,,drop=FALSE]
  curves<-lapply(spec_ids,function(id){
    x<-source_frame[source_frame$model==id,,drop=FALSE]
    if(nrow(x)==0L)return(NULL)
    .etr_assert(is.numeric(x$time)&&is.numeric(x[[value]])&&
      all(is.finite(x$time))&&
      (if(width) all(is.finite(x[[value]])|is.nan(x[[value]]))
       else all(is.finite(x[[value]])))&&
      !anyDuplicated(x$time),
      "sensitivity time/value must be finite without duplicate times")
    data.frame(model=id,time=x$time,value=x[[value]],
      stringsAsFactors=FALSE)
  })
  keep<-!vapply(curves,is.null,logical(1L))
  .etr_assert(any(keep),"no sensitivity curves for declared models")
  curves<-curves[keep]
  curves_flat<-do.call(rbind,curves)
  colors<-grDevices::hcl.colors(length(curves),"Dark 3")
  graphics::plot(NA_real_,NA_real_,type="n",
    xlim=range(curves_flat$time),
    ylim=.etr_source_plot_ymax(c(curves_flat$value,if(width)1 else 0)),
    xlab=paste0("Time (",unit,")"),
    ylab=if(width)"Band-width ratio to reference"
      else "Coefficient difference from reference",
    main=if(width)paste0("Covariance sensitivity of band width: ",nm)
      else paste0("Covariance sensitivity: ",nm))
  for(i in seq_along(curves))
    graphics::lines(curves[[i]]$time,curves[[i]]$value,
      col=colors[i],lwd=2L)
  graphics::abline(h=if(width)1 else 0,lty=3L)
  graphics::legend("topright",legend=spec_ids[keep],lty=1L,
    col=colors,bty="n")
  if(isTRUE(strict_source_record))
    return(invisible(.etr_mixed_artist_sensitivity(
      nm,width,curves,spec_ids[keep],unit)))
  invisible(curves_flat)
}

#' Plot difference of covariance-sensitivity coefficients from reference
#' @param result Explicit sensitivity record and source-ordered fit records.
#' @param coefficient One named fitted regression coefficient.
#' @param strict_source_record Return an R scientific artist geometry
#'   record of native Gaussian likelihood source lines, not Matplotlib Axes.
#' @return Invisible source coefficient sensitivity geometry.
#' @export
etr_plot_covariance_sensitivity_coefficients <- function(
    result,coefficient,strict_source_record=FALSE) {
  .etr_source_plot_sensitivity(result,coefficient,width=FALSE,
    strict_source_record=strict_source_record)
}

#' Plot covariance-sensitivity simultaneous band-width ratios
#' @inheritParams etr_plot_covariance_sensitivity_coefficients
#' @return Invisible source band-width-ratio geometry.
#' @export
etr_plot_covariance_sensitivity_band_widths <- function(
    result,coefficient,strict_source_record=FALSE) {
  # In strict mode only a source-shaped real joint Gaussian likelihood
  # sensitivity record is accepted. Its band_width_frame was derived from
  # audited, already calibrated participant-bootstrap bands.
  .etr_mixed_artist_check(strict_source_record,result,"sensitivity")
  if(isTRUE(strict_source_record)) {
    .etr_assert(isTRUE(result$provenance$
      source_paired_bootstrap_bands_validated),
      "strict source band widths require paired calibrated participant bootstrap provenance")
    .etr_assert(is.data.frame(result$band_width_frame)&&
      nrow(result$band_width_frame)>0L,
      "result does not contain simultaneous-band sensitivity information")
  }
  .etr_source_plot_sensitivity(result,coefficient,width=TRUE,
    strict_source_record=strict_source_record)
}

.etr_source_residual_frame <- function(result,level,curve_id,participant_id) {
  .etr_scientific_frame_fields(result,
    c("trial_diagnostics","participant_diagnostics",
      "overall_diagnostics","reference","residual_scale"),
    "residual diagnostics")
  .etr_assert(is.character(level)&&length(level)==1L&&
    !is.na(level)&&level%in%c("trial","participant","overall"),
    "level must be trial, participant or overall")
  if(level=="trial"){
    .etr_assert(is.null(participant_id),
      "participant_id not accepted for trial")
    .etr_assert(!is.null(curve_id),
      "curve_id required for trial-level plot")
    key<-.etr_source_text_word(curve_id,"curve_id")
    df<-result$trial_diagnostics
    .etr_assert(is.data.frame(df)&&"curve_id"%in%names(df),
      "trial_diagnostics requires curve_id")
    df<-df[as.character(df$curve_id)==key,,drop=FALSE]
    .etr_assert(nrow(df)>0L,"Unknown curve_id")
  } else if(level=="participant"){
    .etr_assert(is.null(curve_id),
      "curve_id not accepted for participant")
    .etr_assert(!is.null(participant_id),
      "participant_id required for participant-level plot")
    key<-.etr_source_text_word(participant_id,"participant_id")
    df<-result$participant_diagnostics
    .etr_assert(is.data.frame(df)&&"participant_id"%in%names(df),
      "participant_diagnostics requires participant_id")
    df<-df[as.character(df$participant_id)==key,,drop=FALSE]
    .etr_assert(nrow(df)>0L,"Unknown participant_id")
  } else {
    .etr_assert(is.null(curve_id)&&is.null(participant_id),
      "overall level does not accept curve or participant IDs")
    df<-result$overall_diagnostics
  }
  .etr_assert(is.data.frame(df)&&nrow(df)>=1L&&all(c(
    "lag_time_mean","lag_time_min","lag_time_max",
    "autocorrelation","semivariance")%in%names(df)),
    "residual frame must contain observed physical lags and metrics")
  for(n in c("lag_time_mean","lag_time_min","lag_time_max"))
    .etr_assert(is.numeric(df[[n]])&&all(is.finite(df[[n]])),
      "lag physical times must be finite")
  .etr_assert(all(df$lag_time_min<=df$lag_time_mean)&
    all(df$lag_time_mean<=df$lag_time_max),
    "physical lag means must fall between observed extrema")
  .etr_scientific_frame_fields(result$reference,
    c("time_unit"),"residual reference")
  .etr_source_text_word(result$reference$time_unit,"time_unit")
  df
}
.etr_source_plot_residual <- function(result,metric,level,curve_id,
    participant_id,strict_source_record=FALSE) {
  .etr_mixed_artist_check(strict_source_record,result,"residual")
  df<-.etr_source_residual_frame(result,level,curve_id,participant_id)
  x<-df$lag_time_mean
  y<-.etr_source_plot_vector(df[[metric]],length(x),metric,allow_na=TRUE)
  if(!isTRUE(strict_source_record))
    .etr_assert(any(is.finite(y)),
      "residual metric must contain at least one defined value")
  scale<-.etr_source_text_word(result$residual_scale,"residual_scale")
  .etr_assert(scale%in%c("whitened","raw"),
    "residual_scale must be raw or whitened")
  prefix<-if(scale=="whitened")"Whitened residual" else "Residual"
  unit<-result$reference$time_unit
  nonuniform<-any(df$lag_time_min!=df$lag_time_max)
  limits<-if(any(is.finite(y))) .etr_source_plot_ymax(
    c(y,if(metric=="autocorrelation")0)) else c(-1,1)
  graphics::plot(x,y,type="o",pch=1L,ylim=limits,
    xlab=paste0("Physical lag (",unit,")"),
    ylab=paste(prefix,metric),
    main=if(nonuniform)
      "Index-lag diagnostic (x = mean physical lag; inspect min/max or pair frame)"
      else "")
  if(metric=="autocorrelation")graphics::abline(h=0,lty=3L)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_mixed_artist_residual(df,metric,level,
      curve_id,participant_id,scale,unit)))
  invisible(data.frame(lag_time_mean=x,
    lag_time_min=df$lag_time_min,lag_time_max=df$lag_time_max,
    value=y))
}

#' Plot residual autocorrelation against retained physical time lag
#' @param result Native functional mixed-effects residual diagnostics.
#' @param level Summary: overall, participant or selected trial.
#' @param curve_id Required for a trial-level plot.
#' @param participant_id Required for a participant-level plot.
#' @param strict_source_record Require true native joint likelihood
#'   residual diagnostics and return source line/horizontal reference
#'   artist geometry; actual Matplotlib Axes remain unavailable.
#' @return Invisible source physical lag and autocorrelation geometry.
#' @export
etr_plot_functional_mixed_effects_residual_acf <- function(result,
    level="overall",curve_id=NULL,participant_id=NULL,
    strict_source_record=FALSE) {
  .etr_source_plot_residual(result,"autocorrelation",
    level,curve_id,participant_id,
    strict_source_record=strict_source_record)
}

#' Plot residual empirical semivariance against physical lag
#' @inheritParams etr_plot_functional_mixed_effects_residual_acf
#' @return Invisible source physical lag and semivariance geometry.
#' @export
etr_plot_functional_mixed_effects_residual_variogram <- function(result,
    level="overall",curve_id=NULL,participant_id=NULL,
    strict_source_record=FALSE) {
  .etr_source_plot_residual(result,"semivariance",
    level,curve_id,participant_id,
    strict_source_record=strict_source_record)
}
