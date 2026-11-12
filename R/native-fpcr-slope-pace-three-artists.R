# Frozen eyetrajectoriespy 1.2.0 scientific Matplotlib artist schemas:
# src/eyetrajectoriespy/plotting.py @ c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R only. No Python object identity, re-estimation or live matplotlib.

.etr_fpcr_slope_source_artist <- function(frame,dimension,unit,level,scope,
    operation) {
  .etr_assert(is.data.frame(frame)&&
    identical(names(frame),c("time","reference","lower","upper"))&&
    nrow(frame)>=2L&&all(is.finite(as.matrix(frame)))&&
    all(frame$lower<=frame$reference)&
    all(frame$reference<=frame$upper),
    "source FPCR slope artist requires finite, ordered reference bands")
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&nzchar(dimension)&&
    is.character(unit)&&length(unit)==1L&&
    !is.na(unit)&&nzchar(unit),
    "source slope dimension and time unit must be non-empty strings")
  .etr_assert(operation%in%c("plot_fpca_regression_slope_band",
    "plot_fpca_regression_slope_uncertainty"),
    "unsupported FPCR slope source operation")
  .etr_assert(is.numeric(level)&&length(level)==1L&&
    is.finite(level)&&level>0&&level<1,
    "source FPCR slope confidence level outside (0,1)")
  label<-sprintf("%.1f%% %s",100*level,scope)
  title<-if(identical(operation,"plot_fpca_regression_slope_band"))
    "Gaussian FPCR simultaneous slope band" else
    "Gaussian FPCR slope uncertainty"
  x<-as.numeric(frame$time)
  artists<-list(
    list(kind="fill_between",alpha=.2,label=label,
      xdata=x,lower=as.numeric(frame$lower),
      upper=as.numeric(frame$upper)),
    list(kind="line",label="full-sample FPCR slope",
      linestyle="-",xdata=x,ydata=as.numeric(frame$reference)),
    list(kind="horizontal_reference",linestyle="--",
      label="_child_zero",x_transform="axes_fraction",
      xdata=c(0,1),ydata=c(0,0)))
  axis<-list(title=title,xlabel=paste0("Time (",unit,")"),
    ylabel=paste0("Slope for ",dimension),artists=artists,
    legend=TRUE,legend_labels=c(label,"full-sample FPCR slope"))
  .etr_fpca_inference_artist_record(operation,axis,
    options=list(dimension=dimension,confidence_level=as.numeric(level),
      scope=scope,source_time_grid=x))
}

.etr_sparse_pace_source_artist <- function(frame) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
    identical(names(frame),c("n_samples","condition_number",
      "status_code","finite","ok","flagged"))&&
    is.numeric(frame$n_samples)&&
    is.numeric(frame$condition_number)&&
    is.character(frame$status_code)&&
    is.logical(frame$finite)&&is.logical(frame$ok)&&
    is.logical(frame$flagged)&&
    !anyNA(frame$n_samples)&&!anyNA(frame$status_code)&&
    !anyNA(frame$finite)&&!anyNA(frame$ok)&&!anyNA(frame$flagged)&&
    all(is.finite(frame$n_samples))&&
    any(frame$finite)&&
    all(frame$finite==(is.finite(frame$condition_number)&
      frame$condition_number>0))&&
    all(frame$ok==(frame$finite&frame$status_code=="ok"))&&
    all(frame$flagged==(frame$finite&frame$status_code!="ok")),
    "source PACE scientific scatter requires coherent finite, ok and flagged masks")
  artists<-list()
  if(any(frame$ok))artists[[length(artists)+1L]]<-list(
    kind="scatter",label="score system ok",marker="o",
    offsets=unname(cbind(as.numeric(frame$n_samples[frame$ok]),
      as.numeric(frame$condition_number[frame$ok]))))
  if(any(frame$flagged))artists[[length(artists)+1L]]<-list(
    kind="scatter",label="flagged/failed score system",marker="x",
    offsets=unname(cbind(as.numeric(frame$n_samples[frame$flagged]),
      as.numeric(frame$condition_number[frame$flagged]))))
  labels<-vapply(artists,function(a)a$label,character(1L))
  ax<-list(title="Sparse PACE score-system conditioning",
    xlabel="Observed samples used for PACE score",
    ylabel="Conditional covariance condition number",
    yscale="log",artists=artists,
    legend=any(frame$flagged),
    legend_labels=if(any(frame$flagged))labels else character(0))
  # Sparse source is permitted a single artist if all fitted scores pass.
  # The shared source record validator expects two; do not invent an artist.
  structure(list(source_export="plot_sparse_fpca_score_diagnostics",
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),axes=list(ax),
    source_options=list(
      original_n=nrow(frame),
      finite_count=sum(frame$finite),
      ok_count=sum(frame$ok),
      flagged_count=sum(frame$flagged)),
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_fpca_inference_artist_source_record","list"))
}
