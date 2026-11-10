# Two complete developer-verified native semantic catalog contracts.
# Frozen Python source: eyetrajectoriespy==1.2.0,
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Mapping: ordered Python tuple of frozen dataclasses <=>
# language-native R named list of S3 records (same field names, lengths,
# order, UTF-8 bytes and observed caller-isolation behavior).
# Python class identity/tuple hashability are NOT claimed in R.
# External independent certification remains zero.

.etr_check_full_zeroarg_record_catalog <- function(
    native_function,python_name,n_records,fields,primary_key) {
  records<-native_function()
  expect_true(is.list(records))
  expect_identical(length(records),n_records)
  expect_identical(length(formals(native_function)),0L)
  expect_identical(names(records),unname(vapply(records,
    function(x)as.character(x[[primary_key]]),character(1L))))
  expect_true(all(vapply(records,function(x)
    is.list(x)&&identical(names(x),fields),logical(1L))))
  expect_true(all(vapply(records,function(x)
    all(vapply(x,function(z)is.character(z)&&
      all(!is.na(z))&&all(nzchar(z)),logical(1L))),logical(1L))))
  expect_identical(native_function(),records)
  for(args in list(list(1L),list(unexpected_argument=TRUE),
      list(NULL),list(1L,2L))) {
    expect_error(do.call(native_function,args),
      info=paste(python_name,"additional argument"))
  }
  # Native R copy isolation matches source's unmodifiable catalog state;
  # unlike Python frozen dataclasses, caller-owned R values are mutable.
  copy<-records
  copy[[1L]][[fields[[2L]]]]<-"CALLER_MUTATION"
  expect_identical(native_function(),records)
  expect_false(identical(copy,native_function()))

  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Complete catalog source oracle requires pinned Python 1.2")
  expect_identical(et_python_version(),"1.2.0")
  callable<-etpy_get_export(python_name)
  original<-reticulate::py_call(callable)
  expect_identical(as.integer(reticulate::py_len(original)),n_records)
  python_builtin<-reticulate::import_builtins(convert=FALSE)
  expect_true(as.logical(reticulate::py_to_r(
    python_builtin$isinstance(original,python_builtin$tuple))))
  dataclasses<-reticulate::import("dataclasses",convert=FALSE)
  for(i in seq_len(n_records)) {
    reference<-reticulate::py_get_item(original,i-1L)
    native<-records[[i]]
    expect_true(as.logical(reticulate::py_to_r(
      dataclasses$is_dataclass(reference))))
    expect_true(as.logical(reticulate::py_to_r(
      reticulate::py_get_attr(
        reticulate::py_get_attr(reference,"__dataclass_params__"),
        "frozen"))))
    pyfields<-dataclasses$fields(reference)
    python_names<-vapply(seq_len(reticulate::py_len(pyfields)),
      function(j)as.character(et_to_r(reticulate::py_get_attr(
        reticulate::py_get_item(pyfields,j-1L),"name"))),
      character(1L))
    expect_identical(python_names,fields,
      info=paste(python_name,"field names",i))
    for(field in fields) {
      py_value<-as.character(unlist(et_to_r(
        reticulate::py_get_attr(reference,field)),use.names=FALSE))
      r_value<-as.character(native[[field]])
      expect_identical(enc2utf8(r_value),enc2utf8(py_value),
        info=paste(python_name,i,field))
      expect_identical(
        charToRaw(paste(enc2utf8(r_value),collapse="\u000a")),
        charToRaw(paste(enc2utf8(py_value),collapse="\u000a")),
        info=paste(python_name,i,field,"UTF-8 bytes"))
    }
  }
  expect_error(reticulate::py_call(callable,1L))
  expect_error(reticulate::py_call(callable,unexpected_argument=TRUE))
  # Published immutable instances cannot be changed in-place.
  first<-reticulate::py_get_item(original,0L)
  expect_error(reticulate::py_set_attr(first,fields[[2L]],"caller mutation"),
    "FrozenInstanceError")
}

test_that("41 frozen math registry dataclasses are exhausted in native order",{
  .etr_check_full_zeroarg_record_catalog(
    etr_list_mathematical_contracts,
    "list_mathematical_contracts",41L,
    c("key","title","public_api","equations","site_anchor","scope"),
    "key")
})

test_that("27 frozen recovery metric dataclasses are exhausted in native order",{
  .etr_check_full_zeroarg_record_catalog(
    etr_functional_recovery_metric_catalog,
    "functional_recovery_metric_catalog",27L,
    c("name","quantity","direction","units","scope","description"),
    "name")
})

test_that("only two additional record catalog gaps receive developer closure",{
  catalog<-etr_native_parity_catalog()
  for(n in c("list_mathematical_contracts",
             "functional_recovery_metric_catalog")) {
    row<-catalog[catalog$is_python_function&
      catalog$python_name==n,,drop=FALSE]
    expect_identical(nrow(row),1L)
    expect_true(row$source_contract_gap_known)
    expect_false(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
    expect_false(row$independent_numeric_parity_pass)
  }
  expect_identical(sum(catalog$is_python_function&
    catalog$source_contract_gap_unresolved),197L)
  expect_identical(sum(catalog$nonfunction_source_gap_unresolved),1L)
  expect_identical(sum(!catalog$source_contract_gap_unresolved&
    !catalog$nonfunction_source_gap_unresolved),310L)
  expect_false(any(catalog$one_to_one_native_contract_complete))
})
