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
  expect_true(inherits(contracts[[1]],"etr_mathematical_contract"))
  expect_true(inherits(metrics[[1]],"etr_recovery_metric"))
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
