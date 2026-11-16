# Website-only atlas. Executed native eyetrajectories R functions, source v0.4.3.
stopifnot(dir.exists("site/reference"),
          identical(unname(read.dcf("DESCRIPTION",fields="Version")[1]),"0.4.3"))
stopifnot(requireNamespace("pkgload",quietly=TRUE),
          requireNamespace("jsonlite",quietly=TRUE))
pkgload::load_all(".",quiet=TRUE)
out <- "site/plot-atlas"
images <- file.path(out,"images")
dir.create(images,recursive=TRUE,showWarnings=FALSE)
scripts_out <- file.path(out,"scripts")
dir.create(scripts_out,recursive=TRUE,showWarnings=FALSE)
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
  stopifnot(grepl("^etr_plot_[A-Za-z0-9_]+$",name),
            grepl("^[A-Za-z0-9_-]+$",slug),
            is.character(code),length(code)==1L,nzchar(code))
  script_name <- paste0(name,"__",slug,".R")
  script_path <- file.path(scripts_out,script_name)
  complete_code <- paste(
    "# eyetrajectories plotting atlas | v0.4.3 | synthetic teaching fixture",
    "# This demonstrates the native plotting API; not independent validation.",
    'stopifnot(as.character(utils::packageVersion("eyetrajectories")) == "0.4.3")',
    code,sep="\n")
  writeLines(complete_code,script_path,useBytes=TRUE)
  stopifnot(file.exists(script_path),file.info(script_path)$size>100,
            grepl(paste0(name,"\\("),complete_code))
  list(label=label,image=paste0("plot-atlas/images/",basename(path)),
       script=paste0("plot-atlas/scripts/",script_name),
       code=complete_code)
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
sys.source("scripts/extend_plot_atlas_wave3.R",envir=environment())
sys.source("scripts/extend_plot_atlas_wave4.R",envir=environment())
sys.source("scripts/extend_plot_atlas_wave5.R",envir=environment())
stopifnot(length(atlas_new_success)>=36L)
stopifnot(length(wave3_pass)==14L, length(wave4_pass)==11L,
          length(wave5_pass)==8L, length(plot_spec)==81L)
ns <- readLines("NAMESPACE",warn=FALSE)
exports <- grep("^export\\([A-Za-z][A-Za-z0-9_]*\\)$",ns,value=TRUE)
exports <- sub("^export\\(([^)]+)\\)$","\\1",exports)
native <- sort(unique(grep("^etr_plot_",exports,value=TRUE)))
bridge <- sort(unique(grep("^(etpy_plot_|et_plot_)",exports,value=TRUE)))
stopifnot(length(native)>40L,all(names(plot_spec)%in%native))
# Exact, version-frozen scientific taxonomy. Order is deliberately
# mutually exclusive for all 81 v0.4.3 native plotting exports.
scientific_categories <- c(
 "Trajectories & reconstruction",
 "Functional PCA & diagnostics",
 "Functional regression",
 "Mixed-effects & covariance",
 "Functional inference & bootstrap",
 "Sparse functional data",
 "Nonlinear dynamics & RQA",
 "Information transfer & surrogates",
 "Registration & alignment",
 "Simulation & recovery",
 "Workflow dispatch")
category <- function(name,strict=FALSE){
  x <- sub("^(etpy_plot_|et_plot_)","etr_plot_",name)
  patterns <- c(
    "^etr_plot_(trajectories|planar_trajectories|reconstruction_curve)$",
    "^etr_plot_fpca_(?!regression|wild_bootstrap)",
    "^etr_plot_(generalized_function_on_scalar|function_on_scalar|fpca_regression|nested_fpca_regression)",
    "^etr_plot_(functional_mixed_effects|functional_random_effects|functional_trial_random_effects|functional_variance_decomposition|covariance_sensitivity)",
    "^etr_plot_(functional_band|functional_mean_band|conformal_fpca|fpca_wild_bootstrap)",
    "^etr_plot_sparse_",
    "^etr_plot_(recurrence|joint_recurrence|rqa_|windowed_rqa|embedding_|poincare_|kantz_|lyapunov_|local_divergence)",
    "^etr_plot_(transfer_|conditional_transfer_|surrogate_|multivariate_iaaft_|multivariate_surrogate_)",
    "^etr_plot_(dynamic_time_warping_alignment|registration|warping_functions|trajectory_distance_rank_correlations)$",
    "^etr_plot_(functional_simulation_|functional_recovery_)",
    "^etr_plot_workflow_result$")
  hits <- vapply(patterns,function(pattern)grepl(pattern,x,perl=TRUE),
                 logical(1L))
  if(sum(hits)==1L)return(scientific_categories[which(hits)])
  if(strict)stop("Unclassified or ambiguous native plot: ",name,
                 " (matched ",sum(hits)," categories)")
  "Optional Python bridge (other)"
}
stopifnot(length(native)==81L,
  length(scientific_categories)==11L,
  all(vapply(native,function(name)
    category(name,strict=TRUE)%in%scientific_categories,logical(1L))))
# An educational reference is only as accurate as its source: formals()
# lists the actual v0.4.3 R native plotting signature. Explanations
# are deliberately conservative rather than inferring unsupported units.
parameter_note <- function(arg,family){
  notes <- c(
    result="Precomputed fit, diagnostic, or plotting result; inspect the exact required object class in the reference.",
    trajectories="Trajectory-set input. Check coordinate system, sampling and missing-data requirements.",
    dimension="Functional response or channel selector; see the function's documented naming/index convention.",
    dimensions="Selected functional channels, not necessarily independent observations.",
    component="Principal-component selector; see the documented index convention.",
    coefficient="Exactly named fitted coefficient; interpretation depends on the model and link scale.",
    interval="Interval display selector. Pointwise and simultaneous bands target different coverage statements.",
    band="Optional precomputed uncertainty-band object; it is not estimated by the plotting call.",
    confidence_level="Nominal interval level supplied to a diagnostic; calibration and coverage depend on how its input was obtained.",
    n_bootstrap="Bootstrap replicate count for the underlying procedure; small values do not support stable tail inference.",
    radius="Recurrence neighborhood threshold in the chosen measurement/distance space; sensitivity should be checked.",
    theiler="Temporal-neighbor exclusion for recurrence analysis, in the units required by the estimator.",
    theiler_window="Temporal-neighbor exclusion; check sample versus physical-time units.",
    embedding_dimension="State-space reconstruction dimension; diagnostics are conditional on this choice.",
    delay="Embedding lag; use the estimator's declared sample or physical-time units.",
    sd_multiplier="Visual multiplier of the fitted component's score SD; not a confidence interval.",
    max_curves="Upper bound on the number of displayed curves; does not change the fitted analysis.",
    invert_y="Coordinate-display convention: reverse screen-space Y versus Cartesian Y.",
    max_participants="Limits rendered participant-level random-effect functions; does not re-estimate them.",
    max_trials="Limits displayed nested trial functions; does not re-estimate them.",
    participant_id="Subset to a named participant already present in the result.",
    max_points="Display guard on the number of rendered points; not a data-imputation option.",
    metric="Named source diagnostic metric. Its meaning and range depend on the estimator.",
    metrics="Metrics selected from a source diagnostic; see the returned metric definitions.",
    statistic="Summary statistic from the supplied result, such as a mean or median; not automatically an effect estimate.",
    strict_source_record="Requests a native source-oriented geometry/artist record; this does not return a Python Matplotlib Axes object.",
    plot="Exact workflow plot identifier, dispatched only for supported result types.",
    alpha="Context-dependent opacity or alpha-level argument; check the exact function reference before interpreting it.",
    "..."="Additional graphical arguments passed to the plotting backend; read the specific reference for accepted options."
  )
  if(arg%in%names(notes))return(unname(notes[[arg]]))
  paste0("Argument declared in the frozen v0.4.3 R function signature. ",
         "See this function's exact reference for accepted values, units, ",
         "and scientific interpretation.")
}
parameters_for <- function(name,backend,family){
 if(backend!="Native R")return(list())
 fn <- getExportedValue("eyetrajectories",name)
 stopifnot(is.function(fn))
 ff <- formals(fn)
 nms <- names(ff)
 lapply(nms,function(arg){
   expr <- ff[[arg]]
   default <- if(identical(expr,quote(expr=))) "(required)" else
     paste(deparse(expr,width.cutoff=120L),collapse=" ")
   if(nchar(default)>150L)default <- paste0(substr(default,1,147L),"...")
   list(name=arg,default=default,
        explanation=parameter_note(arg,family))
 })
}
entry <- function(name,backend){
  sp <- plot_spec[[name]]
  doc <- paste0("reference/",name,".html")
  has_doc <- file.exists(file.path("site",doc))
  list(name=name,title=gsub("_"," ",sub("^(etr_plot_|etpy_plot_|et_plot_)","",name)),
    category=category(name,strict=identical(backend,"Native R")),backend=backend,
    description=if(!is.null(sp))sp$description else if(backend=="Native R")
      "Exported native R plotting function. Consult the documented input and model assumptions." else
      "Optional Python-backed plotting interface; requires the separately installed Python backend.",
    doc=if(has_doc)doc else "reference/index.html",
    exactDoc=has_doc,variants=if(is.null(sp))list() else sp$variants,
    parameters=parameters_for(name,backend,category(name)))
}
catalog <- c(lapply(native,entry,backend="Native R"),
             lapply(bridge,entry,backend="Python-backed"))
stopifnot(length(unique(vapply(catalog,function(x)x$name,"")))==length(catalog))
json <- jsonlite::toJSON(catalog,auto_unbox=TRUE,null="null",digits=9)
writeLines(paste0("window.ET_PLOT_ATLAS_CATALOG=",json,";"),
  file.path(out,"catalog.js"),useBytes=TRUE)
png_count <- length(list.files(images,pattern="\\.png$"))
stopifnot(png_count>=108L)
script_count <- length(list.files(scripts_out,pattern="\\.R$"))
stopifnot(script_count==png_count,
          all(vapply(catalog[seq_along(native)],function(x)
            length(x$parameters)>=1L,logical(1L))),
          all(vapply(catalog[seq_along(native)],function(x)
            x$category%in%scientific_categories,logical(1L))))
writeLines(c("WAVE6_INTERACTIVE_ATLAS_AUDIT",
  "Source: immutable eyetrajectories v0.4.3 native API",
  paste("Native plotting functions:",length(native)),
  paste("Scientific method categories:",length(scientific_categories)),
  paste("Generated R reproduction scripts:",script_count),
  paste("Generated native R PNGs:",png_count),
  "Every native function has source-signature parameters; browser explanations are conservative and refer to exact documentation.",
  "Python-backed interfaces remain catalogued but are not executed.",
  "R images are precomputed; comparison is visual, not a controlled causal or inferential comparison.",
  "Scientific validation: rendering and browser checks do not independently validate estimation methods."),
  file.path(out,"WAVE6_AUDIT.txt"))
writeLines(c("eyetrajectories v0.4.3 actual native R plotting atlas",
  paste("Native plotting exports:",length(native)),
  paste("Python-backed plotting exports:",length(bridge)),
  paste("Directly illustrated exported native functions:",length(plot_spec)),
  paste("New additional native R plotting exports:",length(atlas_new_success)),
  paste("Wave 3 advanced inference functions:",length(wave3_pass)),
  paste("Wave 4 nonlinear dynamics functions:",length(wave4_pass)),
  paste("Wave 5 final native plotting functions:",length(wave5_pass)),
  paste("Unrendered additional fixture candidates:",length(atlas_new_failures)),
  paste("Native R generated PNG examples:",png_count),
  paste("Wave 6 scientific categories:",length(scientific_categories)),
  paste("Wave 6 downloadable R scripts:",script_count),
  "The searchable function inventory was generated from the actual NAMESPACE.",
  "All previews are direct output from exported native R plotting functions, not recreated JavaScript approximations.",
  "Synthetic data only; optional Python bridge never executed. No empirical validation claim."
),file.path(out,"MANIFEST.txt"))
message("NATIVE_PLOT_ATLAS_PASS native=",length(native),
  " bridge=",length(bridge)," direct=",length(plot_spec)," png=",png_count)
