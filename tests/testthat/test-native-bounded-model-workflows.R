# Frozen Python 1.2 source workflow boundaries. Native alternatives are
# deliberately not labelled Python likelihood/PACE algorithm equivalents.
.etr_bounded_workflow_fixture<-function(){
  time<-seq(0,1,length.out=11L)
  n<-12L;np<-4L;nt<-3L
  vals<-array(0,c(n,length(time),1L))
  participants<-rep(sprintf("P%03d",seq_len(np)),each=nt)
  design<-data.frame(curve_id=sprintf("c%02d",seq_len(n)),
    stimulus=rep(c(0,0,1),np))
  for(i in seq_len(n)){
    g<-(i-1L)%/%nt+1L;j<-(i-1L)%%nt+1L
    vals[i,,1L]<-.1+g*.04+design$stimulus[i]*.12+
      .2*sin(pi*time)+j*.05*cos(2*pi*time)+.02*(i%%5)*time^2
  }
  x<-etr_trajectory_set(time,vals,design$curve_id,
    "response",metadata=data.frame(participant_id=participants),
    time_unit="s",coordinate_system="unknown")
  list(trajectories=x,design=design)
}

test_that("native mixed workflow declares independent method-of-moments estimator",{
  fixture<-.etr_bounded_workflow_fixture()
  cfg<-list(predictors="stimulus",participant_column="participant_id",
    dimension="response",estimator="two_level_functional_method_of_moments")
  x<-etr_run_functional_mixed_effects_workflow(
    fixture$trajectories,fixture$design,cfg)
  expect_s3_class(x,"etr_functional_mixed_effects_workflow")
  expect_identical(x$fit$estimator,"two_level_functional_method_of_moments")
  expect_identical(x$fit$n_participants,4L)
  expect_identical(x$fit$n_curves,12L)
  expect_identical(x$workflow_contract,"functional_mixed_effects:native_moments_only")
  expect_true(is.data.frame(x$tables$coefficients))
  expect_identical(x$provenance$source_python_equivalent,FALSE)
  expect_identical(x$provenance$REML,FALSE)
  expect_identical(x$provenance$full_source_contract_certified,FALSE)
  expect_identical(x$steps[[1L]]$status,"completed")
  expect_identical(x$steps[[1L]][["function"]],
    "fit_functional_mixed_effects_regression_native_moments")
  expect_error(etr_run_functional_mixed_effects_workflow(
    fixture$trajectories,fixture$design,
    modifyList(cfg,list(estimator="Python_MixedLM"))),
    "not implemented")
  expect_error(etr_run_functional_mixed_effects_workflow(
    fixture$trajectories,fixture$design,
    modifyList(cfg,list(preprocessing=list(list(kind="smooth"))))),
    "empty preprocessing")
  expect_error(etr_run_functional_mixed_effects_workflow(
    fixture$trajectories,fixture$design,
    modifyList(cfg,list(reml=TRUE))),
    "unsupported fields")
})

test_that("native sparse workflow rejects source Python estimator conflation",{
  cfg<-list(dimension="value",backend="fdapace",
    max_components=1L,fve=.9)
  expect_error(etr_run_sparse_fpca_workflow(list(),cfg),
    "trajectories")
  expect_error(etr_run_sparse_fpca_workflow(list(),
    modifyList(cfg,list(backend="python"))),"fdapace")
  expect_error(etr_run_sparse_fpca_workflow(list(),
    modifyList(cfg,list(bandwidth_selection=list()))),"unsupported fields")
  expect_error(etr_run_sparse_fpca_workflow(list(),
    modifyList(cfg,list(preprocessing=list(scale=TRUE)))),
    "empty preprocessing")
  expect_error(etr_run_sparse_fpca_workflow(list(),
    cfg,observation_process=list()),"observation_process")
  expect_error(etr_run_sparse_fpca_workflow(list(),
    modifyList(cfg,list(dimension=""))),
    "dimension")
})

test_that("explicit fdapace workflow can fit native irregular observations",{
  if(!identical(Sys.getenv("ET_RUN_FDAPACE_TESTS"),"true"))
    skip("optional R fdapace numerical backend smoke test is opt-in")
  if(!requireNamespace("fdapace",quietly=TRUE))
    skip("optional independent R fdapace backend not installed")
  grid<-seq(0,1,length.out=25L)
  times<-lapply(seq_len(24L),function(i)
    grid[sort(unique(c(1L,25L,seq(2L,24L,by=3L)+((i-1L)%%3L))))])
  ys<-lapply(seq_len(24L),function(i){
    t<-times[[i]]
    sin(2*pi*t)+(.15+.02*i)*cos(pi*t)+.025*((i%%7)-3)*t
  })
  sparse<-etr_sparse_curves(times,ys,
    sprintf("s%02d",seq_len(24L)),"s")
  fit<-etr_run_sparse_fpca_workflow(sparse,list(dimension="value",
    backend="fdapace",max_components=1L,fve=.9))
  expect_s3_class(fit,"etr_sparse_fpca_workflow")
  expect_s3_class(fit$fit,"etr_sparse_pace")
  expect_equal(nrow(fit$tables$scores),24L)
  expect_identical(fit$provenance$source_python_equivalent,FALSE)
  expect_identical(fit$provenance$raw_interpolation_performed,FALSE)
  expect_identical(fit$provenance$full_source_contract_certified,FALSE)
  expect_match(fit$reports$fit,"NOT custom Python 1.2 PACE",fixed=TRUE)
})
