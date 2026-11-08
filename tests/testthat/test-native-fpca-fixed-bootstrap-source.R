# Frozen Python 1.2 stability.py fixed unit-draw numerical replay.
# Source: c1cd95ad718327550f7e55393ff38582872f7a94.
# Paired numerical developer evidence is not independent source certification.

.etr_fixed_fpca_sample<-function(){
  time<-seq(0,1,length.out=17L)
  z<-array(0,c(12L,17L,1L))
  for(i in seq_len(12L))
    z[i,,1L]<-sin(2*pi*time)*(1+i/11)+
      .18*i*time+.14*cos(pi*time*i/13)+
      .04*i*sin(4*pi*time)
  etr_trajectory_set(time,z,sprintf("curve%02d",seq_len(12L)),"x",
    metadata=data.frame(participant=rep(sprintf("p%d",1:6),each=2L)),
    coordinate_system="normalized",time_unit="s")
}

.etr_fixed_fpca_draws<-function(n=12L,b=4L){
  lapply(seq_len(b),function(i)
    as.integer((seq_len(n)*7L+i*3L+(seq_len(n)^2L)%%11L)%%n))
}

test_that("fixed curve-index draws replay both FPCA bootstrap estimators",{
  x<-.etr_fixed_fpca_sample();draws<-.etr_fixed_fpca_draws()
  set.seed(4321L);seed<-.Random.seed
  a<-etr_bootstrap_fpca_component_envelopes(x,n_bootstrap=4L,
    n_components=1L,level=.8,bootstrap_unit_indices=draws,
    random_state=3L)
  b<-etr_bootstrap_fpca_stability(x,n_bootstrap=4L,
    n_components=1L,bootstrap_unit_indices=draws,
    random_state=91L)
  expect_identical(.Random.seed,seed)
  expect_identical(dim(a$lower),c(1L,17L,1L))
  expect_identical(dim(a$similarities),c(4L,1L))
  expect_identical(dim(b$similarities),c(4L,1L))
  expect_equal(a$similarities,b$similarities,tolerance=1e-10)
  expect_true(all(a$lower<=a$median & a$median<=a$upper))
  expect_identical(a$provenance$random_engine,
    "caller_supplied_fixed_unit_indices")
  expect_identical(b$provenance$random_engine,
    "caller_supplied_fixed_unit_indices")
  expect_true(a$provenance$fixed_draw_replay)
  expect_true(b$provenance$fixed_draw_replay)
  other<-etr_bootstrap_fpca_component_envelopes(x,n_bootstrap=4L,
    n_components=1L,level=.8,bootstrap_unit_indices=draws,
    random_state=999L)
  expect_equal(a$lower,other$lower,tolerance=0)
  expect_identical(.Random.seed,seed)
})

test_that("fixed participant draws preserve whole-cluster resampling",{
  x<-.etr_fixed_fpca_sample()
  draws<-replicate(4L,as.integer(c(0L,3L,3L,5L,2L,1L)),
    simplify=FALSE)
  sample<-eyetrajectories:::.etr_fpca_stability_fixed_boot(x,
    "participant","participant",draws[[1L]])
  expect_identical(length(sample$curve_ids),12L)
  expect_identical(length(unique(sample$metadata$participant)),6L)
  expect_identical(as.character(sample$metadata$participant)[1L],
    "p1#bootstrap0000")
  expect_identical(as.character(sample$metadata$participant)[5L],
    "p4#bootstrap0002")
  z<-etr_bootstrap_fpca_component_envelopes(x,n_bootstrap=4L,
    n_components=1L,resample_unit="participant",
    participant_column="participant",bootstrap_unit_indices=draws)
  v<-etr_bootstrap_fpca_stability(x,n_bootstrap=4L,
    n_components=1L,resample_unit="participant",
    participant_column="participant",bootstrap_unit_indices=draws)
  expect_identical(dim(z$similarities),c(4L,1L))
  expect_equal(z$similarities,v$similarities,tolerance=1e-10)
  expect_true(all(is.finite(z$lower)))
})

test_that("bad bootstrap unit indices fail before fitting and cannot recycle",{
  x<-.etr_fixed_fpca_sample();valid<-.etr_fixed_fpca_draws()
  invalid<-list(valid[-1L],list(0L),replicate(4L,c(-1L,rep(0L,11L)),
    simplify=FALSE),replicate(4L,c(12L,rep(0L,11L)),simplify=FALSE),
    replicate(4L,c(0,rep(.5,11L)),simplify=FALSE),
    replicate(4L,rep(NA_real_,12L),simplify=FALSE),
    replicate(4L,matrix(0L,3L,4L),simplify=FALSE))
  for(values in invalid){
    expect_error(etr_bootstrap_fpca_component_envelopes(x,
      n_bootstrap=4L,n_components=1L,
      bootstrap_unit_indices=values),"bootstrap_unit_indices")
    expect_error(etr_bootstrap_fpca_stability(x,
      n_bootstrap=4L,n_components=1L,
      bootstrap_unit_indices=values),"bootstrap_unit_indices")
  }
  expect_error(etr_bootstrap_fpca_component_envelopes(x,
    n_bootstrap=4L,n_components=1L,resample_unit="participant",
    participant_column="participant",bootstrap_unit_indices=valid),
    "bootstrap_unit_indices")
})

test_that("frozen Python 1.2 FPCA envelope and stability share source draws",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Direct frozen Python 1.2 FPCA fixed-unit replay is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_fixed_fpca_sample()
  np<-reticulate::import("numpy",convert=FALSE)
  pd<-reticulate::import("pandas",convert=FALSE)
  py_meta<-pd$DataFrame(reticulate::r_to_py(list(
    participant=as.list(x$metadata$participant))))
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    metadata=py_meta,coordinate_system="normalized",time_unit="s")
  b<-4L;seed<-43L;n<-12L
  rng<-np$random$default_rng(as.integer(seed))
  draws<-lapply(seq_len(b),function(i)as.integer(et_to_r(
    rng$integers(as.integer(0L),as.integer(n),
      size=as.integer(n)))))
  local<-etr_bootstrap_fpca_component_envelopes(x,n_bootstrap=b,
    n_components=1L,level=.8,random_state=seed,
    bootstrap_unit_indices=draws)
  src<-reticulate::py_call(etpy_get_export(
    "bootstrap_fpca_component_envelopes"),trajectories=pyx,
    n_bootstrap=as.integer(b),n_components=as.integer(1L),
    scaling="none",resample_unit="curve",level=.8,
    random_state=as.integer(seed))
  # Eigenvector signs are arbitrary across the R and sklearn LAPACK
  # conventions. Align the reference component before comparing signed
  # envelope quantiles; corresponding tails must reverse if sign flips.
  source_reference<-et_to_r(src$reference$components)
  local_reference<-local$reference$components
  alignment<-if(sum(as.numeric(local_reference)*
    as.numeric(source_reference))>=0)1 else -1
  for(field in c("lower","median","upper")){
    source_values<-et_to_r(reticulate::py_get_attr(src,field))
    local_field<-if(alignment==1)field else
      if(field=="lower")"upper" else
      if(field=="upper")"lower" else "median"
    expect_equal(unname(alignment*local[[local_field]]),
      unname(source_values),tolerance=2e-7,
      info=paste("sign-invariant envelope",field))
  }
  expect_equal(unname(local$similarities),
    unname(et_to_r(src$similarities)),tolerance=2e-7)
  stable<-etr_bootstrap_fpca_stability(x,n_bootstrap=b,
    n_components=1L,random_state=seed,bootstrap_unit_indices=draws)
  source_stable<-reticulate::py_call(etpy_get_export(
    "bootstrap_fpca_stability"),trajectories=pyx,
    n_bootstrap=as.integer(b),n_components=as.integer(1L),
    scaling="none",resample_unit="curve",
    random_state=as.integer(seed))
  # Absolute similarity is sign invariant; raw signed similarities
  # are not comparable across independent eigensolver orientations.
  for(field in c("similarities","explained_variance_ratio")){
    expect_equal(unname(stable[[field]]),
      unname(et_to_r(reticulate::py_get_attr(source_stable,field))),
      tolerance=2e-7,info=paste("stability",field))
  }
  expect_equal(unname(stable$assignments),
    unname(et_to_r(source_stable$assignments)),tolerance=0)
})

test_that("same-draw FPCA evidence does not certify full Python exports",{
  row<-etr_native_parity_catalog()
  r<-row[row$python_name=="bootstrap_fpca_component_envelopes"&
    row$is_python_function,,drop=FALSE]
  expect_equal(nrow(r),1L)
  expect_true(r$source_contract_gap_unresolved)
  expect_false(r$one_to_one_native_contract_complete)
})
