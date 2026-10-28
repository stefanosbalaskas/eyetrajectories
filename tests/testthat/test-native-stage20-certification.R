# Stage 20: certificate-first, no promotion based only on old tests.
# Source pins: published eyetrajectoriespy==1.2.0, Git SHA in frozen census.
# The source-of-record candidate manifest remains unapproved until independent
# numeric, schema, scope and review evidence is committed and reproduced.

.etr20_simplex_fixture <- function(){
  a<-array(0,c(3L,5L,3L))
  for(i in 1:3)for(j in 1:5)
    a[i,j,]<-c(.11+.015*i,.27+.013*j,
      .62-.015*i-.013*j)
  a
}

test_that("Stage 20 certification census never treats candidate as complete",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),183L)
  expect_equal(sum(z$native_implementation_started),158L)
  expect_equal(sum(z$is_python_function & !z$named_native_candidate),197L)
  expect_equal(sum(z$native_implementation_stage==20L,na.rm=TRUE),1L)
  expect_equal(sum(z$contract_certification_candidate),3L)
  expect_identical(sort(z$python_name[z$contract_certification_candidate]),
    sort(c("alr_transform","inverse_alr","score_distance_matrix")))
  expect_equal(sum(z$contract_numerical_fixture_pass),3L)
  expect_true(all(z$contract_numerical_fixture_pass[
    z$contract_certification_candidate]))
  # Source-oracle fixture PASS is not the same as complete-domain
  # independent numeric-equivalence approval.
  expect_true(all(!z$independent_numeric_parity_pass))
  expect_true(all(!z$behavioral_schema_parity_pass))
  expect_true(all(!z$scientific_inference_qualified))
  expect_true(all(!z$independent_contract_review_pass))
  expect_true(all(!z$one_to_one_native_contract_complete))
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_identical(unique(z$contract_certification_evidence_state[
    z$contract_certification_candidate]),
    "numeric_fixtures_passed_full_contract_review_pending")
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
    "NOT complete")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("Stage 20 ALR/inverse contract candidate exercises dimensions and bounds",{
  v<-.etr20_simplex_fixture()
  for(ref in c(-1L,0L,1L,2L,5L)){
    a<-etr_alr_transform(v,reference_dimension=ref)
    expect_identical(dim(a),c(3L,5L,2L))
    back<-etr_inverse_alr(a,reference_dimension=ref,n_dimensions=3L)
    expect_equal(back,v,tolerance=1e-12)
    expect_equal(apply(back,c(1L,2L),sum),
      matrix(1,3L,5L),tolerance=1e-12)
  }
  # Python 1.2 permits a one-part probability simplex (zero ALR
  # components); this is a valid domain edge, not an invalid-input test.
  singleton<-array(1,c(3L,5L,1L))
  no_ratios<-etr_alr_transform(singleton,reference_dimension=-1L)
  expect_identical(dim(no_ratios),c(3L,5L,0L))
  expect_equal(etr_inverse_alr(no_ratios,0L,1L),
    singleton,tolerance=0)
  zero<-v;zero[1L,1L,]<-c(0,.4,.6)
  a<-etr_alr_transform(zero,reference_dimension=0L,epsilon=1e-5)
  expect_true(all(is.finite(a)))
  back<-etr_inverse_alr(a,0L,3L)
  expect_true(all(back>0))
  expect_equal(sum(back[1L,1L,]),1,tolerance=1e-12)
  expect_error(etr_alr_transform(v,epsilon=0),"epsilon")
  expect_error(etr_inverse_alr(a,0L,4L),"dimensions")
  expect_error(etr_inverse_alr(array(NA_real_,c(3,5,2)),0L,3L),
    "nonfinite")
})

test_that("Stage 20 score-distance candidate preserves finite symmetric Euclidean geometry",{
  time<-seq(0,2,length.out=15L)
  v<-array(0,c(6L,length(time),2L))
  for(i in 1:6){
    v[i,,1L]<-sin(time*2+i*.21)+.07*i*time
    v[i,,2L]<-cos(time*1.3+i*.14)-.03*i*time
  }
  x<-etr_trajectory_set(time,v,sprintf("c%02d",1:6),c("x","y"))
  fit<-etr_fit_mfpca(x,n_components=2L)
  for(k in c(1L,2L)){
    d<-etr_score_distance_matrix(fit,n_components=k)
    expect_equal(dim(d),c(6L,6L))
    expect_equal(diag(d),rep(0,6))
    expect_equal(d,t(d),tolerance=1e-13)
    expect_true(all(d>=0))
    expect_equal(d[1L,2L],
      sqrt(sum((fit$scores[1L,seq_len(k)]-
        fit$scores[2L,seq_len(k)])^2)),tolerance=1e-12)
  }
  expect_error(etr_score_distance_matrix(fit,n_components=0L),
    "range")
  expect_error(etr_score_distance_matrix(fit,n_components=3L),
    "range")
})

test_that("Stage 20 native IAAFT surrogates are permutation-preserving and seed scoped",{
  signal<-sin(seq(0,6*pi,length.out=64L))+
    .17*cos(seq(0,10*pi,length.out=64L))
  set.seed(201);before<-.Random.seed
  a<-.etr20_iaaft_one(signal,20L,1)
  expect_equal(sort(a$values),sort(signal),tolerance=0)
  expect_true(a$iterations>=2L && a$iterations<=20L)
  expect_true(is.finite(a$spectral_error))
  set.seed(201);before<-.Random.seed
  x<-etr_trajectory_set(seq(0,1,length.out=64L),
    array(signal,c(1L,64L,1L)),"test","x",time_unit="s")
  result<-etr_surrogate_nonlinearity_test(x,"test","x",
    statistic="largest_lyapunov",embedding_dimension=2L,delay=2L,
    theiler_window=3L,max_horizon=7L,fit_start=1L,fit_end=4L,
    n_surrogates=3L,random_state=23L,
    max_iterations=20L,tolerance=1)
  expect_identical(before,.Random.seed)
  expect_s3_class(result,"etr_surrogate_nonlinearity")
  expect_equal(length(result$surrogate_statistics),3L)
  expect_true(all(is.finite(result$surrogate_statistics)))
  expect_equal(result$p_value,
    (1+sum(result$surrogate_statistics>=result$observed_statistic))/4,
    tolerance=0)
  again<-etr_surrogate_nonlinearity_test(x,"test","x",
    "largest_lyapunov",2L,2L,3L,7L,1L,4L,
    n_surrogates=3L,random_state=23L,max_iterations=20L,tolerance=1)
  expect_identical(result$surrogate_statistics,again$surrogate_statistics)
  expect_false(result$provenance$source_python_equivalent_stochastic_draws)
  expect_error(etr_surrogate_nonlinearity_test(x,"test","x",
    "wrong",2L,2L,3L,7L,1L,4L),"largest_lyapunov")
})

test_that("Stage 20 exact published Python 1.2 ALR and distance contract oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 20 508-contract certification pilot Python numerical/schema oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  v<-.etr20_simplex_fixture()
  for(ref in c(-1L,0L,1L,2L,5L)){
    ra<-etr_alr_transform(v,reference_dimension=ref)
    py<-reticulate::py_call(etpy_get_export("alr_transform"),
      values=reticulate::r_to_py(v),reference_dimension=as.integer(ref))
    expect_equal(unname(ra),unname(et_to_r(py)),tolerance=1e-12)
    rb<-etr_inverse_alr(ra,ref,3L)
    pyi<-reticulate::py_call(etpy_get_export("inverse_alr"),
      transformed=py,reference_dimension=as.integer(ref),
      n_dimensions=as.integer(3L))
    expect_equal(unname(rb),unname(et_to_r(pyi)),tolerance=1e-12)
  }
  singleton<-array(1,c(3L,5L,1L))
  r_single<-etr_alr_transform(singleton)
  py_single<-reticulate::py_call(etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(singleton),
    reference_dimension=as.integer(-1L))
  expect_identical(dim(r_single),c(3L,5L,0L))
  expect_equal(unname(r_single),unname(et_to_r(py_single)),tolerance=0)
  r_back<-etr_inverse_alr(r_single,0L,1L)
  py_back<-reticulate::py_call(etpy_get_export("inverse_alr"),
    transformed=py_single,reference_dimension=as.integer(0L),
    n_dimensions=as.integer(1L))
  expect_equal(unname(r_back),unname(et_to_r(py_back)),tolerance=0)
  with_zero<-v;with_zero[1L,1L,]<-c(0,.4,.6)
  for(ep in c(1e-8,1e-5,.03)){
    ra<-etr_alr_transform(with_zero,reference_dimension=1L,epsilon=ep)
    py<-reticulate::py_call(etpy_get_export("alr_transform"),
      values=reticulate::r_to_py(with_zero),
      reference_dimension=as.integer(1L),epsilon=as.numeric(ep))
    expect_equal(unname(ra),unname(et_to_r(py)),tolerance=1e-12)
  }
  nt<-15L;t<-seq(0,2,length.out=nt)
  a<-array(0,c(6L,nt,2L))
  for(i in 1:6){
    a[i,,1L]<-sin(t*2+i*.21)+.07*i*t
    a[i,,2L]<-cos(t*1.3+i*.14)-.03*i*t
  }
  x<-etr_trajectory_set(t,a,sprintf("c%02d",1:6),c("x","y"))
  fit<-etr_fit_mfpca(x,n_components=2L)
  # Published Python score_distance_matrix accesses fpca.scores and
  # fpca.n_components without requiring the full fitted dataclass.
  types<-reticulate::import("types")
  ref<-types$SimpleNamespace(scores=reticulate::r_to_py(fit$scores),
    n_components=as.integer(fit$n_components))
  for(k in c(1L,2L)){
    py<-reticulate::py_call(etpy_get_export("score_distance_matrix"),
      fpca=ref,n_components=as.integer(k))
    d<-etr_score_distance_matrix(fit,n_components=k)
    expect_equal(unname(d),unname(et_to_r(py)),tolerance=1e-10)
  }
  # Source-oracle PASS means candidate evidence exists. It does not
  # self-authorize reviewer approval or automatic full certification.
  z<-etr_native_parity_catalog()
  expect_equal(sum(z$contract_certification_candidate),3L)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
})
