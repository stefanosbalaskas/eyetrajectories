# Frozen reference: eyetrajectoriespy 1.2.0 at c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer-authored source replay of opt-in reference. Existing public function is not replaced.
# No independent certification or gap closure.
.etr_batch29_base <- function(...) {
  args<-list(name="expanded",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.25),n_participants=3L,replicates=2L,seed_start=31L)
  for(nm in names(list(...)))args[nm]<-list(...)[nm]
  do.call(etr_functional_simulation_scenario,args)
}

test_that("Batch29 v4 reference expands source dataclass-valued factors in Python product order",{
  base<-.etr_batch29_base()
  out<-etr_expand_functional_simulation_scenarios_b29(base,list(
    n_participants=c(3L,4L),
    eigenvalues=list(c(1,.35),c(1,.15))),seed_policy="disjoint")
  expect_length(out,4L)
  expect_identical(vapply(out,function(x)x$n_participants,integer(1L)),
    c(3L,3L,4L,4L))
  expect_equal(vapply(out,function(x)x$eigenvalues[[2L]],numeric(1L)),
    c(.35,.15,.35,.15),tolerance=0)
  expect_identical(vapply(out,function(x)x$seed_start,integer(1L)),
    c(31L,33L,35L,37L))
  expect_identical(vapply(out,function(x)x$name,character(1L)),c(
    "expanded__n_participants=3__eigenvalues=1.0-0.35",
    "expanded__n_participants=3__eigenvalues=1.0-0.15",
    "expanded__n_participants=4__eigenvalues=1.0-0.35",
    "expanded__n_participants=4__eigenvalues=1.0-0.15"))
})

test_that("Batch29 v4 reference expands mappings, sequences, and explicit NULL scientifically",{
  base<-.etr_batch29_base()
  maps<-etr_expand_functional_simulation_scenarios_b29(base,list(
    missingness=list(list(kind="mcar",probability=.2),
                     list(kind="block",fraction=.2))))
  expect_identical(vapply(maps,function(x)x$name,character(1L)),
    c("expanded__missingness=mcar","expanded__missingness=block"))
  expect_identical(maps[[1L]]$missingness$kind,"mcar")
  expect_identical(maps[[2L]]$missingness$kind,"block")
  grids<-etr_expand_functional_simulation_scenarios_b29(base,list(
    truth_grid=list(c(0,.5,1),seq(0,1,length.out=5L))))
  expect_equal(vapply(grids,function(x)length(x$truth_grid),integer(1L)),
    c(3L,5L))
  expect_true(endsWith(grids[[2L]]$name,"truth_grid=seq5"))
  noise<-etr_expand_functional_simulation_scenarios_b29(base,list(
    measurement_noise_sd=list(0.0,NULL)))
  expect_equal(noise[[1L]]$measurement_noise_sd,0,tolerance=0)
  expect_null(noise[[2L]]$measurement_noise_sd)
  expect_true(endsWith(noise[[2L]]$name,"measurement_noise_sd=None"))
  labels<-etr_expand_functional_simulation_scenarios_b29(base,list(
    labels=list(list(kind="test",source="a"))))
  expect_true(endsWith(labels[[1L]]$name,"labels=test"))
})

test_that("Batch29 v4 reference expansion rejects invalid domains and controlled seeds",{
  base<-.etr_batch29_base()
  expect_error(etr_expand_functional_simulation_scenarios_b29(base,list()),
    "nonempty")
  expect_error(etr_expand_functional_simulation_scenarios_b29(base,
    list(seed_start=c(1L,2L))),"seed_start")
  expect_error(etr_expand_functional_simulation_scenarios_b29(base,
    list(unknown=c(1L,2L))),"unsupported")
  expect_error(etr_expand_functional_simulation_scenarios_b29(base,
    list(n_participants=numeric())),"at least one level")
  expect_error(etr_expand_functional_simulation_scenarios_b29(base,
    list(eigenvalues=list(c(.1,.5)))),"descending")
})

test_that("Batch29 v4 source oracle compares complete expanded scenario records",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct oracle is opt-in")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  py_base<-reticulate::py_call(etpy_get_export("FunctionalSimulationScenario"),
    name="expanded",truth_grid=reticulate::r_to_py(list(0,.5,1)),
    eigenvalues=reticulate::r_to_py(list(1,.25)),
    n_participants=3L,replicates=2L,seed_start=31L)
  py_factors<-reticulate::dict(
    n_participants=reticulate::r_to_py(list(3L,4L)),
    eigenvalues=reticulate::r_to_py(list(list(1.0,.35),list(1.0,.15))))
  py_out<-reticulate::py_call(
    etpy_get_export("expand_functional_simulation_scenarios"),
    base=py_base,factors=py_factors,seed_policy="disjoint")
  r_out<-etr_expand_functional_simulation_scenarios_b29(.etr_batch29_base(),list(
    n_participants=c(3L,4L),
    eigenvalues=list(c(1,.35),c(1,.15))),seed_policy="disjoint")
  expect_identical(length(py_out),length(r_out))
  for(i in seq_along(r_out)){
    src<-py_out[[i-1L]]
    expect_identical(as.character(reticulate::py_to_r(src$name)),
      r_out[[i]]$name,info=paste("name",i))
    expect_equal(as.integer(reticulate::py_to_r(src$seed_start)),
      r_out[[i]]$seed_start,info=paste("seed",i))
    expect_equal(as.integer(reticulate::py_to_r(src$n_participants)),
      r_out[[i]]$n_participants,info=paste("participants",i))
    expect_equal(as.numeric(reticulate::py_to_r(src$eigenvalues)),
      r_out[[i]]$eigenvalues,tolerance=0,info=paste("eigenvalues",i))
  }
})


test_that("Batch29 v4 additive reference exists without mutating original implementation",{
  expect_true(is.function(etr_expand_functional_simulation_scenarios_b29))
  expect_true(is.function(etr_expand_functional_simulation_scenarios))
})
