# Pinned-Python source symbol witness for *unreviewed* R scientific analogues.
#
# This is an actual Python 1.2 exported callable lookup and inspect.getsource
# replay, not a spelling-only grep. It does NOT run the estimator or establish
# numerical, schema, scientific-estimand, accepted-input or error-domain parity.
# The authoritative 508-export certification register is NEVER modified here.
.etr_expect_frozen_python_source_symbol<-function(export,expected_name){
  testthat::expect_identical(et_python_version(),"1.2.0")
  testthat::expect_true(grepl("^[A-Za-z_][A-Za-z_0-9]*$",
    expected_name))
  # Ensure we inspect the actual frozen installed Python source function,
  # rather than a native-R bridge wrapper or an independently named fixture.
  validate<-reticulate::py_eval(
    paste0(
      "lambda f: (callable(f), getattr(f, '__module__', ''), ",
      "tuple(__import__('inspect').signature(f).parameters), ",
      "__import__('inspect').getsourcefile(f), ",
      "len(__import__('inspect').getsource(f)))"),
    convert=FALSE)
  observed<-reticulate::py_to_r(reticulate::py_call(validate,export))
  testthat::expect_true(isTRUE(observed[[1L]]),
    info=paste(expected_name,"not callable in frozen Python"))
  testthat::expect_true(is.character(observed[[2L]])&&
    length(observed[[2L]])==1L&&
    startsWith(observed[[2L]],"eyetrajectoriespy"),
    info=paste(expected_name,"is not implemented in pinned package"))
  testthat::expect_true(length(observed[[3L]])>=1L,
    info=paste(expected_name,"has no observable Python signature arguments"))
  testthat::expect_true(is.character(observed[[4L]])&&
    length(observed[[4L]])==1L&&
    grepl("\\.py$",observed[[4L]]),
    info=paste(expected_name,"has no inspectable Python source file"))
  testthat::expect_true(is.numeric(observed[[5L]])&&
    length(observed[[5L]])==1L&&
    observed[[5L]]>30L,
    info=paste(expected_name,"has no inspectable source body"))
  invisible(observed)
}
