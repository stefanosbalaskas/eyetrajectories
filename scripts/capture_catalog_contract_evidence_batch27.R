# Batch 27: independently reproducible AUTHOR-SIDE source-contract replay.
# This does NOT grant a third-party scientific certification.
# Run from repository root with pinned eyetrajectoriespy 1.2.0 installed.
if(!file.exists("DESCRIPTION") || !dir.exists("tests/testthat"))
  stop("Run from the eyetrajectories package root",call.=FALSE)
for(pkg in c("pkgload","reticulate","jsonlite","digest","testthat"))
  if(!requireNamespace(pkg,quietly=TRUE))
    stop("The source replay requires package: ",pkg,call.=FALSE)
pkgload::load_all(".",quiet=TRUE)
if(!identical(et_python_version(),"1.2.0"))
  stop("Frozen Python eyetrajectoriespy 1.2.0 is required",call.=FALSE)

# Every field of every row, including UTF-8, ordering and exact LaTeX, must agree.
compare_frame <- function(python_name, native_fn, expected_rows, expected_cols) {
  fn<-etpy_get_export(python_name)
  source<-as.data.frame(et_to_r(reticulate::py_call(fn)),
    stringsAsFactors=FALSE,check.names=FALSE)
  native<-native_fn()
  stopifnot(is.data.frame(native), nrow(source)==expected_rows,
    nrow(native)==expected_rows, identical(names(source),expected_cols),
    identical(names(native),expected_cols))
  for(col in expected_cols)
    stopifnot(identical(enc2utf8(as.character(source[[col]])),
      enc2utf8(as.character(native[[col]]))))
  # Both public zero-argument functions must reject extraneous arguments.
  r_reject<-inherits(try(native_fn("extraneous"),silent=TRUE),"try-error")
  p_reject<-inherits(try(reticulate::py_call(fn,"extraneous"),silent=TRUE),"try-error")
  stopifnot(r_reject,p_reject)
  invisible(TRUE)
}
compare_frame("mathematical_contract_frame",etr_mathematical_contract_frame,88L,
  c("contract_key","title","function","latex","site_anchor","scope"))
compare_frame("functional_recovery_metric_catalog_frame",
  etr_functional_recovery_metric_catalog_frame,27L,
  c("metric","quantity","direction","units","scope","description"))

# Review three more source analogues comprehensively, but do NOT close them:
# their Python tuple/dataclass vs native R S3/list runtime classes differ.
py_math<-reticulate::py_call(etpy_get_export("list_mathematical_contracts"))
native_math<-etr_list_mathematical_contracts()
stopifnot(as.integer(reticulate::py_len(py_math))==41L,length(native_math)==41L)
for(i in seq_len(41L)){
  py<-py_math[[as.integer(i-1L)]];nr<-native_math[[i]]
  for(field in c("key","title","public_api","equations","site_anchor","scope")){
    pv<-enc2utf8(as.character(et_to_r(reticulate::py_get_attr(py,field))))
    rv<-enc2utf8(as.character(nr[[field]]))
    stopifnot(identical(pv,rv))
  }
}
py_get<-etpy_get_export("get_mathematical_contract")
frame<-etr_mathematical_contract_frame()
for(key in unique(c(frame$contract_key,frame[["function"]]))){
  py<-reticulate::py_call(py_get,name=key)
  nr<-etr_get_mathematical_contract(key)
  for(field in c("key","title","public_api","equations","site_anchor","scope"))
    stopifnot(identical(enc2utf8(as.character(et_to_r(reticulate::py_get_attr(py,field)))),
      enc2utf8(as.character(nr[[field]]))))
}
for(invalid in list("__not_a_registered_contract__",1L)){
  native_failed<-inherits(try(etr_get_mathematical_contract(invalid),silent=TRUE),"try-error")
  source_failed<-inherits(try(reticulate::py_call(py_get,name=invalid),silent=TRUE),"try-error")
  stopifnot(native_failed,source_failed)
}
py_recovery<-reticulate::py_call(etpy_get_export("functional_recovery_metric_catalog"))
native_recovery<-etr_functional_recovery_metric_catalog()
stopifnot(as.integer(reticulate::py_len(py_recovery))==27L,length(native_recovery)==27L)
for(i in seq_len(27L)){
  py<-py_recovery[[as.integer(i-1L)]];nr<-native_recovery[[i]]
  for(field in c("name","quantity","direction","units","scope","description"))
    stopifnot(identical(enc2utf8(as.character(et_to_r(reticulate::py_get_attr(py,field)))),
      enc2utf8(as.character(nr[[field]]))))
}

# The auditor validates SHA256 against the actual current checkout, not
# against a hard-coded Windows line-ending assumption.
paths<-c("R/native-math-contracts-diagnostics.R",
 "R/native-functional-rqa-recovery.R",
 "inst/extdata/native_mathematical_contract_frame_py120.csv",
 "inst/extdata/native_recovery_metric_catalog_py120.csv",
 "scripts/capture_catalog_contract_evidence_batch27.R")
stopifnot(all(file.exists(paths)))
sha<-vapply(paths,function(p)digest::digest(p,algo="sha256",file=TRUE,serialize=FALSE),
  character(1L))
source_sha<-"c1cd95ad718327550f7e55393ff38582872f7a94"
evidence<-list(
  protocol="developer_catalog_contract_closure_v1",
  python_version="1.2.0",
  frozen_python_commit=source_sha,
  function_results=list(
    list(python_name="mathematical_contract_frame",rows=88L,
      validated_columns=c("contract_key","title","function","latex","site_anchor","scope"),
      complete_zero_argument_domain=TRUE,full_field_equality=TRUE,
      excess_argument_rejected_by_both=TRUE),
    list(python_name="functional_recovery_metric_catalog_frame",rows=27L,
      validated_columns=c("metric","quantity","direction","units","scope","description"),
      complete_zero_argument_domain=TRUE,full_field_equality=TRUE,
      excess_argument_rejected_by_both=TRUE)),
  additional_semantic_comparisons=c("list_mathematical_contracts",
    "get_mathematical_contract","functional_recovery_metric_catalog"),
  python_vs_R_runtime_class_equivalence_claimed=FALSE,
  independent_certification_granted=FALSE,
  local_files_sha256=as.list(sha))
out<-"artifacts/native_full_contract_evidence/catalog_batch27_developer_evidence.json"
dir.create(dirname(out),recursive=TRUE,showWarnings=FALSE)
jsonlite::write_json(evidence,out,pretty=TRUE,auto_unbox=TRUE,null="null")
cat("BATCH27_CATALOG_SOURCE_REPLAY_PASS=5;FRAME_FULL_DOMAINS=2;INDEPENDENT=0\n")
cat("EVIDENCE_FILE=",out,"\n",sep="")
