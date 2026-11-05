# Four frozen-Python 1.2 pilot contracts: reviewer-facing boundary matrix.
# Run from the R package root AFTER successful exact-head source capture:
# source("scripts/build_four_pilot_review_matrix.R")
# etr_build_four_pilot_review_matrix()
#
# This is a structured hand-off, NOT independent oracle replay or reviewer
# approval. Scientific disagreements are never marked as resolved by default.

etr_build_four_pilot_review_matrix<-function(root=".",packet_dir=NULL){
  check<-function(ok,msg){if(!isTRUE(ok))stop(msg,call.=FALSE)}
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  check(file.exists(file.path(root,"DESCRIPTION")),
    "Run from the eyetrajectories package root")
  packet_root<-file.path(root,"artifacts","native_independent_review_packets")
  if(is.null(packet_dir)){
    dirs<-if(dir.exists(packet_root))
      list.dirs(packet_root,recursive=FALSE,full.names=TRUE)
    else character()
    dirs<-dirs[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(dirs))]
    check(length(dirs)>0L,"No captured independent-review packet found")
    packet_dir<-sort(dirs,decreasing=TRUE)[[1L]]
  }
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  status_file<-file.path(packet_dir,"evidence_bundle_status.csv")
  pilot_file<-file.path(packet_dir,
    "four_numerical_pilots_external_review_priority.csv")
  check(all(file.exists(c(status_file,pilot_file))),
    "Four-pilot independent review packet inputs are missing")
  status<-utils::read.csv(status_file,stringsAsFactors=FALSE,
    check.names=FALSE)
  pilots<-utils::read.csv(pilot_file,stringsAsFactors=FALSE,
    check.names=FALSE)
  check(nrow(status)==1L&&nrow(pilots)==4L&&
    all(c("recorded_r_git_head","checkout_matches_evidence",
      "source_file_manifest_matches_checkout","native_suite_pass",
      "pinned_python_suite_pass","independent_review_approved",
      "full_source_contract_certified")%in%names(status)),
    "Invalid exact-head evidence status schema")
  check(all(status$checkout_matches_evidence,
      status$source_file_manifest_matches_checkout,
      status$native_suite_pass,status$pinned_python_suite_pass)&&
    !any(status$independent_review_approved,
      status$full_source_contract_certified),
    "Cannot prepare an unsigned review matrix from failed or approved evidence")
  git<-Sys.which("git")
  check(nzchar(git),"Git must be available to confirm the exact source HEAD")
  current<-suppressWarnings(system2(git,
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  check(length(current)==1L&&
    identical(as.character(current),status$recorded_r_git_head),
    "Current checkout differs from captured qualification HEAD; recapture first")
  expected<-c("alr_transform","inverse_alr",
    "score_distance_matrix","functional_trapezoid_weights")
  check(setequal(pilots$python_name,expected)&&
    !anyDuplicated(pilots$python_name),
    "Pilot priority packet does not contain the four frozen pilot exports")
  required<-c("native_r_candidate","frozen_python_source",
    "pinned_python_commit","source_gap_kind",
    "documented_boundary_difference","required_full_domain_resolution",
    "original_numeric_fixture_pass",
    "full_accepted_input_domain_approved",
    "complete_error_semantics_approved","scientific_scope_approved",
    "independent_reviewer_approved")
  check(all(required%in%names(pilots)),
    "Pilot boundary and reviewer-gate columns are incomplete")
  check(all(pilots$pinned_python_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94")&&
    all(pilots$original_numeric_fixture_pass)&&
    all(!pilots$full_accepted_input_domain_approved)&&
    all(!pilots$complete_error_semantics_approved)&&
    all(!pilots$scientific_scope_approved)&&
    all(!pilots$independent_reviewer_approved),
    "Pilot scientific gaps must remain explicitly unsigned")

  # Each case is a REVIEW TARGET documented by the checked-in source
  # contracts. "shared_scientific_subset" does NOT mean independently
  # verified parity. Differences remain unresolved until adjudicated.
  cases<-data.frame(
    python_name=rep(expected,each=4L),
    case_id=rep(c("finite_scientific_fixture",
      "broader_accepted_containers","exception_or_extreme_boundary",
      "scientific_and_schema_scope"),times=4L),
    reviewer_relation=c(
      "shared_scientific_subset","shared_scientific_subset",
      "documented_source_difference","requires_independent_domain_replay",
      "shared_scientific_subset","shared_scientific_subset",
      "documented_source_difference","requires_independent_domain_replay",
      "shared_scientific_subset","requires_independent_domain_replay",
      "documented_source_difference","requires_independent_domain_replay",
      "shared_scientific_subset","shared_scientific_subset",
      "documented_source_difference","requires_independent_domain_replay"),
    concrete_probe=c(
      "Finite 3D simplex, all reference indices, fixed positive epsilon",
      "Finite numeric-string/Boolean simplex and clipped exact zeros",
      "NaN epsilon accepted by Python comparison, rejected by native R",
      "Additional NumPy dtype, nested coercion, shape and exception matrix",
      "Finite 3D logratio array, varied reference and simplex dimensions",
      "Finite numeric-string and Boolean 3D logratio arrays",
      "Very large finite logratio: Python exp overflow, native R error",
      "Source nonfinite output and R input-error policy require adjudication",
      "Finite 1- and 2-component score distances on fixed FPCA scores",
      "Source duck-typed objects versus native result requirements",
      "sklearn score overflow and validation/error domain not source-matched",
      "Score dtype, empty shape, nonfinite, exception and return schema",
      "Finite strictly increasing time grids, normalized and raw weights",
      "Numeric/character/logical scalar normalization truthiness",
      "Python final +Inf grid can yield Inf, native rejects nonfinite time",
      "Python arbitrary object truthiness and mixed container acceptance"),
    existing_developer_fixture=c(
      "tests/testthat/test-native-certification.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-source-contract-gaps.R",
      "tests/testthat/test-native-certification.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-source-contract-gaps.R",
      "tests/testthat/test-native-certification.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-source-contract-gaps.R",
      "tests/testthat/test-native-source-contract-alignment.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-pilot-source-adversarial.R",
      "tests/testthat/test-native-source-contract-gaps.R"),
    stringsAsFactors=FALSE)
  check(nrow(cases)==16L&&
    identical(unique(cases$python_name),expected)&&
    all(file.exists(file.path(root,cases$existing_developer_fixture))),
    "Reviewer matrix cases or developer fixture paths are inconsistent")
  ix<-match(cases$python_name,pilots$python_name)
  cases$native_r_candidate<-pilots$native_r_candidate[ix]
  cases$python_source_path<-pilots$frozen_python_source[ix]
  cases$frozen_python_commit<-pilots$pinned_python_commit[ix]
  cases$native_r_commit<-status$recorded_r_git_head
  cases$recorded_source_gap_kind<-pilots$source_gap_kind[ix]
  cases$recorded_boundary_difference<-
    pilots$documented_boundary_difference[ix]
  cases$required_full_domain_resolution<-
    pilots$required_full_domain_resolution[ix]
  cases$aggregate_suite_pass_only<-TRUE
  cases$independently_replayed_case<-FALSE
  cases$input_domain_adjudicated<-FALSE
  cases$error_and_warning_semantics_adjudicated<-FALSE
  cases$return_shape_dtype_schema_adjudicated<-FALSE
  cases$scientific_estimand_adjudicated<-FALSE
  cases$reviewer_decision<-rep("PENDING_INDEPENDENT_REVIEW",
    nrow(cases))
  cases$reviewer_evidence_uri<-rep("",nrow(cases))
  cases$reviewer_identity<-rep("",nrow(cases))
  cases$reviewer_signed_commit<-rep("",nrow(cases))
  cases$fully_certified<-FALSE
  check(!any(cases$independently_replayed_case|
      cases$fully_certified)&&
    all(nzchar(cases$recorded_boundary_difference)),
    "Author-prepared matrix must retain open scientific gaps")

  csv<-file.path(packet_dir,"four_pilot_boundary_review_matrix.csv")
  utils::write.csv(cases,csv,row.names=FALSE,na="")
  reread<-utils::read.csv(csv,stringsAsFactors=FALSE,
    check.names=FALSE)
  check(nrow(reread)==16L&&
    !any(reread$fully_certified)&&
    !any(reread$independently_replayed_case),
    "Reviewer boundary matrix failed round-trip or approval gates")
  manual<-file.path(packet_dir,
    "FOUR_PILOT_INDEPENDENT_REVIEW.md")
  writeLines(c(
    "# Four numerical pilots — independent contract-review worksheet",
    "",
    paste0("Evidence bundle: `",status$evidence_bundle,"`"),
    paste0("Native R commit: `",status$recorded_r_git_head,"`"),
    "Frozen Python source commit: `c1cd95ad718327550f7e55393ff38582872f7a94`",
    "",
    "**Status: 16 proposed domain-review cases; 0 independent case replays; 0 approved contracts.**",
    "Developer test-suite PASS and 111/111 literal export references do not independently certify inputs, schemas, errors or estimands.",
    "",
    "## How to adjudicate",
    "",
    "1. Independently check out the frozen Python source and recorded native R commit.",
    "2. Independently execute each listed probe, documenting exact inputs, outputs, shape/dtype, warnings and exceptions.",
    "3. For each known source difference, explicitly choose source-compatible implementation, documented restricted contract, or non-equivalent analogue.",
    "4. Record reviewer identity, affiliations, independent evidence, scope limitations, version pins, and a signed review decision.",
    "5. Do NOT mark full Python-domain parity while known source-boundary differences remain unresolved.",
    "",
    "The file `four_pilot_boundary_review_matrix.csv` is a reviewer worklist, NOT a certificate."
  ),manual,useBytes=TRUE)
  message("Four-pilot independent-review matrix: ",csv)
  message("Four-pilot reviewer worksheet: ",manual)
  message("16 review cases queued; 0 independently replayed; 0 certified.")
  invisible(list(matrix=cases,csv=csv,worksheet=manual))
}
