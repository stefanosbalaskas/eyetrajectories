# First-party boundary observations against frozen Python 1.2.
# This is an author/developer source inspection, NOT an independent
# replay or full-contract certification. Four known source-domain gaps
# are recorded without conflating them with 10 green finite fixtures.
#
# Called after capture_four_pilot_numeric_evidence.R on the exact HEAD.

etr_capture_four_pilot_boundary_evidence<-function(root=".",packet_dir=NULL){
  check<-function(ok,msg){if(!isTRUE(ok))stop(msg,call.=FALSE)}
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  packet_root<-file.path(root,"artifacts","native_independent_review_packets")
  if(is.null(packet_dir)){
    dirs<-if(dir.exists(packet_root))
      list.dirs(packet_root,recursive=FALSE,full.names=TRUE)
    else character()
    dirs<-dirs[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(dirs))]
    check(length(dirs)>0L,"No captured independent-review packet")
    packet_dir<-sort(dirs,decreasing=TRUE)[[1L]]
  }
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  status_path<-file.path(packet_dir,"evidence_bundle_status.csv")
  finite_path<-file.path(packet_dir,
    "four_pilot_developer_paired_numeric_replay.csv")
  review_path<-file.path(packet_dir,
    "four_pilot_boundary_review_matrix.csv")
  check(all(file.exists(c(status_path,finite_path,review_path))),
    "Boundary replay requires completed review and paired numeric evidence")
  status<-utils::read.csv(status_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  finite<-utils::read.csv(finite_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  review<-utils::read.csv(review_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  check(nrow(status)==1L&&nrow(finite)==10L&&nrow(review)==16L&&
    all(c("recorded_r_git_head","checkout_matches_evidence",
      "source_file_manifest_matches_checkout","native_suite_pass",
      "pinned_python_suite_pass","independent_review_approved",
      "full_source_contract_certified")%in%names(status))&&
    all(c("developer_numeric_fixture_pass","independently_replayed_case",
      "fully_certified")%in%names(finite)),
    "Incomplete source qualification schema")
  check(isTRUE(status$checkout_matches_evidence)&&
    isTRUE(status$source_file_manifest_matches_checkout)&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass)&&
    !any(status$independent_review_approved,
      status$full_source_contract_certified)&&
    all(finite$developer_numeric_fixture_pass)&&
    !any(finite$independently_replayed_case|finite$fully_certified)&&
    !any(review$fully_certified|review$independently_replayed_case),
    "Source review evidence cannot be failed, unsigned-mismatched or approved")
  git<-Sys.which("git")
  check(nzchar(git),"git is required for exact-head boundary replay")
  head<-suppressWarnings(system2(git,
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  check(length(head)==1L&&
    identical(as.character(head),status$recorded_r_git_head),
    "Boundary replay checkout differs from pinned source evidence")
  check(requireNamespace("pkgload",quietly=TRUE)&&
    requireNamespace("reticulate",quietly=TRUE),
    "pkgload and reticulate are required for pinned source replay")
  pkgload::load_all(root,quiet=TRUE)
  check(identical(et_python_version(),"1.2.0"),
    "Boundary replay requires installed frozen Python 1.2.0")

  observe<-function(f){
    tryCatch(list(ok=TRUE,value=f(),error=""),
      error=function(e)list(ok=FALSE,value=NULL,
        error=conditionMessage(e)))
  }
  class_result<-function(x){
    if(!x$ok)return("raises")
    y<-as.numeric(et_to_r(x$value))
    if(length(y)>0L&&all(is.nan(y)))return("returns_all_nan")
    if(any(!is.finite(y)))return("returns_nonfinite")
    "returns_finite"
  }
  # Expected source/native behavior is grounded in pinned source tests:
  # this is an explicit divergence ledger, NOT a parity PASS ledger.
  rows<-list()
  record<-function(name,case,source,known_native,
      expected_source,expected_native,relation){
    source_kind<-class_result(source)
    native_kind<-class_result(known_native)
    rows[[length(rows)+1L]]<<-data.frame(
      python_name=name,case_id=case,
      python_observed_behavior=source_kind,
      native_r_observed_behavior=native_kind,
      expected_python_behavior=expected_source,
      expected_native_r_behavior=expected_native,
      source_exception_if_any=source$error,
      native_exception_if_any=known_native$error,
      observed_behavior_as_expected=
        identical(source_kind,expected_source)&&
        identical(native_kind,expected_native),
      relation=relation,
      source_domain_equivalence_established=FALSE,
      independent_reviewer_approved=FALSE,
      independently_replayed_case=FALSE,
      fully_certified=FALSE,
      recorded_r_git_head=status$recorded_r_git_head,
      frozen_python_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
      stringsAsFactors=FALSE)
    invisible(NULL)
  }
  # NumPy comparison (NaN <= 0) is FALSE: epsilon is propagated.
  simplex<-array(rep(c(.2,.35,.45),4L),c(2L,2L,3L))
  src_alr<-observe(function()reticulate::py_call(
    etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(simplex),epsilon=NaN))
  r_alr<-observe(function()etr_alr_transform(simplex,epsilon=NaN))
  record("alr_transform","NaN_epsilon",src_alr,r_alr,
    "returns_all_nan","raises","documented_source_difference")

  # Source exp(1000) gives Inf; normalization contains NaN. Native fails.
  logits<-array(c(1000,-1),c(1L,1L,2L))
  np<-reticulate::import("numpy",convert=FALSE)
  src_inverse<-observe(function()
    with(np$errstate(over="ignore",invalid="ignore"),
      reticulate::py_call(etpy_get_export("inverse_alr"),
        transformed=reticulate::r_to_py(logits),
        reference_dimension=as.integer(0L),
        n_dimensions=as.integer(3L))))
  r_inverse<-observe(function()
    etr_inverse_alr(logits,reference_dimension=0L,n_dimensions=3L))
  record("inverse_alr","finite_logit_exp_overflow",src_inverse,
    r_inverse,"returns_nonfinite","raises",
    "documented_source_difference")

  # Python np.diff(c(0,1,Inf)) remains positive; R requires finite time.
  inf_time<-c(0,1,Inf)
  src_weights<-observe(function()reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(inf_time)))
  r_weights<-observe(function()etr_trapezoid_weights(inf_time))
  record("functional_trapezoid_weights","positive_infinite_endpoint",
    src_weights,r_weights,"returns_nonfinite","raises",
    "documented_source_difference")

  # sklearn and R both reject nonfinite score inputs. Error CLASS/TEXT,
  # breadth of accepted input objects and dtype semantics are not equal.
  score<-matrix(c(0,1,NaN,2,3,4),nrow=3L,ncol=2L)
  py_fit<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(score),
    n_components=as.integer(2L))
  src_distance<-observe(function()reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=py_fit))
  r_distance<-observe(function()etr_score_distance_matrix(
    list(scores=score,n_components=2L)))
  record("score_distance_matrix","nonfinite_score_error",
    src_distance,r_distance,"raises","raises",
    "both_reject_error_schema_unreviewed")

  out<-do.call(rbind,rows)
  check(nrow(out)==4L&&all(out$observed_behavior_as_expected)&&
    !any(out$source_domain_equivalence_established|
      out$independent_reviewer_approved|
      out$independently_replayed_case|out$fully_certified),
    "Frozen source boundary behavior changed or review flags were promoted")
  check(sum(out$relation=="documented_source_difference")==3L&&
    sum(out$relation=="both_reject_error_schema_unreviewed")==1L,
    "Expected source-boundary classification not preserved")
  path<-file.path(packet_dir,
    "four_pilot_developer_source_boundary_observations.csv")
  utils::write.csv(out,path,row.names=FALSE,na="")
  reread<-utils::read.csv(path,stringsAsFactors=FALSE,
    check.names=FALSE)
  check(nrow(reread)==4L&&
    all(reread$observed_behavior_as_expected)&&
    !any(reread$fully_certified),
    "Boundary CSV round-trip lost findings or approval gates")
  message("Developer frozen-source boundary observations: ",path)
  message("3 documented source differences and 1 shared rejection; ",
    "none establish full-domain parity or independent certification.")
  invisible(list(evidence=out,path=path))
}
