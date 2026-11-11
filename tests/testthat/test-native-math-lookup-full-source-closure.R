# Frozen Python eyetrajectoriespy==1.2.0 at c1cd95ad718327550f7e55393ff38582872f7a94:
# mathematical_contracts.py::get_mathematical_contract and
# _mathematical_contracts_base.py::get_mathematical_contract.
# Developer source equivalence, not independent scientific certification.

.etr_source_mathematical_lookup<-function(...) {
  etr_get_mathematical_contract(...,python_boundary_mode=TRUE)
}

test_that("complete 41-contract key and 88-alias lookup source domain is stable",{
  contracts<-etr_list_mathematical_contracts()
  expect_identical(length(contracts),41L)
  frame<-etr_mathematical_contract_frame()
  expect_identical(nrow(frame),88L)
  expect_identical(length(unique(frame$contract_key)),41L)
  seen<-character()
  for(i in seq_along(contracts)){
    record<-contracts[[i]]
    expect_identical(names(record),c("key","title","public_api",
      "equations","site_anchor","scope"))
    expect_true(is.character(record$key)&&length(record$key)==1L)
    expect_identical(.etr_source_mathematical_lookup(record$key),record)
    for(api in record$public_api){
      expect_identical(.etr_source_mathematical_lookup(api),record)
      seen<-c(seen,api)
    }
  }
  expect_identical(length(seen),88L)
  expect_identical(seen,frame[["function"]])
  expect_identical(length(unique(seen)),88L)
  expect_identical(.etr_source_mathematical_lookup(
    name="fit_sparse_mfpca")$key,"sparse-mfpca-joint-pace")
  expect_identical(.etr_source_mathematical_lookup(
    name="sparse-mfpca-joint-pace")$key,"sparse-mfpca-joint-pace")
})

test_that("Python 1.2 call binding, invalid values and sparse array wrappers map correctly",{
  missing<-tryCatch(.etr_source_mathematical_lookup(),error=identity)
  expect_s3_class(missing,"etr_mathematical_contract_type_error")
  expect_identical(conditionMessage(missing),
    "get_mathematical_contract() missing 1 required positional argument: 'name'")
  unknown_kw<-tryCatch(.etr_source_mathematical_lookup(na="quadrature"),
    error=identity)
  expect_s3_class(unknown_kw,"etr_mathematical_contract_type_error")
  expect_identical(conditionMessage(unknown_kw),
    "get_mathematical_contract() got an unexpected keyword argument 'na'")
  duplicate<-tryCatch(.etr_source_mathematical_lookup("quadrature",
    name="quadrature"),error=identity)
  expect_identical(conditionMessage(duplicate),
    "get_mathematical_contract() got multiple values for argument 'name'")
  twice<-tryCatch(.etr_source_mathematical_lookup("quadrature","fpca"),
    error=identity)
  expect_identical(conditionMessage(twice),
    "get_mathematical_contract() takes 1 positional argument but 2 were given")
  for(input in list(NULL,TRUE,FALSE,1L,1.4,NaN,Inf,list("quadrature"),
    c("quadrature","fpca"),NA_character_,matrix("quadrature",ncol=1L))){
    err<-tryCatch(.etr_source_mathematical_lookup(input),error=identity)
    expect_true(inherits(err,c("etr_mathematical_contract_type_error",
      "etr_mathematical_contract_value_error")),info=deparse(input))
  }
  for(input in list(matrix(c("quadrature","fpca"),ncol=1L),
    array(character(),dim=0L),array(c("quadrature","fpca"),dim=2L))){
    err<-tryCatch(.etr_source_mathematical_lookup(input),error=identity)
    expect_s3_class(err,"etr_mathematical_contract_value_error")
    expect_match(conditionMessage(err),"ambiguous")
  }
  expect_identical(.etr_source_mathematical_lookup(
    array("fit_sparse_mfpca",dim=c(1L,1L)))$key,"sparse-mfpca-joint-pace")
  expect_identical(.etr_source_mathematical_lookup(
    array("sparse-mfpca-joint-pace",dim=1L))$key,"sparse-mfpca-joint-pace")
})

test_that("unregistered Unicode and literal quote keys use Python 1.2 repr",{
  keys<-c("","__unknown_key__","FPCA"," fpca","ανύπαρκτο",
    "can't","\"double\"","both'\"quotes","\u007f","line\nbreak",
    "tab\tvalue","backslash\\","emoji 😀")
  for(key in keys){
    err<-tryCatch(.etr_source_mathematical_lookup(key),error=identity)
    expect_s3_class(err,"etr_mathematical_contract_key_error")
    expect_identical(err$name,key)
    expect_match(conditionMessage(err),
      "No mathematical contract is registered for",fixed=TRUE)
  }
})

test_that("direct frozen Python lookup compares all records and failure boundaries",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python mathematical contract source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from dataclasses import fields
import numpy as np
from eyetrajectoriespy.mathematical_contracts import (
    list_mathematical_contracts,get_mathematical_contract)
def _math_source_probe(*args,**kwargs):
    try:
        value=get_mathematical_contract(*args,**kwargs)
        return {'ok':True,'key':value.key}
    except Exception as exc:
        return {'ok':False,'kind':type(exc).__name__,
                'message':str(exc),
                'first_arg':str(exc.args[0]) if exc.args else None}
")
  py<-reticulate::py_eval("_math_source_probe",convert=FALSE)
  records<-reticulate::py_call(
    etpy_get_export("list_mathematical_contracts"))
  native<-etr_list_mathematical_contracts()
  expect_identical(length(native),reticulate::py_len(records))
  for(i in seq_along(native)){
    record<-native[[i]]
    source<-reticulate::py_get_item(records,i-1L)
    sourcefields<-reticulate::py_call(
      reticulate::py_get_attr(reticulate::import("dataclasses",
      convert=FALSE),"fields"),source)
    expect_identical(names(record),vapply(
      seq_len(reticulate::py_len(sourcefields)),
      function(k)as.character(et_to_r(
        reticulate::py_get_attr(reticulate::py_get_item(sourcefields,
          k-1L),"name"))),character(1L)))
    for(key in c(record$key,record$public_api)){
      result<-reticulate::py_call(py,key)
      expect_true(reticulate::py_to_r(
        reticulate::py_get_item(result,"ok")))
      expect_identical(
        as.character(reticulate::py_to_r(
          reticulate::py_get_item(result,"key"))),
        .etr_source_mathematical_lookup(key)$key)
      expect_identical(.etr_source_mathematical_lookup(key),record)
    }
  }
  args<-list(
    list(r=function().etr_source_mathematical_lookup(),
      pyargs=list(),pykwargs=list()),
    list(r=function().etr_source_mathematical_lookup(1L),
      pyargs=list(1L),pykwargs=list()),
    list(r=function().etr_source_mathematical_lookup(TRUE),
      pyargs=list(TRUE),pykwargs=list()),
    list(r=function().etr_source_mathematical_lookup("quadrature","fpca"),
      pyargs=list("quadrature","fpca"),pykwargs=list()),
    list(r=function().etr_source_mathematical_lookup(na="quadrature"),
      pyargs=list(),pykwargs=list(na="quadrature")),
    list(r=function().etr_source_mathematical_lookup("quadrature",
      name="quadrature"),pyargs=list("quadrature"),
      pykwargs=list(name="quadrature"))
  )
  for(i in seq_along(args)){
    case<-args[[i]]
    result<-do.call(reticulate::py_call,
      c(list(py),case$pyargs,case$pykwargs))
    result<-reticulate::py_to_r(result)
    err<-tryCatch(case$r(),error=identity)
    expect_false(result$ok,info=paste("error case",i))
    expect_s3_class(err,"etr_mathematical_contract_type_error")
    expect_identical(result$kind,"TypeError")
    expect_identical(conditionMessage(err),result$message)
  }
  for(key in c("","__unknown_key__","ανύπαρκτο",
    "can't","\"double\"","both'\"quotes","line\nbreak")){
    result<-reticulate::py_to_r(reticulate::py_call(py,key))
    err<-tryCatch(.etr_source_mathematical_lookup(key),error=identity)
    expect_false(result$ok)
    expect_identical(result$kind,"KeyError")
    expect_s3_class(err,"etr_mathematical_contract_key_error")
    expect_identical(conditionMessage(err),result$first_arg)
  }
  for(expr in c("np.array(['fit_sparse_mfpca'])",
    "np.array([['sparse-mfpca-joint-pace']])")){
    value<-reticulate::py_eval(expr,convert=FALSE)
    py_result<-reticulate::py_to_r(reticulate::py_call(py,value))
    expect_true(py_result$ok)
    expect_identical(py_result$key,"sparse-mfpca-joint-pace")
  }
})
