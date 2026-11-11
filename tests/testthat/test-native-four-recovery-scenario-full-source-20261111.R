# Frozen Python oracle: eyetrajectoriespy==1.2.0,
# c1cd95ad718327550f7e55393ff38582872f7a94,
# src/eyetrajectoriespy/simulate.py and recovery_scenarios.py.
# The R S3 record is a semantic equivalent, not a Python dataclass object.
# Compare the COMPLETE source-ordered pandas table, not selected columns.

.etr_four_recovery_compare_frame <- function(actual,source,label) {
  expect_s3_class(actual,"data.frame",info=label)
  expect_s3_class(source,"data.frame",info=label)
  expect_identical(names(actual),names(source),info=label)
  expect_identical(nrow(actual),nrow(source),info=label)
  for(col in names(actual)){
    av<-actual[[col]]
    bv<-source[[col]]
    expect_identical(is.na(av),is.na(bv),
      info=paste(label,col,"missingness"))
    present<-!is.na(av)
    if(is.numeric(av)&&is.numeric(bv)){
      expect_equal(as.numeric(av[present]),as.numeric(bv[present]),
        tolerance=1e-14,info=paste(label,col,"numeric"))
    }else{
      expect_identical(as.character(av[present]),as.character(bv[present]),
        info=paste(label,col,"exact source text"))
    }
  }
}

test_that("source scenario frame validates frozen record invariants on use",{
  s<-etr_functional_recovery_qualification_scenarios()[[1L]]
  expect_identical(nrow(etr_functional_simulation_scenario_frame(list(s))),1L)
  bad<-s;bad$name<-""
  expect_error(etr_functional_simulation_scenario_frame(list(bad)),
    "scenario name")
  bad<-s;bad$eigenvalues<-c(1,2)
  expect_error(etr_functional_simulation_scenario_frame(list(bad)),
    "descending order")
  bad<-s;bad$replicates<-0L
  expect_error(etr_functional_simulation_scenario_frame(list(bad)),
    "replicates")
  bad<-s;bad$truth_grid<-c(0,1,1)
  expect_error(etr_functional_simulation_scenario_frame(list(bad)),
    "strictly increasing")
  bad<-s;bad$participant_eigenvalues<-1
  expect_error(etr_functional_simulation_scenario_frame(list(bad)),
    "participant_eigenvalues")
  expect_error(etr_functional_simulation_scenario_frame(list(list())),
    "every scenario")
  expect_identical(dim(etr_functional_simulation_scenario_frame(list())),
    c(0L,0L))
})

test_that("qualification and stress designs retain all source scientific domains",{
  for(case in list(
    list(qr=1L,sr=1L,qs=202800L,ss=204000L),
    list(qr=3L,sr=10L,qs=202800L,ss=204000L),
    list(qr=7L,sr=2L,qs=1200L,ss=3500L),
    list(qr=2L,sr=4L,qs=900000L,ss=1200000L))){
    qual<-etr_functional_recovery_qualification_scenarios(
      replicates=case$qr,seed_start=case$qs)
    stress<-etr_functional_recovery_stress_scenarios(
      replicates=case$sr,seed_start=case$ss)
    expect_length(qual,4L)
    expect_length(stress,14L)
    expect_true(all(vapply(c(qual,stress),inherits,logical(1L),
      what="etr_functional_simulation_scenario")))
    expect_identical(vapply(qual,function(x)x$replicates,integer(1L)),
      rep(case$qr,4L))
    expect_identical(vapply(stress,function(x)x$replicates,integer(1L)),
      rep(case$sr,14L))
    frame<-etr_functional_simulation_scenario_frame(c(qual,stress))
    expect_identical(dim(frame),c(18L,23L))
    expect_true(any(frame$score_distribution=="student_t"))
    expect_true(any(frame$observation_design=="irregular"))
    expect_identical(frame$measurement_noise_sd[[18L]],"null")
    expect_true(all(!is.na(frame$labels)))
    catalog<-etr_functional_recovery_scenario_catalog_frame(
      qualification_replicates=case$qr,
      stress_replicates=case$sr)
    expect_identical(dim(catalog),c(18L,26L))
    expect_identical(names(catalog)[1:4],c("scenario",
      "matrix_role","scientific_target","description"))
    expect_identical(catalog$matrix_role,
      c(rep("qualification",4L),rep("stress",14L)))
    expect_true(all(nzchar(catalog$description)))
  }
  expect_error(etr_functional_recovery_qualification_scenarios(0L),
    "replicates")
  expect_error(etr_functional_recovery_stress_scenarios(0L),
    "replicates")
  expect_error(etr_functional_recovery_scenario_catalog_frame(
    qualification_replicates=0L),"replicates")
  expect_error(etr_functional_recovery_scenario_catalog_frame(
    stress_replicates=0L),"replicates")
})

test_that("four exact Python 1.2 scenario contracts match every source column",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 full-source oracle is opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  qualification<-etpy_get_export(
    "functional_recovery_qualification_scenarios")
  stress<-etpy_get_export("functional_recovery_stress_scenarios")
  scenario_frame<-etpy_get_export("functional_simulation_scenario_frame")
  catalog_frame<-etpy_get_export("functional_recovery_scenario_catalog_frame")
  for(case in list(
    list(qr=1L,sr=1L,qs=202800L,ss=204000L),
    list(qr=3L,sr=10L,qs=202800L,ss=204000L),
    list(qr=7L,sr=2L,qs=1200L,ss=3500L),
    list(qr=2L,sr=4L,qs=900000L,ss=1200000L))){
    pyq<-reticulate::py_call(qualification,
      replicates=case$qr,seed_start=case$qs)
    pys<-reticulate::py_call(stress,
      replicates=case$sr,seed_start=case$ss)
    nq<-etr_functional_recovery_qualification_scenarios(
      replicates=case$qr,seed_start=case$qs)
    ns<-etr_functional_recovery_stress_scenarios(
      replicates=case$sr,seed_start=case$ss)
    # Both scenario constructors are checked through every source design
    # column, including exact JSON for matrices, provenance, and None.
    .etr_four_recovery_compare_frame(
      etr_functional_simulation_scenario_frame(nq),
      et_to_r(reticulate::py_call(scenario_frame,scenarios=pyq)),
      paste("qualification",case$qr,case$qs))
    .etr_four_recovery_compare_frame(
      etr_functional_simulation_scenario_frame(ns),
      et_to_r(reticulate::py_call(scenario_frame,scenarios=pys)),
      paste("stress",case$sr,case$ss))
    # The catalog always uses its published fixed baseline seed starts.
    .etr_four_recovery_compare_frame(
      etr_functional_recovery_scenario_catalog_frame(
        qualification_replicates=case$qr,stress_replicates=case$sr),
      et_to_r(reticulate::py_call(catalog_frame,
        qualification_replicates=case$qr,stress_replicates=case$sr)),
      paste("full recovery catalog",case$qr,case$sr))
    expect_identical(length(pyq),length(nq))
    expect_identical(length(pys),length(ns))
  }
  # Python pd.DataFrame([]) versus native data.frame(): both are 0 x 0.
  .etr_four_recovery_compare_frame(
    etr_functional_simulation_scenario_frame(list()),
    et_to_r(reticulate::py_call(scenario_frame,
      scenarios=reticulate::tuple())),
    "empty source frame")
})
