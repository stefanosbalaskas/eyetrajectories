# This file is run against the frozen v0.4.3 source plus only the L2
# optimization patch. It deliberately checks the legacy Python boundary
# mode; development main has a different public signature.

.make_candidate_fixture <- function(n=13L, nt=29L, nd=3L,
                                    seed=20261118L,offset=0) {
  set.seed(seed+n*100L+nt*3L+nd)
  t<-sort(c(0,1,stats::runif(nt-2L)))
  y<-array(stats::rnorm(n*nt*nd,sd=4),c(n,nt,nd))+offset
  etr_trajectory_set(t,y,
      curve_ids=sprintf("curve%03d",seq_len(n)),
      dimension_names=paste0("channel",seq_len(nd)),
      coordinate_system="pixels")
}
.pairwise_l2_oracle <- function(x,dw=NULL,python_boundary_mode=FALSE) {
  n<-dim(x$values)[1L]
  d<-matrix(0,n,n,dimnames=list(x$curve_ids,x$curve_ids))
  if(n>1L)for(i in seq_len(n-1L))for(j in seq.int(i+1L,n)){
    a<-matrix(x$values[i,,,drop=FALSE],
               nrow=length(x$time),ncol=dim(x$values)[3L])
    b<-matrix(x$values[j,,,drop=FALSE],
               nrow=length(x$time),ncol=dim(x$values)[3L])
    d[i,j]<-etr_l2_distance(a,b,x$time,
          dimension_weights=dw,python_boundary_mode=python_boundary_mode)
    d[j,i]<-d[i,j]
  }
  d
}
testthat::test_that("candidate: native irregular 3D pairwise L2 matches scalar reference",{
  x<-.make_candidate_fixture()
  for(dw in list(NULL,c(1,1,1),c(0,3,.75),c(0,0,0),c(1e-3,2,10))){
    got<-etr_pairwise_l2(x,dimension_weights=dw)
    truth<-.pairwise_l2_oracle(x,dw)
    testthat::expect_identical(dim(got),dim(truth))
    testthat::expect_identical(dimnames(got),dimnames(truth))
    testthat::expect_equal(got,truth,tolerance=1e-10)
    testthat::expect_equal(got,t(got),tolerance=1e-12)
    testthat::expect_true(all(diag(got)==0))
  }
})
testthat::test_that("candidate: archived source-boundary mode remains scalar",{
  x<-.make_candidate_fixture(n=7L,nt=19L,nd=2L)
  for(dw in list(NULL,c(1,2),c("1","3"),c(0,.5))){
    actual<-etr_pairwise_l2(x,dimension_weights=dw,
                            python_boundary_mode=TRUE)
    expected<-.pairwise_l2_oracle(x,dw,TRUE)
    testthat::expect_equal(actual,expected,tolerance=1e-12)
  }
  testthat::expect_error(etr_pairwise_l2(x,python_boundary_mode=NA),
                         "python_boundary_mode")
  testthat::expect_error(etr_pairwise_l2(x,python_boundary_mode=1),
                         "python_boundary_mode")
})
testthat::test_that("candidate: n=1 keeps archived short-circuit semantics",{
  x<-.make_candidate_fixture(n=1L,nt=18L,nd=2L)
  # The old implementation did not inspect weights when there are no pairs.
  for(m in c(FALSE,TRUE))
    testthat::expect_identical(
      etr_pairwise_l2(x,dimension_weights=c(-4,Inf),
                      python_boundary_mode=m),
      matrix(0,1,1,dimnames=list(x$curve_ids,x$curve_ids)))
})
testthat::test_that("candidate: invalid weighting still fails for multi-curves",{
  x<-.make_candidate_fixture(n=5L,nt=12L,nd=2L)
  testthat::expect_error(etr_pairwise_l2(x,c(-1,2)),"non-negative")
  testthat::expect_error(etr_pairwise_l2(x,c(1,NA_real_)),"finite")
  testthat::expect_error(etr_pairwise_l2(x,dimension_weights=c(1,2,3)),
                         "match dimensions")
})
testthat::test_that("candidate: large common offset does not corrupt distances",{
  x<-.make_candidate_fixture(n=16L,nt=35L,nd=2L,offset=1e8)
  testthat::expect_equal(etr_pairwise_l2(x),
                         .pairwise_l2_oracle(x),tolerance=1e-7)
})
testthat::test_that("candidate: smaller and larger matrices reproduce reference",{
  for(n in c(2L,9L,64L)) {
    x<-.make_candidate_fixture(n=n,nt=64L,nd=2L)
    result<-etr_pairwise_l2(x,dimension_weights=c(1.25,.5))
    testthat::expect_equal(result,
      .pairwise_l2_oracle(x,c(1.25,.5)),tolerance=1e-10)
  }
})
