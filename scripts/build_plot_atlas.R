# Website-only atlas. Executed native eyetrajectories R functions, source v0.4.3.
stopifnot(dir.exists("site/reference"),
          identical(unname(read.dcf("DESCRIPTION",fields="Version")[1]),"0.4.3"))
stopifnot(requireNamespace("pkgload",quietly=TRUE),
          requireNamespace("jsonlite",quietly=TRUE))
pkgload::load_all(".",quiet=TRUE)
out <- "site/plot-atlas"
images <- file.path(out,"images")
dir.create(images,recursive=TRUE,showWarnings=FALSE)
time <- seq(0,1,length.out=81L)
values <- array(0,c(12L,length(time),2L))
for(i in seq_len(12L)){
  phase <- (i-1)/35
  values[i,,1] <- .5+.28*sin(2*pi*(time+phase))+i/250
  values[i,,2] <- .5+.24*cos(2*pi*(time+phase))
}
paths <- eyetrajectories::etr_trajectory_set(
  time,values,curve_ids=paste0("synthetic_",seq_len(12L)),
  dimension_names=c("x","y"),coordinate_system="normalized",time_unit="s")
fit <- eyetrajectories::etr_fit_fpca(paths,n_components=3L)
rec1 <- eyetrajectories::etr_recurrence_matrix(paths,curve=1L,radius=.12,theiler=2L)
rec2 <- eyetrajectories::etr_recurrence_matrix(paths,curve=1L,radius=.30,theiler=2L)
a <- cbind(sin(2*pi*time),cos(2*pi*time))
b <- cbind(sin(2*pi*(time+.19)),cos(2*pi*(time+.19)))
warp1 <- eyetrajectories::etr_dtw(a,a,return_path=TRUE)
warp2 <- eyetrajectories::etr_dtw(a,b,return_path=TRUE)
worked <- new.env(parent=globalenv())
sys.source("scripts/run_native_worked_gallery.R",envir=worked)

path_code <- paste(c(
  "library(eyetrajectories)",
  "time <- seq(0,1,length.out=81L)",
  "values <- array(0,c(12L,length(time),2L))",
  "for(i in seq_len(12L)){",
  "  phase <- (i-1)/35",
  "  values[i,,1] <- .5+.28*sin(2*pi*(time+phase))+i/250",
  "  values[i,,2] <- .5+.24*cos(2*pi*(time+phase))",
  "}",
  'paths <- etr_trajectory_set(time,values,curve_ids=paste0("synthetic_",1:12),',
  '  dimension_names=c("x","y"),coordinate_system="normalized",time_unit="s")'
),collapse="\n")
band_code <- paste(c(
  "library(eyetrajectories)",
  "s <- etr_simulate_hierarchical(n_subjects=20L,trials_per_subject=3L,",
  "  n_time=41L,seed=2501L)",
  "band <- etr_bootstrap_mean_band(s$trajectories,s$participant,",
  "  B=99L,alpha=.10,seed=2502L)"
),collapse="\n")
sparse_code <- paste(c(
  "library(eyetrajectories)",
  "s <- etr_simulate_sparse_known_truth(n_subjects=35L,seed=2505L)",
  "support <- etr_sparse_design_diagnostics(s$curves,bins=10L)"
),collapse="\n")
te_code <- paste(c(
  "library(eyetrajectories)",
  "set.seed(2506L)",
  "source_states <- sample(0:1,220L,replace=TRUE)",
  "target_states <- c(0L,head(source_states,-1L))",
  "flip <- runif(220L)<.1",
  "target_states[flip] <- 1L-target_states[flip]",
  "te <- etr_transfer_entropy_shift_test(source_states,target_states,",
  "  n_surrogates=49L,seed=2507L)"
),collapse="\n")
plot_spec <- list()
render <- function(name,slug,label,fn,code) {
  path <- file.path(images,paste0(name,"__",slug,".png"))
  grDevices::png(path,width=960,height=660,res=130,bg="white")
  error <- NULL
  tryCatch({
    graphics::par(mar=c(5.1,5.1,3.5,1.6))
    fn()
  },error=function(e) error <<- conditionMessage(e),
  finally=grDevices::dev.off())
  if(!is.null(error))stop(name,": ",error,call.=FALSE)
  stopifnot(file.exists(path),file.info(path)$size>3500)
  list(label=label,image=paste0("plot-atlas/images/",basename(path)),code=code)
}
add <- function(name,category,description,variants)
  plot_spec[[name]] <<- list(category=category,description=description,variants=variants)
v <- function(name,slug,label,fn,setup,call)
  render(name,slug,label,fn,paste(setup,call,sep="\n"))
add("etr_plot_trajectories","Trajectory geometry",
    "Native planar display with explicit screen or Cartesian Y-axis direction.",
    list(
      v("etr_plot_trajectories","screen","Screen Y reversed",
        function()eyetrajectories::etr_plot_trajectories(paths,max_curves=12L,invert_y=TRUE),
        path_code,"etr_plot_trajectories(paths,max_curves=12L,invert_y=TRUE)"),
      v("etr_plot_trajectories","cartesian","Cartesian Y",
        function()eyetrajectories::etr_plot_trajectories(paths,max_curves=12L,invert_y=FALSE),
        path_code,"etr_plot_trajectories(paths,max_curves=12L,invert_y=FALSE)")))
add("etr_plot_planar_trajectories","Trajectory geometry",
    "R-native screen-space trajectories with a selectable opacity (base graphics, not Matplotlib).",
    list(
      v("etr_plot_planar_trajectories","alpha018","Opacity 0.18",
        function()eyetrajectories::etr_plot_planar_trajectories(paths,max_curves=12L,alpha=.18,invert_y=TRUE),
        path_code,"etr_plot_planar_trajectories(paths,max_curves=12L,alpha=.18,invert_y=TRUE)"),
      v("etr_plot_planar_trajectories","alpha075","Opacity 0.75",
        function()eyetrajectories::etr_plot_planar_trajectories(paths,max_curves=12L,alpha=.75,invert_y=TRUE),
        path_code,"etr_plot_planar_trajectories(paths,max_curves=12L,alpha=.75,invert_y=TRUE)")))
fit_code <- paste(path_code,"fit <- etr_fit_fpca(paths,n_components=3L)",sep="\n")
add("etr_plot_fpca_variance","Functional PCA",
    "Explained variance from the actual native FPCA fit: cumulative versus individual.",
    list(
      v("etr_plot_fpca_variance","cumulative","Cumulative",
        function()eyetrajectories::etr_plot_fpca_variance(fit,cumulative=TRUE),
        fit_code,"etr_plot_fpca_variance(fit,cumulative=TRUE)"),
      v("etr_plot_fpca_variance","individual","Individual",
        function()eyetrajectories::etr_plot_fpca_variance(fit,cumulative=FALSE),
        fit_code,"etr_plot_fpca_variance(fit,cumulative=FALSE)")))
add("etr_plot_fpca_component","Functional PCA",
    "First functional component, showing mean and plus/minus score standard deviations.",
    list(
      v("etr_plot_fpca_component","sd1","±1 score SD",
        function()eyetrajectories::etr_plot_fpca_component(fit,component=0L,dimension="x",sd_multiplier=1),
        fit_code,'etr_plot_fpca_component(fit,component=0L,dimension="x",sd_multiplier=1)'),
      v("etr_plot_fpca_component","sd2","±2 score SD",
        function()eyetrajectories::etr_plot_fpca_component(fit,component=0L,dimension="x",sd_multiplier=2),
        fit_code,'etr_plot_fpca_component(fit,component=0L,dimension="x",sd_multiplier=2)')))
add("etr_plot_recurrence","Recurrence & nonlinear",
    "Empirical recurrence matrix; comparing two radii under a fixed Theiler exclusion.",
    list(
      v("etr_plot_recurrence","r012","Radius 0.12",
        function()eyetrajectories::etr_plot_recurrence(rec1),
        path_code,"r <- etr_recurrence_matrix(paths,curve=1L,radius=.12,theiler=2L)\netr_plot_recurrence(r)"),
      v("etr_plot_recurrence","r030","Radius 0.30",
        function()eyetrajectories::etr_plot_recurrence(rec2),
        path_code,"r <- etr_recurrence_matrix(paths,curve=1L,radius=.30,theiler=2L)\netr_plot_recurrence(r)")))
warp_code <- paste(path_code,
  "a <- cbind(sin(2*pi*time),cos(2*pi*time))",sep="\n")
add("etr_plot_dynamic_time_warping_alignment","Distances & alignment",
    "Real native DTW path, computed with return_path=TRUE. This is not a JS approximation.",
    list(
      v("etr_plot_dynamic_time_warping_alignment","same","Identical series",
        function()eyetrajectories::etr_plot_dynamic_time_warping_alignment(warp1),
        warp_code,"d <- etr_dtw(a,a,return_path=TRUE)\netr_plot_dynamic_time_warping_alignment(d)"),
      v("etr_plot_dynamic_time_warping_alignment","phase","Phase-shifted series",
        function()eyetrajectories::etr_plot_dynamic_time_warping_alignment(warp2),
        warp_code,"b <- cbind(sin(2*pi*(time+.19)),cos(2*pi*(time+.19)))\nd <- etr_dtw(a,b,return_path=TRUE)\netr_plot_dynamic_time_warping_alignment(d)")))
add("etr_plot_functional_band","Functional uncertainty",
    "Experimental cluster-bootstrap intervals. The empirical coverage is not independently certified.",
    list(
      v("etr_plot_functional_band","simultaneous","Simultaneous",
        function()eyetrajectories::etr_plot_functional_band(worked$mean_band,dimension=1L,interval="simultaneous"),
        band_code,'etr_plot_functional_band(band,dimension=1L,interval="simultaneous")'),
      v("etr_plot_functional_band","pointwise","Pointwise",
        function()eyetrajectories::etr_plot_functional_band(worked$mean_band,dimension=1L,interval="pointwise"),
        band_code,'etr_plot_functional_band(band,dimension=1L,interval="pointwise")')))
add("etr_plot_sparse_support","Sparse observations",
    "Actual observed support fractions; no interpolation or imputed observations.",
    list(v("etr_plot_sparse_support","support","Observed support",
      function()eyetrajectories::etr_plot_sparse_support(worked$support),
      sparse_code,"etr_plot_sparse_support(support)")))
add("etr_plot_transfer_surrogates","Recurrence & nonlinear",
    "Circular-shift surrogate TE display; predictive information is not causal inference.",
    list(v("etr_plot_transfer_surrogates","te","Shift surrogate test",
      function()eyetrajectories::etr_plot_transfer_surrogates(worked$te),
      te_code,"etr_plot_transfer_surrogates(te)")))

# Extend with validated scientific fixtures from the qualified native package.
sys.source("scripts/extend_plot_atlas.R",envir=environment())
sys.source("scripts/extend_plot_atlas_wave2.R",envir=environment())
stopifnot(length(atlas_new_success)>=30L)
ns <- readLines("NAMESPACE",warn=FALSE)
exports <- grep("^export\\([A-Za-z][A-Za-z0-9_]*\\)$",ns,value=TRUE)
exports <- sub("^export\\(([^)]+)\\)$","\\1",exports)
native <- sort(unique(grep("^etr_plot_",exports,value=TRUE)))
bridge <- sort(unique(grep("^(etpy_plot_|et_plot_)",exports,value=TRUE)))
stopifnot(length(native)>40L,all(names(plot_spec)%in%native))
category <- function(name){
  if(grepl("sparse|irregular|pace",name))return("Sparse observations")
  if(grepl("transfer|surrogate|recurrence|rqa|lyapunov|kantz|poincare|embedding|divergence",name))return("Recurrence & nonlinear")
  if(grepl("distance|warping|alignment|registration",name))return("Distances & alignment")
  if(grepl("band|uncertainty|interval|bootstrap|conformal|prediction|sensitivity",name))return("Functional uncertainty")
  if(grepl("fpca|eigen|component|functional|regression|mixed|random_effects|reconstruction",name))return("Functional PCA")
  "Trajectory geometry"
}
entry <- function(name,backend){
  sp <- plot_spec[[name]]
  doc <- paste0("reference/",name,".html")
  has_doc <- file.exists(file.path("site",doc))
  list(name=name,title=gsub("_"," ",sub("^(etr_plot_|etpy_plot_|et_plot_)","",name)),
    category=if(is.null(sp))category(name) else sp$category,backend=backend,
    description=if(!is.null(sp))sp$description else if(backend=="Native R")
      "Exported native R plotting function. Consult the documented input and model assumptions." else
      "Optional Python-backed plotting interface; requires the separately installed Python backend.",
    doc=if(has_doc)doc else "reference/index.html",
    exactDoc=has_doc,variants=if(is.null(sp))list() else sp$variants)
}
catalog <- c(lapply(native,entry,backend="Native R"),
             lapply(bridge,entry,backend="Python-backed"))
stopifnot(length(unique(vapply(catalog,function(x)x$name,"")))==length(catalog))
json <- jsonlite::toJSON(catalog,auto_unbox=TRUE,null="null",digits=9)
writeLines(paste0("window.ET_PLOT_ATLAS_CATALOG=",json,";"),
  file.path(out,"catalog.js"),useBytes=TRUE)
png_count <- length(list.files(images,pattern="\\.png$"))
stopifnot(png_count>=15L)
writeLines(c("eyetrajectories v0.4.3 actual native R plotting atlas",
  paste("Native plotting exports:",length(native)),
  paste("Python-backed plotting exports:",length(bridge)),
  paste("Directly illustrated exported native functions:",length(plot_spec)),
  paste("New additional native R plotting exports:",length(atlas_new_success)),
  paste("Unrendered additional fixture candidates:",length(atlas_new_failures)),
  paste("Native R generated PNG examples:",png_count),
  "The searchable function inventory was generated from the actual NAMESPACE.",
  "All previews are direct output from exported native R plotting functions, not recreated JavaScript approximations.",
  "Synthetic data only; optional Python bridge never executed. No empirical validation claim."
),file.path(out,"MANIFEST.txt"))
message("NATIVE_PLOT_ATLAS_PASS native=",length(native),
  " bridge=",length(bridge)," direct=",length(plot_spec)," png=",png_count)
