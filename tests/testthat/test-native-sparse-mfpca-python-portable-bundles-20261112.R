# Native R standalone scientific portability for frozen Python 1.2
# portable_results.py and workflows/_core.py, pinned to
# c1cd95ad718327550f7e55393ff38582872f7a94.
# No Python runtime required in the writer; Python oracle opt-in only.

.etr_mfpca_portable_fixture<-function(){
  x<-.etr_spnm_fixture()
  p<-c(list(backend="native_covariance"),.etr_spnm_args())
  fit<-do.call(etr_fit_sparse_mfpca,
    c(list(trajectories=x,strict_source_record=TRUE),p))
  w<-etr_run_sparse_mfpca_workflow(x,p,strict_source_record=TRUE)
  list(x=x,params=p,fit=fit,workflow=w)
}

test_that("Python 1.2 portable strict MFPCA fit retains 29 source fields without Python",{
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  skip_if_not_installed("zip")
  f<-.etr_mfpca_portable_fixture()
  root<-tempfile("etr_spm_portable_fit_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  output<-etr_export_python_portable_result(f$fit,root)
  expect_true(dir.exists(output))
  snapshot<-etr_read_python_portable_result(output)
  expect_s3_class(snapshot,"etr_python_portable_snapshot")
  expect_identical(snapshot$result_type,
    "eyetrajectoriespy.types.SparseMFPCAResult")
  expect_identical(snapshot$payload[["__python_type__"]],
    snapshot$result_type)
  expect_identical(names(snapshot$payload)[-1L],
    .etr_sparse_mfpca_w2_fields)
  expect_identical(dim(snapshot$payload$scores),c(24L,2L))
  expect_identical(dim(snapshot$payload$mean),c(9L,2L))
  expect_equal(snapshot$payload$scores,f$fit$scores,tolerance=0)
  expect_equal(snapshot$payload$covariance_cxy,
    f$fit$covariance_cxy,tolerance=0)
  expect_identical(as.character(unlist(snapshot$payload$curve_ids)),
    f$x$curve_ids)
  expect_equal(as.numeric(snapshot$payload$eigenvalues),
    f$fit$eigenvalues,tolerance=0)
  expect_identical(names(snapshot$payload$metadata),
    names(f$fit$metadata))
  expect_identical(snapshot$environment,NULL)
  expect_length(snapshot$nonportable_fields,0L)
  expect_identical(snapshot$units$coordinate_system,
    f$fit$coordinate_system)
  expect_true(grepl("^R-native-eyetrajectories-",
    snapshot$source_package_version))
  expect_error(etr_export_python_portable_result(f$fit,output),"not empty")
  expect_error(etr_export_python_portable_result(f$fit,tempfile(),
    overwrite=TRUE),"overwrite")
  expect_error(etr_export_python_portable_result(f$fit,tempfile(),
    include_environment=TRUE),"environment")
})

test_that("portable fixed-mode W2 workflow retains nested fitted scientific state and audited report",{
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  skip_if_not_installed("zip")
  f<-.etr_mfpca_portable_fixture()
  root<-tempfile("etr_spm_w2_bundle_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  output<-etr_export_workflow_bundle(f$workflow,root,
    format="python_1_2")
  expect_true(dir.exists(output))
  expected<-c("workflow.json","config.json","provenance.json",
    "environment.json","steps.csv","decisions.csv","SHA256SUMS",
    "result/arrays.npz","result/manifest.json","reports/fit.txt",
    "tables/scores.csv")
  expect_true(all(file.exists(file.path(output,expected))))
  manifest<-jsonlite::fromJSON(file.path(output,"workflow.json"),
    simplifyVector=FALSE)
  expect_identical(manifest$format,
    "eyetrajectoriespy-workflow-bundle")
  expect_identical(manifest$workflow_contract,"sparse_mfpca:v1")
  expect_identical(manifest$reports,list("fit.txt"))
  expect_identical(manifest$tables,list("scores.csv"))
  expect_false(manifest$figure_export_included)
  expect_false(file.exists(file.path(output,"result","result.rds")))
  environment<-jsonlite::fromJSON(
    file.path(output,"environment.json"),simplifyVector=FALSE)
  expect_identical(environment$runtime,"R")
  expect_null(environment$python)
  snapshot<-etr_read_python_portable_result(
    file.path(output,"result"))
  expect_identical(snapshot$result_type,
    "eyetrajectoriespy.workflows._sparse_mfpca.SparseMFPCAWorkflowResult")
  # Frozen portable_results.py writes JSON with sort_keys=True;
  # round-tripped mapping order is lexical, not dataclass field order.
  expect_setequal(names(snapshot$payload)[-1L],
    names(f$workflow))
  expect_identical(snapshot$payload$fit[["__python_type__"]],
    "eyetrajectoriespy.types.SparseMFPCAResult")
  expect_equal(snapshot$payload$fit$scores,
    f$workflow$fit$scores,tolerance=0)
  expect_equal(snapshot$payload$fit$covariance_cxy,
    f$workflow$fit$covariance_cxy,tolerance=0)
  expect_equal(snapshot$payload$tables$scores$SMFPC1,
    f$workflow$tables$scores$SMFPC1,tolerance=0)
  expect_identical(snapshot$payload$decisions$mean_bandwidth$source,
    "analyst")
  expect_s3_class(snapshot$payload$steps,"etr_python_tuple")
  expect_length(snapshot$payload$steps,1L)
  expect_true(is.finite(snapshot$payload$steps[[1L]]$elapsed_seconds))
  expect_identical(snapshot$payload$config[["__python_type__"]],
    "eyetrajectoriespy.workflows._sparse_mfpca.SparseMFPCAWorkflowConfig")
  expect_setequal(names(snapshot$payload$config)[-1L],
    names(f$workflow$config))
  expect_identical(snapshot$payload$provenance,
    f$workflow$provenance)
  expect_length(snapshot$nonportable_fields,0L)
  checks<-readLines(file.path(output,"SHA256SUMS"))
  expect_setequal(substring(checks,67L),
    setdiff(list.files(output,recursive=TRUE),"SHA256SUMS"))
  for(line in checks){
    p<-file.path(output,substring(line,67L))
    expect_identical(substring(line,1L,64L),
      digest::digest(p,algo="sha256",file=TRUE))
  }
  expect_error(etr_export_workflow_bundle(f$workflow,output,
    format="python_1_2"),"already exists")
})

test_that("portable strict MFPCA fails closed outside fixed source domain",{
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  skip_if_not_installed("zip")
  f<-.etr_mfpca_portable_fixture()
  invalid<-f$workflow
  invalid$config$bandwidth_selection<-list(mean_bandwidths=.5)
  dest<-tempfile("etr_spm_rejected_")
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  expect_error(etr_export_python_portable_result(invalid,dest),
    "fixed bandwidth|optional diagnostics")
  expect_false(file.exists(dest))
  invalid<-f$workflow
  invalid$score_uncertainty<-list(unexpected=TRUE)
  expect_error(etr_export_python_portable_result(invalid,dest),
    "fixed-bandwidth|fit-only")
  invalid<-f$fit
  invalid$mean<-matrix(1,ncol=1L)
  expect_error(etr_export_python_portable_result(invalid,dest),
    "shape")
  expect_false(file.exists(dest))
  expect_error(etr_export_python_portable_result(list(a=1),dest),
    "etr_trajectory_set")
})

test_that("frozen Python 1.2 loads native source MFPCA fit and workflow and verifies byte-level bundle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 portable result oracle")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  skip_if_not_installed("zip")
  expect_identical(et_python_version(),"1.2.0")
  f<-.etr_mfpca_portable_fixture()
  root<-tempfile("etr_spm_python_source_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  fitdir<-file.path(root,"fit")
  bundledir<-file.path(root,"bundle")
  etr_export_python_portable_result(f$fit,fitdir)
  etr_export_workflow_bundle(f$workflow,bundledir,
    format="python_1_2")
  reticulate::py_run_string("
from pathlib import Path
from dataclasses import fields
from hashlib import sha256
import json
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
import eyetrajectoriespy.workflows as wf
def _spm_validate_portable(fitdir,bundledir,score0,source_field_count):
    f=et.load_portable_result(fitdir)
    root=Path(bundledir)
    manifest=json.loads((root/'workflow.json').read_text(encoding='utf-8'))
    w=et.load_portable_result(root/manifest['portable_result_directory'])
    def assert_source(payload,cls):
        assert payload['__python_type__']==cls.__module__+'.'+cls.__qualname__
        assert set(payload)-{'__python_type__'}=={field.name for field in fields(cls)}
        assert len(payload)==len(fields(cls))+1
    assert_source(f.payload,et.SparseMFPCAResult)
    assert len(fields(et.SparseMFPCAResult))==source_field_count==29
    assert np.isclose(f.payload['scores'][0,0],score0)
    assert f.environment is None and w.environment is None
    assert not f.nonportable_fields and not w.nonportable_fields
    assert_source(w.payload,wf.SparseMFPCAWorkflowResult)
    assert_source(w.payload['config'],wf.SparseMFPCAWorkflowConfig)
    assert_source(w.payload['fit'],et.SparseMFPCAResult)
    assert w.payload['fit']['scores'].shape==(24,2)
    assert w.payload['fit']['mean'].shape==(9,2)
    assert w.payload['tables']['scores'].shape[0]==24
    assert isinstance(w.payload['tables']['scores'],pd.DataFrame)
    assert len(w.payload['steps'])==1
    assert w.payload['steps'][0]['elapsed_seconds']>=0
    assert w.payload['decisions']['psd_action']['source']=='analyst'
    lines=(root/'SHA256SUMS').read_text(encoding='utf-8').splitlines()
    actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()}
    assert {line.split('  ',1)[1] for line in lines}==actual-{'SHA256SUMS'}
    for line in lines:
        sha,path=line.split('  ',1)
        assert sha256((root/path).read_bytes()).hexdigest()==sha,path
    return w.result_type
")
  source<-reticulate::py_call(
    reticulate::py_eval("_spm_validate_portable",convert=FALSE),
    fitdir=fitdir,bundledir=bundledir,
    score0=f$fit$scores[1L,1L],source_field_count=29L)
  expect_identical(et_to_r(source),
    "eyetrajectoriespy.workflows._sparse_mfpca.SparseMFPCAWorkflowResult")
})
