# Frozen eyetrajectoriespy==1.2.0
# functional_mixed_effects_covariance_sensitivity.py::_validate_bands
# and _band_width_frame, commit c1cd95ad718327550f7e55393ff38582872f7a94.
#
# This is a source-scientific R comparison of already calibrated participant
# bootstrap bands. No model selection or new covariance optimizer occurs.
# R structural equality is NOT Python object identity.
.etr_joint_source_band_width_frame <- function(fits,bands,reference) {
  empty <- data.frame(
    model=character(),coefficient=character(),time=numeric(),
    band_width=numeric(),reference_band_width=numeric(),
    band_width_ratio_to_reference=numeric(),stringsAsFactors=FALSE)
  if(is.null(bands))return(empty)
  .etr_assert(is.list(bands)&&!is.data.frame(bands),
    "bands must be a named list of calibrated mixed coefficient bands")
  if(length(bands)==0L)return(empty)
  .etr_assert(!is.null(names(bands))&&!anyNA(names(bands))&&
    all(nzchar(names(bands)))&&!anyDuplicated(names(bands)),
    "bands must have distinct nonempty model labels")
  .etr_assert(all(names(bands)%in%names(fits)),
    "bands contain labels without successful fits")
  .etr_assert(reference%in%names(bands),
    "band-width sensitivity requires a band for the declared reference")
  base <- bands[[reference]]
  .etr_assert(inherits(base,"etr_mixed_effects_simultaneous_band"),
    "reference band must be an actual native mixed simultaneous band")
  .etr_assert(is.numeric(base$confidence_level)&&
    length(base$confidence_level)==1L&&
    !is.logical(base$confidence_level)&&
    is.finite(base$confidence_level)&&
    base$confidence_level>0&&base$confidence_level<1,
    "reference band confidence level must lie within (0,1)")
  .etr_assert(is.character(base$simultaneous_scope)&&
    length(base$simultaneous_scope)==1L&&
    base$simultaneous_scope%in%c("coefficient","family"),
    "reference band simultaneous scope is invalid")
  .etr_assert(is.list(base$bootstrap)&&
    base$bootstrap$bootstrap_type%in%
      c("conditional_covariance","full_refit"),
    "reference bootstrap type is not a native participant bootstrap")
  .etr_assert(is.array(base$bootstrap$bootstrap_coefficient_functions)&&
    length(dim(base$bootstrap$bootstrap_coefficient_functions))==3L,
    "reference band must retain original coefficient bootstrap replicates")
  B<-dim(base$bootstrap$bootstrap_coefficient_functions)[1L]
  sampled<-base$bootstrap$sampled_participant_indices
  .etr_assert(is.matrix(sampled)&&is.numeric(sampled)&&
    nrow(sampled)==B&&ncol(sampled)>=1L&&
    all(is.finite(sampled))&&all(sampled>=0)&&
    all(sampled==floor(sampled)),
    "reference band must retain complete participant draw indices")
  ncoef<-length(fits[[reference]]$coefficient_names)
  time<-as.numeric(fits[[reference]]$time)
  nt<-length(time)
  .etr_assert(is.numeric(time)&&nt>=1L&&all(is.finite(time))&&
    all(diff(time)>0)&&ncoef>=1L,
    "reference fit must declare coefficient names and observed time grid")
  check <- function(label) {
    band<-bands[[label]]
    fit<-fits[[label]]
    .etr_assert(inherits(band,"etr_mixed_effects_simultaneous_band"),
      paste("band",label,"must be an actual calibrated mixed coefficient band"))
    .etr_assert(identical(band$reference,fit),
      paste("band",label,"must refer to the supplied fitted model"))
    .etr_assert(identical(as.numeric(band$confidence_level),
      as.numeric(base$confidence_level)),
      "all supplied sensitivity bands must use the same confidence level")
    .etr_assert(identical(band$simultaneous_scope,base$simultaneous_scope),
      "all supplied sensitivity bands must use the same simultaneous scope")
    .etr_assert(is.list(band$bootstrap)&&
      identical(band$bootstrap$bootstrap_type,base$bootstrap$bootstrap_type),
      "all supplied sensitivity bands must use the same bootstrap contract")
    draws<-band$bootstrap$bootstrap_coefficient_functions
    .etr_assert(is.array(draws)&&length(dim(draws))==3L&&
      dim(draws)[1L]==B,
      "all supplied sensitivity bands must use the same number of bootstrap replicates")
    .etr_assert(is.matrix(band$bootstrap$sampled_participant_indices)&&
      identical(unname(band$bootstrap$sampled_participant_indices),
        unname(sampled)),
      "band-width sensitivity requires identical participant bootstrap draws across supplied models")
    .etr_assert(identical(fit$coefficient_names,
        fits[[reference]]$coefficient_names)&&
      identical(as.numeric(fit$time),time),
      "sensitivity band must share exact fitted coefficient and observed time support")
    .etr_assert(is.matrix(band$lower)&&is.matrix(band$upper)&&
      identical(dim(band$lower),c(ncoef,nt))&&
      identical(dim(band$upper),c(ncoef,nt))&&
      all(is.finite(band$lower))&&all(is.finite(band$upper))&&
      all(band$upper>=band$lower),
      "sensitivity band endpoints must be finite ordered coefficient-by-time matrices")
    invisible(TRUE)
  }
  invisible(lapply(names(bands),check))
  denominator<-base$upper-base$lower
  records<-vector("list",length(bands)*ncoef*nt)
  k<-0L
  # Frozen Python loops successful fit order, then coefficient and time.
  for(label in names(fits)){
    if(!label%in%names(bands))next
    band<-bands[[label]]
    width<-band$upper-band$lower
    for(j in seq_len(ncoef)){
      for(t in seq_len(nt)){
        k<-k+1L
        den<-as.numeric(denominator[j,t])
        num<-as.numeric(width[j,t])
        records[[k]]<-data.frame(model=label,
          coefficient=as.character(fits[[label]]$coefficient_names[j]),
          time=time[t],band_width=num,reference_band_width=den,
          band_width_ratio_to_reference=if(den>0)num/den else NaN,
          stringsAsFactors=FALSE)
      }
    }
  }
  .etr_assert(k>0L,
    "paired sensitivity bands did not match any successful model")
  out<-do.call(rbind,records[seq_len(k)])
  rownames(out)<-NULL
  .etr_assert(identical(names(out),names(empty)),
    "band width source dataframe schema mismatch")
  out
}
