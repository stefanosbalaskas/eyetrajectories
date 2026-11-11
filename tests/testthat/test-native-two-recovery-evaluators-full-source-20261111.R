# Frozen Python source: eyetrajectoriespy==1.2.0,
# commit c1cd95ad718327550f7e55393ff38582872f7a94,
# recovery.py::evaluate_hierarchy_truth_recovery and
# recovery.py::evaluate_registration_recovery.
# Evidence compares entire semantic metric frames and original provenance.

.etr_two_recovery_fixture <- function(variant="basic") {
  stopifnot(variant %in% c("basic","uneven","zero_eigen","no_components"))
  if(variant=="uneven"){
    grid<-c(0,.2,.55,.8,1)
    warps<-rbind(c(0,.14,.5,.87,1),c(0,.29,.6,.86,1),
      c(0,.1,.4,.9,1))
    scores<-list(
      curve=matrix(c(.1,.3,.8, 2.1,1.5,-.5, 1.5,.2,1.8),3,3,
        byrow=TRUE),
      participant=matrix(c(.4,1.1, .8,1.3, 1.1,-.2),3,2,
        byrow=TRUE),
      trial=matrix(c(-1,0,2),3,1))
    eig<-list(curve=c(1,.3,0),participant=c(.7,.2),trial=c(1.4))
  } else {
    grid<-c(0,.5,1)
    warps<-rbind(c(0,.25,1),c(0,.75,1))
    if(variant=="no_components"){
      scores<-list(curve=matrix(numeric(),2,0),
        participant=matrix(numeric(),2,0),
        trial=matrix(numeric(),2,0))
      eig<-list(curve=numeric(),participant=numeric(),trial=numeric())
    } else if(variant=="zero_eigen"){
      scores<-list(curve=matrix(c(1,1,2,2),2,2,byrow=TRUE),
        participant=matrix(c(2,2),2,1),
        trial=matrix(c(1,2),2,1))
      eig<-list(curve=c(0,1),participant=0,trial=0)
    } else {
      scores<-list(curve=matrix(c(1,2,3,4),2,2,byrow=TRUE),
        participant=matrix(c(0,4),2,1),
        trial=matrix(c(-1,1),2,1))
      eig<-list(curve=c(1,2),participant=2,trial=0)
    }
  }
  truth<-list(
    curve_scores=scores$curve,participant_scores=scores$participant,
    trial_scores=scores$trial,
    eigenvalues=eig$curve,participant_eigenvalues=eig$participant,
    trial_eigenvalues=eig$trial,
    truth_grid=grid,phase_warps_on_truth_grid=warps)
  # The same source grid may have uneven spacing. The estimator supplied
  # identity is deliberately not automatically set to the true inverse.
  fit<-list(original=list(time=grid),
    warping_functions=matrix(rep(grid,each=nrow(warps)),
      nrow=nrow(warps)))
  list(truth=truth,registration=fit)
}

.etr_two_recovery_compare_frame <- function(actual,expected,tag){
  expect_identical(names(actual),names(expected),
    info=paste(tag,"column names and order"))
  expect_identical(nrow(actual),nrow(expected),
    info=paste(tag,"row count"))
  for(field in names(actual)){
    a<-actual[[field]];b<-expected[[field]]
    expect_identical(is.na(a),is.na(b),
      info=paste(tag,field,"missingness"))
    keep<-!is.na(a)
    if(is.numeric(a) && is.numeric(b))
      expect_equal(as.numeric(a[keep]),as.numeric(b[keep]),
        tolerance=1e-12,info=paste(tag,field,"numbers"))
    else expect_identical(as.character(a[keep]),as.character(b[keep]),
      info=paste(tag,field,"text"))
  }
}

test_that("hierarchy source variance errors retain empty truth and zero targets",{
  empty<-.etr_two_recovery_fixture("no_components")
  result<-etr_evaluate_hierarchy_truth_recovery(empty$truth)
  expect_identical(result$values,list())
  expect_identical(result$provenance$ddof,0L)
  for(variant in c("basic","uneven","zero_eigen")){
    z<-.etr_two_recovery_fixture(variant)
    out<-etr_evaluate_hierarchy_truth_recovery(z$truth)
    expect_s3_class(out,"etr_functional_recovery_assessment")
    expect_true(length(out$values)>0L)
    expect_identical(out$provenance$purpose,
      "simulation_source_variance_audit")
    expect_true(all(vapply(out$values,function(v)
      is.finite(v$value)&&v$value>=0,logical(1L))))
    v<-etr_functional_recovery_assessment_frame(out,
      python_boundary_mode=TRUE)
    expect_identical(names(v),c("metric","value","component",
      "source","quantity","direction","units","scope","description"))
    expect_identical(unique(v$source),
      c("curve","participant","trial"))
    # A truly zero declared eigenvalue has no relative error.
    if(variant=="zero_eigen"){
      rel<-v$metric=="source_variance_relative_error"
      expect_identical(sum(rel),1L)
    }
  }
})

test_that("nonuniform phase inverses and declared source metrics remain explicit",{
  for(variant in c("basic","uneven","zero_eigen")){
    z<-.etr_two_recovery_fixture(variant)
    a<-etr_evaluate_registration_recovery(z$registration,z$truth)
    expect_identical(length(a$values),2L)
    expect_identical(vapply(a$values,function(v)v$metric$name,
      character(1L)),
      c("phase_warp_ise","phase_warp_max_absolute_error"))
    expect_true(all(vapply(a$values,function(v)
      is.finite(v$value) && v$value>=0,logical(1L))))
    expect_identical(a$provenance$truth_target,"inverse_phase_warp")
    moved<-z$registration
    moved$warping_functions[1L,2L]<-
      moved$warping_functions[1L,2L]+.15
    b<-etr_evaluate_registration_recovery(moved,z$truth)
    expect_false(identical(
      vapply(a$values,function(v)v$value,numeric(1L)),
      vapply(b$values,function(v)v$value,numeric(1L))))
    bad<-z$registration
    bad$original$time[2L]<-bad$original$time[2L]+.01
    expect_error(etr_evaluate_registration_recovery(bad,z$truth),
      "equal truth.truth_grid exactly")
  }
  z<-.etr_two_recovery_fixture("basic")
  bad<-z$truth;bad$curve_scores[1L,1L]<-Inf
  expect_error(etr_evaluate_hierarchy_truth_recovery(bad),"finite")
  bad<-z$registration;bad$warping_functions<-matrix(0,3,3)
  expect_error(etr_evaluate_registration_recovery(bad,z$truth),
    "identical curve/time geometry")
  bad<-z$truth;bad$phase_warps_on_truth_grid[1L,2L]<-(-.2)
  expect_error(etr_evaluate_registration_recovery(z$registration,bad),
    "nondecreasing")
})

test_that("frozen Python 1.2 matches whole recovery value records on four domains",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 source replay opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth",
    "from types import SimpleNamespace",
    "def _etr_pair_source_new(cls,**fields):",
    "    obj=object.__new__(cls)",
    "    for key,val in fields.items():object.__setattr__(obj,key,val)",
    "    return obj",
    "def _etr_pair_recovery_source(truth_record,reg_record):",
    "    fields={}",
    "    for key in ('curve_scores','participant_scores','trial_scores',",
    "      'eigenvalues','participant_eigenvalues','trial_eigenvalues',",
    "      'truth_grid','phase_warps_on_truth_grid'):",
    "        fields[key]=np.asarray(truth_record[key],dtype=float)",
    "    truth=_etr_pair_source_new(FunctionalSimulationTruth,**fields)",
    "    model=_etr_pair_source_new(et.RegistrationResult,",
    "      original=SimpleNamespace(time=np.asarray(",
    "        reg_record['original']['time'],dtype=float)),",
    "      warping_functions=np.asarray(reg_record['warping_functions'],",
    "        dtype=float))",
    "    hierarchy=et.evaluate_hierarchy_truth_recovery(truth)",
    "    registration=et.evaluate_registration_recovery(model,truth)",
    "    return (hierarchy,registration)"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,
    "_etr_pair_recovery_source")
  for(variant in c("basic","uneven","zero_eigen","no_components")){
    z<-.etr_two_recovery_fixture(variant)
    expected<-reticulate::py_to_r(reticulate::py_call(oracle,
      reticulate::r_to_py(z$truth),
      reticulate::r_to_py(z$registration)))
    a<-etr_evaluate_hierarchy_truth_recovery(z$truth)
    b<-etr_evaluate_registration_recovery(z$registration,z$truth)
    pairs<-list(hierarchy=a,registration=b)
    for(i in seq_along(pairs)){
      obj<-pairs[[i]]
      ref<-reticulate::py_get_item(
        reticulate::py_call(oracle,reticulate::r_to_py(z$truth),
          reticulate::r_to_py(z$registration)),as.integer(i-1L))
      # Direct original public Python output converted to complete source
      # 9-column metric table, including metadata, null labels, ordering.
      pyFrame<-as.data.frame(et_to_r(reticulate::py_call(
        etpy_get_export("functional_recovery_assessment_frame"),
        assessment=ref)),stringsAsFactors=FALSE)
      if(length(obj$values)){
        native<-etr_functional_recovery_assessment_frame(
          obj,python_boundary_mode=TRUE)
        .etr_two_recovery_compare_frame(native,pyFrame,
          paste(variant,names(pairs)[i]))
      }else{
        expect_identical(dim(pyFrame),c(0L,0L))
      }
      pyProvenance<-et_to_r(ref$provenance)
      expect_identical(names(obj$provenance),names(pyProvenance))
      for(n in names(obj$provenance))
        expect_equal(obj$provenance[[n]],pyProvenance[[n]],
          info=paste(variant,n))
    }
  }
})
