# Frozen Python 1.2 _functional_simulation.py::_missingness_mask:
# source SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R dense MCAR and contiguous-block observation dropout.
# No Python dependency. A supplied PCG64 stream consumes source draws.

.etr_functional_simulation_missingness_spec <- function(missingness) {
  if(is.null(missingness))return(list(kind="none",parameter=NULL))
  .etr_assert(is.list(missingness)&&!is.data.frame(missingness)&&
    !is.null(names(missingness))&&
    !anyDuplicated(names(missingness)),
    "missingness must be a named mapping or NULL")
  kind<-missingness[["kind",exact=TRUE]]
  .etr_assert(is.character(kind)&&length(kind)==1L&&
    !is.na(kind)&&kind%in%c("mcar","block"),
    "missingness currently supports kind='mcar' or kind='block'")
  label<-if(identical(kind,"mcar"))"probability" else "fraction"
  value<-missingness[[label,exact=TRUE]]
  # Frozen Python casts float(mapping[label]), including finite numeric
  # strings and logical booleans. Explicitly reject NA/nonfinite domains.
  .etr_assert((is.numeric(value)||is.logical(value)||
    is.character(value))&&length(value)==1L&&!is.na(value),
    paste0("missingness['",label,"'] must be in [0, 1)"))
  number<-suppressWarnings(as.numeric(value))
  .etr_assert(length(number)==1L&&is.finite(number)&&
    number>=0&&number<1,
    paste0("missingness['",label,"'] must be in [0, 1)"))
  list(kind=kind,parameter=number)
}

.etr_functional_simulation_missingness_draw <- function(nt,spec,rng=NULL) {
  .etr_assert(is.numeric(nt)&&length(nt)==1L&&
    nt>=2L&&nt==as.integer(nt),
    "dense missingness requires at least two samples")
  if(identical(spec$kind,"none"))return(rep(FALSE,nt))
  if(identical(spec$kind,"mcar")){
    uniform<-if(is.null(rng))stats::runif(nt) else rng$uniform(nt)
    return(uniform<spec$parameter)
  }
  .etr_assert(identical(spec$kind,"block"),"unknown source missingness kind")
  block<-as.integer(floor(spec$parameter*nt))
  if(spec$parameter>0&&block==0L)block<-1L
  mask<-rep(FALSE,nt)
  if(block>0L){
    start<-if(is.null(rng))sample.int(nt-block+1L,1L) else
      rng$integers(1L,nt-block+1L)+1L
    mask[seq.int(start,length.out=block)]<-TRUE
  }
  mask
}

.etr_functional_simulation_missingness_replay <- function(masks,n,nt) {
  # Python FunctionalSimulationTruth.missingness_mask is a tuple of
  # one-dimensional bool arrays, one vector per simulated curve.
  .etr_assert(is.list(masks)&&length(masks)==n,
    "source_draws missingness_mask must contain one logical vector per curve")
  for(i in seq_len(n))
    .etr_assert(is.logical(masks[[i]])&&
      is.null(dim(masks[[i]]))&&
      length(masks[[i]])==nt&&!anyNA(masks[[i]]),
      "source_draws missingness_mask must contain finite logical sample masks")
  masks
}
