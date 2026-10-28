# Stage 11: scientific reporting parity, source-boundary and zero-Python tests.

.etr11_fixture <- function() {
  t<-seq(0,1,length.out=7L)
  vals<-array(0,c(3L,length(t),2L))
  for(i in 1:3) {
    vals[i,,1L]<-sin(t*2*pi+i/5)
    vals[i,,2L]<-cos(t*2*pi-i/7)
  }
  etr_trajectory_set(t,vals,paste0("g",1:3),c("x","y"),
    coordinate_system="normalized",time_unit="s")
}

test_that("Stage 11 native recurrence report adapters preserve study specifications",{
  x<-.etr11_fixture()
  a<-etr_recurrence_matrix(x,curve=1L,radius=1.5,theiler=0L)
  b<-etr_recurrence_matrix(x,curve=2L,radius=1.5,theiler=0L)
  net<-etr_recurrence_network(a)
  net_text<-etr_recurrence_network_reporting_text(net)
  expect_true(grepl("undirected recurrence network",net_text,fixed=TRUE))
  expect_true(grepl("Theiler window of 0 samples",net_text,fixed=TRUE))
  expect_true(grepl("No threshold tuning",net_text,fixed=TRUE))
  joint<-etr_joint_recurrence_matrix(list(a,b),labels=c("left","right"))
  metrics<-etr_joint_rqa_metrics(joint)
  joint_text<-etr_joint_recurrence_reporting_text(joint,metrics)
  expect_true(grepl("logical intersection",joint_text,fixed=TRUE))
  expect_true(grepl("left:",joint_text,fixed=TRUE))
  expect_true(grepl("right:",joint_text,fixed=TRUE))
  expect_true(grepl("causal coupling",joint_text,fixed=TRUE))
  expect_true(grepl("Joint-RQA used minimum",joint_text,fixed=TRUE))
  no_metrics<-etr_joint_recurrence_reporting_text(joint)
  expect_false(grepl("Joint-RQA used minimum",no_metrics,fixed=TRUE))
  expect_error(etr_joint_recurrence_reporting_text(list()),"joint")
  rqa<-etr_rqa_metrics(a,2L,2L)
  rqa$min_diagonal_length<-2L
  rqa$min_vertical_length<-2L
  text<-etr_rqa_reporting_text(a,rqa)
  expect_true(grepl("fixed radius",text,fixed=TRUE))
  expect_true(grepl("minimum diagonal and vertical",text,fixed=TRUE))
  expect_error(etr_rqa_reporting_text(a,list()),"metrics")
  expect_error(etr_recurrence_network_reporting_text(a),"network")
})

test_that("Stage 11 native radius and windows report complete-time support",{
  x<-.etr11_fixture()
  rp<-etr_recurrence_radius_profile(x,1L,radii=c(.1,1,2))
  text<-etr_recurrence_radius_profile_reporting_text(rp)
  expect_true(grepl("3 predeclared radii",text,fixed=TRUE))
  expect_true(grepl("No radius was selected automatically",text,fixed=TRUE))
  w<-etr_windowed_rqa(x,curve=1L,window=4L,step=2L,radius=1.5)
  report<-etr_windowed_rqa_reporting_text(w)
  expect_true(grepl("windows of 4 samples",report,fixed=TRUE))
  expect_true(grepl("producing 2 windows",report,fixed=TRUE))
  expect_true(grepl("partial window",report,fixed=TRUE))
  f<-etr_windowed_rqa_trajectory_set(x,metrics="recurrence_rate",
    window=4L,step=2L,radius=1.5)
  textf<-etr_windowed_rqa_functional_reporting_text(f)
  expect_true(grepl("3 source curve(s)",textf,fixed=TRUE))
  expect_true(grepl("Functional dimensions were recurrence_rate",textf,
    fixed=TRUE))
  expect_true(grepl("not treated as independent",textf,fixed=TRUE))
  expect_error(etr_windowed_rqa_functional_reporting_text(list()),
    "native functional")
})

test_that("Stage 11 schema reporting is conditional on declared bootstrap units",{
  b<-list(metrics=c("determinism","laminarity"),
    unit="participant",unit_ids=c("P1","P2"),
    participant_column="participant",n_bootstrap=199L,
    confidence_level=.95)
  p<-etr_rqa_metric_mean_bootstrap_reporting_text(b)
  expect_true(grepl("equal-weight participant units",p,fixed=TRUE))
  expect_true(grepl("199 percentile bootstrap replicates",p,fixed=TRUE))
  b$unit<-"curve"
  q<-etr_rqa_metric_mean_bootstrap_reporting_text(b)
  expect_true(grepl("curve-level independent units",q,fixed=TRUE))
  expect_false(grepl("equal-weight participant",q,fixed=TRUE))
  expect_error(etr_rqa_metric_mean_bootstrap_reporting_text(list()),
    "required")
  sens<-list(analyses=list(1,2,3),
    design_table=data.frame(overlap_fraction=c(0,.25,.5),
      profile_grid_spacing_time=c(.1,.2,.3),profile_time_unit="s"))
  t<-etr_windowed_rqa_sensitivity_reporting_text(sens)
  expect_true(grepl("3 predeclared window/step specifications",t,
    fixed=TRUE))
  expect_true(grepl("0.0% to 50.0%",t,fixed=TRUE))
  expect_true(grepl("no interpolation",t,fixed=TRUE))
  expect_error(etr_windowed_rqa_sensitivity_reporting_text(
    list(analyses=list(1),design_table=data.frame(x=1))),
    "design_table")
  mb<-list(functional_rqa=list(window_samples=5L,step_samples=2L,
     overlap_fraction=.6),band=list(unit_ids=c("a","b"),
     confidence_level=.9),unit="participant",participant_column="id")
  bt<-etr_windowed_rqa_mean_band_reporting_text(mb)
  expect_true(grepl("90.0% Gaussian multiplier band",bt,fixed=TRUE))
  expect_true(grepl("not window rows",bt,fixed=TRUE))
})

test_that("Stage 11 sensitivity reports report declared ranges, not inferential probability",{
  summary<-data.frame(metric=c("determinism","laminarity","recurrence_rate"),
    minimum=c(.1,.2,.3),maximum=c(.6,.7,.8))
  data<-list(summary_table=summary,table=data.frame(index=1:4),
    curve_id="c1",provenance=list(threshold_policy="target_recurrence_rate"))
  txt<-etr_rqa_parameter_sensitivity_reporting_text(data)
  expect_true(grepl("4 predeclared parameter specifications",txt,
    fixed=TRUE))
  expect_true(grepl("Recurrence rate was controlled",txt,fixed=TRUE))
  expect_error(etr_rqa_parameter_sensitivity_reporting_text(
    within(data,summary_table<-summary[summary$metric!="determinism",])),
    "missing or duplicated")
  t2<-data.frame(metric=c("exponent","initial_supported_reference_fraction"),
    minimum=c(-.01,.3),maximum=c(.2,.7),
    positive_specification_fraction=c(.75,NA_real_))
  kantz<-list(summary_table=t2,table=data.frame(index=1:4),
    curve_id="c1",exponent_unit="1/s")
  kt<-etr_kantz_parameter_sensitivity_reporting_text(kantz)
  expect_true(grepl("75.0%",kt,fixed=TRUE))
  expect_true(grepl("not sampling uncertainty",kt,fixed=TRUE))
  t3<-t2[t2$metric=="exponent",]
  ros<-list(summary_table=t3,table=data.frame(index=1:4),
    curve_id="c1",exponent_unit="1/s")
  rt<-etr_lyapunov_parameter_sensitivity_reporting_text(ros)
  expect_true(grepl("Rosenstein",rt,fixed=TRUE))
  expect_true(grepl("not as a probability of deterministic chaos",rt,
    fixed=TRUE))
})

test_that("Stage 11 Lyapunov, surrogate and return-map wording remains conditional",{
  ly<-list(divergence=list(time_unit="s"),
    fit_start=.1,fit_end=.4,n_fit_points=5L,exponent=.3,
    exponent_unit="1/s",r_squared=.8,standard_error=.04)
  t<-etr_largest_lyapunov_reporting_text(ly)
  expect_true(grepl("Rosenstein nearest-neighbor",t,fixed=TRUE))
  expect_true(grepl("not as standalone evidence",t,fixed=TRUE))
  ly$divergence$radius<-.25
  ly$divergence$min_neighbors<-3L
  expect_true(grepl("Kantz fixed-radius",etr_largest_lyapunov_reporting_text(ly),
    fixed=TRUE))
  sur<-list(surrogate_statistics=c(.1,.2,.3),n_surrogates=3L,
    method="iaaft",statistic="rqa_rate",alternative="greater",
    p_value=.25,random_state=42L,spectral_errors=c(.001,.003))
  text<-etr_surrogate_nonlinearity_reporting_text(sur)
  expect_true(grepl("plus-one Monte Carlo p-value",text,fixed=TRUE))
  expect_true(grepl("not as proof",text,fixed=TRUE))
  sur$surrogate_statistics[1L]<-Inf
  expect_error(etr_surrogate_nonlinearity_reporting_text(sur),
    "must all be finite")
  fit<-list(neighborhood_policy="k_nearest",neighborhood_value=8L,
    n_transitions=21L,design_condition_number=14,
    r_squared=c(.7,.8),provenance=list(crossing_provenance=list(
      section_dimension="x",section_value=0,direction="up")))
  stability<-list(eigenvalues=c(.3+0.2i,.3-0.2i),spectral_radius=.36,
    tolerance=.01,classification="contracting")
  report<-etr_return_map_stability_reporting_text(fit,stability)
  expect_true(grepl("section x=0",report,fixed=TRUE))
  expect_true(grepl("not interpreted as classical Floquet",report,fixed=TRUE))
})

test_that("Stage 11 frozen source inventory is conservative and offline",{
  was<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),121L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),259L)
  expect_equal(sum(z$native_implementation_started),91L)
  expect_equal(sum(z$native_implementation_stage==11L,na.rm=TRUE),15L)
  expect_equal(sum(!is.na(z$native_representation_stage)),7L)
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  expect_identical(was,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 11 pinned Python 1.2 windowed-RQA reporting oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 11 pinned Python 1.2 reporting oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr11_fixture()
  w<-etr_windowed_rqa(x,curve=1L,window=4L,step=2L,radius=1.5)
  py<-reticulate::py_call(etpy_get_export("WindowedRQAResult"),
    table=reticulate::r_to_py(w$table),
    window_samples=as.integer(w$window_samples),
    step_samples=as.integer(w$step_samples),
    dropped_tail_samples=as.integer(w$dropped_tail_samples),
    time_unit=w$time_unit)
  expected<-et_to_r(reticulate::py_call(
    etpy_get_export("windowed_rqa_reporting_text"),result=py))
  expect_identical(etr_windowed_rqa_reporting_text(w),
    as.character(expected))
})
