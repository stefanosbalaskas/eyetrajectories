# Frozen public Python oracle: eyetrajectoriespy==1.2.0,
# commit c1cd95ad718327550f7e55393ff38582872f7a94,
# src/eyetrajectoriespy/reporting.py, typed source result dataclasses.
.etr_simulation_report_source_pair <- function(variant="base") {
  stopifnot(variant %in% c("base","student","no_group"))
  student<-identical(variant,"student")
  no_group<-identical(variant,"no_group")
  n<-4L
  grid<-seq(0,1,length.out=5L)
  metadata<-data.frame(
    participant_id=c("p1","p1","p2","p2"),
    trial_id=c("a","b","a","b"),stringsAsFactors=FALSE)
  if(no_group)metadata$participant_id<-NULL
  warp<-matrix(rep(grid,each=n),nrow=n)
  warp[2L,3L]<-.63
  scores<-matrix(seq_len(8L)/10,nrow=n)
  masks<-list(c(FALSE,TRUE,FALSE,FALSE,FALSE),
    rep(FALSE,5L),c(TRUE,FALSE,FALSE,FALSE,FALSE),rep(FALSE,5L))
  prov<-if(no_group)list() else list(
    phase_variation_kind=if(student)"fish's phase" else "power",
    missingness_kind=if(student)"fish's dropout" else "mcar",
    raw_dense_to_irregular_interpolation_performed=FALSE)
  list(
    observations=list(curve_ids=paste0("curve_",seq_len(n))),
    truth=list(
      metadata=metadata,truth_grid=grid,
      pre_missing_observation_times=rep(list(grid),n),
      observation_times=rep(list(grid),n),
      missingness_mask=masks,phase_warps_on_truth_grid=warp,
      eigenvalues=c(1,.35),scores=scores,
      curve_scores=scores/2,trial_scores=scores/4,
      participant_scores=matrix(c(.3,.1,.6,.2),nrow=2L),
      dimension_names=c("x","y"),
      participant_eigenvalues=c(.2,.05),trial_eigenvalues=c(.1,.02),
      measurement_noise_covariance=diag(c(.0025,.04)),
      observation_design=if(student)"irregular's β" else "dense",
      score_distribution=if(student)"student_t" else "normal",
      score_distribution_parameters=if(student)list(df=3.375) else list(),
      random_state=if(no_group)NULL else if(student)2^32+9 else 821L,
      provenance=prov))
}
test_that("simulation source frame and reporter preserve source scientific meaning",{
  for(variant in c("base","student","no_group")){
    x<-.etr_simulation_report_source_pair(variant)
    frame<-etr_functional_simulation_truth_frame(x)
    txt<-etr_functional_simulation_reporting_text(x)
    expect_identical(nrow(frame),4L)
    expect_identical(frame$n_missing_by_design,c(1L,0L,1L,0L))
    expect_equal(frame$max_phase_displacement,c(0,.13,0,0),
      tolerance=1e-14)
    expect_equal(frame$score_total_2,c(.5,.6,.7,.8))
    expect_match(txt,"Exact latent curves, score sources",fixed=TRUE)
    if(variant=="student"){
      expect_match(txt,'observation design was "irregular\'s β"',fixed=TRUE)
      expect_match(txt,'missingness mechanism ("fish\'s dropout"',fixed=TRUE)
      expect_match(txt,'Phase variation used "fish\'s phase"',fixed=TRUE)
      expect_match(txt,"student_t (df=3.38)",fixed=TRUE)
    }
    if(variant=="no_group"){
      expect_false("score_participant_1"%in%names(frame))
      expect_match(txt,"random state was None",fixed=TRUE)
      expect_false(grepl("No dense-to-irregular raw-trajectory interpolation",
        txt,fixed=TRUE))
    }else{
      expect_true("score_participant_1"%in%names(frame))
      expect_equal(frame$score_participant_1,c(.3,.3,.1,.1))
    }
  }
})
test_that("paired simulation science adapters reject malformed native records",{
  x<-.etr_simulation_report_source_pair()
  bad<-x;bad$truth$missingness_mask[[1L]]<-logical(3L)
  expect_error(etr_functional_simulation_truth_frame(bad),"missingness masks")
  expect_error(etr_functional_simulation_reporting_text(bad),"missingness masks")
  bad<-x;bad$truth$phase_warps_on_truth_grid<-matrix(0,2,5)
  expect_error(etr_functional_simulation_truth_frame(bad),"phase warps")
  bad<-x;bad$truth$eigenvalues[1]<-NA_real_
  expect_error(etr_functional_simulation_truth_frame(bad),"eigenvalues")
  bad<-x;bad$truth$measurement_noise_covariance[1,1]<-Inf
  expect_error(etr_functional_simulation_reporting_text(bad),
    "noise covariance")
  expect_error(etr_functional_simulation_reporting_text(x,digits=-1L),
    "digits")
  expect_error(etr_functional_simulation_reporting_text(x,digits=1.5),
    "digits")
})
test_that("typed frozen Python 1.2 frame and 12 reporting texts equal native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 source pair differential test opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "def _etr_pair_make(cls,**fields):",
    "    obj=object.__new__(cls)",
    "    for key,val in fields.items():object.__setattr__(obj,key,val)",
    "    return obj",
    "def _etr_sim_truth_pair(variant,digits):",
    "    student=variant=='student';no_group=variant=='no_group'",
    "    grid=np.linspace(0.,1.,5)",
    "    warp=np.tile(grid,(4,1));warp[1,2]=.63",
    "    metadata=pd.DataFrame({'trial_id':['a','b','a','b']})",
    "    if not no_group:metadata.insert(0,'participant_id',['p1','p1','p2','p2'])",
    "    masks=(np.array([False,True,False,False,False]),",
    "      np.array([False]*5),np.array([True,False,False,False,False]),",
    "      np.array([False]*5))",
    "    scores=np.array([[.1,.5],[.2,.6],[.3,.7],[.4,.8]])",
    "    provenance={} if no_group else {",
    "      'phase_variation_kind':\"fish's phase\" if student else 'power',",
    "      'missingness_kind':\"fish's dropout\" if student else 'mcar',",
    "      'raw_dense_to_irregular_interpolation_performed':False}",
    "    truth=_etr_pair_make(et.FunctionalSimulationTruth,",
    "      metadata=metadata,truth_grid=grid,",
    "      pre_missing_observation_times=tuple(np.array(grid) for _ in range(4)),",
    "      observation_times=tuple(np.array(grid) for _ in range(4)),",
    "      missingness_mask=masks,phase_warps_on_truth_grid=warp,",
    "      eigenvalues=np.array([1.,.35]),scores=scores,",
    "      curve_scores=scores/2,trial_scores=scores/4,",
    "      participant_scores=np.array([[.3,.6],[.1,.2]]),",
    "      dimension_names=('x','y'),",
    "      participant_eigenvalues=np.array([.2,.05]),",
    "      trial_eigenvalues=np.array([.1,.02]),",
    "      measurement_noise_covariance=np.diag([.0025,.04]),",
    "      observation_design=\"irregular's β\" if student else 'dense',",
    "      score_distribution='student_t' if student else 'normal',",
    "      score_distribution_parameters={'df':3.375} if student else {},",
    "      random_state=None if no_group else (2**32+9 if student else 821),",
    "      provenance=provenance)",
    "    observations=_etr_pair_make(et.TrajectorySet,",
    "      curve_ids=tuple('curve_'+str(i) for i in range(1,5)))",
    "    obj=_etr_pair_make(et.FunctionalSimulationResult,",
    "      truth=truth,observations=observations)",
    "    return (et.functional_simulation_truth_frame(obj),",
    "      et.functional_simulation_reporting_text(obj,digits=digits))"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_sim_truth_pair")
  for(variant in c("base","student","no_group")){
    native<-.etr_simulation_report_source_pair(variant)
    expectedFrame<-NULL
    for(digits in c(1L,3L,6L,11L)){
      expected<-reticulate::py_to_r(
        reticulate::py_call(oracle,variant,as.integer(digits)))
      actual<-etr_functional_simulation_reporting_text(native,digits)
      expect_identical(actual,as.character(expected[[2L]]),
        info=paste(variant,digits,"report"))
      if(is.null(expectedFrame))expectedFrame<-expected[[1L]]
    }
    frame<-etr_functional_simulation_truth_frame(native)
    expect_identical(names(frame),names(expectedFrame),info=variant)
    expect_identical(nrow(frame),nrow(expectedFrame),info=variant)
    for(col in names(frame)){
      if(is.numeric(frame[[col]])&&is.numeric(expectedFrame[[col]]))
        expect_equal(as.numeric(frame[[col]]),as.numeric(expectedFrame[[col]]),
          tolerance=1e-14,info=paste(variant,col))
      else expect_identical(as.character(frame[[col]]),
        as.character(expectedFrame[[col]]),info=paste(variant,col))
    }
  }
})
