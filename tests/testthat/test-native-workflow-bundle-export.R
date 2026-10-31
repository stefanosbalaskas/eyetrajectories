# Native R workflow bundle source alternative, not Python JSON+NPZ parity.
.etr_bundle_test_workflow<-function(){
  time<-seq(0,1,length.out=13L)
  y<-array(0,c(8L,length(time),1L))
  for(i in 1:8)y[i,,1L]<-sin(pi*time)+i*.07*cos(2*pi*time)+
    (i%%3)*.021*time
  tr<-etr_trajectory_set(time,y,
    sprintf("c%02d",1:8),"x",time_unit="s")
  etr_run_fpca_workflow(tr,config=list(n_components=1L))
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
