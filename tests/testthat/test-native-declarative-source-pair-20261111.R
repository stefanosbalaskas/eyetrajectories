# Frozen Python 1.2 source contracts, commit
# c1cd95ad718327550f7e55393ff38582872f7a94:
# workflows/_core.py::workflow_config_to_dict
# simulate.py::expand_functional_simulation_scenarios
# Native S3 declarations map semantically to frozen Python dataclasses;
# no Python invocation occurs within either native R export.

.etr_pair_config_case <- function(case) {
  step <- etr_preprocessing_step_config(
    "smooth_trajectories",
    parameters=list(window=3L,method="mean",enabled=TRUE),
    scientific_effect="Explicitly requested smoothing")
  if(case=="empty_plan")return(etr_preprocessing_plan())
  if(case=="step")return(step)
  if(case=="plan")return(etr_preprocessing_plan(list(step,
    etr_preprocessing_step_config("reject_artifacts",
      list(threshold=.125), "Remove flagged observations"))))
  if(case=="nested")return(etr_workflow_config(list(
    preprocessing=etr_preprocessing_plan(list(step)),
    select_components=FALSE,n_components=3L,
    weights=matrix(c(.25,.5,.75,1.0),nrow=2L,byrow=TRUE),
    # Frozen Python converts pathlib.Path("fish/study") to its native
    # platform string: Windows backslashes, POSIX forward slashes.
    # R has no pathlib Path object; supply the matching serialized string
    # without weakening equality of the nested metadata or other fields.
    metadata=list(site="fish's β",
      path=if(.Platform$OS.type=="windows") "fish\\study" else "fish/study",
      notes=list("α","β")),empty=list())))
  if(case=="decision")return(etr_workflow_config(
    list(value=list("right","left"),source="audited_selector",
      criterion="retain both axes")))
  stop("unknown case")
}

.etr_pair_expand_native <- function(kind,policy) {
  multi <- identical(kind,"covariance")
  irregular <- identical(kind,"irregular")
  base <- etr_functional_simulation_scenario(
    name=if(multi)"multi" else if(irregular)"irregular" else "fish β",
    truth_grid=c(0,.5,1),eigenvalues=c(2,1),
    n_participants=3L,replicates=2L,seed_start=31L,
    observation_design=if(irregular)"irregular" else "dense",
    samples_per_curve=if(irregular)c(3L,5L) else NULL,
    dimension_names=if(multi)c("x","y") else "value")
  factors <- switch(kind,
    scalar=list(n_participants=c(3L,5L),
      trials_per_participant=c(1L,2L)),
    float=list(score_df=c(3.375,5.0)),
    irregular=list(samples_per_curve=list(c(3L,5L),c(5L,7L)),
      score_distribution=c("normal","student_t")),
    covariance=list(measurement_noise_covariance=list(
      matrix(c(.09,.01,.01,.04),nrow=2L,byrow=TRUE),NULL),
      participant_eigenvalues=list(c(.3,.1),NULL)))
  etr_expand_functional_simulation_scenarios(base,factors,
    seed_policy=policy)
}

.etr_pair_compare_json <- function(native,py,info="source") {
  # reticulate can convert an empty Python dictionary to an R list with
  # names=character(0), whereas a native list() has names=NULL.
  # Both have zero fields: preserve strict key/order checks otherwise.
  if(is.list(native)&&is.list(py)&&length(native)==0L&&length(py)==0L)
    return(invisible(NULL))
  expect_identical(names(native),names(py),info=paste(info,"keys"))
  if(is.list(native)) {
    for(n in names(native))
      .etr_pair_compare_json(native[[n]],py[[n]],paste(info,n))
    if(is.null(names(native))){
      expect_identical(length(native),length(py),info=info)
      for(i in seq_along(native))
        .etr_pair_compare_json(native[[i]],py[[i]],
          paste(info,i))
    }
  } else if(is.numeric(native)&&is.numeric(py))
    expect_equal(as.numeric(native),as.numeric(py),tolerance=1e-14,
      info=info)
  else expect_identical(native,py,info=info)
}

.etr_pair_compare_frame <- function(a,b,info){
  expect_identical(names(a),names(b),info=info)
  expect_identical(nrow(a),nrow(b),info=info)
  for(n in names(a)){
    x<-a[[n]];y<-b[[n]]
    expect_identical(is.na(x),is.na(y),info=paste(info,n,"missing"))
    keep<-!is.na(x)
    if(is.numeric(x)&&is.numeric(y))
      expect_equal(as.numeric(x[keep]),as.numeric(y[keep]),
        tolerance=1e-14,info=paste(info,n))
    else expect_identical(as.character(x[keep]),as.character(y[keep]),
      info=paste(info,n))
  }
}

test_that("source configuration conversion rechecks mutable scientific plans",{
  x<-etr_preprocessing_step_config("smooth",list(window=3L),"No bias")
  x[["function"]]<-""
  expect_error(etr_workflow_config_to_dict(x),"nonempty")
  x<-etr_preprocessing_step_config("smooth",list(window=3L),"No bias")
  x[["parameters"]]$window<-Inf
  expect_error(etr_workflow_config_to_dict(x),"nonfinite")
  x<-etr_preprocessing_plan(list(
    etr_preprocessing_step_config("smooth",list(),"Effect")))
  x$steps[[1L]][["scientific_effect"]]<-""
  expect_error(etr_workflow_config_to_dict(x),"effect")
  x<-etr_workflow_config(list(plan=etr_preprocessing_plan(list(
    etr_preprocessing_step_config("smooth",list(),"Effect")))))
  x$plan$steps[[1L]][["function"]]<-""
  expect_error(etr_workflow_config_to_dict(x),"nonempty")
  expect_error(etr_workflow_config_to_dict(list()),"native workflow")
})

test_that("source scenario expansion rechecks frozen-base scientific validity",{
  base<-etr_functional_simulation_scenario("fish",c(0,.5,1),
    c(2,1),n_participants=3L,replicates=2L,seed_start=31L)
  bad<-base;bad$eigenvalues<-c(1,2)
  expect_error(etr_expand_functional_simulation_scenarios(
    bad,list(n_participants=c(2L,4L))),"descending order")
  bad<-base;bad$replicates<-0L
  expect_error(etr_expand_functional_simulation_scenarios(
    bad,list(n_participants=c(2L,4L))),"replicates")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list()),"nonempty")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(seed_start=c(1L,2L))),"seed_start")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(n_participants=integer())),"at least one level")
  expect_error(etr_expand_functional_simulation_scenarios(base,
    list(n_participants=c(2L,4L)),seed_policy="invalid"),"arg")
  for(kind in c("scalar","float","irregular","covariance")){
    shared<-.etr_pair_expand_native(kind,"shared")
    disjoint<-.etr_pair_expand_native(kind,"disjoint")
    expect_identical(vapply(shared,function(x)x$seed_start,integer(1L)),
      rep(31L,length(shared)))
    expect_identical(vapply(disjoint,function(x)x$seed_start,integer(1L)),
      seq.int(31L,by=2L,length.out=length(disjoint)))
    expect_identical(vapply(shared,function(x)x$name,character(1L)),
      vapply(disjoint,function(x)x$name,character(1L)))
  }
  expect_match(.etr_pair_expand_native("float","shared")[[2L]]$name,
    "score_df=5.0",fixed=TRUE)
  expect_match(.etr_pair_expand_native("covariance","shared")[[1L]]$name,
    "measurement_noise_covariance=array4",fixed=TRUE)
})

test_that("typed Python 1.2 config and factor-grid source results match R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "from dataclasses import make_dataclass",
    "from pathlib import Path",
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "import eyetrajectoriespy.workflows as wf",
    "def _etr_pair_config_source(case):",
    "    step=wf.PreprocessingStepConfig(function='smooth_trajectories',",
    "      parameters={'window':3,'method':'mean','enabled':True},",
    "      scientific_effect='Explicitly requested smoothing')",
    "    if case=='empty_plan': obj=wf.PreprocessingPlan()",
    "    elif case=='step': obj=step",
    "    elif case=='plan': obj=wf.PreprocessingPlan(steps=(step,",
    "      wf.PreprocessingStepConfig(function='reject_artifacts',",
    "        parameters={'threshold':.125},",
    "        scientific_effect='Remove flagged observations')))",
    "    elif case=='nested':",
    "      cfg=make_dataclass('NativeEquivalent',",
    "        [('preprocessing',object),('select_components',bool),",
    "         ('n_components',int),('weights',object),",
    "         ('metadata',object),('empty',object)],frozen=True)",
    "      obj=cfg(wf.PreprocessingPlan(steps=(step,)),False,3,",
    "        np.array([[.25,.5],[.75,1.0]]),",
    "        {'site':\"fish's β\",'path':Path('fish/study'),",
    "         'notes':pd.Index(['α','β'])}, {})",
    "    elif case=='decision':",
    "      obj=wf.WorkflowDecisionRecord(value=pd.Index(['right','left']),",
    "        source='audited_selector',criterion='retain both axes')",
    "    else: raise ValueError(case)",
    "    return wf.workflow_config_to_dict(obj)",
    "def _etr_pair_expansion_source(kind,policy):",
    "    multi=(kind=='covariance'); irregular=(kind=='irregular')",
    "    base=et.FunctionalSimulationScenario(",
    "      name='multi' if multi else 'irregular' if irregular else 'fish β',",
    "      truth_grid=[0.,.5,1.],eigenvalues=(2.,1.),",
    "      n_participants=3,replicates=2,seed_start=31,",
    "      observation_design='irregular' if irregular else 'dense',",
    "      samples_per_curve=(3,5) if irregular else None,",
    "      dimension_names=('x','y') if multi else ('value',))",
    "    if kind=='scalar': factors={'n_participants':[3,5],",
    "      'trials_per_participant':[1,2]}",
    "    elif kind=='float': factors={'score_df':[3.375,5.0]}",
    "    elif kind=='irregular': factors={'samples_per_curve':[(3,5),(5,7)],",
    "      'score_distribution':['normal','student_t']}",
    "    elif kind=='covariance':",
    "      factors={'measurement_noise_covariance':[",
    "        np.array([[.09,.01],[.01,.04]]),None],",
    "        'participant_eigenvalues':[(.3,.1),None]}",
    "    else: raise ValueError(kind)",
    "    scenarios=et.expand_functional_simulation_scenarios(",
    "      base,factors,seed_policy=policy)",
    "    return (et.functional_simulation_scenario_frame(scenarios),",
    "       [(s.name,s.seed_start) for s in scenarios])"
  ),collapse="\n"),convert=FALSE)
  py_config<-reticulate::py_get_attr(reticulate::py,
    "_etr_pair_config_source")
  for(case in c("empty_plan","step","plan","nested","decision")){
    native<-etr_workflow_config_to_dict(.etr_pair_config_case(case))
    expected<-reticulate::py_to_r(reticulate::py_call(py_config,case))
    .etr_pair_compare_json(native,expected,paste("config",case))
  }
  py_expand<-reticulate::py_get_attr(reticulate::py,
    "_etr_pair_expansion_source")
  for(kind in c("scalar","float","irregular","covariance")){
    for(policy in c("shared","disjoint")){
      result<-reticulate::py_to_r(reticulate::py_call(
        py_expand,kind,policy))
      native<-.etr_pair_expand_native(kind,policy)
      expected_frame<-as.data.frame(result[[1L]])
      native_frame<-etr_functional_simulation_scenario_frame(native)
      .etr_pair_compare_frame(native_frame,expected_frame,
        paste("scenario",kind,policy))
      expected_names<-vapply(result[[2L]],
        function(x)as.character(x[[1L]]),character(1L))
      expected_seeds<-vapply(result[[2L]],
        function(x)as.integer(x[[2L]]),integer(1L))
      expect_identical(vapply(native,function(x)x$name,character(1L)),
        expected_names)
      expect_identical(vapply(native,function(x)x$seed_start,integer(1L)),
        expected_seeds)
    }
  }
})
