# Wave 4: native R nonlinear-dynamics Plotting Atlas demonstrations.
# Website-only fixtures against frozen eyetrajectories v0.4.3.
# Every PNG is produced by the named exported R plotting function.
# Synthetic source-record demonstrations are explicitly separated from
# native estimator outputs; drawing a figure does not validate a method.
wave4_required <- c(
  "etr_plot_recurrence_network_degree",
  "etr_plot_local_divergence",
  "etr_plot_surrogate_nonlinearity",
  "etr_plot_kantz_sensitivity",
  "etr_plot_lyapunov_sensitivity",
  "etr_plot_windowed_rqa_sensitivity",
  "etr_plot_transfer_entropy_sensitivity",
  "etr_plot_transfer_entropy_circular_shift_test",
  "etr_plot_conditional_transfer_entropy_circular_shift_test",
  "etr_plot_multivariate_iaaft_diagnostics",
  "etr_plot_multivariate_surrogate_nonlinearity")
wave4_pass <- character()
wave4_failed <- character()
reg4 <- function(name, description, build) {
  stopifnot(name %in% wave4_required, !name %in% names(plot_spec))
  before <- atlas_new_success
  register_native(name, "Recurrence & nonlinear", description, build)
  if(name %in% setdiff(atlas_new_success, before))
    wave4_pass <<- c(wave4_pass,name)
  else wave4_failed <<- c(wave4_failed,name)
}
# Direct recurrence-network graph from the native recurrence estimator.
network_code <- paste(path_code,
 "rec <- etr_recurrence_matrix(paths,curve=1L,radius=.12,theiler=2L)",
 "network <- etr_recurrence_network(rec)",sep="\n")
reg4("etr_plot_recurrence_network_degree",
 "Native graph constructed from an actual recurrence matrix. Node degree is sensitive to the recurrence threshold and Theiler exclusion; graph structure is descriptive, not evidence of a unique dynamical mechanism.",
 function(){
  net <- fixture("wave4_network",function()
    eyetrajectories::etr_recurrence_network(rec1))
  stopifnot(inherits(net,"etr_recurrence_network"))
  list(
   v("etr_plot_recurrence_network_degree","normalized","Normalized node degree",
    function()eyetrajectories::etr_plot_recurrence_network_degree(net,normalized=TRUE),
    network_code,"etr_plot_recurrence_network_degree(network,normalized=TRUE)"),
   v("etr_plot_recurrence_network_degree","raw","Unnormalized node degree",
    function()eyetrajectories::etr_plot_recurrence_network_degree(net,normalized=FALSE),
    network_code,"etr_plot_recurrence_network_degree(network,normalized=FALSE)"))
 })
# Native Rosenstein delay reconstruction, nearest-neighbor divergence and
# declared horizon: a diagnostic, not a validated positive Lyapunov exponent.
divergence_code <- paste(path_code,
 "embedded <- etr_delay_embed_trajectory(paths,embedding_dimension=2L,",
 '  delay=2L,dimensions="x")',
 "divergence <- etr_local_divergence_curve(embedded,curve=1L,",
 "  theiler_window=3L,max_horizon=10L)",sep="\n")
reg4("etr_plot_local_divergence",
 "Actual native delay embedding and Rosenstein mean-log-distance divergence curve for synthetic trajectories. Curve slope depends on embedding, horizon and temporal-neighbor exclusions; no chaos diagnosis follows from this plot.",
 function(){
  result <- fixture("wave4_divergence",function(){
    e <- eyetrajectories::etr_delay_embed_trajectory(
      paths,embedding_dimension=2L,delay=2L,dimensions="x")
    eyetrajectories::etr_local_divergence_curve(e,curve=1L,
      theiler_window=3L,max_horizon=10L)
  })
  stopifnot(inherits(result,"etr_local_divergence"))
  list(v("etr_plot_local_divergence","rosenstein","Native mean-log divergence",
   function()eyetrajectories::etr_plot_local_divergence(result),
   divergence_code,"etr_plot_local_divergence(divergence)"))
 })
# Explicit plotting-contract source records follow: no surrogate refitting.
# These synthetic numbers are NOT calibrated null tests or fitted exponents.
surrogate_record <- structure(list(
  surrogate_statistics=c(.21,.24,.29,.31,.37,.40,.43,.45,.49,.50,
    .54,.56,.60,.62,.68,.71,.76,.79,.82,.85,.91),
  observed_statistic=.73,p_value=.2272727272727,
  statistic="largest_lyapunov",method="iaaft",
  provenance=list(source="synthetic_plot_contract",independent_validation=FALSE)),
  class="etr_surrogate_nonlinearity")
reg4("etr_plot_surrogate_nonlinearity",
 "Source-record demonstration of the real native surrogate histogram function, using explicitly synthetic test statistics. No IAAFT series were fitted, no null-model adequacy or p-value calibration was established.",
 function(){
  setup <- record_setup(surrogate_record,"surrogate")
  list(v("etr_plot_surrogate_nonlinearity","bins6","Synthetic null, six bins",
    function()eyetrajectories::etr_plot_surrogate_nonlinearity(surrogate_record,bins=6L),
    setup,"etr_plot_surrogate_nonlinearity(surrogate,bins=6L)"),
   v("etr_plot_surrogate_nonlinearity","bins10","Synthetic null, ten bins",
    function()eyetrajectories::etr_plot_surrogate_nonlinearity(surrogate_record,bins=10L),
    setup,"etr_plot_surrogate_nonlinearity(surrogate,bins=10L)"))
 })
sensitivity_table <- data.frame(
  embedding_dimension=c(2,3,4,5),
  requested_delay=c(1,1,1,1),
  exponent=c(.12,.04,-.03,.06),
  r_squared=c(.64,.76,.71,.69),
  standard_error=c(.06,.04,.05,.05))
kantz_record <- structure(list(table=sensitivity_table,
  curve_id="synthetic_1",exponent_unit="1/s",
  provenance=list(source="synthetic_plot_contract")),
  class="etr_kantz_parameter_sensitivity")
lyap_record <- structure(list(table=transform(sensitivity_table,
  exponent=c(.08,.15,.11,-.02),r_squared=c(.61,.73,.84,.68)),
  curve_id="synthetic_1",exponent_unit="1/s",
  provenance=list(source="synthetic_plot_contract")),
  class="etr_lyapunov_parameter_sensitivity")
reg4("etr_plot_kantz_sensitivity",
 "Exact native Kantz plotting-contract visualization using synthetic sensitivity-table records. These are not fitted neighborhood-divergence estimates; reconstructed-dimension sensitivity cannot itself establish deterministic chaos.",
 function(){
  setup <- record_setup(kantz_record,"sensitivity")
  list(v("etr_plot_kantz_sensitivity","exponent","Illustrative exponent by embedding dimension",
     function()eyetrajectories::etr_plot_kantz_sensitivity(kantz_record,
        parameter="embedding_dimension"),
     setup,'etr_plot_kantz_sensitivity(sensitivity,parameter="embedding_dimension")'),
    v("etr_plot_kantz_sensitivity","r_squared","Illustrative fit quality",
     function()eyetrajectories::etr_plot_kantz_sensitivity(kantz_record,
       parameter="embedding_dimension",response="r_squared"),
     setup,'etr_plot_kantz_sensitivity(sensitivity,parameter="embedding_dimension",response="r_squared")'))
 })
reg4("etr_plot_lyapunov_sensitivity",
 "Exact native Rosenstein/Lyapunov plotting-contract visualization using synthetic parameter-sweep records, not independently fitted exponent estimates. Exponent values are illustrative and do not establish chaos.",
 function(){
  setup <- record_setup(lyap_record,"sensitivity")
  list(v("etr_plot_lyapunov_sensitivity","exponent","Illustrative exponent sensitivity",
      function()eyetrajectories::etr_plot_lyapunov_sensitivity(lyap_record,
       parameter="embedding_dimension"),
      setup,'etr_plot_lyapunov_sensitivity(sensitivity,parameter="embedding_dimension")'))
 })
rqa_setup <- paste(path_code,
  "sensitivity <- etr_windowed_rqa_sensitivity(paths,",
  '  metrics="recurrence_rate",',
  "  window_step_pairs=list(c(13L,4L),c(17L,6L)),",
  "  radius=.25)",sep="\n")
reg4("etr_plot_windowed_rqa_sensitivity",
 "Actual native R window/step RQA recomputation on synthetic trajectory sets, with fixed recurrence radius. Overlapping windows are dependent and do not represent independent replications or a universally optimal window length.",
 function(){
  s <- fixture("wave4_windowed_rqa",function()
     eyetrajectories::etr_windowed_rqa_sensitivity(paths,
       metrics="recurrence_rate",
       window_step_pairs=list(c(13L,4L),c(17L,6L)),radius=.25))
  stopifnot(inherits(s,"etr_windowed_rqa_sensitivity"))
  list(v("etr_plot_windowed_rqa_sensitivity","window_step",
    "Native window/step profile",
    function()eyetrajectories::etr_plot_windowed_rqa_sensitivity(
       s,curve="synthetic_1",metric="recurrence_rate"),
    rqa_setup,
    'etr_plot_windowed_rqa_sensitivity(sensitivity,curve="synthetic_1",metric="recurrence_rate")'))
 })
# Native discrete transfer-entropy and circular-shift estimators.
# Shift tests assess dependence under their declared null, not causality.
te_setup <- paste(c(
 "library(eyetrajectories)",
 "set.seed(4404L)",
 "source <- sample(0:1,180L,replace=TRUE)",
 "target <- c(0L,head(source,-1L))",
 "noise <- runif(180L)<.16",
 "target[noise] <- 1L-target[noise]",
 "condition <- sample(0:1,180L,replace=TRUE)",
 "shifts <- as.integer(c(3,7,11,17,23,29,37,43,59,67,71))"
 ),collapse="\n")
make_te <- function(){
 set.seed(4404L)
 src <- sample(0:1,180L,replace=TRUE)
 target <- c(0L,head(src,-1L))
 noise <- runif(180L)<.16
 target[noise] <- 1L-target[noise]
 condition <- sample(0:1,180L,replace=TRUE)
 list(source=src,target=target,condition=condition,
      shifts=as.integer(c(3,7,11,17,23,29,37,43,59,67,71)))
}
reg4("etr_plot_transfer_entropy_sensitivity",
 "Native discrete transfer-entropy multiverse over declared source lags, evaluated on synthetic lagged binary series. Finite-sample bias and conditioning matter; directed predictive information is not an intervention or causality estimate.",
 function(){
  z <- fixture("wave4_te",make_te)
  s <- eyetrajectories::etr_transfer_entropy_parameter_sensitivity(
    z$source,z$target,target_histories=1L,
    source_histories=1L,source_lags=1:4)
  stopifnot(inherits(s,"etr_transfer_entropy_sensitivity"))
  list(v("etr_plot_transfer_entropy_sensitivity","source_lag",
    "Native source-lag sensitivity",
    function()eyetrajectories::etr_plot_transfer_entropy_sensitivity(
      s,parameter="source_lag"),
    paste(te_setup,
      "sensitivity <- etr_transfer_entropy_parameter_sensitivity(source,target,",
      "  target_histories=1L,source_histories=1L,source_lags=1:4)",sep="\n"),
    'etr_plot_transfer_entropy_sensitivity(sensitivity,parameter="source_lag")'))
 })
reg4("etr_plot_transfer_entropy_circular_shift_test",
 "Native source-only circular-shift null for discrete transfer entropy on synthetic lagged binary series. Shifts preserve selected source features but do not remove all autocorrelation confounding or identify causal effects.",
 function(){
  z <- fixture("wave4_te",make_te)
  s <- eyetrajectories::etr_transfer_entropy_circular_shift_test(
     z$source,z$target,1L,1L,1L,shifts=z$shifts)
  stopifnot(inherits(s,"etr_transfer_entropy_circular_shift_test"))
  setup <- paste(te_setup,
    "test <- etr_transfer_entropy_circular_shift_test(source,target,",
    "  1L,1L,1L,shifts=shifts)",sep="\n")
  list(v("etr_plot_transfer_entropy_circular_shift_test","shift",
    "Observed versus shifted null (11 shifts)",
    function()eyetrajectories::etr_plot_transfer_entropy_circular_shift_test(
     s,bins=6L),setup,
    "etr_plot_transfer_entropy_circular_shift_test(test,bins=6L)"))
 })
reg4("etr_plot_conditional_transfer_entropy_circular_shift_test",
 "Native conditional-TE circular-shift null, conditioning on a measured synthetic binary process. A low shift-null tail probability does not identify causal direction or eliminate unmeasured confounding.",
 function(){
  z <- fixture("wave4_te",make_te)
  s <- eyetrajectories::etr_conditional_transfer_entropy_circular_shift_test(
    z$source,z$target,z$condition,1L,1L,1L,1L,1L,shifts=z$shifts)
  stopifnot(inherits(s,"etr_conditional_transfer_entropy_circular_shift_test"))
  setup <- paste(te_setup,
   "test <- etr_conditional_transfer_entropy_circular_shift_test(",
   "  source,target,condition,1L,1L,1L,1L,1L,shifts=shifts)",sep="\n")
  list(v("etr_plot_conditional_transfer_entropy_circular_shift_test",
    "conditional_shift","Conditional shifted-source null",
    function()eyetrajectories::etr_plot_conditional_transfer_entropy_circular_shift_test(
      s,bins=6L),setup,
    "etr_plot_conditional_transfer_entropy_circular_shift_test(test,bins=6L)"))
 })
# Preset synthetic scientific records as in the source-contract tests;
# the plotting function is executed, but the IAAFT optimizer is not.
mv_iaaft_record <- list(
  n_surrogates=5L,reference_dimension="x",
  convergence_iterations=c(4L,7L,5L,8L,6L),
  spectral_errors=matrix(c(.09,.11,.12,.17,.08,.11,.06,.08,.10,.14),
    nrow=5L,ncol=2L,byrow=TRUE),
  cross_spectral_errors=matrix(c(.03,.04,.05,.04,.07),ncol=1L),
  provenance=list(source="synthetic_plot_contract"))
mv_nonlinearity_record <- list(
  surrogate_statistics=c(.08,.11,.14,.16,.19,.22,.26,.31,.37,.41,.46),
  observed_statistic=.33,statistic="largest_lyapunov",
  p_value=.25,provenance=list(source="synthetic_plot_contract"))
reg4("etr_plot_multivariate_iaaft_diagnostics",
 "Executed native IAAFT spectral-preservation plotting function on explicitly synthetic error matrices. These inputs do not come from fitted multivariate IAAFT surrogates; no preservation tolerance, convergence or spectral match is certified.",
 function(){
  list(v("etr_plot_multivariate_iaaft_diagnostics","source_record",
    "Illustrative spectral mismatch",
    function()eyetrajectories::etr_plot_multivariate_iaaft_diagnostics(
      mv_iaaft_record),
    record_setup(mv_iaaft_record,"diagnostics"),
    "etr_plot_multivariate_iaaft_diagnostics(diagnostics)"))
 })
reg4("etr_plot_multivariate_surrogate_nonlinearity",
 "Executed native multivariate surrogate-statistic histogram on a synthetic result record. No multivariate IAAFT resampling, phase-preservation analysis, or calibrated hypothesis test is implied.",
 function(){
  list(v("etr_plot_multivariate_surrogate_nonlinearity","source_record",
     "Illustrative multivariate null",
     function()eyetrajectories::etr_plot_multivariate_surrogate_nonlinearity(
      mv_nonlinearity_record,bins=6L),
     record_setup(mv_nonlinearity_record,"nonlinearity"),
     "etr_plot_multivariate_surrogate_nonlinearity(nonlinearity,bins=6L)"))
 })
stopifnot(length(wave4_required)==11L,
 length(unique(wave4_required))==11L,
 all(wave4_pass %in% wave4_required))
writeLines(c(
 "WAVE4_NONLINEAR_DYNAMICS_NATIVE_PLOT_AUDIT",
 "Version: immutable eyetrajectories v0.4.3, website-only renderer",
 paste("Requested functions:",length(wave4_required)),
 paste("Rendered native plotting functions:",length(wave4_pass)),
 paste("Not yet rendered:",length(wave4_failed)),
 "Native computed fixtures: recurrence network, local divergence, windowed RQA sensitivity, transfer-entropy sensitivity, unconditional and conditional circular-shift tests.",
 "Synthetic plotting-contract records: Kantz and Rosenstein parameter sweeps, IAAFT surrogate-null histogram, multivariate IAAFT errors, multivariate nonlinearity histogram.",
 "No independent scientific validation, chaos identification, statistical calibration or causal inference is claimed.",
 paste("PASS",wave4_pass),paste("MISSING",wave4_failed)),
 file.path(out,"WAVE4_AUDIT.txt"))
message("WAVE4_NONLINEAR_REPORT validated=",length(wave4_pass),
  " required=",length(wave4_required),
  " unresolved=",length(wave4_failed))
if(length(wave4_pass)!=length(wave4_required))
 stop("Wave 4 incomplete: ",paste(setdiff(wave4_required,wave4_pass),
  collapse=", "),". Blocking website publication.")
