# Frozen Python source: eyetrajectoriespy 1.2.0 simulate.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Target: Python float-to-scenario-name representation, not a scientific
# estimator, complete contract closure, or independent certification.

.b31_source_float_values <- function() list(
  0.0, -0.0, 0.1, 0.35, 0.0001, 0.00001, 1e15, 1e16,
  1.2345678901234567, 0.12345678901234568,
  1.0000000000000002, 1e-308, 1e308, -1e-05,
  3140000.0, 1e20, -1e20)

.b31_source_float_expected <- function() c(
  "0.0", "-0.0", "0.1", "0.35", "0.0001", "1e-05",
  "1000000000000000.0", "1e+16", "1.2345678901234567",
  "0.12345678901234568", "1.0000000000000002", "1e-308",
  "1e+308", "-1e-05", "3140000.0", "1e+20", "-1e+20")

test_that("native float slug preserves Python 1.2 binary64 representation", {
  floats <- .b31_source_float_values()
  actual <- vapply(floats,.etr_b29_factor_py_scalar,character(1L))
  expect_identical(unname(actual),.b31_source_float_expected())
  expect_identical(.etr_b29_factor_py_scalar(2L),"2")
  expect_identical(.etr_b29_factor_py_scalar(2),"2.0")
  expect_identical(.etr_b29_factor_py_scalar(TRUE),"True")
  expect_identical(.etr_b29_factor_py_scalar(NULL),"None")
  expect_identical(.etr_b29_factor_py_scalar(NaN),"nan")
  expect_identical(.etr_b29_factor_py_scalar(Inf),"inf")
  expect_identical(.etr_b29_factor_py_scalar(-Inf),"-inf")
  # Frozen Python _scenario_factor_slug() finally strips leading hyphens.
  expect_identical(.etr_b29_scenario_factor_slug(-0.0),"0.0")
  expect_identical(.etr_b29_scenario_factor_slug(-1e-05),"1e-05")
  expect_identical(.etr_b29_scenario_factor_slug(
    structure(list(),names=character())),"mapping")
})

test_that("public scenario name expansion now retains binary64 precision", {
  base <- etr_functional_simulation_scenario(
    name="precision", truth_grid=c(0,.5,1),
    eigenvalues=c(1,.25), n_participants=3L)
  floats <- .b31_source_float_values()
  out <- etr_expand_functional_simulation_scenarios(
    base,list(score_df=floats))
  expect_length(out,length(floats))
  expect_identical(vapply(out,function(x)x$name,character(1L)),
    paste0("precision__score_df=",sub("^-+","",.b31_source_float_expected())))
  expect_identical(vapply(out,function(x)x$score_df,numeric(1L)),
    unlist(floats,use.names=FALSE))
})

test_that("frozen Python 1.2 expansion generates exactly the same float names", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 direct-source oracle is opt-in")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  floats <- .b31_source_float_values()
  py_base <- reticulate::py_call(
    etpy_get_export("FunctionalSimulationScenario"),
    name="precision",truth_grid=reticulate::r_to_py(list(0,.5,1)),
    eigenvalues=reticulate::r_to_py(list(1,.25)),n_participants=3L)
  py_factors <- reticulate::dict(
    score_df=reticulate::r_to_py(floats))
  py_out <- reticulate::py_call(
    etpy_get_export("expand_functional_simulation_scenarios"),
    base=py_base,factors=py_factors)
  r_base <- etr_functional_simulation_scenario(
    name="precision",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.25),n_participants=3L)
  r_out <- etr_expand_functional_simulation_scenarios(
    r_base,list(score_df=floats))
  expect_identical(length(py_out),length(r_out))
  for(i in seq_along(r_out)){
    expect_identical(as.character(reticulate::py_to_r(py_out[[i-1L]]$name)),
      r_out[[i]]$name,info=paste("Python float name",i))
    expect_equal(as.numeric(reticulate::py_to_r(py_out[[i-1L]]$score_df)),
      r_out[[i]]$score_df,tolerance=0)
  }
})
