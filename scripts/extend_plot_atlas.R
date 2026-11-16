# Additional real R plotting demonstrations, derived from the qualified v0.4.3 source.
# This is a website-only generator. No CRAN release source files are edited.
# It is sourced by scripts/build_plot_atlas.R after the nine initial examples.
atlas_new_success <- character()
atlas_new_failures <- character()
atlas_cache <- new.env(parent=emptyenv())
fixture <- function(key, fn) {
  if (!exists(key, envir=atlas_cache, inherits=FALSE))
    assign(key, fn(), envir=atlas_cache)
  get(key, envir=atlas_cache, inherits=FALSE)
}
register_native <- function(name, family, description, generate) {
  stopifnot(grepl("^etr_plot_",name),is.function(generate))
  tryCatch({
    variants <- generate()
    stopifnot(is.list(variants),length(variants)>0L,
              all(vapply(variants,function(x)is.list(x)&&
                all(c("label","image","code")%in%names(x)),logical(1L))))
    add(name,family,description,variants)
    atlas_new_success <<- c(atlas_new_success,name)
    message("NATIVE_ATLAS_ADDITION_PASS ",name," variants=",length(variants))
  },error=function(e){
    # No false preview is published. Drop orphan PNGs from a partly
    # completed generator before leaving the function Docs / API only.
    un <- list.files(images,full.names=TRUE,
       pattern=paste0("^",name,"__"))
    if(length(un))unlink(un)
    atlas_new_failures <<- c(atlas_new_failures,
      paste0(name,": ",conditionMessage(e)))
    message("NATIVE_ATLAS_ADDITION_NOT_YET_READY ",name,": ",
      conditionMessage(e))
  })
}
# All examples use the actual released native estimators to produce plotted
# objects. Every code string repeats the deterministic scientific inputs.
cv_code <- paste(path_code,
  "cv <- etr_cross_validate_fpca_reconstruction(paths,",
  "  candidate_components=1:3,n_splits=3L,shuffle=FALSE)",sep="\n")
register_native("etr_plot_fpca_cross_validation","Functional PCA",
  "Observed held-out FPCA reconstruction error by retained rank, computed by native three-fold cross-validation.",
  function(){
    cv <- fixture("crossvalidation",function()
      eyetrajectories::etr_cross_validate_fpca_reconstruction(paths,
        candidate_components=1:3,n_splits=3L,shuffle=FALSE))
    stopifnot(inherits(cv,"etr_fpca_cv"))
    list(v("etr_plot_fpca_cross_validation","3fold","Three held-out folds",
       function()eyetrajectories::etr_plot_fpca_cross_validation(cv),
       cv_code,"etr_plot_fpca_cross_validation(cv)"))
  })
register_native("etr_plot_reconstruction_curve","Functional PCA",
  "Mean integrated reconstruction RMSE derived from actual FPCA cross-validation folds.",
  function(){
    cv <- fixture("crossvalidation",function()
      eyetrajectories::etr_cross_validate_fpca_reconstruction(paths,
        candidate_components=1:3,n_splits=3L,shuffle=FALSE))
    s <- eyetrajectories::etr_summarise_fpca_cross_validation(cv)
    stopifnot(all(c("n_components","mean_rmse")%in%names(s)))
    tab <- data.frame(n_components=s$n_components,
                      mean_integrated_rmse=s$mean_rmse)
    list(v("etr_plot_reconstruction_curve","cv","CV reconstruction trend",
      function()eyetrajectories::etr_plot_reconstruction_curve(tab),
      paste(cv_code,
       "s <- etr_summarise_fpca_cross_validation(cv)",
       "tab <- data.frame(n_components=s$n_components,",
       "  mean_integrated_rmse=s$mean_rmse)",sep="\n"),
      "etr_plot_reconstruction_curve(tab)"))
  })
stability_code <- paste(path_code,
  "st <- etr_bootstrap_fpca_stability(paths,",
  "  n_bootstrap=30L,n_components=2L,random_state=410L)",sep="\n")
register_native("etr_plot_fpca_stability","Functional PCA",
  "Bootstrap-matched FPC similarities from thirty complete native R resampling fits; descriptive stability, not identification certainty.",
  function(){
    st <- fixture("stability",function()
      eyetrajectories::etr_bootstrap_fpca_stability(paths,
        n_bootstrap=30L,n_components=2L,random_state=410L))
    stopifnot(inherits(st,"etr_fpca_stability"))
    list(v("etr_plot_fpca_stability","bootstrap","Matched-component similarities",
      function()eyetrajectories::etr_plot_fpca_stability(st),
      stability_code,"etr_plot_fpca_stability(st)"))
  })
register_native("etr_plot_fpca_influence","Functional PCA",
  "Genuine leave-one-curve-out FPCA component similarity, with no observations automatically removed.",
  function(){
    influence <- fixture("fpca_influence",function()
      eyetrajectories::etr_leave_one_group_out_fpca_influence(
        paths,n_components=2L))
    stopifnot(inherits(influence,"etr_fpca_influence"))
    setup <- paste(path_code,
      "influence <- etr_leave_one_group_out_fpca_influence(",
      "  paths,n_components=2L)",sep="\n")
    list(
      v("etr_plot_fpca_influence","similarity","Minimum FPC similarity",
       function()eyetrajectories::etr_plot_fpca_influence(influence,
         metric="min_abs_component_similarity"),
       setup,'etr_plot_fpca_influence(influence,metric="min_abs_component_similarity")'),
      v("etr_plot_fpca_influence","score","Influence score",
       function()eyetrajectories::etr_plot_fpca_influence(influence,
         metric="influence_score"),
       setup,'etr_plot_fpca_influence(influence,metric="influence_score")'))
  })
register_native("etr_plot_fpca_outlier_diagnostics","Functional PCA",
  "Empirical score covariance and reconstruction-error flags from an actual fitted FPCA; flags are only review diagnostics.",
  function(){
    result <- fixture("fpca_outlier",function(){
      fitted <- eyetrajectories::etr_fit_fpca(paths,n_components=2L)
      eyetrajectories::etr_diagnose_fpca_outliers(
        fitted,paths,n_components=2L,score_covariance="empirical")
    })
    stopifnot(inherits(result,"etr_fpca_outliers"))
    list(v("etr_plot_fpca_outlier_diagnostics","review","Review score-space flags",
      function()eyetrajectories::etr_plot_fpca_outlier_diagnostics(result),
      paste(path_code,
       "fit <- etr_fit_fpca(paths,n_components=2L)",
       'diag <- etr_diagnose_fpca_outliers(fit,paths,n_components=2L,',
       '  score_covariance="empirical")',sep="\n"),
      "etr_plot_fpca_outlier_diagnostics(diag)"))
  })
register_native("etr_plot_fpca_component_envelope","Functional uncertainty",
  "Matched-bootstrap descriptive pointwise component-shape envelopes; not calibrated confidence bands.",
  function(){
    env <- fixture("fpca_component_envelope",function()
      eyetrajectories::etr_bootstrap_fpca_component_envelopes(paths,
        n_bootstrap=28L,n_components=2L,level=.90,random_state=411L))
    stopifnot(inherits(env,"etr_fpca_component_envelope"))
    list(v("etr_plot_fpca_component_envelope","90pct","90% matched-bootstrap envelope",
      function()eyetrajectories::etr_plot_fpca_component_envelope(env,
        component=0L,dimension="x"),
      paste(path_code,
       "env <- etr_bootstrap_fpca_component_envelopes(paths,",
       "  n_bootstrap=28L,n_components=2L,level=.90,random_state=411L)",sep="\n"),
      'etr_plot_fpca_component_envelope(env,component=0L,dimension="x")'))
  })
register_native("etr_plot_fpca_component_band","Functional uncertainty",
  "Real simultaneous observed-grid FPC bootstrap band, with the component matching performed by the native estimator.",
  function(){
    band <- fixture("fpca_component_band",function()
      eyetrajectories::etr_bootstrap_fpca_component_bands(paths,
        n_bootstrap=30L,n_components=2L,confidence_level=.90,
        random_state=412L))
    stopifnot(inherits(band,"etr_fpca_component_band"))
    list(v("etr_plot_fpca_component_band","90pct","90% simultaneous FPC band",
      function()eyetrajectories::etr_plot_fpca_component_band(band,
        component=0L,dimension="x"),
      paste(path_code,
       "band <- etr_bootstrap_fpca_component_bands(paths,",
       "  n_bootstrap=30L,n_components=2L,",
       "  confidence_level=.90,random_state=412L)",sep="\n"),
      'etr_plot_fpca_component_band(band,component=0L,dimension="x")'))
  })
register_native("etr_plot_functional_mean_band","Functional uncertainty",
  "Actual simultaneous Gaussian-multiplier functional mean-band estimator on the observed grid; experimental uncertainty.",
  function(){
    band <- fixture("multiplier_mean_band",function()
      eyetrajectories::etr_multiplier_functional_mean_band(paths,
        n_multiplier=100L,confidence_level=.90,random_state=413L))
    stopifnot(inherits(band,"etr_functional_mean_band"))
    setup <- paste(path_code,
      "band <- etr_multiplier_functional_mean_band(paths,",
      "  n_multiplier=100L,confidence_level=.90,random_state=413L)",sep="\n")
    list(v("etr_plot_functional_mean_band","channel_x","Channel x mean band",
      function()eyetrajectories::etr_plot_functional_mean_band(band,dimension="x"),
      setup,'etr_plot_functional_mean_band(band,dimension="x")'),
    v("etr_plot_functional_mean_band","channel_y","Channel y mean band",
      function()eyetrajectories::etr_plot_functional_mean_band(band,dimension="y"),
      setup,'etr_plot_functional_mean_band(band,dimension="y")'))
  })
embed_code <- paste(path_code,
  'delay <- etr_embedding_delay_diagnostics(paths,',
  '  curve=1L,dimension="x",max_lag=16L,bins=8L)',sep="\n")
register_native("etr_plot_embedding_delay_diagnostics","Recurrence & nonlinear",
  "Native average mutual information and autocorrelation by lag; exploratory embedding diagnostic.",
  function(){
    delay <- fixture("embedding_delay",function()
      eyetrajectories::etr_embedding_delay_diagnostics(paths,
        curve=1L,dimension="x",max_lag=16L,bins=8L))
    stopifnot(inherits(delay,"etr_embedding_delay_diagnostics"))
    list(v("etr_plot_embedding_delay_diagnostics","ami","Embedding lag sensitivity",
      function()eyetrajectories::etr_plot_embedding_delay_diagnostics(delay),
      embed_code,"etr_plot_embedding_delay_diagnostics(delay)"))
  })
register_native("etr_plot_embedding_dimension_diagnostics","Recurrence & nonlinear",
  "Observed false-nearest-neighbor diagnostics from the real native embedding routine.",
  function(){
    dimdiag <- fixture("embedding_dim",function()
      eyetrajectories::etr_embedding_dimension_diagnostics(paths,
        curve=1L,dimension="x",delay=2L,max_dimension=5L,
        theiler_window=2L))
    stopifnot(inherits(dimdiag,"etr_embedding_dimension_diagnostics"))
    list(v("etr_plot_embedding_dimension_diagnostics","fnn","False-nearest-neighbor fractions",
      function()eyetrajectories::etr_plot_embedding_dimension_diagnostics(dimdiag),
      paste(path_code,
       "dimdiag <- etr_embedding_dimension_diagnostics(paths,",
       '  curve=1L,dimension="x",delay=2L,max_dimension=5L,',
       "  theiler_window=2L)",sep="\n"),
      "etr_plot_embedding_dimension_diagnostics(dimdiag)"))
  })
register_native("etr_plot_recurrence_rate_curve","Recurrence & nonlinear",
  "Recomputed recurrence-rate profile over explicit fixed radii with the same Theiler exclusion.",
  function(){
    radii <- seq(.03,.45,length.out=10L)
    profile <- fixture("recurrence_radius",function()
      eyetrajectories::etr_recurrence_radius_profile(paths,curve=1L,
        radii=seq(.03,.45,length.out=10L),theiler_window=2L))
    stopifnot(inherits(profile,"etr_recurrence_radius_profile"))
    list(v("etr_plot_recurrence_rate_curve","radius","Recurrence radius profile",
      function()eyetrajectories::etr_plot_recurrence_rate_curve(profile),
      paste(path_code,
        "profile <- etr_recurrence_radius_profile(paths,curve=1L,",
        "  radii=seq(.03,.45,length.out=10L),theiler_window=2L)",sep="\n"),
      "etr_plot_recurrence_rate_curve(profile)"))
  })
register_native("etr_plot_windowed_rqa","Recurrence & nonlinear",
  "Actual sliding-window recurrence quantification computed across the synthetic trajectory.",
  function(){
    window <- fixture("windowed_rqa",function()
      eyetrajectories::etr_windowed_rqa(paths,curve=1L,
        window=30L,step=10L,radius=.20,theiler_window=2L))
    stopifnot(inherits(window,"etr_windowed_rqa"))
    setup <- paste(path_code,
      "window <- etr_windowed_rqa(paths,curve=1L,",
      "  window=30L,step=10L,radius=.20,theiler_window=2L)",sep="\n")
    list(v("etr_plot_windowed_rqa","rate","Sliding recurrence rate",
      function()eyetrajectories::etr_plot_windowed_rqa(window,
        metrics="recurrence_rate"),
      setup,'etr_plot_windowed_rqa(window,metrics="recurrence_rate")'),
    v("etr_plot_windowed_rqa","metrics","Recurrence rate and determinism",
      function()eyetrajectories::etr_plot_windowed_rqa(window,
        metrics=c("recurrence_rate","determinism")),
      setup,'etr_plot_windowed_rqa(window,metrics=c("recurrence_rate","determinism"))'))
  })
register_native("etr_plot_joint_recurrence","Recurrence & nonlinear",
  "Joint recurrence of two distinct synthetic trajectories, based on two actual R recurrence matrices.",
  function(){
    other <- eyetrajectories::etr_recurrence_matrix(paths,curve=2L,
      radius=.30,theiler=2L)
    joint <- eyetrajectories::etr_joint_recurrence_matrix(
      list(rec1,other),labels=c("path 1","path 2"))
    stopifnot(inherits(joint,"etr_joint_recurrence"))
    list(v("etr_plot_joint_recurrence","two_paths","Two-trajectory joint recurrence",
      function()eyetrajectories::etr_plot_joint_recurrence(joint),
      paste(path_code,
       "r1 <- etr_recurrence_matrix(paths,curve=1L,radius=.12,theiler=2L)",
       "r2 <- etr_recurrence_matrix(paths,curve=2L,radius=.30,theiler=2L)",
       'joint <- etr_joint_recurrence_matrix(list(r1,r2),labels=c("path 1","path 2"))',
       sep="\n"),
      "etr_plot_joint_recurrence(joint)"))
  })
register_native("etr_plot_trajectory_distance_rank_correlations",
  "Distances & alignment",
  "Rank agreement between actual integrated functional L2 and discrete Fréchet pairwise distances.",
  function(){
    sensitive <- eyetrajectories::etr_trajectory_distance_sensitivity(
      paths,list(list(name="L2",method="functional_l2"),
                 list(name="Frechet",method="discrete_frechet")),
      neighbor_k=2L)
    stopifnot(inherits(sensitive,"etr_trajectory_distance_sensitivity"))
    list(v("etr_plot_trajectory_distance_rank_correlations","metrics","Distance-rank agreement",
      function()eyetrajectories::etr_plot_trajectory_distance_rank_correlations(sensitive),
      paste(path_code,
        "sensitivity <- etr_trajectory_distance_sensitivity(paths,",
        '  list(list(name="L2",method="functional_l2"),',
        '       list(name="Frechet",method="discrete_frechet")),neighbor_k=2L)',sep="\n"),
      "etr_plot_trajectory_distance_rank_correlations(sensitivity)"))
  })
register_native("etr_plot_fpca_regression_cv","Functional PCA",
  "Held-out Gaussian functional-PC regression loss from a native, actual three-fold cross-validation fit.",
  function(){
    y <- vapply(seq_len(dim(paths$values)[1L]),
       function(i)sum(paths$values[i,,1L]*sin(2*pi*time)),numeric(1L))
    cv <- eyetrajectories::etr_cross_validate_fpca_regression(
      paths,outcome=y,candidate_components=1:2,n_splits=3L,
      family="gaussian",shuffle=FALSE)
    stopifnot(is.data.frame(cv$fold_losses))
    list(v("etr_plot_fpca_regression_cv","3fold","Gaussian FPCR three-fold CV",
      function()eyetrajectories::etr_plot_fpca_regression_cv(cv),
      paste(path_code,
       "y <- vapply(seq_len(dim(paths$values)[1L]),",
       "  function(i)sum(paths$values[i,,1L]*sin(2*pi*time)),numeric(1L))",
       "cv <- etr_cross_validate_fpca_regression(paths,outcome=y,",
       '  candidate_components=1:2,n_splits=3L,family="gaussian",',
       "  shuffle=FALSE)",sep="\n"),
      "etr_plot_fpca_regression_cv(cv)"))
  })

# Sparse observations and actual native PACE fit based on the stable test
# fixture in test-native-sparse-source-pace.R. No synthetic covariance heatmap.
irregular_code <- paste(c(
  "library(eyetrajectories)",
  "n <- 24L; ids <- sprintf('spn_%03d',seq_len(n))",
  "times <- values <- vector('list',n)",
  "for (i in seq_len(n)) {",
  "  j <- seq(0,1,length.out=8L)",
  "  ti <- .03+.94*j+.004*((i-1L)%%4L)*sin(pi*j)",
  "  x <- -.5+.18*ti+.35*sin(.31*i)*sin(pi*ti)+",
  "    .22*cos(.43*i)*cos(2*pi*ti)+.035*cos(3*pi*ti+.7*i)",
  "  times[[i]] <- ti; values[[i]] <- matrix(x,ncol=1L)",
  "}",
  "irregular <- etr_irregular_trajectory_set(",
  "  times,values,ids,'signal',",
  "  metadata=data.frame(batch=rep(1:6,each=4L)),",
  '  coordinate_system="degrees",time_unit="s")'
),collapse="\n")
make_irregular <- function() {
  n <- 24L; ids <- sprintf("spn_%03d",seq_len(n))
  times <- vals <- vector("list",n)
  for(i in seq_len(n)){
    j <- seq(0,1,length.out=8L)
    ti <- .03+.94*j+.004*((i-1L)%%4L)*sin(pi*j)
    x <- -.5+.18*ti+.35*sin(.31*i)*sin(pi*ti)+
      .22*cos(.43*i)*cos(2*pi*ti)+.035*cos(3*pi*ti+.7*i)
    times[[i]] <- ti;vals[[i]] <- matrix(x,ncol=1L)
  }
  eyetrajectories::etr_irregular_trajectory_set(times,vals,ids,
    "signal",metadata=data.frame(batch=rep(1:6,each=4L)),
    coordinate_system="degrees",time_unit="s")
}
register_native("etr_plot_sparse_irregular_dimension","Sparse observations",
  "Actual original per-curve sparse observation times, with no hidden interpolation.",
  function(){
    irregular <- fixture("irregular",make_irregular)
    stopifnot(inherits(irregular,"etr_irregular_trajectory_set"))
    list(v("etr_plot_sparse_irregular_dimension","signal","Irregular signal observations",
      function()eyetrajectories::etr_plot_sparse_irregular_dimension(irregular,
        dimension="signal"),
      irregular_code,'etr_plot_sparse_irregular_dimension(irregular,dimension="signal")'))
  })
pace_code <- paste(irregular_code,
 "fit <- etr_fit_sparse_fpca_native(irregular,'signal',n_components=1L,",
 "  evaluation_grid=seq(.08,.92,length.out=9L),",
 "  mean_bandwidth=.50,covariance_bandwidth=.85,",
 '  noise_variance_method="fixed",measurement_error_variance=.07,',
 '  analysis_support_action="restrict",psd_action="project",',
 "  score_ridge=.002,score_condition_limit=1e12,",
 "  mean_min_local_points=3L,covariance_min_local_pairs=6L)",sep="\n")
native_pace <- function() {
  irregular <- fixture("irregular",make_irregular)
  eyetrajectories::etr_fit_sparse_fpca_native(
    irregular,"signal",n_components=1L,
    evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
}
register_native("etr_plot_sparse_fpca_component","Sparse observations",
  "R-estimated sparse/PACE functional component from the native covariance smoother.",
  function(){
    pace <- fixture("native_pace",native_pace)
    stopifnot(inherits(pace,"etr_sparse_fpca_native"))
    list(v("etr_plot_sparse_fpca_component","sd1","Mean ±1 score SD",
      function()eyetrajectories::etr_plot_sparse_fpca_component(pace,
        component=0L,sd_multiplier=1),
      pace_code,"etr_plot_sparse_fpca_component(fit,component=0L,sd_multiplier=1)"),
    v("etr_plot_sparse_fpca_component","sd2","Mean ±2 score SD",
      function()eyetrajectories::etr_plot_sparse_fpca_component(pace,
        component=0L,sd_multiplier=2),
      pace_code,"etr_plot_sparse_fpca_component(fit,component=0L,sd_multiplier=2)"))
  })
register_native("etr_plot_sparse_fpca_covariance","Sparse observations",
  "Latent covariance estimated by an actual native sparse-functional covariance/PACE fit.",
  function(){
    pace <- fixture("native_pace",native_pace)
    stopifnot(inherits(pace,"etr_sparse_fpca_native"))
    list(v("etr_plot_sparse_fpca_covariance","latent","Estimated sparse covariance",
      function()eyetrajectories::etr_plot_sparse_fpca_covariance(pace),
      pace_code,"etr_plot_sparse_fpca_covariance(fit)"))
  })
register_native("etr_plot_sparse_fpca_score_diagnostics","Sparse observations",
  "Condition numbers for actual PACE score systems fitted on independent irregular observations.",
  function(){
    pace <- fixture("native_pace",native_pace)
    stopifnot(inherits(pace,"etr_sparse_fpca_native"))
    list(v("etr_plot_sparse_fpca_score_diagnostics","conditioning","PACE score conditioning",
      function()eyetrajectories::etr_plot_sparse_fpca_score_diagnostics(pace),
      pace_code,"etr_plot_sparse_fpca_score_diagnostics(fit)"))
  })
sim_code <- paste(c(
  "library(eyetrajectories)",
  "sim <- etr_simulate_functional_process(",
  "  mean=function(t)0*t,",
  "  eigenfunctions=list(function(t)sqrt(2)*sin(pi*t)),",
  "  eigenvalues=1,truth_grid=seq(0,1,length.out=41L),",
  "  n_participants=3L,trials_per_participant=2L,",
  '  dimension_names="value",coordinate_system="unknown",time_unit="s",',
  "  participant_eigenvalues=.2,trial_eigenvalues=.1,",
  "  measurement_noise_sd=.04,random_state=821L)"
),collapse="\n")
simulation <- function(){
  eyetrajectories::etr_simulate_functional_process(
    mean=function(t)0*t,
    eigenfunctions=list(function(t)sqrt(2)*sin(pi*t)),
    eigenvalues=1,truth_grid=seq(0,1,length.out=41L),
    n_participants=3L,trials_per_participant=2L,
    dimension_names="value",coordinate_system="unknown",time_unit="s",
    participant_eigenvalues=.2,trial_eigenvalues=.1,
    measurement_noise_sd=.04,random_state=821L)
}
register_native("etr_plot_functional_simulation_curve","Functional PCA",
  "Real latent simulation truth versus recorded noisy observations; never an interpolation of the observed curve.",
  function(){
    sim <- fixture("sim",simulation)
    stopifnot(inherits(sim,"etr_functional_simulation_result"))
    list(v("etr_plot_functional_simulation_curve","curve1","First simulated curve",
      function()eyetrajectories::etr_plot_functional_simulation_curve(sim,
        curve=1L,dimension="value"),
      sim_code,'etr_plot_functional_simulation_curve(sim,curve=1L,dimension="value")'),
    v("etr_plot_functional_simulation_curve","curve2","Second simulated curve",
      function()eyetrajectories::etr_plot_functional_simulation_curve(sim,
        curve=2L,dimension="value"),
      sim_code,'etr_plot_functional_simulation_curve(sim,curve=2L,dimension="value")'))
  })
register_native("etr_plot_functional_simulation_phase_warps","Distances & alignment",
  "Source-recorded phase warps on the simulation truth grid (identity under the declared no-warp design).",
  function(){
    sim <- fixture("sim",simulation)
    list(v("etr_plot_functional_simulation_phase_warps","phase","Declared phase-warp geometry",
      function()eyetrajectories::etr_plot_functional_simulation_phase_warps(
        sim,max_curves=6L,alpha=.65),
      sim_code,"etr_plot_functional_simulation_phase_warps(sim,max_curves=6L,alpha=.65)"))
  })
register_native("etr_plot_functional_simulation_score_variances","Functional PCA",
  "Declared versus empirically realized score variances from the original multilevel functional simulation.",
  function(){
    sim <- fixture("sim",simulation)
    list(v("etr_plot_functional_simulation_score_variances","levels","Score-variance decomposition",
      function()eyetrajectories::etr_plot_functional_simulation_score_variances(sim),
      sim_code,"etr_plot_functional_simulation_score_variances(sim)"))
  })

# Produce transparent evidence: a skipped fixture never receives a fake image.
writeLines(c(
  paste("Additional direct native R plot exports:",length(atlas_new_success)),
  if(length(atlas_new_success)) paste("PASS",atlas_new_success) else "NO ADDITIONS",
  paste("Unrendered candidates:",length(atlas_new_failures)),
  atlas_new_failures
),file.path(out,"EXTENSION_AUDIT.txt"))
message("NATIVE_PLOT_ATLAS_EXTENSION_REPORT successful=",length(atlas_new_success),
  " unsuccessful=",length(atlas_new_failures))
if(length(atlas_new_success)<12L)
  stop("Too few new verified R plotting exports: ",
       length(atlas_new_success),
       " (expected at least 12); investigate EXTENSION_AUDIT.txt")
