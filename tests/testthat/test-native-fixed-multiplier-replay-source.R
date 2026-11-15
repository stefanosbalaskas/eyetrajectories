# Frozen Python 1.2 inference.py and functional_rqa.py.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Same-draw developer numerical replay is not independent certification.

.etr_multiplier_replay_fixture<-function() {
  nt<-15L;n<-6L;t<-seq(0,1,length.out=nt)
  z<-array(0,c(n,nt,2L))
  for(i in seq_len(n)) {
    z[i,,1L]<-sin(2*pi*t*(1+i/15))+(i%%3)*t/3+
      .10*i*cos(3*pi*t)
    z[i,,2L]<-cos(2*pi*t+(i/6))+t*(i/7)+
      .09*sin(pi*t*i/2)
  }
  etr_trajectory_set(t,z,sprintf("c%d",seq_len(n)),c("x","y"),
    metadata=data.frame(participant=rep(c("p1","p2","p3"),each=2L)),
    coordinate_system="normalized",time_unit="s")
}

.etr_multiplier_replay_draws<-function(n_draw=100L,n_unit=6L) {
  # An explicit matrix is a computational audit input, NOT a claim that
  # R and NumPy PCG64 implement the same random-number generator.
  matrix(sin(seq_len(n_draw*n_unit)*0.137)+
    cos(seq_len(n_draw*n_unit)*0.211),nrow=n_draw,ncol=n_unit)
}

test_that("fixed Gaussian draw injection reproduces full observed-grid calibration", {
  x<-.etr_multiplier_replay_fixture()
  draws<-.etr_multiplier_replay_draws()
  set.seed(911L);original<-.Random.seed
  a<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    confidence_level=.9,gaussian_multiplier_draws=draws,
    random_state=11L)
  expect_identical(.Random.seed,original)
  expect_identical(dim(a$mean),c(15L,2L))
  expect_identical(length(a$max_statistics),100L)
  expect_true(all(is.finite(a$max_statistics)))
  expect_gt(max(a$max_statistics),0)
  expect_equal(a$critical_value,
    sort(a$max_statistics)[1L+ceiling(99*.9)],tolerance=0)
  expect_equal(a$lower,a$mean-a$critical_value*a$pointwise_se,
    tolerance=1e-13)
  expect_equal(a$upper,a$mean+a$critical_value*a$pointwise_se,
    tolerance=1e-13)
  expect_identical(a$provenance$functional_mean_band$random_engine,
    "caller_supplied_fixed_Gaussian_matrix")
  expect_true(a$provenance$functional_mean_band$fixed_draw_replay)
  b<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    confidence_level=.9,gaussian_multiplier_draws=draws,
    random_state=999L)
  expect_equal(a$max_statistics,b$max_statistics,tolerance=0)
  expect_equal(a$critical_value,b$critical_value,tolerance=0)
  expect_identical(.Random.seed,original)
  ordinary<-etr_multiplier_functional_mean_band(x,
    n_multiplier=100L,random_state=11L)
  expect_identical(ordinary$provenance$functional_mean_band$random_engine,
    "numpy_pcg64")
  expect_false(ordinary$provenance$functional_mean_band$fixed_draw_replay)
  expect_identical(.Random.seed,original)
  legacy<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    random_state=11L,random_engine="base_R")
  legacy_draws<-withr::with_seed(11L,
    matrix(stats::rnorm(600L),100L,6L,byrow=TRUE))
  replay<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
    gaussian_multiplier_draws=legacy_draws)
  expect_identical(legacy$max_statistics,replay$max_statistics)
  expect_identical(legacy$provenance$functional_mean_band$random_engine,
    "base_R_not_NumPy")
  expect_identical(.Random.seed,original)
})

test_that("invalid fixed multiplier arrays cannot silently recycle units", {
  x<-.etr_multiplier_replay_fixture()
  good<-.etr_multiplier_replay_draws()
  invalid<-list(good[-1L,,drop=FALSE],good[,-1L,drop=FALSE],
    unname(as.vector(good)),matrix(NA_real_,100L,6L),
    matrix(Inf,100L,6L),matrix("1",100L,6L),
    matrix(1+1i,100L,6L))
  for(draws in invalid)expect_error(
    etr_multiplier_functional_mean_band(x,n_multiplier=100L,
      gaussian_multiplier_draws=draws),"gaussian_multiplier_draws")
  expect_error(etr_multiplier_functional_mean_band(x,
    n_multiplier=99L,gaussian_multiplier_draws=good),"n_multiplier")
})

test_that("whole-participant unit draws propagate through windowed RQA band", {
  x<-.etr_multiplier_replay_fixture()
  draws<-.etr_multiplier_replay_draws(n_unit=3L)
  a<-etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,radius=.75,
    unit="participant",participant_column="participant",
    n_multiplier=100L,gaussian_multiplier_draws=draws)
  expect_s3_class(a,"etr_windowed_rqa_mean_band")
  expect_identical(a$band$unit_ids,c("p1","p2","p3"))
  expect_identical(a$band$curves_per_unit,c(2L,2L,2L))
  expect_identical(a$band$provenance$functional_mean_band$random_engine,
    "caller_supplied_fixed_Gaussian_matrix")
  replay<-etr_multiplier_functional_mean_band(a$functional_rqa$trajectories,
    unit="participant",participant_column="participant",n_multiplier=100L,
    gaussian_multiplier_draws=draws)
  expect_equal(a$band$max_statistics,replay$max_statistics,tolerance=0)
  expect_equal(a$band$critical_value,replay$critical_value,tolerance=0)
  expect_equal(a$band$lower,replay$lower,tolerance=0)
  expect_error(etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,radius=.75,
    unit="participant",participant_column="participant",
    n_multiplier=100L,gaussian_multiplier_draws=matrix(0,100L,6L)),
    "gaussian_multiplier_draws")
})

test_that("frozen Python 1.2 Gaussian streams replay full mean bands", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 deterministic Gaussian oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_multiplier_replay_fixture()
  np<-reticulate::import("numpy",convert=FALSE)
  pandas<-reticulate::import("pandas",convert=FALSE)
  py_meta<-pandas$DataFrame(reticulate::r_to_py(list(
    participant=as.list(x$metadata$participant))))
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=py_meta,coordinate_system="normalized",time_unit="s")
  for(unit in c("curve","participant")){
    col<-if(unit=="participant")"participant" else NULL
    n_unit<-if(unit=="curve")6L else 3L
    rng<-np$random$default_rng(as.integer(71L))
    source_draws<-et_to_r(rng$normal(size=reticulate::tuple(
      as.integer(100L),as.integer(n_unit))))
    local<-etr_multiplier_functional_mean_band(x,n_multiplier=100L,
      unit=unit,participant_column=col,confidence_level=.91,
      gaussian_multiplier_draws=source_draws)
    source<-reticulate::py_call(etpy_get_export(
      "multiplier_functional_mean_band"),trajectories=pyx,
      unit=unit,participant_column=col,confidence_level=.91,
      n_multiplier=as.integer(100L),random_state=as.integer(71L))
    for(field in c("mean","pointwise_se","lower","upper"))
      expect_equal(unname(local[[field]]),
        unname(et_to_r(reticulate::py_get_attr(source,field))),
        tolerance=1e-10,info=paste(unit,field))
    expect_equal(local$max_statistics,
      as.numeric(et_to_r(source$max_statistics)),tolerance=1e-10,
      info=paste(unit,"Gaussian max statistics"))
    expect_equal(local$critical_value,
      as.numeric(et_to_r(source$critical_value)),tolerance=1e-10,
      info=paste(unit,"calibrated critical value"))
  }
})

test_that("frozen Python 1.2 whole-participant RQA band replays every statistic", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 functional RQA multiplier oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_multiplier_replay_fixture()
  np<-reticulate::import("numpy",convert=FALSE)
  pandas<-reticulate::import("pandas",convert=FALSE)
  py_meta<-pandas$DataFrame(reticulate::r_to_py(list(
    participant=as.list(x$metadata$participant))))
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=py_meta,coordinate_system="normalized",time_unit="s")
  rng<-np$random$default_rng(as.integer(83L))
  draws<-et_to_r(rng$normal(size=reticulate::tuple(
    as.integer(100L),as.integer(3L))))
  local<-etr_windowed_rqa_functional_mean_band(x,
    metrics="recurrence_rate",window=5L,step=2L,radius=.75,
    unit="participant",participant_column="participant",
    n_multiplier=100L,confidence_level=.90,
    gaussian_multiplier_draws=draws)
  source<-reticulate::py_call(etpy_get_export(
    "windowed_rqa_functional_mean_band"),
    trajectories=pyx,metrics=as.list("recurrence_rate"),
    window=as.integer(5L),step=as.integer(2L),radius=.75,
    unit="participant",participant_column="participant",
    dimensions=as.list(x$dimension_names),n_multiplier=as.integer(100L),
    confidence_level=.90,random_state=as.integer(83L))
  for(field in c("mean","pointwise_se","lower","upper"))
    expect_equal(unname(local$band[[field]]),
      unname(et_to_r(reticulate::py_get_attr(source$band,field))),
      tolerance=1e-10,info=paste("RQA",field))
  expect_equal(local$band$max_statistics,
    as.numeric(et_to_r(source$band$max_statistics)),tolerance=1e-10)
  expect_equal(local$band$critical_value,
    as.numeric(et_to_r(source$band$critical_value)),tolerance=1e-10)
})

test_that("same-draw scientific evidence does not independently certify exports", {
  d<-etr_native_parity_catalog()
  row<-d[d$python_name=="windowed_rqa_functional_mean_band" &
    d$is_python_function,,drop=FALSE]
  expect_equal(nrow(row),1L)
  .etr_expect_source_gap_matches_registry(row)
  expect_false(row$one_to_one_native_contract_complete)
})
