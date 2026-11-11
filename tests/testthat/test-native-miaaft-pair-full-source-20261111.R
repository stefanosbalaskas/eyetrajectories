# Frozen Python eyetrajectoriespy==1.2.0
# multivariate_surrogates.py, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R S3 scientific source mode, not Python frozen dataclass identity.
# Existing fixed-order/phase-replay tests remain native extension tests.

.etr_source_miaaft_provenance<-c(
  "operation","source_provenance","curve_id","dimensions",
  "reference_dimension","method","fourier_constraint",
  "marginal_constraint","cross_spectral_preservation",
  "reference_dimension_selected_automatically","sampling_grid",
  "sampling_step","time_unit","dimension_scaling","smoothing",
  "interpolation","failed_surrogate_policy","interpretation_boundary")
.etr_source_miaaft_fields<-c(
  "surrogates","source_values","curve_id","dimension_names",
  "reference_dimension","dimension_pairs","convergence_iterations",
  "spectral_errors","cross_spectral_errors","n_surrogates",
  "max_iterations","tolerance","random_state","provenance")
.etr_source_miaaft_nonlinear_provenance<-c(
  "operation","source_provenance","curve_id","dimensions",
  "reference_dimension","surrogate_method",
  "common_statistic_settings","p_value_correction",
  "failed_surrogate_policy","interpretation_boundary")

test_that("source MIAAFT hides R-only audit/replay flags but preserves original science",{
  for(n in c(23L,32L)){
    x<-.etr_miaaft_fixed_fixture(n)
    for(seed in c(17L,89L)){
      args<-list(trajectories=x,curve="a",
        dimensions=c("z","x","y"),reference_dimension="x",
        n_surrogates=2L,max_iterations=100L,tolerance=.5,
        random_state=seed)
      normal<-do.call(etr_generate_multivariate_iaaft_surrogates,args)
      source<-do.call(etr_generate_multivariate_iaaft_surrogates,
        c(args,list(python_boundary_mode=TRUE)))
      expect_s3_class(source,"etr_multivariate_iaaft")
      expect_identical(names(source),.etr_source_miaaft_fields)
      expect_identical(names(source$provenance),
        .etr_source_miaaft_provenance)
      for(field in c("surrogates","source_values","spectral_errors",
        "cross_spectral_errors","convergence_iterations"))
        expect_equal(source[[field]],normal[[field]],tolerance=0,
          ignore_attr=TRUE)
      expect_identical(source$provenance$operation,
        "generate_multivariate_iaaft_surrogates")
      expect_identical(source$provenance$dimension_scaling,FALSE)
      expect_identical(source$provenance$reference_dimension_selected_automatically,
        FALSE)
      expect_match(source$provenance$interpretation_boundary,
        "^surrogates target a multivariate linear-stochastic null")
      expect_true(all(is.finite(source$spectral_errors)))
      expect_true(all(is.finite(source$cross_spectral_errors)))
      for(i in seq_len(source$n_surrogates))
        for(j in seq_along(source$dimension_names))
          expect_identical(sort(source$surrogates[i,,j]),
            sort(source$source_values[,j]))
    }
  }
})

test_that("source MIAAFT rejects native replay extensions only in strict mode",{
  x<-.etr_miaaft_fixed_fixture(23L)
  args<-list(trajectories=x,curve="a",
    dimensions=c("z","x","y"),reference_dimension="x",
    n_surrogates=2L,max_iterations=100L,tolerance=.5,random_state=89L)
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    c(args,list(python_boundary_mode=1L))),"python_boundary_mode")
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    c(args,list(python_boundary_mode=TRUE,
      initial_permutations=.etr_miaaft_fixed_orders(2L,23L,3L)))),
    "native-only")
  expect_error(do.call(etr_generate_multivariate_iaaft_surrogates,
    c(args,list(python_boundary_mode=TRUE,phase_replay=list()))),
    "native-only")
  local<-do.call(etr_generate_multivariate_iaaft_surrogates,args)
  expect_false(local$provenance$source_python_equivalent_stochastic_draws)
  expect_true(local$provenance$seeded_initialization_matches_numpy)
})

test_that("source nonlinear MIAAFT respects two-sided plus-one and unit conversion",{
  x<-.etr_multivariate_lle_fixture()
  configs<-list(
    samples=list(delay=2L,theiler_window=3L,max_horizon=7L,
      fit_start=1L,fit_end=4L),
    seconds=list(delay=2*(x$time[2L]-x$time[1L]),
      theiler_window=3*(x$time[2L]-x$time[1L]),
      max_horizon=7*(x$time[2L]-x$time[1L]),
      fit_start=(x$time[2L]-x$time[1L]),
      fit_end=4*(x$time[2L]-x$time[1L]),
      delay_units="s",theiler_window_units="s",
      max_horizon_units="s",fit_units="s"))
  for(name in names(configs)){
    args<-c(list(trajectories=x,curve="example",
      dimensions=c("x","y","z"),reference_dimension="y",
      statistic="largest_lyapunov",embedding_dimension=2L),
      configs[[name]],list(n_surrogates=3L,
      max_iterations=100L,tolerance=.7,alternative="two-sided",
      random_state=17L,python_boundary_mode=TRUE))
    current<-do.call(etr_multivariate_surrogate_nonlinearity_test,args)
    expect_s3_class(current,"etr_multivariate_surrogate_nonlinearity")
    expect_identical(names(current),c("observed_statistic",
      "surrogate_statistics","p_value","alternative","statistic",
      "surrogate_result","provenance"))
    expect_identical(names(current$provenance),
      .etr_source_miaaft_nonlinear_provenance)
    expect_identical(names(current$surrogate_result$provenance),
      .etr_source_miaaft_provenance)
    expect_equal(current$p_value,min(1,2*min(
      (sum(current$surrogate_statistics>=current$observed_statistic)+1)/4,
      (sum(current$surrogate_statistics<=current$observed_statistic)+1)/4)),
      tolerance=0)
    expect_identical(current$provenance$common_statistic_settings$delay_units,
      if(name=="seconds")"s"else"samples")
    expect_identical(current$provenance$p_value_correction,
      "two_sided_double_min_plus_one_tails")
    expect_match(current$provenance$interpretation_boundary,
      "^rejection is evidence against")
    expect_true(all(is.finite(current$surrogate_statistics)))
    if(name=="samples")baseline<-current else{
      expect_equal(current$observed_statistic,baseline$observed_statistic,
        tolerance=1e-10)
      expect_equal(current$surrogate_statistics,
        baseline$surrogate_statistics,tolerance=1e-10)
      expect_equal(current$p_value,baseline$p_value,tolerance=0)
    }
  }
})

test_that("frozen Python 1.2 source MIAAFT generator compares complete seeded arrays",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 exact scientific MIAAFT generator oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  for(n in c(23L,32L)){
    x<-.etr_miaaft_fixed_fixture(n)
    pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
      time=x$time,values=x$values,
      curve_ids=reticulate::tuple("a","b"),
      dimension_names=reticulate::tuple("x","y","z"),
      coordinate_system="pixels",time_unit="s")
    for(seed in c(17L,89L)){
      actual<-etr_generate_multivariate_iaaft_surrogates(
        x,"a",c("z","x","y"),"x",n_surrogates=2L,
        max_iterations=100L,tolerance=.5,
        random_state=seed,python_boundary_mode=TRUE)
      source<-reticulate::py_call(
        etpy_get_export("generate_multivariate_iaaft_surrogates"),
        trajectories=pyx,curve="a",
        dimensions=reticulate::tuple("z","x","y"),
        reference_dimension="x",n_surrogates=2L,max_iterations=100L,
        tolerance=.5,random_state=seed)
      for(field in c("surrogates","source_values",
        "spectral_errors","cross_spectral_errors",
        "convergence_iterations")){
        expected<-et_to_r(reticulate::py_get_attr(source,field))
        expect_equal(actual[[field]],expected,
          tolerance=if(field=="convergence_iterations")0 else 1e-9,
          ignore_attr=TRUE,info=paste(n,seed,field))
      }
      expected_prov<-et_to_r(source$provenance)
      expect_identical(names(actual$provenance),names(expected_prov))
      for(field in names(expected_prov))
        expect_equal(actual$provenance[[field]],expected_prov[[field]],
          tolerance=1e-10,ignore_attr=TRUE,
          info=paste(n,seed,"generator provenance",field))
    }
  }
})

test_that("frozen Python source nonlinearity compares p-values and physical-time geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 MIAAFT nonlinear test oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fixture<-.etr_multivariate_lle_fixture()
  # Broadband perturbation avoids unstable near-zero reference Fourier phase
  # bins in purely periodic test curves; separately audited by replay tests.
  for(j in seq_len(3L))
    fixture$values[1L,,j]<-fixture$values[1L,,j]+
      .01*sin(seq_len(96L)*sqrt(2)*(1+j/7))
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=fixture$time,values=fixture$values,
    curve_ids=reticulate::tuple("example"),
    dimension_names=reticulate::tuple("x","y","z"),
    coordinate_system="pixels",time_unit="s")
  for(alt in c("greater","less","two-sided")){
    args<-list(curve="example",
      dimensions=c("x","y","z"),reference_dimension="y",
      statistic="largest_lyapunov",embedding_dimension=2L,
      delay=2L,theiler_window=3L,max_horizon=7L,
      fit_start=1L,fit_end=4L,
      n_surrogates=3L,max_iterations=100L,tolerance=.7,
      alternative=alt,random_state=17L)
    actual<-do.call(etr_multivariate_surrogate_nonlinearity_test,
      c(list(trajectories=fixture),args,list(python_boundary_mode=TRUE)))
    source<-do.call(reticulate::py_call,
      c(list(etpy_get_export("multivariate_surrogate_nonlinearity_test"),
        trajectories=pyx),args[setdiff(names(args),"dimensions")],
        list(dimensions=reticulate::tuple("x","y","z"))))
    for(field in c("observed_statistic","surrogate_statistics","p_value")){
      expected<-et_to_r(reticulate::py_get_attr(source,field))
      expect_equal(actual[[field]],expected,tolerance=1e-8,
        ignore_attr=TRUE,info=paste(alt,field))
    }
    expected_prov<-et_to_r(source$provenance)
    expect_identical(names(actual$provenance),names(expected_prov))
    for(field in names(expected_prov))
      expect_equal(actual$provenance[[field]],expected_prov[[field]],
        tolerance=1e-10,ignore_attr=TRUE,
        info=paste(alt,"source provenance",field))
    expect_identical(names(actual$surrogate_result$provenance),
      names(et_to_r(source$surrogate_result$provenance)))
  }
})
