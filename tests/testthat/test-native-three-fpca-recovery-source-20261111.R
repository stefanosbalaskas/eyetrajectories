# Frozen public Python 1.2 source: eyetrajectoriespy==1.2.0
# commit c1cd95ad718327550f7e55393ff38582872f7a94
# recovery.py::evaluate_fpca_recovery, evaluate_sparse_fpca_recovery,
# evaluate_sparse_mfpca_recovery. Native runtime never imports Python.

.etr_three_fpca_truth <- function(variant="base") {
  stopifnot(variant %in%
    c("base","boolean","status_only","empty","zero_noise"))
  time<-c(0,.5,1)
  phi<-array(1/sqrt(2),dim=c(1L,3L,2L))
  mean<-matrix(c(.1,.2,.3,.4,.5,.6),nrow=3L,ncol=2L)
  scores<-matrix(c(-2,-1,1,2),nrow=4L,ncol=1L)
  latent<-array(0,dim=c(4L,3L,2L))
  for(i in seq_len(4L))
    latent[i,,]<-mean+scores[i,1L]*matrix(phi,nrow=3L,ncol=2L)
  noise<-diag(c(if(variant=="zero_noise")0 else .1,.2))
  truth<-list(truth_grid=time,dimension_names=c("x","y"),
    mean=mean,eigenfunctions=phi,eigenvalues=.5,scores=scores,
    latent_on_truth_grid=latent,measurement_noise_covariance=noise)
  w<-etr_trapezoid_weights(time)
  dense<-list(time=time,dimension_names=c("x","y"),
    provenance=list(fpca=list(scaling="none")),
    scale=c(1,1),mean=mean,components= -phi,
    explained_variance=.5,scores= -scores,weights=w)
  diagnostics<-if(variant=="empty")data.frame() else
    if(variant=="status_only")
      data.frame(status_code=c("ok","bad","ok","ok"))
    else data.frame(
      status_code=c("ok","bad","ok","ok"),
      condition_number=if(variant=="boolean")
        c(TRUE,FALSE,TRUE,FALSE) else c(1,2,3,4))
  covariance_diagnostics<-if(variant=="empty"||variant=="status_only")
    list() else list(
      applied_action="project",
      relative_operator_correction_frobenius_norm=
        if(variant=="boolean") TRUE else .02)
  sparse<-list(evaluation_grid=time,dimension="x",
    mean=mean[,1L],covariance=matrix(.35,3L,3L),
    eigenfunctions=matrix(-1/sqrt(2),1L,3L),eigenvalues=.5,
    scores= -scores,quadrature_weights=NULL,noise_variance=.15,
    score_diagnostics=diagnostics,
    covariance_diagnostics=covariance_diagnostics,
    provenance=list(sparse_fpca=list(
      noise_variance_method="difference_diagonal",
      measurement_error_variance_supplied=FALSE)))
  mfpca<-list(evaluation_grid=time,dimensions=c("x","y"),
    mean=mean,eigenfunctions= -phi,eigenvalues=.5,
    scores= -scores,quadrature_weights=w,
    covariance_cxx=matrix(.30,3L,3L),
    covariance_cxy=matrix(.28,3L,3L),
    covariance_cyx=matrix(.28,3L,3L),
    covariance_cyy=matrix(.32,3L,3L),
    measurement_error_covariance=diag(c(.1,.2)),
    score_diagnostics=diagnostics,
    covariance_diagnostics=covariance_diagnostics,
    provenance=list(sparse_mfpca=list(
      measurement_error_mode="supplied")))
  list(truth=truth,dense=dense,sparse=sparse,mfpca=mfpca)
}

.etr_three_fpca_values <- function(z) {
  list(
    dense=etr_evaluate_fpca_recovery(z$dense,z$truth),
    sparse=etr_evaluate_sparse_fpca_recovery(z$sparse,z$truth),
    mfpca=etr_evaluate_sparse_mfpca_recovery(z$mfpca,z$truth))
}

.etr_three_fpca_compare <- function(native,python,variant,which) {
  info<-paste(variant,which)
  expect_identical(names(native),names(python),info=paste(info,"columns"))
  expect_identical(nrow(native),nrow(python),info=paste(info,"rows"))
  for(col in names(native)) {
    x<-native[[col]];y<-python[[col]]
    expect_identical(is.na(x),is.na(y),
      info=paste(info,col,"missingness"))
    keep<-!is.na(x)
    if(is.numeric(x) && is.numeric(y)){
      x<-as.numeric(x[keep]);y<-as.numeric(y[keep])
      if(identical(col,"value")){
        angles<-native$metric[keep]=="subspace_principal_angle_degrees"
        if(any(!angles))
          expect_equal(x[!angles],y[!angles],tolerance=1e-10,
            info=paste(info,col,"numeric source"))
        if(any(angles))
          expect_lte(max(abs(x[angles]-y[angles])),2e-5,
            info=paste(info,col,"ill-conditioned acos"))
      }else expect_equal(x,y,tolerance=1e-12,info=paste(info,col))
    }else expect_identical(as.character(x[keep]),as.character(y[keep]),
      info=paste(info,col))
  }
}

test_that("three recovery families share proper source component and covariance semantics",{
  for(variant in c("base","boolean","status_only","empty","zero_noise")){
    z<-.etr_three_fpca_truth(variant)
    out<-.etr_three_fpca_values(z)
    expect_identical(names(out),c("dense","sparse","mfpca"))
    for(key in names(out)){
      expect_s3_class(out[[key]],"etr_functional_recovery_assessment")
      expect_true(length(out[[key]]$values)>=9L)
      expect_identical(out[[key]]$provenance$matched_truth_components,0L)
      expect_equal(out[[key]]$provenance$alignment_signs,-1,
        tolerance=0)
      metrics<-vapply(out[[key]]$values,
        function(v)v$metric$name,character(1L))
      expect_true(all(c("mean_ise","covariance_ise",
        "reconstruction_ise")%in%metrics))
      if(key!="dense"){
        if(variant=="boolean"){
          values<-vapply(out[[key]]$values,
            function(v)v$value,numeric(1L))
          expect_equal(values[metrics=="score_condition_number_median"],.5)
          expect_equal(values[metrics=="score_condition_number_q95"],1)
          expect_equal(values[metrics=="score_condition_number_max"],1)
          expect_equal(values[metrics=="psd_relative_operator_correction"],1)
        }
        if(variant=="empty"){
          expect_false("score_condition_number_median"%in%metrics)
          expect_false("psd_relative_operator_correction"%in%metrics)
          expect_identical(sum(metrics=="score_failure_rate"),1L)
        }
      }
      if(key=="sparse" && variant=="zero_noise")
        expect_false("noise_variance_relative_error"%in%metrics)
      if(key=="mfpca" && variant=="zero_noise")
        expect_false(out[[key]]$provenance$measurement_error_truth_supplied)
    }
  }
})

test_that("three source recovery records fail closed on unsupported geometry",{
  z<-.etr_three_fpca_truth()
  bad<-z$dense;bad$time[2L]<-.4
  expect_error(etr_evaluate_fpca_recovery(bad,z$truth),"exact source grid")
  bad<-z$dense;bad$provenance$fpca$scaling<-"dimension_sd"
  expect_error(etr_evaluate_fpca_recovery(bad,z$truth),"scaling='none'")
  bad<-z$sparse;bad$dimension<-"absent"
  expect_error(etr_evaluate_sparse_fpca_recovery(bad,z$truth),
    "absent from generating truth")
  bad<-z$sparse;bad$covariance<-matrix(1,2L,2L)
  expect_error(etr_evaluate_sparse_fpca_recovery(bad,z$truth),
    "sparse covariance")
  bad<-z$mfpca;bad$dimensions<-c("y","x")
  expect_error(etr_evaluate_sparse_mfpca_recovery(bad,z$truth),
    "source order")
  bad<-z$mfpca;bad$quadrature_weights<-rep(1/3,3L)
  expect_error(etr_evaluate_sparse_mfpca_recovery(bad,z$truth),
    "quadrature weights")
})

test_that("15 full typed frozen Python 1.2 scientific recovery assessments match R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 source differential comparison opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth",
    "def _etr_three_fpca_new(cls,**fields):",
    "    z=object.__new__(cls)",
    "    for k,v in fields.items():object.__setattr__(z,k,v)",
    "    return z",
    "def _etr_three_fpca_oracle(variant):",
    "    t=np.array([0.,.5,1.])",
    "    m=np.array([[.1,.4],[.2,.5],[.3,.6]])",
    "    phi=np.full((1,3,2),1/np.sqrt(2))",
    "    sc=np.array([[-2.],[-1.],[1.],[2.]])",
    "    latent=m[None,:,:]+sc[:,:,None]*phi[0][None,:,:]",
    "    noise=np.diag([0. if variant=='zero_noise' else .1,.2])",
    "    truth=_etr_three_fpca_new(FunctionalSimulationTruth,",
    "      truth_grid=t,dimension_names=('x','y'),",
    "      mean=m,eigenfunctions=phi,eigenvalues=np.array([.5]),",
    "      scores=sc,latent_on_truth_grid=latent,",
    "      measurement_noise_covariance=noise)",
    "    dense=_etr_three_fpca_new(et.FPCAResult,time=t,",
    "      dimension_names=('x','y'),provenance={'fpca':{'scaling':'none'}},",
    "      scale=np.ones(2),mean=m,components=-phi,",
    "      explained_variance=np.array([.5]),scores=-sc,",
    "      weights=np.array([.25,.5,.25]))",
    "    diag=pd.DataFrame() if variant=='empty' else pd.DataFrame(",
    "      {'status_code':['ok','bad','ok','ok']} if variant=='status_only'",
    "      else {'status_code':['ok','bad','ok','ok'],",
    "        'condition_number':[True,False,True,False]",
    "        if variant=='boolean' else [1,2,3,4]})",
    "    covdiag={} if variant in ('empty','status_only') else {",
    "      'applied_action':'project',",
    "      'relative_operator_correction_frobenius_norm':",
    "        True if variant=='boolean' else .02}",
    "    sparse=_etr_three_fpca_new(et.SparseFPCAResult,",
    "      evaluation_grid=t,dimension='x',mean=m[:,0],",
    "      covariance=np.full((3,3),.35),",
    "      eigenfunctions=np.full((1,3),-1/np.sqrt(2)),",
    "      eigenvalues=np.array([.5]),scores=-sc,",
    "      quadrature_weights=None,noise_variance=.15,",
    "      score_diagnostics=diag,covariance_diagnostics=covdiag,",
    "      provenance={'sparse_fpca':{",
    "        'noise_variance_method':'difference_diagonal',",
    "        'measurement_error_variance_supplied':False}})",
    "    multi=_etr_three_fpca_new(et.SparseMFPCAResult,",
    "      evaluation_grid=t,dimensions=('x','y'),",
    "      mean=m,eigenfunctions=-phi,eigenvalues=np.array([.5]),",
    "      scores=-sc,quadrature_weights=np.array([.25,.5,.25]),",
    "      covariance_cxx=np.full((3,3),.30),",
    "      covariance_cxy=np.full((3,3),.28),",
    "      covariance_cyx=np.full((3,3),.28),",
    "      covariance_cyy=np.full((3,3),.32),",
    "      measurement_error_covariance=np.diag([.1,.2]),",
    "      score_diagnostics=diag,covariance_diagnostics=covdiag,",
    "      provenance={'sparse_mfpca':{'measurement_error_mode':'supplied'}})",
    "    results=(et.evaluate_fpca_recovery(dense,truth),",
    "      et.evaluate_sparse_fpca_recovery(sparse,truth),",
    "      et.evaluate_sparse_mfpca_recovery(multi,truth))",
    "    return tuple((et.functional_recovery_assessment_frame(res),",
    "      dict(res.provenance)) for res in results)"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_three_fpca_oracle")
  for(variant in c("base","boolean","status_only","empty","zero_noise")){
    z<-.etr_three_fpca_truth(variant)
    own<-.etr_three_fpca_values(z)
    py<-reticulate::py_call(oracle,variant)
    for(i in seq_along(own)){
      key<-names(own)[i]
      pair<-reticulate::py_get_item(py,as.integer(i-1L))
      py_frame<-reticulate::py_to_r(reticulate::py_get_item(pair,0L))
      py_provenance<-reticulate::py_to_r(reticulate::py_get_item(pair,1L))
      frame<-etr_functional_recovery_assessment_frame(own[[i]],
        python_boundary_mode=TRUE)
      .etr_three_fpca_compare(frame,py_frame,variant,key)
      native_provenance<-own[[i]]$provenance
      expect_identical(names(native_provenance),names(py_provenance),
        info=paste(variant,key,"provenance fields"))
      for(field in names(native_provenance)){
        a<-native_provenance[[field]];b<-py_provenance[[field]]
        if(is.null(a)){
          expect_null(b,info=paste(variant,key,field))
        }else if(is.numeric(a)&&is.numeric(b)){
          expect_equal(as.numeric(a),as.numeric(b),tolerance=1e-12,
            info=paste(variant,key,field))
        }else{
          expect_identical(as.character(unlist(a,use.names=FALSE)),
            as.character(unlist(b,use.names=FALSE)),
            info=paste(variant,key,field))
        }
      }
    }
  }
})
