test_that("native R environment has explicit pinned-source ancestry",{
  a<-etr_capture_environment()
  expect_identical(names(a),c("schema_version","captured_at_utc",
    "package","r","platform","dependencies","optional_backends",
    "numerical_thread_environment"))
  expect_identical(a$schema_version,1L)
  expect_identical(a$package$name,"eyetrajectories")
  expect_identical(a$r$implementation,"GNU R")
  expect_match(a$captured_at_utc,
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+\\+00:00$")
  expect_identical(names(a$numerical_thread_environment),
    c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS",
      "NUMEXPR_NUM_THREADS"))
  expect_false("python" %in% names(a))
  expect_true("r" %in% names(a))
  p<-etr_native_parity_catalog()
  row<-p[p$python_name=="capture_environment" &
    p$namespace=="root",,drop=FALSE]
  expect_identical(nrow(row),1L)
  expect_identical(row$native_r_candidate,"etr_capture_environment")
  expect_true(row$named_native_candidate)
  expect_true(row$native_implementation_started)
  expect_true(row$source_contract_gap_unresolved)
  expect_false(row$one_to_one_native_contract_complete)
})
