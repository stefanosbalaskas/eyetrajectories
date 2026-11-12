# Exact frozen Python 1.2 default scikit-fda BoxplotOutlierDetector
# ModifiedBandDepth = integrated pointwise univariate SimplicialDepth;
# SciPy composite Simpson; central envelope = top ceil(n/2) MBD curves.
# This suite deliberately does not claim MSPlot / robust-MCD parity.

.etr_mbd_doc_example<-function(time=c(0,2,4,6,8,10)) {
  y<-rbind(
    c(1,1,2,3,2.5,2),
    c(.5,.5,1,2,1.5,1),
    c(-1,-1,-.5,1,1,.5),
    c(-.5,-.5,-.5,-1,-1,-1))
  a<-array(as.numeric(y),dim=c(4L,6L,1L))
  etr_trajectory_set(time,a,paste0("c",1:4),"x",
    provenance=list(source="scikit-fda-BoxplotOutlierDetector_example"))
}

test_that("native Simpson time weights reproduce SciPy for irregular sampled quadratics",{
  for(time in list(
    c(0,1),c(0,.23,1.3),c(0,.2,.8,1.7),
    c(0,.31,.54,.8,1.9),c(0,.12,.8,1.1,2.5,3.4))){
    w<-.etr_skfda_simpson_weights(time)
    expect_equal(sum(w),1,tolerance=1e-12)
    expect_equal(sum(w*time),mean(range(time)),tolerance=1e-12)
    # Simpson is exact for quadratic polynomials with >=3 points
    # even on nonuniform grids and SciPy's Cartwright correction.
    if(length(time)>=3L)
      expect_equal(sum(w*time^2),
        (max(time)^3-min(time)^3)/
          (3*(max(time)-min(time))),tolerance=1e-12)
  }
  expect_error(.etr_skfda_simpson_weights(c(0,0,1)),"increasing")
  expect_error(.etr_skfda_simpson_weights(1),"increasing")
})

test_that("source ModifiedBandDepth matches known scikit-fda published four-curve example",{
  x<-.etr_mbd_doc_example()
  source<-etr_detect_functional_outliers_skfda(
    x,"x",method="boxplot",factor=1.5,
    strict_source_record=TRUE)
  expect_s3_class(source,"etr_skfda_mbd_boxplot_scientific_record")
  expect_s3_class(source,"etr_native_functional_outlier_result")
  expect_identical(source$diagnostics$curve_id,paste0("c",1:4))
  expect_identical(source$diagnostics$backend_label,
    c(-1L,1L,1L,-1L))
  expect_identical(source$diagnostics$review_flag,
    c(TRUE,FALSE,FALSE,TRUE))
  expect_equal(source$modified_band_depth,
    c(.5,5/6,13/18,59/90),
    tolerance=1e-12)
  expect_identical(source$central_curve_indices_zero_based,c(1L,2L))
  expect_equal(source$central_envelope$lower,
    c(-1,-1,-.5,1,1,.5),tolerance=0)
  expect_equal(source$central_envelope$upper,
    c(.5,.5,1,2,1.5,1),tolerance=0)
  expect_identical(source$method,"skfda_boxplot")
  expect_identical(source$reference,NULL)
  expect_identical(source$provenance$source,
    "scikit-fda-BoxplotOutlierDetector_example")
  expect_identical(source$provenance$dimension,"x")
  expect_identical(source$provenance$factor,1.5)
  expect_identical(source$provenance$random_state,0L)
  expect_match(source$provenance$scientific_warning,
    "not automatic exclusion criteria")
  expect_null(source$backend_object)
  expect_false(source$source_equivalent)
  expect_false(source$independently_source_certified)
  expect_false(source$actual_msplot_implemented)
})

test_that("source MBD varies with true nonuniform times, and is not marginal Tukey",{
  tt<-c(0,.2,.6,1.2,3,5)
  x<-.etr_mbd_doc_example(tt)
  source<-etr_detect_functional_outliers_skfda(
    x,"x",strict_source_record=TRUE)
  y<-matrix(x$values[,,1L],nrow=4L)
  pointwise<-.etr_skfda_pointwise_simplicial_depth(y)
  weights<-.etr_skfda_simpson_weights(tt)
  expect_equal(source$modified_band_depth,
    as.vector(pointwise%*%weights),tolerance=1e-14)
  expect_equal(source$integration_weights,weights,tolerance=0)
  expect_true(any(abs(weights-rep(1/6,6))>.05))
  old<-etr_detect_functional_outliers_skfda(x,"x")
  expect_s3_class(old,"etr_native_functional_outlier_result")
  expect_false(inherits(old,"etr_skfda_mbd_boxplot_scientific_record"))
  expect_identical(old$method,"native_marginal_tukey_envelope")
  expect_true(all(source$diagnostics$backend_label %in% c(-1L,1L)))
  expect_identical(x$values,.etr_mbd_doc_example(tt)$values)
})

test_that("source functional boxplot guards rank ties and stochastic MSPlot exclusions",{
  x<-.etr_mbd_doc_example()
  expect_error(etr_detect_functional_outliers_skfda(
    x,"x",method="msplot",strict_source_record=TRUE),
    "MSPlot")
  expect_error(etr_detect_functional_outliers_skfda(
    x,"x",strict_source_record=NA),"strict_source_record")
  expect_error(etr_detect_functional_outliers_skfda(
    x,"x",factor=0,strict_source_record=TRUE),"positive")
  expect_error(etr_detect_functional_outliers_skfda(
    x,"y",strict_source_record=TRUE),"dimension")
  same<-array(1,dim=c(4L,6L,1L))
  tied<-etr_trajectory_set(0:5,same,paste0("a",1:4),"x")
  expect_error(etr_detect_functional_outliers_skfda(
    tied,"x",strict_source_record=TRUE),
    "cutoff is tied")
  partial<-x$values
  partial[1,1,1]<-NA_real_
  incomplete<-etr_trajectory_set(x$time,partial,
    x$curve_ids,x$dimension_names)
  expect_error(etr_detect_functional_outliers_skfda(
    incomplete,"x",strict_source_record=TRUE),"complete observations")
})

test_that("real scikit-fda frozen Python 1.2 functional boxplot yields same depths and flags",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 and real scikit-fda outlier oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from skfda.exploratory.depth import ModifiedBandDepth
from skfda import FDataGrid
source_y=np.array([
 [1.,1.,2.,3.,2.5,2.],
 [.5,.5,1.,2.,1.5,1.],
 [-1.,-1.,-.5,1.,1.,.5],
 [-.5,-.5,-.5,-1.,-1.,-1.]])
source_data={}
for name,grid in (('uniform',np.array([0.,2.,4.,6.,8.,10.])),
                  ('irregular',np.array([0.,.2,.6,1.2,3.,5.]))):
    tr=et.TrajectorySet(
      time=grid,values=source_y[:,:,np.newaxis],
      curve_ids=('c1','c2','c3','c4'),dimension_names=('x',),
      provenance={'source':'scikit-fda-BoxplotOutlierDetector_example'})
    fd=FDataGrid(data_matrix=tr.values,grid_points=tr.time)
    res=et.detect_functional_outliers_skfda(
      tr,dimension='x',method='boxplot',factor=1.5,random_state=0)
    depths=np.asarray(ModifiedBandDepth()(fd),dtype=float)
    source_data[name]={
      'depth':depths,
      'label':np.asarray(res.diagnostics['backend_label'],dtype=int),
      'flag':np.asarray(res.diagnostics['review_flag'],dtype=bool)}
")
  for(spec in list(
    list(name="uniform",time=c(0,2,4,6,8,10)),
    list(name="irregular",time=c(0,.2,.6,1.2,3,5)))){
    z<-reticulate::py_eval(
      paste0("source_data['",spec$name,"']"),convert=TRUE)
    x<-.etr_mbd_doc_example(spec$time)
    ours<-etr_detect_functional_outliers_skfda(
      x,"x",strict_source_record=TRUE)
    expect_equal(ours$modified_band_depth,as.numeric(z$depth),
      tolerance=1e-10,info=spec$name)
    expect_identical(ours$diagnostics$backend_label,
      as.integer(z$label))
    expect_identical(ours$diagnostics$review_flag,
      as.logical(z$flag))
  }
})
