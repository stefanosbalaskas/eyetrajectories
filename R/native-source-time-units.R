# Frozen Python 1.2 source semantics:
# src/eyetrajectoriespy/embedding.py::_regular_step and ::_resolve_samples
# commit c1cd95ad718327550f7e55393ff38582872f7a94
#
# Explicitly no interpolation, resampling or timestamp rewriting. Python's
# supported s/ms aliases and approximately regular observed grids are honored.

.etr_source_regular_time_step <- function(time) {
  .etr_assert(is.numeric(time)&&!is.logical(time)&&
    length(time)>=2L&&all(is.finite(time))&&
    all(diff(time)>0),
    "time-based nonlinear parameters require strictly increasing finite time")
  delta<-diff(time)
  step<-stats::median(delta)
  atol<-max(1e-12,abs(step)*1e-9)
  .etr_assert(all(abs(delta-step)<=atol+1e-6*abs(step)),
    paste("time-based nonlinear dynamics parameters require an",
      "approximately regular grid; resample explicitly upstream"))
  as.numeric(step)
}

.etr_source_time_unit_samples <- function(time,value,units,time_unit,
    name,allow_zero=FALSE) {
  .etr_assert(is.character(name)&&length(name)==1L&&
    !is.na(name)&&nzchar(name),
    "source time conversion requires explicit parameter name")
  .etr_assert(is.numeric(value)&&!is.logical(value)&&
    length(value)==1L&&!is.na(value)&&is.finite(value),
    paste0(name," must be a finite numeric scalar, not logical"))
  .etr_assert(is.character(units)&&length(units)==1L&&
    !is.na(units)&&nzchar(units)&&
    is.character(time_unit)&&length(time_unit)==1L&&
    !is.na(time_unit)&&nzchar(time_unit),
    paste0(name," units and trajectory time_unit must be nonempty strings"))
  if(identical(units,"samples")){
    .etr_assert(value==floor(value),
      paste0(name," must be integer when units='samples'"))
    resolved<-as.numeric(value)
  }else{
    step<-.etr_source_regular_time_step(time)
    aliases<-c(s=1,sec=1,second=1,seconds=1,
      ms=.001,millisecond=.001,milliseconds=.001)
    lower_units<-tolower(units);lower_source<-tolower(time_unit)
    if(lower_units%in%names(aliases)&&
       lower_source%in%names(aliases)) {
      in_source<-value*unname(aliases[[lower_units]])/
        unname(aliases[[lower_source]])
    }else if(identical(lower_units,lower_source)){
      in_source<-value
    }else{
      stop(paste0(name,"_units cannot be converted to trajectory time_unit"),
        call.=FALSE)
    }
    raw<-in_source/step
    .etr_assert(is.finite(raw),
      paste0(name," cannot resolve to finite sample count"))
    resolved<-round(raw)
    # Matches NumPy isclose(raw, samples, rtol=1e-6, atol=1e-8)
    .etr_assert(abs(raw-resolved)<=1e-8+1e-6*abs(resolved),
      paste0(name," is not an integer multiple of the observed grid step"))
  }
  minimum<-if(isTRUE(allow_zero))0 else 1
  .etr_assert(is.finite(resolved)&&resolved>=minimum&&
    resolved<=.Machine$integer.max,
    paste0(name," must resolve to ",
      if(minimum==0)"non-negative" else "positive"," sample count"))
  as.integer(resolved)
}
