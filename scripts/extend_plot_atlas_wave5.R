# Wave 5: complete the 81 native R plot exports for eyetrajectories v0.4.3.
# This file is a website-only generator; no R package/release sources change.
# The eight registered plotting functions execute in an actual R graphics
# device. Distinguish native estimation from illustrative source records.
wave5_required <- c(
 "etr_plot_function_on_scalar_coefficients",
 "etr_plot_rqa_metric_mean_bootstrap",
 "etr_plot_functional_recovery_summary",
 "etr_plot_functional_random_effects",
 "etr_plot_functional_trial_random_effects",
 "etr_plot_generalized_function_on_scalar_mean_difference",
 "etr_plot_generalized_function_on_scalar_coefficients",
 "etr_plot_workflow_result")
wave5_pass <- character()
wave5_failed <- character()
reg5 <- function(name, family, description, generate) {
  stopifnot(name %in% wave5_required, !name %in% names(plot_spec))
  before <- atlas_new_success
  register_native(name,family,description,generate)
  if(name %in% setdiff(atlas_new_success,before))
    wave5_pass <<- c(wave5_pass,name)
  else wave5_failed <<- c(wave5_failed,name)
}

# 1 — Actual observed-grid function-on-scalar estimator, with independent
# synthetic curves as the declared inference units. No causal identification.
fos5_setup <- paste(path_code,
 "design <- data.frame(curve_id=paths$curve_ids,",
 "  dose=seq(-1,1,length.out=length(paths$curve_ids)))",
 "fos <- etr_fit_function_on_scalar_regression(",
 '  paths,design,predictors="dose",dimensions=c("x","y"))',sep="\n")
reg5("etr_plot_function_on_scalar_coefficients","Functional uncertainty",
 "Actual native observed-grid function-on-scalar fit to synthetic trajectories with declared independent curve-level units. Coefficients are descriptive associations, not causal effects or calibrated simultaneous bands.",
 function(){
  fit <- fixture("wave5_fos",function(){
    design <- data.frame(curve_id=paths$curve_ids,
      dose=seq(-1,1,length.out=length(paths$curve_ids)))
    eyetrajectories::etr_fit_function_on_scalar_regression(
      paths,design,predictors="dose",dimensions=c("x","y"))
  })
  stopifnot(inherits(fit,"etr_function_on_scalar"))
  list(
    v("etr_plot_function_on_scalar_coefficients","dose_x",
      "Native dose coefficient: x",
      function()eyetrajectories::etr_plot_function_on_scalar_coefficients(
        fit,coefficient="dose",dimension="x"),
      fos5_setup,
      'etr_plot_function_on_scalar_coefficients(fos,coefficient="dose",dimension="x")'),
    v("etr_plot_function_on_scalar_coefficients","dose_y",
      "Native dose coefficient: y",
      function()eyetrajectories::etr_plot_function_on_scalar_coefficients(
        fit,coefficient="dose",dimension="y"),
      fos5_setup,
      'etr_plot_function_on_scalar_coefficients(fos,coefficient="dose",dimension="y")'))
 })

# 2 — Real whole-curve bootstrap over per-curve RQA metrics.
rqa5_setup <- paste(path_code,
  "rqa <- etr_bootstrap_rqa_metric_means(paths,",
  '  dimensions=c("x","y"),metrics=c("recurrence_rate","determinism"),',
  "  radius=.35,theiler_window=2L,n_bootstrap=120L,",
  "  unit='curve',confidence_level=.9,random_state=5505L)",sep="\n")
reg5("etr_plot_rqa_metric_mean_bootstrap","Recurrence & nonlinear",
 "Native fixed-radius, whole-curve bootstrap of RQA population-average metrics. Synthetic curves are treated as independent units; the band is not individual time-series uncertainty, and finite-sample coverage is not certified.",
 function(){
   result <- fixture("wave5_rqa",function()
     eyetrajectories::etr_bootstrap_rqa_metric_means(paths,
       dimensions=c("x","y"),
       metrics=c("recurrence_rate","determinism"),
       radius=.35,theiler_window=2L,n_bootstrap=120L,
       unit="curve",confidence_level=.9,random_state=5505L))
   stopifnot(inherits(result,"etr_rqa_metric_bootstrap"))
   list(v("etr_plot_rqa_metric_mean_bootstrap","whole_curve",
     "Whole-curve RQA bootstrap, B=120",
     function()eyetrajectories::etr_plot_rqa_metric_mean_bootstrap(result),
     rqa5_setup,"etr_plot_rqa_metric_mean_bootstrap(rqa)"))
 })

# 3 — Use the native recovery aggregation on fully transparent synthetic
# replicate records. No externally benchmarked or fitted recovery study.
recovery5_setup <- paste(c(
 "library(eyetrajectories)",
 'metric <- list(name="mean_integrated_error",',
 '  quantity="integrated_error",direction="lower_is_better",',
 '  units="squared_units",scope="curve",',
 '  description="Synthetic integrated reconstruction error")',
 'value <- function(v) list(metric=metric,value=v,component=0L,source="curve")',
 'key <- "mean_integrated_error.source_curve.component_1"',
 'records <- list()',
 'for(i in 1:6) for(group in c("baseline","regularized")) {',
 '  v <- if(group=="baseline") .24+.028*i+.025*sin(i) else',
 '       .13+.015*i+.012*cos(i)',
 '  records[[length(records)+1L]] <- list(',
 '    scenario_name=group,replicate=as.integer(i-1L),',
 '    seed=as.integer(5600L+i),status="ok",',
 '    metrics=setNames(v,key),metric_values=list(value(v)))',
 '}',
 'recovery <- etr_functional_recovery_result(records,list(metric))',
 'summary <- etr_functional_recovery_summary_frame(recovery)'
 ),collapse="\n")
make_recovery5 <- function(){
 metric <- list(name="mean_integrated_error",
   quantity="integrated_error",direction="lower_is_better",
   units="squared_units",scope="curve",
   description="Synthetic integrated reconstruction error")
 value <- function(v)list(metric=metric,value=v,component=0L,source="curve")
 key <- "mean_integrated_error.source_curve.component_1"
 records <- list()
 for(i in 1:6)for(group in c("baseline","regularized")){
  v <- if(group=="baseline") .24+.028*i+.025*sin(i) else
       .13+.015*i+.012*cos(i)
  records[[length(records)+1L]] <- list(
    scenario_name=group,replicate=as.integer(i-1L),
    seed=as.integer(5600L+i),status="ok",
    metrics=setNames(v,key),metric_values=list(value(v)))
 }
 recovery <- eyetrajectories::etr_functional_recovery_result(records,list(metric))
 eyetrajectories::etr_functional_recovery_summary_frame(recovery)
}
reg5("etr_plot_functional_recovery_summary","Functional uncertainty",
 "Native recovery-summary aggregation and plotting of explicitly synthetic replicate metrics. Interquartile whiskers describe the synthetic inputs; these are not empirical reconstruction benchmarks or confidence intervals.",
 function(){
  z <- fixture("wave5_recovery",make_recovery5)
  stopifnot(is.data.frame(z),nrow(z)==2L)
  list(
   v("etr_plot_functional_recovery_summary","median_iqr",
     "Synthetic recovery median and IQR",
     function()eyetrajectories::etr_plot_functional_recovery_summary(
       z,metric="mean_integrated_error",statistic="median"),
     recovery5_setup,
     'etr_plot_functional_recovery_summary(summary,metric="mean_integrated_error",statistic="median")'),
   v("etr_plot_functional_recovery_summary","mean",
     "Synthetic recovery mean",
     function()eyetrajectories::etr_plot_functional_recovery_summary(
       z,metric="mean_integrated_error",statistic="mean"),
     recovery5_setup,
     'etr_plot_functional_recovery_summary(summary,metric="mean_integrated_error",statistic="mean")'))
 })

# 4–5 — Published native plotting contracts for realized participant and
# nested-trial random effects. These smooth effects are synthetic source
# records, NOT fitted BLUPs or estimated between-unit covariance.
rand5_time <- seq(0,1,length.out=41L)
rand5_participant <- list(
 participant_ids=c("p1","p2","p3","p4"),time=rand5_time,
 time_unit="s",dimension_name="x",
 random_intercept_functions=t(vapply(1:4,function(i)
    .08*sin(2*pi*rand5_time+.45*i)+.015*(i-2.5),
    numeric(length(rand5_time)))),
 random_slope_functions=t(vapply(1:4,function(i)
    .06*cos(2*pi*rand5_time+.3*i)+.02*i,
    numeric(length(rand5_time)))),
 random_slope_predictor="dose",
 provenance=list(source="synthetic_plot_contract"))
rand5_trial <- list(
 source_curve_ids=c("c1","c2","c3","c4"),
 curve_participant_ids=c("p1","p1","p2","p2"),
 curve_trial_ids=c("t1","t2","t1","t2"),
 trial_ids=c("p1/t1","p1/t2","p2/t1","p2/t2"),
 time=rand5_time,time_unit="s",trial_random_effect="functional_intercept",
 trial_random_effect_functions=t(vapply(1:4,function(i)
    .055*cos(2*pi*rand5_time+1.1*i)+.01*(i-2),
    numeric(length(rand5_time)))),
 provenance=list(source="synthetic_plot_contract"))
reg5("etr_plot_functional_random_effects","Functional uncertainty",
 "Native participant random-effect plot using explicitly synthetic realized intercept and slope functions. Illustrates source geometry only; no mixed model was fitted, and these are not estimated empirical participant BLUPs.",
 function(){
  setup <- record_setup(rand5_participant,"effects")
  list(
   v("etr_plot_functional_random_effects","intercepts",
     "Synthetic participant intercept functions",
     function()eyetrajectories::etr_plot_functional_random_effects(
       rand5_participant,effect="intercept",max_participants=4L),
     setup,
     'etr_plot_functional_random_effects(effects,effect="intercept",max_participants=4L)'),
   v("etr_plot_functional_random_effects","slopes",
     "Synthetic participant dose slopes",
     function()eyetrajectories::etr_plot_functional_random_effects(
       rand5_participant,effect="slope",max_participants=4L),
     setup,
     'etr_plot_functional_random_effects(effects,effect="slope",max_participants=4L)'))
 })
reg5("etr_plot_functional_trial_random_effects","Functional uncertainty",
 "Native nested trial-effect plotting function with explicitly synthetic realized trial intercepts. Demonstrates within-participant selection, not fitted conditional effects or independently estimated random-effect variance.",
 function(){
   setup <- record_setup(rand5_trial,"effects")
   list(
    v("etr_plot_functional_trial_random_effects","all_trials",
      "All four synthetic trial intercept functions",
      function()eyetrajectories::etr_plot_functional_trial_random_effects(
        rand5_trial,max_trials=4L),
      setup,"etr_plot_functional_trial_random_effects(effects,max_trials=4L)"),
    v("etr_plot_functional_trial_random_effects","participant_p1",
      "Synthetic trials for participant p1",
      function()eyetrajectories::etr_plot_functional_trial_random_effects(
        rand5_trial,participant_id="p1",max_trials=2L),
      setup,
      'etr_plot_functional_trial_random_effects(effects,participant_id="p1",max_trials=2L)'))
 })

# 6–7 — Compute contrasts and coefficient intervals using real native R
# algorithms on fully declared synthetic generalized-FoSR bootstrap records.
# These are NOT draws from a fitted GEE/participant bootstrap.
g5_setup <- paste(c(
 "library(eyetrajectories)",
 'fit <- list(time=c(0,.5,1),time_unit="seconds",',
 '  family="binomial",link="logit",predictor_names="treatment",',
 '  coefficient_names=c("Intercept","treatment"),',
 '  basis=cbind(c(1,1,1),c(0,.5,1)),',
 '  basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),',
 '  coefficient_functions=rbind(c(.2,.25,.3),c(.5,.625,.75)),',
 '  coefficient_standard_errors=rbind(c(.12,.12,.12),c(.14,.16,.17)),',
 '  parameter_covariance=diag(c(.04,.01,.09,.04)),',
 '  scalar_design_matrix=rbind(c(1,0),c(1,1)),exposure=NULL,',
 '  provenance=list(source="synthetic_plot_contract"))',
 'draws <- array(NA_real_,c(4L,2L,3L))',
 'draws[1L,,] <- rbind(c(.10,.20,.25),c(.35,.55,.65))',
 'draws[2L,,] <- rbind(c(.22,.26,.32),c(.48,.58,.68))',
 'draws[3L,,] <- rbind(c(.27,.29,.38),c(.51,.59,.73))',
 'draws[4L,,] <- rbind(c(.32,.36,.42),c(.65,.80,.85))',
 'bootstrap <- list(reference=fit,bootstrap_coefficient_functions=draws,',
 '  provenance=list(source="synthetic_plot_contract"))'
),collapse="\n")
make_generalized5 <- function(){
 fit <- list(time=c(0,.5,1),time_unit="seconds",
   family="binomial",link="logit",predictor_names="treatment",
   coefficient_names=c("Intercept","treatment"),
   basis=cbind(c(1,1,1),c(0,.5,1)),
   basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
   coefficient_functions=rbind(c(.2,.25,.3),c(.5,.625,.75)),
   coefficient_standard_errors=rbind(c(.12,.12,.12),c(.14,.16,.17)),
   parameter_covariance=diag(c(.04,.01,.09,.04)),
   scalar_design_matrix=rbind(c(1,0),c(1,1)),exposure=NULL,
   provenance=list(source="synthetic_plot_contract"))
 draws <- array(NA_real_,c(4L,2L,3L))
 draws[1L,,] <- rbind(c(.10,.20,.25),c(.35,.55,.65))
 draws[2L,,] <- rbind(c(.22,.26,.32),c(.48,.58,.68))
 draws[3L,,] <- rbind(c(.27,.29,.38),c(.51,.59,.73))
 draws[4L,,] <- rbind(c(.32,.36,.42),c(.65,.80,.85))
 list(reference=fit,bootstrap_coefficient_functions=draws,
   provenance=list(source="synthetic_plot_contract"))
}
reg5("etr_plot_generalized_function_on_scalar_mean_difference",
 "Functional uncertainty",
 "Native probability-scale generalized FoSR profile difference and observed-grid simultaneous-band algorithm evaluated on four precomputed synthetic coefficient-draw records. No fitted GEE or calibrated empirical coverage is implied.",
 function(){
  b <- fixture("wave5_gbootstrap",make_generalized5)
  p <- eyetrajectories::etr_bootstrap_generalized_function_on_scalar_predictions(
     b,data.frame(profile_id=c("A","B"),treatment=c(0,1)))
  d <- eyetrajectories::etr_generalized_function_on_scalar_mean_difference_band(
     p,profile_a="B",profile_b="A",confidence_level=.5)
  list(v("etr_plot_generalized_function_on_scalar_mean_difference",
    "probability_difference","Illustrative B minus A probability profile",
    function()eyetrajectories::etr_plot_generalized_function_on_scalar_mean_difference(d),
    paste(g5_setup,
      'pred <- etr_bootstrap_generalized_function_on_scalar_predictions(',
      '  bootstrap,data.frame(profile_id=c("A","B"),treatment=c(0,1)))',
      'difference <- etr_generalized_function_on_scalar_mean_difference_band(',
      '  pred,profile_a="B",profile_b="A",confidence_level=.5)',sep="\n"),
    "etr_plot_generalized_function_on_scalar_mean_difference(difference)"))
 })
reg5("etr_plot_generalized_function_on_scalar_coefficients",
 "Functional uncertainty",
 "Native logit-scale generalized-FoSR coefficient graphics, with 50% maximum-statistic bands computed from four synthetic coefficient records. Demonstrates plotting and observed-grid calibration mechanics only, not an independently fitted model.",
 function(){
  b <- fixture("wave5_gbootstrap",make_generalized5)
  band <- eyetrajectories::etr_generalized_function_on_scalar_simultaneous_bands(
    b,confidence_level=.5,simultaneous_scope="coefficient")
  list(
    v("etr_plot_generalized_function_on_scalar_coefficients",
      "logit_coefficient_band","Illustrative treatment band on logit scale",
      function()eyetrajectories::etr_plot_generalized_function_on_scalar_coefficients(
        band,coefficient="treatment"),
      paste(g5_setup,
        'band <- etr_generalized_function_on_scalar_simultaneous_bands(',
        '  bootstrap,confidence_level=.5,simultaneous_scope="coefficient")',
        sep="\n"),
      'etr_plot_generalized_function_on_scalar_coefficients(band,coefficient="treatment")'),
    v("etr_plot_generalized_function_on_scalar_coefficients",
      "logit_plain","Illustrative treatment coefficient (no band)",
      function()eyetrajectories::etr_plot_generalized_function_on_scalar_coefficients(
        b$reference,coefficient="treatment"),
      g5_setup,
      'etr_plot_generalized_function_on_scalar_coefficients(fit,coefficient="treatment")'))
 })

# 8 — Actual native workflow execution and dispatched plotting, not a
# manually redrawn preview of a workflow's child function.
workflow5_setup <- paste(path_code,
 "workflow <- etr_run_fpca_workflow(paths,list(n_components=2L))",sep="\n")
reg5("etr_plot_workflow_result","Functional PCA",
 "Actual native FPCA workflow and exact exported workflow plotting dispatcher, with explicit component index, dimension and SD multiplier. The image does not imply independent estimation certification.",
 function(){
  wf <- fixture("wave5_workflow",function()
     eyetrajectories::etr_run_fpca_workflow(paths,list(n_components=2L)))
  stopifnot(inherits(wf,"etr_fpca_workflow"))
  list(
    v("etr_plot_workflow_result","fpca_sd1","Workflow FPCA: one SD mode",
      function()eyetrajectories::etr_plot_workflow_result(wf,
        plot="fpca_component",component=0L,dimension="x",sd_multiplier=1),
      workflow5_setup,
      'etr_plot_workflow_result(workflow,plot="fpca_component",component=0L,dimension="x",sd_multiplier=1)'),
    v("etr_plot_workflow_result","fpca_sd2","Workflow FPCA: two SD modes",
      function()eyetrajectories::etr_plot_workflow_result(wf,
        plot="fpca_component",component=0L,dimension="x",sd_multiplier=2),
      workflow5_setup,
      'etr_plot_workflow_result(workflow,plot="fpca_component",component=0L,dimension="x",sd_multiplier=2)'))
 })

stopifnot(length(wave5_required)==8L,
 length(unique(wave5_required))==8L,
 all(wave5_pass %in% wave5_required))
writeLines(c(
 "WAVE5_COMPLETE_NATIVE_PLOT_AUDIT",
 "Version: immutable eyetrajectories v0.4.3; website-only R renderer",
 paste("Requested functions:",length(wave5_required)),
 paste("Rendered native plotting functions:",length(wave5_pass)),
 paste("Not yet rendered:",length(wave5_failed)),
 "Estimator-backed figures: native observed-grid FoSR, whole-curve RQA bootstrap, native synthetic recovery aggregation, and FPCA workflow dispatcher.",
 "Synthetic plotting-contract records: participant/trial random effects and generalized FoSR coefficient/contrast bootstrap inputs. Native analytic transformations and plotting functions execute but fitted data and calibrated inference are not claimed.",
 "Statistical validation: none inferred from render success; all observations are synthetic.",
 paste("PASS",wave5_pass),paste("MISSING",wave5_failed)),
 file.path(out,"WAVE5_AUDIT.txt"))
message("WAVE5_COMPLETE_NATIVE_REPORT validated=",length(wave5_pass),
 " required=",length(wave5_required),
 " unresolved=",length(wave5_failed))
if(length(wave5_pass)!=8L)
  stop("Wave 5 incomplete: ",
    paste(setdiff(wave5_required,wave5_pass),collapse=", "),
    ". Website publication blocked.")
