# Frozen eyetrajectoriespy==1.2.0 fpca.py supports explicit 1D/2D
# scores; native R formerly reconstructed only its original fitted curves.
# Numerical source equivalence below is bounded and never certifies all
# upstream accepted input types or output-class parity.
.etr_external_score_fixture<-function(){
  t<-c(0,.25,.6,1)
  v<-array(0,c(6L,4L,2L))
  for(i in 1:6){
    v[i,,1]<-(i-3.5)*c(0.4,1,0.3,0.9)+
      ((i*i)%%5)*c(.02,.1,-.04,.2)
    v[i,,2]<-(i-3.5)*c(.2,-.7,.8,-.4)+
      ((i*3)%%4)*c(.3,-.2,.14,.08)
  }
  etr_trajectory_set(t,v,paste0("p",1:6),c("x","y"),
    coordinate_system="normalized",time_unit="s")
}

test_that("external vector and matrix FPCA scores reconstruct source geometry",{
  x<-.etr_external_score_fixture()
  fit<-etr_fit_fpca(x,n_components=2L)
  original<-etr_reconstruct_fpca(fit)
  expect_s3_class(original,"etr_trajectory_set")
  expect_equal(original$values,
    etr_reconstruct_fpca(fit,scores=fit$scores),tolerance=1e-12)
  one<-etr_reconstruct_fpca(fit,scores=c(.25,-.5))
  expect_identical(dim(one),c(1L,4L,2L))
  expect_equal(as.numeric(one[1,,1]),
    fit$mean[,1]+.25*fit$components[1,,1]-
      .5*fit$components[2,,1],tolerance=1e-12)
  new_scores<-rbind(c(.25,-.5),c(1.2,.4),c(-.2,0))
  all<-etr_reconstruct_fpca(fit,scores=new_scores)
  expect_identical(dim(all),c(3L,4L,2L))
  first<-etr_reconstruct_fpca(fit,n_components=1L,scores=new_scores)
  expect_equal(as.numeric(first[1,,1]),
    fit$mean[,1]+new_scores[1,1]*fit$components[1,,1],
    tolerance=1e-12)
  expect_equal(etr_reconstruct_fpca(fit,scores=c(0)),
    array(rep(as.numeric(fit$mean),each=1L),
      dim=c(1L,4L,2L)),tolerance=1e-12)
  augmented<-cbind(new_scores,99)
  expect_equal(etr_reconstruct_fpca(fit,scores=augmented),
    all,tolerance=1e-12)
  expect_identical(dim(etr_reconstruct_fpca(fit,
    scores=matrix(c(.1,.2),nrow=2L))),
    c(2L,4L,2L))
  expect_error(etr_reconstruct_fpca(fit,scores=c(.2),
    n_components=2L),"fewer columns")
  expect_error(etr_reconstruct_fpca(fit,
    scores=array(1,c(2L,2L,2L))),"scores")
  expect_error(etr_reconstruct_fpca(fit,scores=c(.2,NA_real_)),
    "finite")
  expect_error(etr_reconstruct_fpca(fit,scores=matrix(
    numeric(0),0L,2L)),"scores")
  expect_error(etr_reconstruct_fpca(fit,scores=c("1","2")),"scores")
  expect_error(etr_reconstruct_fpca(fit,scores=new_scores,
    n_components=3L),"n_components")
})

test_that("frozen Python 1.2 reconstructs identical external score arrays",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 explicit FPCA score reconstruction is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fit<-etr_fit_fpca(.etr_external_score_fixture(),n_components=2L)
  reticulate::py_run_string("from types import SimpleNamespace")
  model<-reticulate::py_call(
    reticulate::py_eval("SimpleNamespace",convert=FALSE),
    mean=reticulate::r_to_py(fit$mean),
    components=reticulate::r_to_py(fit$components),
    scores=reticulate::r_to_py(fit$scores),
    n_components=as.integer(fit$n_components))
  source<-etpy_get_export("reconstruct_fpca")
  for(scores in list(c(.25,-.5),c(.25),
      matrix(c(.25,1.2,-.2,-.5,.4,0),nrow=3L),
      cbind(matrix(c(.25,1.2,-.2,-.5,.4,0),nrow=3L),9))){
    for(k in c(1L,2L)){
      if(length(scores)<k)next
      actual<-etr_reconstruct_fpca(fit,scores=scores,n_components=k)
      direct<-reticulate::py_call(source,result=model,
        scores=reticulate::r_to_py(scores),n_components=k)
      expect_equal(unname(actual),unname(et_to_r(direct)),
        tolerance=1e-12,ignore_attr=TRUE,
        info=paste("external FPCA",length(scores),"k",k))
    }
  }
  native<-etr_reconstruct_fpca(fit)
  direct<-reticulate::py_call(source,result=model)
  expect_equal(unname(native$values),unname(et_to_r(direct)),
    tolerance=1e-12,ignore_attr=TRUE)
  # Python returns an ndarray; native original reconstruction continues
  # to return a trajectory set for backwards compatibility.
  expect_true(inherits(native,"etr_trajectory_set"))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
