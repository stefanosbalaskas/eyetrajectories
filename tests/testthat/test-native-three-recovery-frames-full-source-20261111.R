# eyetrajectoriespy==1.2.0, frozen
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Published Python: src/eyetrajectoriespy/simulate.py,
# functional_recovery_frame, failure_frame, summary_frame.
# No reticulate is invoked in the native R implementation.

.etr_three_recovery_fixture <- function(variant="structured"){
  stopifnot(variant%in%c("structured","fallback","all_failed","wide"))
  definition<-list(
    name="mean_integrated_error",quantity="integrated_error",
    direction="lower_is_better",units="squared_units",scope="curve",
    description="Simulation reconstruction error")
  mk<-function(scenario,replicate,seed,status="ok",
      value=NULL,structured=TRUE){
    if(status!="ok")return(list(scenario_name=scenario,
      replicate=as.integer(replicate),seed=as.integer(seed),status=status,
      metrics=numeric(),metric_values=list(),
      error_type="ValueError",error_message="frozen recovery failure"))
    if(structured){
      mv<-list(metric=definition,value=value,component=0L,source="curve")
      return(list(scenario_name=scenario,
        replicate=as.integer(replicate),seed=as.integer(seed),status="ok",
        metrics=stats::setNames(value,etr_functional_recovery_value_key(mv)),
        metric_values=list(mv)))
    }
    list(scenario_name=scenario,replicate=as.integer(replicate),
      seed=as.integer(seed),status="ok",
      metrics=c(mean_integrated_error=value,
        unregistered_metric=value*2),metric_values=list())
  }
  records<-switch(variant,
    structured=list(mk("α",0,101,value=.1),mk("α",1,102,value=.3),
      mk("α",2,103,"fit_failed"),mk("β",0,201,value=.2),
      mk("β",1,202,"recovery_failed")),
    fallback=list(mk("gamma",0,10,value=.125,structured=FALSE),
      mk("gamma",1,11,value=.375,structured=FALSE),
      mk("gamma",2,12,"simulation_failed"),
      mk("delta",0,20,value=.525,structured=FALSE)),
    all_failed=list(mk("z",0,1,"fit_failed"),
      mk("α",0,2,"simulation_failed"),
      mk("z",1,3,"recovery_failed")),
    wide=c(lapply(seq_len(9L),function(i)
      mk("wide",i-1L,100L+i,value=c(.05,.13,.21,.27,
        .43,.51,.63,.82,.94)[[i]])),
      list(mk("wide",9,110,"fit_failed"))))
  etr_functional_recovery_result(records,list(definition))
}

.etr_three_recovery_native <- function(z){
  list(values=etr_functional_recovery_frame(z),
    failures=etr_functional_recovery_failure_frame(z),
    summaries=etr_functional_recovery_summary_frame(z))
}

.etr_three_recovery_compare <- function(a,b,variant,name){
  expect_s3_class(a,"data.frame")
  expect_s3_class(b,"data.frame")
  expect_identical(names(a),names(b),info=paste(variant,name,"columns"))
  expect_identical(nrow(a),nrow(b),info=paste(variant,name,"rows"))
  for(col in names(a)){
    x<-a[[col]];y<-b[[col]]
    expect_identical(is.na(x),is.na(y),
      info=paste(variant,name,col,"missingness"))
    keep<-!is.na(x)
    if(is.numeric(x)&&is.numeric(y)){
      expect_equal(as.numeric(x[keep]),as.numeric(y[keep]),
        tolerance=1e-12,info=paste(variant,name,col))
    }else expect_identical(as.character(x[keep]),as.character(y[keep]),
      info=paste(variant,name,col))
  }
}

test_that("recovery source default follows NumPy not legacy R arithmetic",{
  z<-.etr_three_recovery_fixture("structured")
  a<-etr_functional_recovery_summary_frame(z)
  expect_identical(a$scenario,c("α","β"))
  expect_equal(a$mean,c(.2,.2))
  expect_equal(a$sd,c(sqrt(.02),0),tolerance=1e-14)
  expect_equal(a$failure_proportion,c(1/3,.5))
  expect_equal(a$mcse_mean,c(.1,0),tolerance=1e-14)
  empty<-.etr_three_recovery_native(.etr_three_recovery_fixture("all_failed"))
  expect_identical(dim(empty$values),c(0L,0L))
  expect_identical(dim(empty$failures),c(2L,6L))
  expect_identical(dim(empty$summaries),c(0L,19L))
  expect_true(all(empty$failures$failure_proportion==1))
  wide<-.etr_three_recovery_native(.etr_three_recovery_fixture("wide"))
  expect_equal(wide$summaries$n,9L)
  expect_equal(wide$summaries$n_failed,1L)
  expect_equal(wide$summaries$q05,.05+.4*(.13-.05),tolerance=1e-14)
  # The old native R aggregation is explicitly available but not the
  # default Python-compatibility contract.
  expect_identical(names(etr_functional_recovery_summary_frame(
    z,python_boundary_mode=FALSE)),names(a))
})

test_that("native recovery source-domain evidence rejects invalid records",{
  z<-.etr_three_recovery_fixture()
  bad<-z$records
  bad[[1L]]$metrics[[1L]]<-Inf
  expect_error(etr_functional_recovery_result(bad,z$metric_definitions),
    "finite")
  bad<-z$records
  bad[[1L]]$status<-"unknown"
  expect_error(etr_functional_recovery_result(bad,z$metric_definitions),
    "known status")
  bad<-z$records
  bad[[3L]]$metrics<-c(invalid=.3)
  expect_error(etr_functional_recovery_result(bad,z$metric_definitions),
    "no metrics")
  bad<-z$records
  bad[[1L]]$metric_values[[1L]]$value<-.2
  expect_error(etr_functional_recovery_result(bad,z$metric_definitions),
    "exactly match")
  expect_error(etr_functional_recovery_summary_frame(z,
    python_boundary_mode=NA),"python_boundary_mode")
  expect_error(etr_functional_recovery_frame(list()),"native functional")
})

test_that("twelve complete typed frozen Python 1.2 recovery frames match R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  py_metric<-etpy_get_export("FunctionalRecoveryMetric")
  py_value<-etpy_get_export("FunctionalRecoveryValue")
  py_record<-etpy_get_export("FunctionalRecoveryRecord")
  py_result<-etpy_get_export("FunctionalRecoveryResult")
  source_functions<-list(
    values=etpy_get_export("functional_recovery_frame"),
    failures=etpy_get_export("functional_recovery_failure_frame"),
    summaries=etpy_get_export("functional_recovery_summary_frame"))
  to_python<-function(z){
    metrics<-lapply(z$metric_definitions,function(d)
      reticulate::py_call(py_metric,name=d$name,quantity=d$quantity,
        direction=d$direction,units=d$units,scope=d$scope,
        description=d$description))
    entries<-lapply(z$records,function(r){
      structured<-lapply(r$metric_values,function(v){
        def<-metrics[[match(v$metric$name,
          vapply(z$metric_definitions,function(d)d$name,character(1L)))]]
        reticulate::py_call(py_value,metric=def,value=as.numeric(v$value),
          component=as.integer(v$component),source=v$source)
      })
      values<-reticulate::dict()
      for(key in names(r$metrics))values[[key]]<-as.numeric(r$metrics[[key]])
      reticulate::py_call(py_record,scenario_name=r$scenario_name,
        replicate=as.integer(r$replicate),seed=as.integer(r$seed),
        status=r$status,metrics=values,
        metric_values=reticulate::r_to_py(structured),
        error_type=r$error_type,error_message=r$error_message)
    })
    reticulate::py_call(py_result,
      records=reticulate::r_to_py(entries),
      metric_definitions=reticulate::r_to_py(metrics))
  }
  for(variant in c("structured","fallback","all_failed","wide")){
    z<-.etr_three_recovery_fixture(variant)
    python<-to_python(z)
    actual<-.etr_three_recovery_native(z)
    for(name in names(source_functions)){
      expected<-as.data.frame(et_to_r(reticulate::py_call(
        source_functions[[name]],result=python)),
        stringsAsFactors=FALSE)
      .etr_three_recovery_compare(actual[[name]],expected,variant,name)
    }
  }
})
