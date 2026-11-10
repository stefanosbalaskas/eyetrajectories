# Frozen eyetrajectoriespy 1.2.0: _functional_simulation.py
# _resolve_phase_variation() and _apply_power_warp(), immutable source
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Pure native R with optional source-seeded phase draws.

.etr_functional_simulation_phase_spec<-function(phase_variation){
  if(is.null(phase_variation))
    return(list(kind="none",sd=NULL))
  .etr_assert(is.list(phase_variation)&&!is.data.frame(phase_variation)&&
    !is.null(names(phase_variation))&&
    !anyDuplicated(names(phase_variation)),
    "phase_variation must be a named mapping or NULL")
  .etr_assert(identical(phase_variation[["kind",exact=TRUE]],"power"),
    "phase_variation currently supports only kind='power'")
  sd<-phase_variation[["sd",exact=TRUE]]
  .etr_assert((is.numeric(sd)||is.logical(sd)||is.character(sd))&&
    length(sd)==1L&&!is.na(sd),
    "phase_variation['sd'] must be finite and non-negative")
  sd<-suppressWarnings(as.numeric(sd))
  .etr_assert(length(sd)==1L&&is.finite(sd)&&sd>=0,
    "phase_variation['sd'] must be finite and non-negative")
  list(kind="power",sd=sd)
}

.etr_functional_simulation_phase_draw<-function(spec,n,source_draws=NULL,rng=NULL){
  .etr_assert(is.list(spec)&&
    spec$kind%in%c("power","none")&&
    is.numeric(n)&&length(n)==1L&&n>=1L,
    "phase spec must be valid for positive curve count")
  if(!is.null(source_draws)&&
     "phase_exponents"%in%names(source_draws)){
    .etr_assert(identical(spec$kind,"power"),
      "source_draws phase_exponents require declared phase variation")
    exponents<-source_draws$phase_exponents
    .etr_assert(is.numeric(exponents)&&is.null(dim(exponents))&&
      length(exponents)==n&&all(is.finite(exponents))&&
      all(exponents>0),
      "source_draws phase_exponents must contain one positive finite exponent per curve")
    return(as.numeric(exponents))
  }
  if(identical(spec$kind,"none"))return(rep.int(1,n))
  draws<-if(is.null(rng))stats::rnorm(n,mean=0,sd=spec$sd) else
    spec$sd*rng$normal(n)
  exponents<-exp(draws)
  .etr_assert(all(is.finite(exponents))&&all(exponents>0),
    "generated phase exponents overflowed to nonfinite or zero")
  exponents
}

.etr_functional_simulation_power_warp<-function(time,grid,exponent){
  .etr_assert(is.numeric(time)&&is.null(dim(time))&&
    length(time)>=2L&&all(is.finite(time))&&
    is.numeric(grid)&&length(grid)>=2L&&
    all(is.finite(grid))&&grid[length(grid)]>grid[1L]&&
    is.numeric(exponent)&&length(exponent)==1L&&
    is.finite(exponent)&&exponent>0,
    "phase power warp requires finite time, domain and positive exponent")
  start<-grid[1L];end<-grid[length(grid)]
  span<-end-start
  unit<-(time-start)/span
  .etr_assert(all(unit>=0)&&all(unit<=1),
    "phase power warp observation times must lie within truth support")
  out<-start+span*unit^exponent
  # NumPy preserves domain endpoints under np.isclose; protect exact
  # support endpoints without modifying source interior times.
  close_start<-abs(time[1L]-start)<=1e-8+1e-5*abs(start)
  close_end<-abs(time[length(time)]-end)<=1e-8+1e-5*abs(end)
  if(close_start)out[1L]<-start
  if(close_end)out[length(time)]<-end
  .etr_assert(all(is.finite(out)),
    "phase power warp produced nonfinite timestamps")
  as.numeric(out)
}
