# Second scientific plotting expansion: additional actual native R workflows.
# Uses register_native(), fixture(), v(), paths, time and path_code from
# the earlier website-only generators. Any failed candidate is docs-only.
subspace_setup <- paste(path_code,
  "sub <- etr_bootstrap_fpca_subspace_stability(paths,",
  "  start_component=0L,n_components=2L,",
  "  n_bootstrap=28L,random_state=430L)",sep="\n")
register_native("etr_plot_fpca_subspace_stability","Functional PCA",
 "Bootstrap-matched 2D FPCA subspace diagnostics: projector distance and largest principal angle.",
 function(){
   obj <- fixture("subspace_stability",function()
     eyetrajectories::etr_bootstrap_fpca_subspace_stability(
       paths,start_component=0L,n_components=2L,
       n_bootstrap=28L,random_state=430L))
   stopifnot(inherits(obj,"etr_fpca_subspace_stability"))
   list(v("etr_plot_fpca_subspace_stability","projector",
     "Normalized projector distance",
     function()eyetrajectories::etr_plot_fpca_subspace_stability(
       obj,metric="normalized_projector_distance"),
     subspace_setup,'etr_plot_fpca_subspace_stability(sub,metric="normalized_projector_distance")'),
   v("etr_plot_fpca_subspace_stability","angle",
     "Maximum principal angle (degrees)",
     function()eyetrajectories::etr_plot_fpca_subspace_stability(
       obj,metric="max_principal_angle_degrees"),
     subspace_setup,'etr_plot_fpca_subspace_stability(sub,metric="max_principal_angle_degrees")'))
 })
score_setup <- paste(path_code,
 "score <- etr_bootstrap_fpca_score_uncertainty(paths,",
 "  n_bootstrap=30L,n_components=2L,level=.90,random_state=431L)",sep="\n")
register_native("etr_plot_fpca_score_uncertainty","Functional uncertainty",
 "Matched-basis resampling uncertainty of actual native FPC scores for fixed target curves.",
 function(){
   score <- fixture("score_uncertainty",function()
     eyetrajectories::etr_bootstrap_fpca_score_uncertainty(
       paths,n_bootstrap=30L,n_components=2L,level=.90,random_state=431L))
   stopifnot(inherits(score,"etr_fpca_score_uncertainty"))
   list(v("etr_plot_fpca_score_uncertainty","fpc1","First FPC scores",
       function()eyetrajectories::etr_plot_fpca_score_uncertainty(
         score,component=0L,max_targets=12L),
       score_setup,"etr_plot_fpca_score_uncertainty(score,component=0L,max_targets=12L)"),
     v("etr_plot_fpca_score_uncertainty","fpc2","Second FPC scores",
       function()eyetrajectories::etr_plot_fpca_score_uncertainty(
         score,component=1L,max_targets=12L),
       score_setup,"etr_plot_fpca_score_uncertainty(score,component=1L,max_targets=12L)"))
 })
spectrum_setup <- paste(path_code,
 "spectrum <- etr_bootstrap_fpca_spectrum_uncertainty(paths,",
 "  n_bootstrap=30L,n_components=2L,",
 "  confidence_level=.90,random_state=432L)",sep="\n")
register_native("etr_plot_fpca_spectrum_uncertainty","Functional uncertainty",
 "True FPC spectrum bootstrap bounds on the observed grid, with explicitly selected eigenvalue or variance-ratio scales.",
 function(){
   spec <- fixture("spectrum_uncertainty",function()
     eyetrajectories::etr_bootstrap_fpca_spectrum_uncertainty(
       paths,n_bootstrap=30L,n_components=2L,
       confidence_level=.90,random_state=432L))
   stopifnot(inherits(spec,"etr_fpca_spectrum_uncertainty"))
   list(v("etr_plot_fpca_spectrum_uncertainty","ratio",
     "Explained variance ratio",
     function()eyetrajectories::etr_plot_fpca_spectrum_uncertainty(
       spec,metric="explained_variance_ratio"),
     spectrum_setup,'etr_plot_fpca_spectrum_uncertainty(spectrum,metric="explained_variance_ratio")'),
     v("etr_plot_fpca_spectrum_uncertainty","eigen",
     "Eigenvalue uncertainty",
     function()eyetrajectories::etr_plot_fpca_spectrum_uncertainty(
       spec,metric="eigenvalue"),
     spectrum_setup,'etr_plot_fpca_spectrum_uncertainty(spectrum,metric="eigenvalue")'))
 })

# Source-tested native multivariate sparse/PACE fit. The two-dimensional
# covariance blocks are estimated, never fabricated or copied from another plot.
sparse2_code <- paste(c(
  "library(eyetrajectories)",
  "grid <- seq(0,1,length.out=11L)",
  "w <- etr_trapezoid_weights(grid)",
  "scale <- sqrt(2*sum((grid-.5)^2*w))",
  "modes <- list(",
  " function(t)matrix(1/sqrt(2),length(t),2L),",
  " function(t)cbind((t-.5)/scale,(.5-t)/scale))",
  "sim <- etr_simulate_functional_process(",
  " mean=function(t)matrix(0,length(t),2L),",
  " eigenfunctions=modes,eigenvalues=c(2,.6),",
  " truth_grid=grid,n_participants=18L,",
  ' dimension_names=c("x","y"),observation_design="irregular",',
  " observation_times=rep(list(grid),18L),",
  " measurement_noise_sd=sqrt(.05),random_state=42L)",
  "joint <- etr_fit_sparse_mfpca_native(sim$observations,",
  " n_components=2L,evaluation_grid=grid,",
  " mean_bandwidth=.45,covariance_bandwidth=.65,",
  ' measurement_error_variance=rep(.05,2L),psd_action="project")'
),collapse="\n")
make_sparse2 <- function(){
  grid <- seq(0,1,length.out=11L)
  w <- eyetrajectories::etr_trapezoid_weights(grid)
  scale <- sqrt(2*sum((grid-.5)^2*w))
  modes <- list(
    function(t)matrix(1/sqrt(2),length(t),2L),
    function(t)cbind((t-.5)/scale,(.5-t)/scale))
  sim <- eyetrajectories::etr_simulate_functional_process(
    mean=function(t)matrix(0,length(t),2L),
    eigenfunctions=modes,eigenvalues=c(2,.6),
    truth_grid=grid,n_participants=18L,
    dimension_names=c("x","y"),
    observation_design="irregular",
    observation_times=rep(list(grid),18L),
    measurement_noise_sd=sqrt(.05),random_state=42L)
  eyetrajectories::etr_fit_sparse_mfpca_native(
    sim$observations,n_components=2L,evaluation_grid=grid,
    mean_bandwidth=.45,covariance_bandwidth=.65,
    measurement_error_variance=rep(.05,2L),
    psd_action="project")
}
register_native("etr_plot_sparse_mfpca_component","Sparse observations",
 "Actual joint x/y sparse multivariate FPCA component modes, fitted from simulated observed data.",
 function(){
   joint <- fixture("sparse_mfpca",make_sparse2)
   stopifnot(inherits(joint,"etr_sparse_mfpca_source"))
   list(v("etr_plot_sparse_mfpca_component","component1","First multivariate component",
     function()eyetrajectories::etr_plot_sparse_mfpca_component(joint,component=0L),
     sparse2_code,"etr_plot_sparse_mfpca_component(joint,component=0L)"),
     v("etr_plot_sparse_mfpca_component","component2","Second multivariate component",
     function()eyetrajectories::etr_plot_sparse_mfpca_component(joint,component=1L),
     sparse2_code,"etr_plot_sparse_mfpca_component(joint,component=1L)"))
 })
register_native("etr_plot_sparse_mfpca_covariance_blocks","Sparse observations",
 "All four covariance blocks of the real native sparse multivariate FPCA fit.",
 function(){
   joint <- fixture("sparse_mfpca",make_sparse2)
   stopifnot(inherits(joint,"etr_sparse_mfpca_source"))
   list(v("etr_plot_sparse_mfpca_covariance_blocks","estimated","Joint covariance blocks",
     function()eyetrajectories::etr_plot_sparse_mfpca_covariance_blocks(joint),
     sparse2_code,"etr_plot_sparse_mfpca_covariance_blocks(joint)"))
 })
register_native("etr_plot_sparse_mfpca_cross_covariance","Sparse observations",
 "The estimated x-to-y cross-covariance structure from the same native multivariate sparse functional fit.",
 function(){
   joint <- fixture("sparse_mfpca",make_sparse2)
   stopifnot(inherits(joint,"etr_sparse_mfpca_source"))
   list(v("etr_plot_sparse_mfpca_cross_covariance","estimated","Cross-channel covariance",
     function()eyetrajectories::etr_plot_sparse_mfpca_cross_covariance(joint),
     sparse2_code,"etr_plot_sparse_mfpca_cross_covariance(joint)"))
 })
register_native("etr_plot_sparse_mfpca_score_diagnostics","Sparse observations",
 "Observed joint-PACE score-conditioning diagnostics from the actual sparse multivariate fit.",
 function(){
   joint <- fixture("sparse_mfpca",make_sparse2)
   stopifnot(inherits(joint,"etr_sparse_mfpca_source"))
   list(v("etr_plot_sparse_mfpca_score_diagnostics","conditioning","Joint-PACE conditioning",
     function()eyetrajectories::etr_plot_sparse_mfpca_score_diagnostics(joint),
     sparse2_code,"etr_plot_sparse_mfpca_score_diagnostics(joint)"))
 })

# A source-tested restricted functional mixed-moment model, not REML.
mixed_setup <- paste(c(
  "library(eyetrajectories)",
  "n <- 18L; tt <- seq(0,1,length.out=17L)",
  'groups <- rep(sprintf("p%02d",1:6),each=3L)',
  "z <- rep(c(-1,0,1),6L)+rep((1:6-3.5)/10,each=3L)",
  "Y <- array(0,c(n,length(tt),1L))",
  "for(i in seq_len(n)){",
  "  g <- match(groups[i],unique(groups))",
  "  Y[i,,1L] <- 1+.55*sin(pi*tt)+.7*z[i]*cos(pi*tt)+",
  "   .15*g*sin(2*pi*tt)+.1*sin(6*pi*tt+.4*i)+",
  "   .05*cos(3*pi*tt+i*.7)+.025*i*tt",
  "}",
  'x <- etr_trajectory_set(tt,Y,sprintf("c%02d",1:n),"x",',
  '  metadata=data.frame(participant_id=groups),time_unit="s",',
  '  coordinate_system="normalized")',
  "design <- data.frame(curve_id=x$curve_ids,exposure=z)",
  "mixed <- etr_fit_functional_mixed_effects_regression(x,design,",
  '  predictors="exposure",participant_column="participant_id",',
  '  dimension="x")'
),collapse="\n")
make_mixed <- function(){
  n<-18L;tt<-seq(0,1,length.out=17L)
  groups<-rep(sprintf("p%02d",1:6),each=3L)
  z<-rep(c(-1,0,1),6L)+rep((1:6-3.5)/10,each=3L)
  Y<-array(0,c(n,length(tt),1L))
  for(i in seq_len(n)){
    g<-match(groups[i],unique(groups))
    Y[i,,1L]<-1+.55*sin(pi*tt)+.7*z[i]*cos(pi*tt)+
      .15*g*sin(2*pi*tt)+.1*sin(6*pi*tt+.4*i)+
      .05*cos(3*pi*tt+i*.7)+.025*i*tt
  }
  x<-eyetrajectories::etr_trajectory_set(tt,Y,
    sprintf("c%02d",1:n),"x",
    metadata=data.frame(participant_id=groups),
    time_unit="s",coordinate_system="normalized")
  design<-data.frame(curve_id=x$curve_ids,exposure=z)
  eyetrajectories::etr_fit_functional_mixed_effects_regression(
    x,design,predictors="exposure",
    participant_column="participant_id",dimension="x")
}
register_native("etr_plot_functional_mixed_effects_coefficient","Functional uncertainty",
 "Restricted functional mixed-effects moment coefficients with pointwise Wald intervals; not REML and not simultaneous.",
 function(){
   m<-fixture("mixed",make_mixed)
   stopifnot(inherits(m,"etr_functional_mixed_moments"))
   list(v("etr_plot_functional_mixed_effects_coefficient","exposure","Exposure coefficient",
     function()eyetrajectories::etr_plot_functional_mixed_effects_coefficient(
       m,coefficient="exposure"),mixed_setup,
     'etr_plot_functional_mixed_effects_coefficient(mixed,coefficient="exposure")'),
   v("etr_plot_functional_mixed_effects_coefficient","intercept","Intercept coefficient",
     function()eyetrajectories::etr_plot_functional_mixed_effects_coefficient(
       m,coefficient="Intercept"),mixed_setup,
     'etr_plot_functional_mixed_effects_coefficient(mixed,coefficient="Intercept")'))
 })
register_native("etr_plot_functional_variance_decomposition","Functional uncertainty",
 "Actual participant-intercept and residual variance decomposition from a restricted functional mixed-moment estimator.",
 function(){
   m<-fixture("mixed",make_mixed)
   list(v("etr_plot_functional_variance_decomposition","components","Moment-based variance components",
     function()eyetrajectories::etr_plot_functional_variance_decomposition(m),
     mixed_setup,"etr_plot_functional_variance_decomposition(mixed)"))
 })
mixed_diag_setup <- paste(mixed_setup,
   "diagnostics <- etr_functional_mixed_effects_residual_diagnostics(",
   "  mixed,max_lag=4L)",sep="\n")
register_native("etr_plot_functional_mixed_effects_residual_acf","Functional uncertainty",
 "Residual autocorrelation calculated from the fitted restricted mixed-effects model at original lags.",
 function(){
   m<-fixture("mixed",make_mixed)
   d<-fixture("mixed_diagnostics",function()
     eyetrajectories::etr_functional_mixed_effects_residual_diagnostics(
       m,max_lag=4L))
   list(v("etr_plot_functional_mixed_effects_residual_acf","overall","Residual ACF by lag",
     function()eyetrajectories::etr_plot_functional_mixed_effects_residual_acf(d),
     mixed_diag_setup,"etr_plot_functional_mixed_effects_residual_acf(diagnostics)"))
 })
register_native("etr_plot_functional_mixed_effects_residual_variogram","Functional uncertainty",
 "Residual semivariance/variogram diagnostic from genuine mixed-effects model residuals.",
 function(){
   m<-fixture("mixed",make_mixed)
   d<-fixture("mixed_diagnostics",function()
     eyetrajectories::etr_functional_mixed_effects_residual_diagnostics(
       m,max_lag=4L))
   list(v("etr_plot_functional_mixed_effects_residual_variogram","overall","Residual variogram by lag",
     function()eyetrajectories::etr_plot_functional_mixed_effects_residual_variogram(d),
     mixed_diag_setup,"etr_plot_functional_mixed_effects_residual_variogram(diagnostics)"))
 })

# Nonlinear recurrence, Poincare crossings, registration and nested FPCR.
rqa_code <- paste(path_code,
 "rqa <- etr_rqa_parameter_sensitivity(",
 '  paths,curve="synthetic_1",dimensions=c("x","y"),',
 "  embedding_dimensions=2L,delays=1L,",
 "  theiler_windows=2L,radii=c(.20,.35,.50),",
 "  min_diagonal_lengths=2L,min_vertical_lengths=2L)",sep="\n")
register_native("etr_plot_rqa_sensitivity","Recurrence & nonlinear",
 "Full fixed-radius native recurrence sensitivity grid; varying only the declared radius.",
 function(){
   rqa<-fixture("rqa_grid",function()
     eyetrajectories::etr_rqa_parameter_sensitivity(
       paths,curve="synthetic_1",dimensions=c("x","y"),
       embedding_dimensions=2L,delays=1L,
       theiler_windows=2L,radii=c(.20,.35,.50),
       min_diagonal_lengths=2L,min_vertical_lengths=2L))
   stopifnot(inherits(rqa,"etr_rqa_parameter_sensitivity"))
   list(v("etr_plot_rqa_sensitivity","radius","Recurrence rate by radius",
      function()eyetrajectories::etr_plot_rqa_sensitivity(rqa,
        parameter="requested_radius",metric="recurrence_rate"),
      rqa_code,'etr_plot_rqa_sensitivity(rqa,parameter="requested_radius",metric="recurrence_rate")'))
 })
poincare_setup <- paste(c(
 "library(eyetrajectories)",
 "tt <- seq(0,1,length.out=301L)",
 "state <- array(0,c(1L,length(tt),2L))",
 "state[1,,1L] <- sin(12*pi*tt)",
 "state[1,,2L] <- cos(12*pi*tt)+.05*tt+.02*sin(4*pi*tt)",
 'trajectory <- etr_trajectory_set(tt,state,"cycle_1",c("x","y"),',
 '  coordinate_system="arbitrary",time_unit="s")',
 'crossings <- etr_poincare_crossings(trajectory,curve=1L,',
 '  section_dimension="x",section_value=0,direction="positive",',
 '  state_dimensions="y")'
),collapse="\n")
register_native("etr_plot_poincare_return_map","Recurrence & nonlinear",
 "Successive crossing states from six explicit oscillation cycles, using the native Poincare section algorithm.",
 function(){
   tt<-seq(0,1,length.out=301L)
   state<-array(0,c(1L,length(tt),2L))
   state[1,,1L]<-sin(12*pi*tt)
   state[1,,2L]<-cos(12*pi*tt)+.05*tt+.02*sin(4*pi*tt)
   trajectory<-eyetrajectories::etr_trajectory_set(
     tt,state,"cycle_1",c("x","y"),
     coordinate_system="arbitrary",time_unit="s")
   crossing<-eyetrajectories::etr_poincare_crossings(
     trajectory,curve=1L,section_dimension="x",
     section_value=0,direction="positive",state_dimensions="y")
   stopifnot(inherits(crossing,"etr_poincare_crossings"),nrow(crossing$states)>=3L)
   list(v("etr_plot_poincare_return_map","crossings","Successive section crossings",
     function()eyetrajectories::etr_plot_poincare_return_map(crossing),
     poincare_setup,"etr_plot_poincare_return_map(crossings)"))
 })
register_native("etr_plot_windowed_rqa_trajectories","Recurrence & nonlinear",
 "Functional recurrence-rate curves for individual synthetic trials with an explicit across-curve mean.",
 function(){
   q<-eyetrajectories::etr_windowed_rqa_trajectory_set(
     paths,metrics="recurrence_rate",window=30L,
     step=10L,radius=.20,theiler_window=2L,undefined_policy="keep")
   stopifnot(inherits(q,"etr_windowed_rqa_functional"))
   setup<-paste(path_code,
     'q <- etr_windowed_rqa_trajectory_set(paths,metrics="recurrence_rate",',
     '  window=30L,step=10L,radius=.20,theiler_window=2L,',
     '  undefined_policy="keep")',sep="\n")
   list(v("etr_plot_windowed_rqa_trajectories","trials","Trial-level recurrence profiles",
     function()eyetrajectories::etr_plot_windowed_rqa_trajectories(q,
       metric="recurrence_rate",show_mean=TRUE,max_curves=8L),
     setup,'etr_plot_windowed_rqa_trajectories(q,metric="recurrence_rate",show_mean=TRUE,max_curves=8L)'))
 })
reg_setup<-paste(c(
  "library(eyetrajectories)",
  "tt <- as.numeric(0:6)",
  "vals <- array(0,c(2L,length(tt),1L))",
  "vals[1L,,1L] <- sin(tt/3)",
  "vals[2L,,1L] <- cos(tt/3)",
  'x <- etr_trajectory_set(tt,vals,c("a","b"),"x",',
  '  coordinate_system="arbitrary",time_unit="s")',
  "registered <- etr_register_landmarks(x,",
  "  source_landmarks=matrix(c(2,4),nrow=2L,ncol=1L),",
  "  target_landmarks=3)"
),collapse="\n")
make_registration <- function(){
   tt<-as.numeric(0:6)
   vals<-array(0,c(2L,length(tt),1L))
   vals[1L,,1L]<-sin(tt/3)
   vals[2L,,1L]<-cos(tt/3)
   x<-eyetrajectories::etr_trajectory_set(
     tt,vals,c("a","b"),"x",
     coordinate_system="arbitrary",time_unit="s")
   eyetrajectories::etr_register_landmarks(
     x,source_landmarks=matrix(c(2,4),nrow=2L,ncol=1L),
     target_landmarks=3)
}
register_native("etr_plot_registration","Distances & alignment",
 "Actual landmark alignment of two synthetic curves; before versus registered coordinates.",
 function(){
   r<-fixture("landmark_registration",make_registration)
   list(v("etr_plot_registration","aligned","Before and after alignment",
     function()eyetrajectories::etr_plot_registration(r,dimension="x"),
     reg_setup,'etr_plot_registration(registered,dimension="x")'))
 })
register_native("etr_plot_warping_functions","Distances & alignment",
 "Native learned landmark time-warp functions, comparing source times and displacement from identity.",
 function(){
   r<-fixture("landmark_registration",make_registration)
   list(v("etr_plot_warping_functions","warp","Warped source time",
     function()eyetrajectories::etr_plot_warping_functions(r,displacement=FALSE),
     reg_setup,"etr_plot_warping_functions(registered,displacement=FALSE)"),
   v("etr_plot_warping_functions","displacement","Warp displacement",
     function()eyetrajectories::etr_plot_warping_functions(r,displacement=TRUE),
     reg_setup,"etr_plot_warping_functions(registered,displacement=TRUE)"))
 })

nested_setup <- paste(path_code,
  "y <- vapply(seq_len(dim(paths$values)[1L]),",
  " function(i)sum(paths$values[i,,1L]*sin(2*pi*time)),numeric(1L))",
  "nested <- etr_nested_cross_validate_fpca_regression(paths,outcome=y,",
  " candidate_components=1:2,outer_splits=3L,inner_splits=2L,",
  ' family="gaussian",shuffle=FALSE)',sep="\n")
register_native("etr_plot_nested_fpca_regression_cv","Functional PCA",
 "True nested FPCR cross-validation with separate outer and inner folds, calculated from an actual native estimator.",
 function(){
   y<-vapply(seq_len(dim(paths$values)[1L]),
     function(i)sum(paths$values[i,,1L]*sin(2*pi*time)),numeric(1L))
   nested<-eyetrajectories::etr_nested_cross_validate_fpca_regression(
     paths,outcome=y,candidate_components=1:2,
     outer_splits=3L,inner_splits=2L,family="gaussian",shuffle=FALSE)
   list(v("etr_plot_nested_fpca_regression_cv","folds","Nested held-out regression losses",
     function()eyetrajectories::etr_plot_nested_fpca_regression_cv(nested),
     nested_setup,"etr_plot_nested_fpca_regression_cv(nested)"))
 })

writeLines(c(
 paste("Additional direct native R plot exports across both extensions:",
   length(atlas_new_success)),
 if(length(atlas_new_success))paste("PASS",atlas_new_success),
 paste("Unrendered candidate exports:",length(atlas_new_failures)),
 atlas_new_failures),
 file.path(out,"EXTENSION_AUDIT.txt"))
message("NATIVE_PLOT_ATLAS_SECOND_WAVE_REPORT successful=",length(atlas_new_success),
 " unsuccessful=",length(atlas_new_failures))
