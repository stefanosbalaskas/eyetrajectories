# Frozen Python 1.2 full refit participant/trial provenance source audit.
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_source_full_refit_pair_fixture<-function() {
  list(
    sampled_participant_indices=matrix(
      c(1L,0L,0L,0L,2L,1L),nrow=3L,byrow=TRUE),
    sampled_source_participant_ids=list(
      c("p1","p0"),c("p0","p0"),c("p2","p1")),
    bootstrap_participant_ids=list(
      c("b01","b02"),c("b11","b12"),c("b21","b22")),
    bootstrap_trial_audit=list(
      list(c("p1","b01","Tβ","b01/Tβ"),
           c("p0","b02","Tα","b02/Tα")),
      list(),
      list(c("p2","b21","T0","b21/T0")))
  )
}

test_that("full-refit participant source audit retains all draws and zero-based provenance",{
  x<-.etr_source_full_refit_pair_fixture()
  y<-etr_functional_mixed_effects_full_refit_audit_frame(x)
  expect_identical(names(y),c("bootstrap_replicate","draw_index",
    "source_participant_index","source_participant_id",
    "bootstrap_participant_id"))
  expect_identical(y$bootstrap_replicate,c(0L,0L,1L,1L,2L,2L))
  expect_identical(y$draw_index,c(0L,1L,0L,1L,0L,1L))
  expect_identical(y$source_participant_index,c(1L,0L,0L,0L,2L,1L))
  expect_identical(y$source_participant_id,
    c("p1","p0","p0","p0","p2","p1"))
  expect_identical(y$bootstrap_participant_id,
    c("b01","b02","b11","b12","b21","b22"))
  expect_identical(nrow(y),6L)
})

test_that("nested trial audit retains repeated nested source IDs and empty draws",{
  x<-.etr_source_full_refit_pair_fixture()
  y<-etr_functional_mixed_effects_full_refit_trial_audit_frame(x)
  expect_identical(names(y),c("bootstrap_replicate",
    "source_participant_id","bootstrap_participant_id",
    "source_trial_id","bootstrap_trial_id"))
  expect_identical(y$bootstrap_replicate,c(0L,0L,2L))
  expect_identical(y$source_participant_id,c("p1","p0","p2"))
  expect_identical(y$bootstrap_participant_id,c("b01","b02","b21"))
  expect_identical(y$source_trial_id,c("Tβ","Tα","T0"))
  expect_identical(y$bootstrap_trial_id,c("b01/Tβ","b02/Tα","b21/T0"))
  x$bootstrap_trial_audit<-list()
  empty<-etr_functional_mixed_effects_full_refit_trial_audit_frame(x)
  expect_identical(names(empty),names(y))
  expect_identical(nrow(empty),0L)
  x$bootstrap_trial_audit<-list(list(),list(),list())
  all_empty<-etr_functional_mixed_effects_full_refit_trial_audit_frame(x)
  expect_identical(names(all_empty),names(y))
  expect_identical(nrow(all_empty),0L)
})

test_that("source provenance audit rejects malformed dimensions and record identities",{
  x<-.etr_source_full_refit_pair_fixture()
  x$sampled_participant_indices[1L,1L]<--1L
  expect_error(etr_functional_mixed_effects_full_refit_audit_frame(x),
    "nonnegative integer matrix")
  x<-.etr_source_full_refit_pair_fixture()
  x$sampled_source_participant_ids[[1L]]<-"p1"
  expect_error(etr_functional_mixed_effects_full_refit_audit_frame(x),
    "align with each bootstrap draw")
  x<-.etr_source_full_refit_pair_fixture()
  x$bootstrap_trial_audit[[1L]][[1L]]<-c("p1","b01","Tβ")
  expect_error(etr_functional_mixed_effects_full_refit_trial_audit_frame(x),
    "four source/target")
  x<-.etr_source_full_refit_pair_fixture()
  # Keep the required field present; test an invalid NULL value, not deletion.
  x["bootstrap_trial_audit"]<-list(NULL)
  expect_error(etr_functional_mixed_effects_full_refit_trial_audit_frame(x),
    "list of replicate records")
})

test_that("typed Python full-refit participant and nested trial frames agree cellwise",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 full-refit audit source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_source_bootstrap_record(**kwargs):",
    "    z=object.__new__(et.FunctionalMixedEffectsFullRefitBootstrapResult)",
    "    for k,v in kwargs.items():object.__setattr__(z,k,v)",
    "    return z",
    "_etr_source_refit=_etr_source_bootstrap_record(",
    "    bootstrap_coefficient_functions=np.zeros((3,1,1),dtype=float),",
    "    sampled_participant_indices=np.array([[1,0],[0,0],[2,1]],dtype=np.int64),",
    "    sampled_source_participant_ids=(('p1','p0'),('p0','p0'),('p2','p1')),",
    "    bootstrap_participant_ids=(('b01','b02'),('b11','b12'),('b21','b22')),",
    "    bootstrap_trial_audit=(",
    "      (('p1','b01','Tβ','b01/Tβ'),('p0','b02','Tα','b02/Tα')),",
    "      (),",
    "      (('p2','b21','T0','b21/T0'),)))",
    "_etr_refit_source_part=et.functional_mixed_effects_full_refit_audit_frame(_etr_source_refit)",
    "_etr_refit_source_trial=et.functional_mixed_effects_full_refit_trial_audit_frame(_etr_source_refit)",
    "object.__setattr__(_etr_source_refit,'bootstrap_trial_audit',())",
    "_etr_refit_source_empty=et.functional_mixed_effects_full_refit_trial_audit_frame(_etr_source_refit)"
  ),collapse="\n"),convert=FALSE)
  x<-.etr_source_full_refit_pair_fixture()
  tests<-list(
    list(n=etr_functional_mixed_effects_full_refit_audit_frame(x),
      p="_etr_refit_source_part"),
    list(n=etr_functional_mixed_effects_full_refit_trial_audit_frame(x),
      p="_etr_refit_source_trial"))
  x$bootstrap_trial_audit<-list()
  tests[[3L]]<-list(
    n=etr_functional_mixed_effects_full_refit_trial_audit_frame(x),
    p="_etr_refit_source_empty")
  for(i in seq_along(tests)) {
    p<-tests[[i]]
    source<-as.data.frame(et_to_r(reticulate::py_eval(p$p,convert=FALSE)),
      check.names=FALSE)
    actual<-p$n
    expect_identical(names(source),names(actual),info=paste("schema",i))
    expect_identical(nrow(source),nrow(actual),info=paste("rows",i))
    for(nm in names(source)) {
      if(nrow(source)==0L)next
      if(is.numeric(source[[nm]]))
        expect_equal(as.numeric(actual[[nm]]),as.numeric(source[[nm]]),
          tolerance=0,info=paste("numeric",i,nm))
      else
        expect_identical(as.character(actual[[nm]]),
          as.character(source[[nm]]),info=paste("character",i,nm))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
