# eyetrajectories native plotting atlas, Wave 3: advanced inference.
# WEBSITE-ONLY code executed against immutable GitHub v0.4.3.
# We execute the exported R plotting functions, not JavaScript imitations.
# All estimators and fixed scientific-record demonstrations use synthetic data.
# Classify illustrated records honestly; rendering != coverage calibration.
wave3_required <- c(
 "etr_plot_fpca_regression_future_prediction_interval",
 "etr_plot_fpca_regression_mean_prediction_uncertainty",
 "etr_plot_fpca_regression_slope_band",
 "etr_plot_fpca_regression_slope_uncertainty",
 "etr_plot_fpca_wild_bootstrap_projection",
 "etr_plot_fpca_wild_bootstrap_simultaneous_interval",
 "etr_plot_fpca_wild_bootstrap_family_test",
 "etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
 "etr_plot_fpca_wild_bootstrap_truncation_scan",
 "etr_plot_conformal_fpca_anomaly",
 "etr_plot_covariance_sensitivity_coefficients",
 "etr_plot_covariance_sensitivity_band_widths",
 "etr_plot_functional_mixed_effects_bootstrap_comparison",
 "etr_plot_generalized_function_on_scalar_predictions")
wave3_pass <- character()
wave3_failed <- character()
reg3 <- function(name, family, desc, build) {
 stopifnot(name %in% wave3_required, !name %in% names(plot_spec))
 before <- atlas_new_success
 register_native(name, family,desc,build)
 if(name %in% setdiff(atlas_new_success,before)) {
   wave3_pass <<- c(wave3_pass,name)
 } else {
   wave3_failed <<- c(wave3_failed,name)
 }
}
# Copy-paste R reproduction for precomputed synthetic source geometry.
# Such records demonstrate the plotting contract; they are not inferential
# estimates and may NOT be described as calibrated statistical results.
record_setup <- function(obj, var="result") {
 paste0("library(eyetrajectories)\n",var," <- ",
   paste(capture.output(dput(obj)),collapse="\n"))
}
fpcr_setup <- paste(c(
 "library(eyetrajectories)",
 "n <- 14L; tt <- seq(0,1,length.out=15L)",
 "val <- array(0,c(n,length(tt),1L))",
 "for(i in seq_len(n)) val[i,,1L] <-",
 "  sin(pi*tt)*(1+i/16)+.16*cos(2*pi*tt)*(i%%4)/3+tt*i/18",
 'x <- etr_trajectory_set(tt,val,sprintf("c%02d",1:n),"gaze",',
 '  coordinate_system="normalized",time_unit="s")',
 "y <- .2+1.2*seq_len(n)/n+.2*sin(seq_len(n))",
 "u <- etr_bootstrap_fpca_regression_uncertainty(",
 "  x,y,n_bootstrap=20L,n_components=1L,random_state=123L)"
),collapse="\n")
make_fpcr <- function(){
 n<-14L;tt<-seq(0,1,length.out=15L)
 val<-array(0,c(n,length(tt),1L))
 for(i in seq_len(n))val[i,,1L]<-
   sin(pi*tt)*(1+i/16)+.16*cos(2*pi*tt)*(i%%4)/3+tt*i/18
 x<-eyetrajectories::etr_trajectory_set(tt,val,
   sprintf("c%02d",seq_len(n)),"gaze",
   coordinate_system="normalized",time_unit="s")
 y<-.2+1.2*seq_len(n)/n+.2*sin(seq_len(n))
 u<-eyetrajectories::etr_bootstrap_fpca_regression_uncertainty(
   x,y,n_bootstrap=20L,n_components=1L,random_state=123L)
 list(x=x,y=y,u=u)
}
reg3("etr_plot_fpca_regression_mean_prediction_uncertainty",
 "Functional uncertainty",
 "Actual paired full-refit Gaussian FPCR bootstrap percentile intervals for a fixed conditional mean; marginal per-target intervals, not future noisy outcomes or simultaneous coverage.",
 function(){
   a<-fixture("wave3_fpcr",make_fpcr)
   list(v("etr_plot_fpca_regression_mean_prediction_uncertainty","conditional_mean",
    "Conditional-mean bootstrap percentiles",
    function()eyetrajectories::etr_plot_fpca_regression_mean_prediction_uncertainty(a$u,max_targets=8L),
    fpcr_setup,
    "etr_plot_fpca_regression_mean_prediction_uncertainty(u,max_targets=8L)"))
 })
reg3("etr_plot_fpca_regression_future_prediction_interval",
 "Functional uncertainty",
 "Actual native resampling of centered Gaussian FPCR residuals on top of paired conditional-mean draws. Marginal future noisy outcomes only; NOT conditional-mean intervals or simultaneous across targets.",
 function(){
   a<-fixture("wave3_fpcr",make_fpcr)
   pred<-eyetrajectories::etr_fpca_regression_future_prediction_interval(
      a$u,a$y,confidence_level=.90,random_state=124L)
   list(v("etr_plot_fpca_regression_future_prediction_interval","future",
     "Marginal 90% future-outcome prediction",
     function()eyetrajectories::etr_plot_fpca_regression_future_prediction_interval(pred,max_targets=8L),
     paste(fpcr_setup,"pred <- etr_fpca_regression_future_prediction_interval(u,y,",
        "  confidence_level=.90,random_state=124L)",sep="\n"),
     "etr_plot_fpca_regression_future_prediction_interval(pred,max_targets=8L)"))
 })
reg3("etr_plot_fpca_regression_slope_uncertainty",
 "Functional uncertainty",
 "Native paired-refit pointwise percentile slope intervals; only the observed time grid, not a simultaneous function-wide band.",
 function(){
  a<-fixture("wave3_fpcr",make_fpcr)
  list(v("etr_plot_fpca_regression_slope_uncertainty","pointwise",
   "Pointwise 95% slope uncertainty",
   function()eyetrajectories::etr_plot_fpca_regression_slope_uncertainty(a$u,dimension="gaze"),
   fpcr_setup,'etr_plot_fpca_regression_slope_uncertainty(u,dimension="gaze")'))
 })
reg3("etr_plot_fpca_regression_slope_band",
 "Functional uncertainty",
 "Studentized bootstrap maximum simultaneously over observed time points; no claims for between-grid coverage, arbitrary functional contrasts, or independent scientific calibration.",
 function(){
  a<-fixture("wave3_fpcr",make_fpcr)
  b<-eyetrajectories::etr_fpca_regression_slope_simultaneous_band(
    a$u,confidence_level=.90,simultaneous_scope="global")
  list(v("etr_plot_fpca_regression_slope_band","simultaneous",
   "90% observed-grid simultaneous slope band",
   function()eyetrajectories::etr_plot_fpca_regression_slope_band(b,dimension="gaze"),
   paste(fpcr_setup,'b <- etr_fpca_regression_slope_simultaneous_band(u,',
       '  confidence_level=.90,simultaneous_scope="global")',sep="\n"),
   'etr_plot_fpca_regression_slope_band(b,dimension="gaze")'))
 })
wild_setup <- paste(c(
 "library(eyetrajectories)",
 "n <- 24L;tt <- seq(0,1,length.out=13L)",
 "val <- array(0,c(n,length(tt),1L))",
 "for(i in seq_len(n)) val[i,,1L] <- .25*sin(2*pi*tt)+",
 " .13*cos(i*.8)*cos(pi*tt)+.09*sin(i*.57)*sin(3*pi*tt)+",
 " .07*cos(i*.21)*tt^2",
 'x <- etr_trajectory_set(tt,val,sprintf("curve%02d",1:n),"x",',
 '  time_unit="s",coordinate_system="unknown")',
 "y <- vapply(seq_len(n),function(i)",
 " .6*cos(i*.8)-.35*sin(i*.57)+.04*cos(i*.37),numeric(1L))",
 "draws <- outer(seq_len(20L),seq_len(n),function(i,j)",
 " .9*sin(i*j*.49)+.4*cos(i+j*.23))",
 "p <- etr_wild_bootstrap_fpca_projection(x,y,n_bootstrap=20L,",
 " residual_components=2L,inference_components=3L,",
 " multiplier_draws=draws)"
),collapse="\n")
make_wild <- function(){
 n<-24L;tt<-seq(0,1,length.out=13L)
 val<-array(0,c(n,length(tt),1L))
 for(i in seq_len(n))val[i,,1L]<-.25*sin(2*pi*tt)+
    .13*cos(i*.8)*cos(pi*tt)+.09*sin(i*.57)*sin(3*pi*tt)+
    .07*cos(i*.21)*tt^2
 x<-eyetrajectories::etr_trajectory_set(tt,val,
   sprintf("curve%02d",seq_len(n)),"x",
   time_unit="s",coordinate_system="unknown")
 y<-vapply(seq_len(n),function(i)
   .6*cos(i*.8)-.35*sin(i*.57)+.04*cos(i*.37),numeric(1L))
 draws<-outer(seq_len(20L),seq_len(n),function(i,j)
   .9*sin(i*j*.49)+.4*cos(i+j*.23))
 p<-eyetrajectories::etr_wild_bootstrap_fpca_projection(
   x,y,n_bootstrap=20L,residual_components=2L,
   inference_components=3L,multiplier_draws=draws)
 list(x=x,y=y,draws=draws,p=p)
}
reg3("etr_plot_fpca_wild_bootstrap_projection",
 "Functional uncertainty",
 "Native 20-replicate heteroscedastic Gaussian FPCR wild-bootstrap target intervals, shown for a fixed family. A low replicate count is illustrative, not sufficient for precise tail inference.",
 function(){
  w<-fixture("wave3_wild",make_wild)
  list(v("etr_plot_fpca_wild_bootstrap_projection","projections",
    "Fixed-target projection intervals",
    function()eyetrajectories::etr_plot_fpca_wild_bootstrap_projection(w$p,max_targets=8L),
    wild_setup,"etr_plot_fpca_wild_bootstrap_projection(p,max_targets=8L)"))
 })
reg3("etr_plot_fpca_wild_bootstrap_simultaneous_interval",
 "Functional uncertainty",
 "True native max-absolute-studentized fixed-family simultaneous wild-bootstrap intervals, distinct from narrower targetwise intervals. No arbitrary-subset strong FWER claim.",
 function(){
  w<-fixture("wave3_wild",make_wild)
  sim<-eyetrajectories::etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    w$p,confidence_level=.90)
  setup<-paste(wild_setup,
    "sim <- etr_fpca_wild_bootstrap_projection_simultaneous_interval(p,confidence_level=.90)",
    sep="\n")
  list(v("etr_plot_fpca_wild_bootstrap_simultaneous_interval","both",
    "Simultaneous and targetwise intervals",
    function()eyetrajectories::etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      sim,max_targets=8L,show_targetwise=TRUE),
    setup,"etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,max_targets=8L,show_targetwise=TRUE)"),
   v("etr_plot_fpca_wild_bootstrap_simultaneous_interval","family",
    "Familywise interval only",
    function()eyetrajectories::etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      sim,max_targets=8L,show_targetwise=FALSE),
    setup,"etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,max_targets=8L,show_targetwise=FALSE)"))
 })
reg3("etr_plot_fpca_wild_bootstrap_family_test",
 "Functional uncertainty",
 "Fixed-family single-step maxT adjusted p-values and targetwise p-values from retained wild roots. No post-hoc subset protection is asserted.",
 function(){
  w<-fixture("wave3_wild",make_wild)
  family<-fixture("wave3_family",function()
    eyetrajectories::etr_fpca_wild_bootstrap_projection_family_test(
      w$p,null_values=0,significance_level=.05))
  setup<-paste(wild_setup,
    'family <- etr_fpca_wild_bootstrap_projection_family_test(',
    ' p,null_values=0,significance_level=.05)',sep="\n")
  list(v("etr_plot_fpca_wild_bootstrap_family_test","pvalues",
    "MaxT-adjusted versus targetwise p-values",
    function()eyetrajectories::etr_plot_fpca_wild_bootstrap_family_test(
      family,max_targets=8L,show_targetwise=TRUE),
    setup,"etr_plot_fpca_wild_bootstrap_family_test(family,max_targets=8L,show_targetwise=TRUE)"))
 })
reg3("etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
 "Functional uncertainty",
 "Exact binomial intervals quantify Monte Carlo variability of estimated bootstrap tail probabilities, NOT an effect confidence interval. Only 20 draws are used for this demonstration.",
 function(){
  w<-fixture("wave3_wild",make_wild)
  family<-fixture("wave3_family",function()
    eyetrajectories::etr_fpca_wild_bootstrap_projection_family_test(
      w$p,null_values=0,significance_level=.05))
  mc<-eyetrajectories::etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(family)
  setup<-paste(wild_setup,
    "family <- etr_fpca_wild_bootstrap_projection_family_test(p,",
    " null_values=0,significance_level=.05)",
    "mc <- etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(family)",
    sep="\n")
  list(v("etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics","tail",
    "MaxT and targetwise MC precision",
    function()eyetrajectories::etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      mc,max_targets=8L,show_targetwise=TRUE),
    setup,"etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(mc,max_targets=8L,show_targetwise=TRUE)"))
 })
reg3("etr_plot_fpca_wild_bootstrap_truncation_scan",
 "Functional uncertainty",
 "Shared-draw consecutive inference-rank scan comparing interval width or center. The scan is descriptive; component count is not automatically selected.",
 function(){
  w<-fixture("wave3_wild",make_wild)
  scan<-eyetrajectories::etr_scan_wild_bootstrap_fpca_truncations(
    w$x,w$y,candidate_components=c(2L,3L),n_bootstrap=20L,
    residual_components=2L,multiplier_draws=w$draws)
  setup<-paste(wild_setup,
   "scan <- etr_scan_wild_bootstrap_fpca_truncations(x,y,",
   " candidate_components=c(2L,3L),n_bootstrap=20L,",
   " residual_components=2L,multiplier_draws=draws)",sep="\n")
  list(v("etr_plot_fpca_wild_bootstrap_truncation_scan","width",
      "Interval width by truncation",
      function()eyetrajectories::etr_plot_fpca_wild_bootstrap_truncation_scan(
        scan,target=1L,metric="width"),
      setup,'etr_plot_fpca_wild_bootstrap_truncation_scan(scan,target=1L,metric="width")'),
      v("etr_plot_fpca_wild_bootstrap_truncation_scan","center",
      "Center by truncation",
      function()eyetrajectories::etr_plot_fpca_wild_bootstrap_truncation_scan(
        scan,target=1L,metric="center"),
      setup,'etr_plot_fpca_wild_bootstrap_truncation_scan(scan,target=1L,metric="center")'))
 })
conformal_setup <- paste(c(
 "library(eyetrajectories)",
 "tt <- seq(0,1,length.out=21L)",
 "make_set <- function(ids,shift=0) {",
 " n<-length(ids);val<-array(0,c(n,length(tt),1L))",
 " for(i in seq_len(n)) val[i,,1L]<-sin(2*pi*tt)+",
 "  .17*cos(.6*i)*cos(2*pi*tt)+.11*sin(.45*i)*sin(4*pi*tt)+",
 "  .02*cos(tt*6*pi+.3*i)+shift*sin(6*pi*tt)",
 ' etr_trajectory_set(tt,val,ids,"x")',
 "}",
 'train<-make_set(paste0("train_",1:10))',
 'cal<-make_set(paste0("cal_",1:19))',
 'target<-make_set(paste0("target_",1:5),shift=.09)',
 "fit<-etr_fit_fpca(train,n_components=1L)",
 "screen<-etr_split_conformal_fpca_anomalies(fit,cal,target,alpha=.2)"
),collapse="\n")
reg3("etr_plot_conformal_fpca_anomaly","Functional uncertainty",
 "Conservative marginal rank p-values computed by native split-conformal FPCA from disjoint synthetic training, calibration and target sets. Exchangeability, not a single picture, underlies any coverage guarantee; NOT a familywise test.",
 function(){
  tt<-seq(0,1,length.out=21L)
  make_set<-function(ids,shift=0){
   n<-length(ids);val<-array(0,c(n,length(tt),1L))
   for(i in seq_len(n))val[i,,1L]<-sin(2*pi*tt)+
     .17*cos(.6*i)*cos(2*pi*tt)+.11*sin(.45*i)*sin(4*pi*tt)+
     .02*cos(tt*6*pi+.3*i)+shift*sin(6*pi*tt)
   eyetrajectories::etr_trajectory_set(tt,val,ids,"x")
  }
  train<-make_set(paste0("train_",1:10))
  cal<-make_set(paste0("cal_",1:19))
  target<-make_set(paste0("target_",1:5),shift=.09)
  fit<-eyetrajectories::etr_fit_fpca(train,n_components=1L)
  screen<-eyetrajectories::etr_split_conformal_fpca_anomalies(
    fit,cal,target,alpha=.2)
  list(v("etr_plot_conformal_fpca_anomaly","marginal",
    "Native conservative marginal p-values",
    function()eyetrajectories::etr_plot_conformal_fpca_anomaly(screen),
    conformal_setup,"etr_plot_conformal_fpca_anomaly(screen)"))
 })
# These two are SOURCE-SHAPE PLOT CONTRACTS: the explicit differential
# values are synthetic, precomputed and NOT passed off as fitted nlme/REML
# covariance sensitivity estimates or calibrated participant bootstraps.
sens_record <- function(){
 t<-seq(0,1,length.out=9L)
 list(specifications=list(list(name="reference"),list(name="alternative")),
   reference_label="reference",
   fits=list(reference=list(time_unit="s")),
   coefficient_frame=data.frame(coefficient=rep("dose",18L),
     model=rep(c("reference","alternative"),each=9L),
     time=rep(t,2L),
     difference_from_reference=c(rep(0,9L),.1+.1*sin(2*pi*t))),
   band_width_frame=data.frame(coefficient=rep("dose",18L),
     model=rep(c("reference","alternative"),each=9L),
     time=rep(t,2L),
     band_width_ratio_to_reference=c(rep(1,9L),1.2+.1*cos(2*pi*t))))
}
reg3("etr_plot_covariance_sensitivity_coefficients",
 "Functional uncertainty",
 "Synthetic, explicitly precomputed coefficient-sensitivity source record for testing the native R plot. This DOES NOT constitute actual likelihood fits, optimizer parity, model selection or inferential validation.",
 function(){
  z<-fixture("wave3_sens",sens_record)
  list(v("etr_plot_covariance_sensitivity_coefficients","source_record",
    "Synthetic coefficient differences (plot contract only)",
    function()eyetrajectories::etr_plot_covariance_sensitivity_coefficients(z,"dose"),
    record_setup(z,"sensitivity"),
    'etr_plot_covariance_sensitivity_coefficients(sensitivity,"dose")'))
 })
reg3("etr_plot_covariance_sensitivity_band_widths",
 "Functional uncertainty",
 "Synthetic, precomputed covariance-sensitivity band-width ratios. Not derived from paired calibrated participant bootstraps: teaching-only plot contract, NOT a confidence-band claim.",
 function(){
  z<-fixture("wave3_sens",sens_record)
  list(v("etr_plot_covariance_sensitivity_band_widths","source_record",
    "Synthetic band-width ratios (plot contract only)",
    function()eyetrajectories::etr_plot_covariance_sensitivity_band_widths(z,"dose"),
    record_setup(z,"sensitivity"),
    'etr_plot_covariance_sensitivity_band_widths(sensitivity,"dose")'))
 })
make_mixed_comparison <- function(){
 fit<-list(time=c(0,.5,1),coefficient_names=c("Intercept","dose"),
           coefficient_functions=rbind(c(.3,.4,.6),c(-.1,.2,.3)))
 draws<-array(NA_real_,c(4L,2L,3L))
 draws[1L,,]<-rbind(c(.1,.2,.3),c(.0,.1,.2))
 draws[2L,,]<-rbind(c(.2,.4,.5),c(-.2,.2,.3))
 draws[3L,,]<-rbind(c(.4,.6,.7),c(-.1,.4,.5))
 draws[4L,,]<-rbind(c(.5,.5,.9),c(.1,.2,.7))
 base<-list(reference=fit,bootstrap_coefficient_functions=draws,
    bootstrap_mean=rbind(c(.25,.35,.45),c(-.05,.15,.25)),
    bootstrap_standard_errors=rbind(c(.1,.15,.2),c(.15,.1,.1)),
    provenance=list(source="synthetic_plot_contract"))
 fixed<-base;fixed$bootstrap_type<-"conditional_covariance"
 full<-base;full$bootstrap_type<-"full_refit"
 full$bootstrap_standard_errors<-base$bootstrap_standard_errors*1.25
 eyetrajectories::etr_compare_functional_mixed_effects_bootstraps(
   fixed,full,confidence_level=.5,simultaneous_scope="coefficient")
}
reg3("etr_plot_functional_mixed_effects_bootstrap_comparison",
 "Functional uncertainty",
 "Actual native width-ratio comparison algorithm on a fixed test-record fixture; the paired bootstrap arrays are synthetic. Do not infer real-data full-refit versus fixed-covariance uncertainty.",
 function(){
  result<-fixture("wave3_mixed",make_mixed_comparison)
  stopifnot(is.data.frame(result))
  list(v("etr_plot_functional_mixed_effects_bootstrap_comparison","dose",
      "Synthetic paired-width ratio",
      function()eyetrajectories::etr_plot_functional_mixed_effects_bootstrap_comparison(
        result,"dose"),
      record_setup(result,"comparison"),
      'etr_plot_functional_mixed_effects_bootstrap_comparison(comparison,"dose")'))
 })
make_profile <- function(){
 fit<-list(time=c(0,.5,1),time_unit="seconds",
    family="binomial",link="logit",predictor_names="treatment",
    basis=cbind(c(1,1,1),c(0,.5,1)),
    basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
    parameter_covariance=diag(c(.04,.01,.09,.04)),
    scalar_design_matrix=rbind(c(1,0),c(1,1)),
    exposure=NULL,provenance=list(source="synthetic_fitted_parameters"))
 profiles<-data.frame(profile_id=c("Control","Treatment","Extrapolated"),
    treatment=c(0,1,2))
 eyetrajectories::etr_generalized_function_on_scalar_predict(fit,profiles)
}
reg3("etr_plot_generalized_function_on_scalar_predictions",
 "Functional uncertainty",
 "Native response-scale marginal probability predictions from explicit synthetic fitted coefficients and their covariance. Predeclared profiles; extrapolation is flagged and no simultaneous coverage is implied.",
 function(){
  prediction<-fixture("wave3_profile",make_profile)
  list(v("etr_plot_generalized_function_on_scalar_predictions","binomial",
    "Fixed binomial probability profiles",
    function()eyetrajectories::etr_plot_generalized_function_on_scalar_predictions(prediction),
    record_setup(prediction,"prediction"),
    'etr_plot_generalized_function_on_scalar_predictions(prediction)'))
 })

stopifnot(length(wave3_required)==14L,
 length(unique(wave3_required))==14L,
 all(wave3_pass %in% wave3_required))
writeLines(c(
  "WAVE3_ADVANCED_INFERENCE_NATIVE_PLOT_AUDIT",
  "Version: immutable eyetrajectories v0.4.3; website-only renderer",
  paste("Requested functions:",length(wave3_required)),
  paste("Rendered native plotting functions:",length(wave3_pass)),
  paste("Not yet rendered:",length(wave3_failed)),
  "Distinction: most previews derive from native estimators; covariance sensitivity is an explicit source-record visualization, not a fitted likelihood or calibrated band.",
  paste("PASS",wave3_pass),
  paste("MISSING",wave3_failed)),
  file.path(out,"WAVE3_AUDIT.txt"))
message("WAVE3_ADVANCED_INFERENCE_REPORT validated=",length(wave3_pass),
        " required=",length(wave3_required),
        " unresolved=",length(wave3_failed))
# Fail-closed: do not publish a 62/81 coverage claim unless ALL 14 work.
if(length(wave3_pass)!=length(wave3_required))
 stop("Wave 3 is incomplete: ",
   paste(setdiff(wave3_required,wave3_pass),collapse=", "),
   ". Publishing the current site is blocked.")
