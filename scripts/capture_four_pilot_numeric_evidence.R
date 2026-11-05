# First-party, paired R/Python numerical fixture replay for the four
# frozen Python 1.2 certification pilots. NOT independent scientific review.
# Run after source("scripts/capture_native_source_qualification_evidence.R"):
# source("scripts/capture_four_pilot_numeric_evidence.R")
# etr_capture_four_pilot_numeric_evidence()
#
# Only the shared finite numerical domain is tested here; known differences
# (NaN epsilon, exp overflow, sklearn error semantics, infinite grids) remain
# unresolved in the authoritative source-gap register.

etr_capture_four_pilot_numeric_evidence<-function(root=".",packet_dir=NULL){
  check<-function(ok,msg){if(!isTRUE(ok))stop(msg,call.=FALSE)}
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  check(file.exists(file.path(root,"DESCRIPTION")),
    "Run numerical evidence capture from the package root")
  root_packets<-file.path(root,"artifacts","native_independent_review_packets")
  if(is.null(packet_dir)){
    dirs<-if(dir.exists(root_packets))
      list.dirs(root_packets,recursive=FALSE,full.names=TRUE)
    else character()
    dirs<-dirs[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(dirs))]
    check(length(dirs)>0L,"No completed reviewer packet")
    packet_dir<-sort(dirs,decreasing=TRUE)[[1L]]
  }
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  status_path<-file.path(packet_dir,"evidence_bundle_status.csv")
  matrix_path<-file.path(packet_dir,"four_pilot_boundary_review_matrix.csv")
  check(all(file.exists(c(status_path,matrix_path))),
    "Independent packet or four-pilot boundary matrix absent")
  status<-utils::read.csv(status_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  review<-utils::read.csv(matrix_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  check(nrow(status)==1L&&nrow(review)==16L&&
    all(c("recorded_r_git_head","checkout_matches_evidence",
      "source_file_manifest_matches_checkout","native_suite_pass",
      "pinned_python_suite_pass","full_source_contract_certified",
      "independent_review_approved")%in%names(status)),
    "Incomplete exact-head qualification status")
  check(isTRUE(status$checkout_matches_evidence)&&
    isTRUE(status$source_file_manifest_matches_checkout)&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass)&&
    identical(status$full_source_contract_certified,FALSE)&&
    identical(status$independent_review_approved,FALSE),
    "Only passing and unsigned source packets may be replayed")
  git<-Sys.which("git")
  check(nzchar(git),"git required for exact-head source integrity")
  head<-suppressWarnings(system2(git,
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  check(length(head)==1L&&identical(head,
    status$recorded_r_git_head),
    "Current R HEAD differs from reviewed source evidence")
  check(all(c("python_name","fully_certified",
    "independently_replayed_case")%in%names(review))&&
    !any(review$fully_certified)&&
    !any(review$independently_replayed_case),
    "Do not replace unsigned independent case decisions with developer results")
  check(requireNamespace("reticulate",quietly=TRUE)&&
    requireNamespace("pkgload",quietly=TRUE),
    "Numerical replay requires reticulate and pkgload")
  pkgload::load_all(root,quiet=TRUE)
  check(identical(et_python_version(),"1.2.0"),
    "Frozen Python 1.2.0 runtime is required")

  results<-list()
  record<-function(name,id,r,py,tol=1e-11){
    native<-as.array(r)
    published<-as.array(et_to_r(py))
    same_shape<-identical(dim(native),dim(published))
    diff<-if(same_shape&&length(native)==length(published)&&
        all(is.finite(native))&&all(is.finite(published)))
      max(abs(as.numeric(native)-as.numeric(published)))
    else Inf
    passed<-isTRUE(same_shape)&&is.finite(diff)&&diff<=tol
    results[[length(results)+1L]]<<-data.frame(
      python_name=name,case_id=id,source_shape=paste(dim(published),
        collapse="x"),native_shape=paste(dim(native),collapse="x"),
      max_absolute_difference=diff,tolerance=tol,
      shapes_equal=same_shape,developer_numeric_fixture_pass=passed,
      recorded_r_git_head=status$recorded_r_git_head,
      frozen_python_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
      independent_reviewer_approved=FALSE,
      independently_replayed_case=FALSE,
      fully_certified=FALSE,
      stringsAsFactors=FALSE)
    invisible(passed)
  }
  # Two ALR references on the same strictly positive simplex; Python's
  # np.asarray conversion and native numeric geometry are compared exactly.
  values<-array(0,c(2L,3L,3L))
  for(i in 1:2)for(j in 1:3){
    aa<-.12+.016*i+.01*j;bb<-.28+.014*j+.008*i
    values[i,j,]<-c(aa,bb,1-aa-bb)
  }
  for(ref in c(0L,2L)){
    native<-etr_alr_transform(values,
      reference_dimension=ref,epsilon=1e-6)
    published<-reticulate::py_call(
      etpy_get_export("alr_transform"),
      values=reticulate::r_to_py(values),
      reference_dimension=as.integer(ref),epsilon=1e-6)
    record("alr_transform",paste0("finite_reference_",ref),
      native,published)
  }
  # Two finite logratio references; deliberately exclude overflow here.
  z<-array(seq(-0.8,0.9,length.out=12L),c(2L,3L,2L))
  for(ref in c(0L,2L)){
    native<-etr_inverse_alr(z,reference_dimension=ref,
      n_dimensions=3L)
    published<-reticulate::py_call(
      etpy_get_export("inverse_alr"),
      transformed=reticulate::r_to_py(z),
      reference_dimension=as.integer(ref),
      n_dimensions=as.integer(3L))
    record("inverse_alr",paste0("finite_reference_",ref),
      native,published)
  }
  # Direct FPCA-score container law, without fitting stochastic components.
  score<-matrix(c(0,1,2,1.25,-0.75,1.5,2.5,-1.5),
    nrow=4L,ncol=2L)
  pyp<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(score),n_components=as.integer(2L))
  for(k in c(1L,2L)){
    native<-etr_score_distance_matrix(list(scores=score,
      n_components=2L),n_components=k)
    published<-reticulate::py_call(
      etpy_get_export("score_distance_matrix"),
      fpca=pyp,n_components=as.integer(k))
    record("score_distance_matrix",paste0("score_components_",k),
      native,published)
  }
  # Four scalar truthiness cases on a finite, irregular grid.
  tt<-c(0,.25,.9,1.8,3)
  flags<-list(FALSE,TRUE,"yes","")
  ids<-c("unnormalized","normalized","string_truthy",
    "empty_string_false")
  for(i in seq_along(flags)){
    native<-etr_trapezoid_weights(tt,normalize=flags[[i]])
    published<-reticulate::py_call(
      etpy_get_export("functional_trapezoid_weights"),
      time=reticulate::r_to_py(tt),normalize=flags[[i]])
    record("functional_trapezoid_weights",ids[[i]],
      native,published)
  }
  rows<-do.call(rbind,results)
  check(nrow(rows)==10L&&
    setequal(unique(rows$python_name),c("alr_transform",
      "inverse_alr","score_distance_matrix",
      "functional_trapezoid_weights")),
    "Pilot numerical fixture inventory incomplete")
  out<-file.path(packet_dir,
    "four_pilot_developer_paired_numeric_replay.csv")
  utils::write.csv(rows,out,row.names=FALSE,na="")
  check(all(rows$developer_numeric_fixture_pass),
    paste("Python/native finite numerical mismatches:",
      paste(rows$case_id[!rows$developer_numeric_fixture_pass],
        collapse=", ")))
  check(!any(rows$independent_reviewer_approved|
      rows$independently_replayed_case|rows$fully_certified),
    "Independent scientific approvals cannot be produced by this script")
  message("Developer paired Python/native finite numerical evidence: ",out)
  message(nrow(rows)," source comparisons PASS; independent approvals remain 0.")
  invisible(list(evidence=rows,path=out))
}
