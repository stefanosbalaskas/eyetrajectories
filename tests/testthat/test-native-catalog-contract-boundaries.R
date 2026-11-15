# Five source contracts. The two argument-free frames are eligible for
# evidence-gated developer semantic closure, never automatic external approval.
test_that("catalog frames are complete deterministic column-ordered outputs",{
  math<-etr_mathematical_contract_frame()
  metrics<-etr_functional_recovery_metric_catalog_frame()
  expect_identical(dim(math),c(88L,6L))
  expect_identical(dim(metrics),c(27L,6L))
  expect_identical(names(math),
    c("contract_key","title","function","latex","site_anchor","scope"))
  expect_identical(names(metrics),
    c("metric","quantity","direction","units","scope","description"))
  expect_false(anyNA(math))
  expect_false(anyNA(metrics))
  expect_identical(math,etr_mathematical_contract_frame())
  expect_identical(metrics,etr_functional_recovery_metric_catalog_frame())
  expect_error(etr_mathematical_contract_frame(1),"unused argument")
  expect_error(etr_functional_recovery_metric_catalog_frame(1),"unused argument")
})

test_that("catalog tuple/dataclass semantics are mapped but types remain native",{
  contracts<-etr_list_mathematical_contracts()
  frame<-etr_mathematical_contract_frame()
  expect_length(contracts,41L)
  for(k in unique(frame$contract_key))
    expect_identical(etr_get_mathematical_contract(k)$key,k)
  for(name in frame[["function"]])
    expect_true(name%in%etr_get_mathematical_contract(name)$public_api)
  metrics<-etr_functional_recovery_metric_catalog()
  expect_length(metrics,27L)
  expect_identical(names(metrics),etr_functional_recovery_metric_catalog_frame()$metric)
  expect_error(etr_get_mathematical_contract("__unknown_key__"),"No mathematical contract")
  expect_error(etr_get_mathematical_contract(1L),"single string")
  for(name in list(NULL,NA_character_,TRUE,1L,c("fpca","quadrature"))){
    expect_error(etr_get_mathematical_contract(name),
      class="etr_mathematical_contract_type_error")
  }
  for(name in c("","__unknown_key__","FPCA"," fpca","ανύπαρκτο")){
    error<-expect_error(etr_get_mathematical_contract(name),
      class="etr_mathematical_contract_key_error")
    expect_identical(error$name,name)
  }
  expect_true(inherits(contracts[[1]],"etr_mathematical_contract"))
  expect_true(inherits(metrics[[1]],"etr_recovery_metric"))
})

test_that("catalog records preserve all pinned fields and isolated copies",{
  contracts<-etr_list_mathematical_contracts()
  metrics<-etr_functional_recovery_metric_catalog()
  catalog_functions<-list(etr_list_mathematical_contracts,
    etr_functional_recovery_metric_catalog)
  for(fun in catalog_functions){
    expect_length(formals(fun),0L)
    expect_error(fun(1L),"unused argument")
    expect_error(fun(unexpected_argument=TRUE),"unused argument")
    records<-fun()
    modified<-records
    modified[[1L]][[2L]]<-"changed by caller"
    expect_identical(fun(),records)
  }
  for(record in contracts)
    for(key in c(record$key,record$public_api))
      expect_identical(etr_get_mathematical_contract(key),record)
  expect_error(etr_get_mathematical_contract())
  expect_error(etr_get_mathematical_contract("fpca",1L),"unused argument")

  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned direct-source catalog records are opt in")
  expect_identical(et_python_version(),"1.2.0")
  attr<-reticulate::py_get_attr
  call<-reticulate::py_call
  item<-reticulate::py_get_item
  dataclasses<-reticulate::import("dataclasses",convert=FALSE)
  equal_record<-function(native,source){
    source_fields<-dataclasses$fields(source)
    expect_identical(names(native),vapply(seq_len(reticulate::py_len(source_fields)),
      function(i)et_to_r(attr(item(source_fields,i-1L),"name")),character(1L)))
    for(field in names(native)){
      actual<-enc2utf8(native[[field]])
      expected<-enc2utf8(unlist(et_to_r(attr(source,field)),use.names=FALSE))
      expect_identical(actual,expected,info=field)
    }
  }
  check_catalog<-function(native,source){
    reference<-call(source)
    expect_length(native,reticulate::py_len(reference))
    for(i in seq_along(native))equal_record(native[[i]],item(reference,i-1L))
    expect_error(call(source,1L),"TypeError")
    expect_error(call(source,unexpected_argument=TRUE),"TypeError")
  }
  check_catalog(contracts,etpy_get_export("list_mathematical_contracts"))
  check_catalog(metrics,etpy_get_export("functional_recovery_metric_catalog"))
  lookup<-etpy_get_export("get_mathematical_contract")
  for(record in contracts)
    for(key in c(record$key,record$public_api))
      equal_record(etr_get_mathematical_contract(key,python_boundary_mode=TRUE),
        call(lookup,key))
  for(name in c("","__unknown_key__","FPCA"," fpca","ανύπαρκτο"))
    expect_error(call(lookup,name),"KeyError")
  for(name in list(NULL,TRUE,1L,list("fpca","quadrature")))
    expect_error(call(lookup,name),"TypeError")
  expect_error(call(lookup),"TypeError")
  expect_error(call(lookup,"fpca",1L),"TypeError")
})

test_that("catalog author review exposes native representation and lookup boundaries",{
  old<-options(warnPartialMatchArgs=FALSE)
  on.exit(options(old),add=TRUE)
  expect_identical(etr_get_mathematical_contract(na="quadrature")$key,
    "quadrature")
  expect_identical(etr_get_mathematical_contract(matrix("quadrature"))$key,
    "quadrature")
  strict<-function(...)etr_get_mathematical_contract(...,python_boundary_mode=TRUE)
  expect_identical(strict(name="quadrature")$key,"quadrature")
  expect_identical(strict(matrix("fit_sparse_mfpca"))$key,"sparse-mfpca-joint-pace")
  expect_identical(strict(array("sparse-mfpca-joint-pace",c(1L,1L,1L)))$key,
    "sparse-mfpca-joint-pace")
  for(args in list(list(),list(na="quadrature"),list(unknown="quadrature"),
      list("quadrature","fpca"),list(name="quadrature","fpca"),
      list(matrix("quadrature")),list(array(1L,1L)))){
    expect_error(do.call(strict,args),class="etr_mathematical_contract_type_error")
  }
  expect_error(strict(na="quadrature"),class="etr_mathematical_contract_type_error")
  expect_error(strict(,name="quadrature"),class="etr_mathematical_contract_type_error")
  expect_error(strict(,),class="etr_mathematical_contract_type_error")
  for(input in list(matrix(c("fpca","quadrature")),array(character(),0L)))
    expect_error(strict(input),class="etr_mathematical_contract_value_error")
  error<-expect_error(strict("two'quotes\u007f"),class="etr_mathematical_contract_key_error")
  expect_identical(conditionMessage(error),
    "No mathematical contract is registered for \"two'quotes\\x7f\"")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned direct-source catalog boundaries are opt in")
  expect_identical(et_python_version(),"1.2.0")
  call<-reticulate::py_call
  item<-reticulate::py_get_item
  np<-reticulate::import("numpy",convert=FALSE)
  lookup<-etpy_get_export("get_mathematical_contract")
  expect_error(call(lookup,na="quadrature"),"TypeError")
  expect_error(call(lookup,np$array(matrix("quadrature"),dtype="str")),"TypeError")
  expect_error(call(lookup,np$array(as.list(c("fpca","quadrature")),dtype="str")),
    "truth value of an array")
  # Frozen Python 1.2 checks lookup membership, so a zero-length ndarray
  # fails the string-key type check rather than invoking NumPy truthiness.
  expect_error(call(lookup,np$empty(0L,dtype="str")),
    "name must be a string")
  source_joint<-call(lookup,np$array(matrix("fit_sparse_mfpca"),dtype="str"))
  expect_identical(et_to_r(source_joint$key),"sparse-mfpca-joint-pace")
  source_joint_key<-call(lookup,np$array(matrix("sparse-mfpca-joint-pace"),dtype="str"))
  expect_identical(et_to_r(source_joint_key$key),"sparse-mfpca-joint-pace")
  math<-call(etpy_get_export("list_mathematical_contracts"))
  recovery<-call(etpy_get_export("functional_recovery_metric_catalog"))
  expect_error(reticulate::py_set_attr(item(math,0L),"title","edited"),
    "FrozenInstanceError")
  expect_error(reticulate::py_set_attr(item(recovery,0L),"quantity","edited"),
    "FrozenInstanceError")
})

test_that("catalog full-source Python 1.2 field comparison is opt in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned direct-source catalog contracts are opt in")
  expect_identical(et_python_version(),"1.2.0")
  for(p in list(list(name="mathematical_contract_frame",r=etr_mathematical_contract_frame),
    list(name="functional_recovery_metric_catalog_frame",
      r=etr_functional_recovery_metric_catalog_frame))){
    original<-as.data.frame(et_to_r(reticulate::py_call(etpy_get_export(p$name))),
      stringsAsFactors=FALSE,check.names=FALSE)
    native<-p$r()
    expect_identical(names(native),names(original))
    expect_identical(nrow(native),nrow(original))
    for(field in names(native))
      expect_identical(enc2utf8(as.character(native[[field]])),
        enc2utf8(as.character(original[[field]])),
        info=paste("frozen Python 1.2 full-domain field",p$name,field))
  }
})
