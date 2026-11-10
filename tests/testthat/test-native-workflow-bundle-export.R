# Native R workflow bundles and the bounded frozen Python 1.2 exporter.
.etr_bundle_test_workflow<-function(measure_time=FALSE){
  time<-seq(0,1,length.out=13L)
  y<-array(0,c(8L,length(time),1L))
  for(i in 1:8)y[i,,1L]<-sin(pi*time)+i*.07*cos(2*pi*time)+
    (i%%3)*.021*time
  tr<-etr_trajectory_set(time,y,
    sprintf("c%02d",1:8),"x",time_unit="s")
  etr_run_fpca_workflow(tr,config=list(n_components=1L),measure_time=measure_time)
}

test_that("native workflow bundle contains verifiable checksummed fit and audits",{
  if(!requireNamespace("jsonlite",quietly=TRUE)||
     !requireNamespace("digest",quietly=TRUE))
    skip("native workflow bundle requires optional jsonlite and digest")
  workflow<-.etr_bundle_test_workflow()
  root<-tempfile("etr_bundle_test_")
  dest<-file.path(root,"run","workflow")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  result<-etr_export_workflow_bundle(workflow,dest)
  expect_true(dir.exists(result))
  needed<-c("config.json","provenance.json","environment.json",
    "steps.csv","decisions.csv","workflow.json","SHA256SUMS",
    "result/result.rds","reports/fit.txt",
    "tables/scores.csv","tables/explained_variance.csv")
  expect_true(all(file.exists(file.path(result,needed))))
  saved<-readRDS(file.path(result,"result","result.rds"))
  expect_equal(saved$fit$components,workflow$fit$components)
  manifest<-jsonlite::fromJSON(file.path(result,"workflow.json"))
  expect_identical(manifest$format,"etr_native_r_workflow_bundle_v1")
  expect_identical(manifest$result_encoding,"RDS_not_Python_NPZ")
  expect_false(manifest$full_published_source_contract_certified)
  checks<-readLines(file.path(result,"SHA256SUMS"),warn=FALSE)
  checks<-checks[nzchar(checks)]
  expect_identical(length(checks),length(needed)-1L)
  for(line in checks){
    path<-substring(line,67L)
    expect_true(file.exists(file.path(result,path)))
    expect_identical(substring(line,1L,64L),
      digest::digest(file.path(result,path),algo="sha256",file=TRUE))
  }
  decisions<-utils::read.csv(file.path(result,"decisions.csv"))
  expect_true(all(c("name","value_json","source","criterion")%in%names(decisions)))
  expect_true(nrow(decisions)>=1L)
  expect_error(etr_export_workflow_bundle(workflow,dest),
    "already exists")
  expect_error(etr_export_workflow_bundle(workflow,dest,overwrite=TRUE),
    "overwrite")
})

test_that("native workflow bundle fails closed on unsafe evidence names",{
  if(!requireNamespace("jsonlite",quietly=TRUE)||
     !requireNamespace("digest",quietly=TRUE))
    skip("native workflow bundle requires optional jsonlite and digest")
  w<-.etr_bundle_test_workflow()
  root<-tempfile("etr_bundle_bad_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  a<-w;a$reports<-list("../bad"="text")
  expect_error(etr_export_workflow_bundle(a,file.path(root,"a")),
    "simple filenames")
  b<-w;b$tables<-list("table.pdf"=data.frame(x=1))
  expect_error(etr_export_workflow_bundle(b,file.path(root,"b")),
    "unique CSV")
  c<-w;c$reports<-list(fit=list("invalid"))
  expect_error(etr_export_workflow_bundle(c,file.path(root,"c")),
    "scalar text")
  d<-w;d$steps<-list(list(name="fit"))
  expect_error(etr_export_workflow_bundle(d,file.path(root,"d")),
    "step records")
  e<-w;e$config<-list(bad=function()1)
  expect_error(etr_export_workflow_bundle(e,file.path(root,"e")),
    "JSON")
})

.etr_python_bundle_fixture<-function(){
  w<-.etr_bundle_test_workflow(measure_time=TRUE)
  w$steps[[1L]]$warnings<-c("fixture \"quoted\" warning","numeric \u03bc")
  w$steps[[1L]]$parameters$grid<-matrix(c(1,2,3,4),nrow=2L)
  w$reports$notes<-"Numeric \u03bc, source record\n\n "
  w$tables$audit<-data.frame(label=c("\u03bc",NA_character_),
    accepted=c(TRUE,NA),row.names=c("run_a","run_b"))
  w
}

test_that("Python 1.2 workflow bundles carry the complete native FPCA state",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  w<-.etr_python_bundle_fixture()
  dest<-tempfile("etr_python_bundle_")
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  out<-etr_export_workflow_bundle(w,dest,format="python_1_2")
  manifest<-jsonlite::fromJSON(file.path(out,"workflow.json"),simplifyVector=FALSE)
  expect_identical(manifest$format,"eyetrajectoriespy-workflow-bundle")
  expect_identical(manifest$reports,list("fit.txt","notes.txt"))
  expect_identical(manifest$tables,list("audit.csv","explained_variance.csv","scores.csv"))
  expect_false(file.exists(file.path(out,"result","result.rds")))
  expect_true(w$steps[[1L]]$duration_measured)
  expect_true(is.finite(w$steps[[1L]]$elapsed_seconds))
  env<-jsonlite::fromJSON(file.path(out,"environment.json"))
  expect_identical(env$runtime,"R")
  expect_identical(env$package$name,"eyetrajectories")
  expect_null(env$python)
  snapshot<-etr_read_python_portable_result(file.path(out,"result"))
  expect_identical(snapshot$result_type,manifest$result_type)
  expect_length(snapshot$nonportable_fields,0L)
  expect_identical(snapshot$payload$fit$components,unname(w$fit$components))
  expect_identical(snapshot$payload$fit$scores,unname(w$fit$scores))
  expect_identical(snapshot$payload$steps[[1L]]$parameters$grid,
    w$steps[[1L]]$parameters$grid)
  expect_identical(as.numeric(snapshot$payload$steps[[1L]]$elapsed_seconds),
    w$steps[[1L]]$elapsed_seconds)
  expect_identical(snapshot$payload$provenance,w$provenance)
  expect_identical(snapshot$payload$reports,w$reports)
  expect_identical(snapshot$payload$tables$audit$label,w$tables$audit$label)
  expect_identical(unlist(attr(snapshot$payload$tables$audit,"python_index")),
    rownames(w$tables$audit))
  expect_identical(readLines(file.path(out,"reports","notes.txt"),encoding="UTF-8"),
    "Numeric \u03bc, source record")
  checks<-readLines(file.path(out,"SHA256SUMS"))
  expect_setequal(substring(checks,67L),setdiff(list.files(out,recursive=TRUE),"SHA256SUMS"))
  for(line in checks)
    expect_identical(substring(line,1L,64L),digest::digest(
      file.path(out,substring(line,67L)),algo="sha256",file=TRUE))
})

test_that("portable workflow export rejects invalid inputs without publishing",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  w<-.etr_python_bundle_fixture()
  root<-tempfile("etr_python_bundle_bad_")
  dir.create(root)
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  dest<-file.path(root,"output")
  write_bundle<-function(result,...)etr_export_workflow_bundle(
    result,dest,format="python_1_2",...)
  expect_error(write_bundle(.etr_bundle_test_workflow()),"measure_time")
  unsupported<-w
  class(unsupported)<-"etr_recurrence_workflow"
  expect_error(write_bundle(unsupported),"dense FPCA workflows")
  unsafe<-w
  unsafe$reports<-list(report="a",REPORT.txt="b")
  expect_error(write_bundle(unsafe),"filename collision")
  unsafe$reports<-list("NUL.txt"="a")
  expect_error(write_bundle(unsafe),"reserved filename")
  unsupported<-w
  unsupported$tables$unsupported<-data.frame(value=I(list(1L)))
  expect_error(write_bundle(unsupported),"unsupported metadata column type")
  expect_length(list.files(root,all.files=TRUE,no..=TRUE),0L)
  dir.create(dest)
  writeLines("original",file.path(dest,"retain"))
  expect_error(write_bundle(w),"already exists")
  expect_error(write_bundle(w,overwrite=TRUE),"overwrite")
  expect_identical(readLines(file.path(dest,"retain")),"original")
  if(.Platform$OS.type!="windows"){
    link<-file.path(root,"link")
    missing<-file.path(root,"missing")
    expect_true(file.symlink(missing,link))
    expect_error(etr_export_workflow_bundle(w,link,format="python_1_2"),"already exists")
    expect_identical(Sys.readlink(link),missing)
  }
})

test_that("frozen Python reads, reconstructs and re-exports a native FPCA workflow bundle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python workflow bundle replay is opt-in")
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  expect_identical(et_python_version(),"1.2.0")
  w<-.etr_python_bundle_fixture()
  root<-tempfile("etr_workflow_replay_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  native<-etr_export_workflow_bundle(w,file.path(root,"native"),format="python_1_2")
  oracle<-reticulate::py_run_string(paste(c(
    "def etr_replay_workflow_bundle(native, reexport, elapsed_seconds):",
    "    from dataclasses import fields",
    "    from hashlib import sha256",
    "    from pathlib import Path",
    "    import json",
    "    import pandas as pd",
    "    import eyetrajectoriespy as et",
    "    import eyetrajectoriespy.workflows as wf",
    "    native, reexport = Path(native), Path(reexport)",
    "    def load_json(path):",
    "        return json.loads(path.read_text(encoding='utf-8'))",
    "    def verify_bundle(path):",
    "        lines = (path / 'SHA256SUMS').read_text(encoding='utf-8').splitlines()",
    "        entries = dict(line.split('  ', 1)[::-1] for line in lines)",
    "        names = {item.relative_to(path).as_posix() for item in path.rglob('*') if item.is_file()}",
    "        assert set(entries) == names - {'SHA256SUMS'}",
    "        for name, value in entries.items():",
    "            assert sha256((path / name).read_bytes()).hexdigest() == value",
    "    def record_args(payload, cls):",
    "        data = dict(payload)",
    "        assert data.pop('__python_type__') == cls.__module__ + '.' + cls.__qualname__",
    "        assert set(data) == {field.name for field in fields(cls)}",
    "        return data",
    "    verify_bundle(native)",
    "    manifest = load_json(native / 'workflow.json')",
    "    assert manifest['format'] == wf.WORKFLOW_BUNDLE_FORMAT",
    "    assert manifest['schema_version'] == wf.WORKFLOW_BUNDLE_SCHEMA_VERSION",
    "    snap = et.load_portable_result(native / manifest['portable_result_directory'])",
    "    assert snap.result_type == manifest['result_type'] and not snap.nonportable_fields",
    "    assert not snap.package_version_match and snap.environment is None",
    "    args = record_args(snap.payload, wf.FPCAWorkflowResult)",
    "    cfg = record_args(args['config'], wf.FPCAWorkflowConfig)",
    "    cfg['preprocessing'] = wf.PreprocessingPlan(**record_args(cfg['preprocessing'], wf.PreprocessingPlan))",
    "    args['config'] = wf.FPCAWorkflowConfig(**cfg)",
    "    args['fit'] = et.FPCAResult(**record_args(args['fit'], et.FPCAResult))",
    "    args['steps'] = tuple(wf.WorkflowStepRecord(**record_args(step, wf.WorkflowStepRecord)) for step in args['steps'])",
    "    args['decisions'] = {key: wf.WorkflowDecisionRecord(**record_args(value, wf.WorkflowDecisionRecord)) for key, value in args['decisions'].items()}",
    "    result = wf.FPCAWorkflowResult(**args)",
    "    assert wf.workflow_config_to_dict(result.config) == load_json(native / 'config.json')",
    "    assert result.provenance == load_json(native / 'provenance.json')",
    "    assert list(result.tables['audit'].index) == ['run_a', 'run_b']",
    "    assert result.steps[0].function == 'etr_fit_fpca'",
    "    assert result.steps[0].elapsed_seconds == elapsed_seconds >= 0",
    "    assert pd.read_csv(native / 'steps.csv', float_precision='round_trip').loc[0, 'elapsed_seconds'] == elapsed_seconds",
    "    assert result.steps[0].warnings == ('fixture \\\"quoted\\\" warning', 'numeric \\u03bc')",
    "    assert wf.workflow_summary_frame(result).loc[0, 'warning_count'] == 2",
    "    wf.export_workflow_bundle(result, reexport)",
    "    verify_bundle(reexport)",
    "    for name in ('workflow.json', 'config.json', 'provenance.json'):",
    "        assert load_json(native / name) == load_json(reexport / name)",
    "    for name in manifest['reports']:",
    "        assert (native / 'reports' / name).read_text(encoding='utf-8') == (reexport / 'reports' / name).read_text(encoding='utf-8')",
    "    for name in ('steps.csv', 'decisions.csv', *('tables/' + t for t in manifest['tables'])):",
    "        pd.testing.assert_frame_equal(pd.read_csv(native / name, keep_default_na=False), pd.read_csv(reexport / name, keep_default_na=False), check_dtype=False, rtol=1e-13, atol=1e-15)",
    "    return et.reconstruct_fpca(result.fit)"
  ),collapse="\n"),local=TRUE,convert=FALSE)
  reconstruction<-reticulate::py_to_r(oracle$etr_replay_workflow_bundle(
    native,file.path(root,"python"),w$steps[[1L]]$elapsed_seconds))
  expect_equal(reconstruction,etr_reconstruct_fpca(w$fit)$values,tolerance=1e-12)
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: export_workflow_bundle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("export_workflow_bundle",.namespace="workflows"),"export_workflow_bundle")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
