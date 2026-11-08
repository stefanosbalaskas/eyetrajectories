# Batch 30 regression: public dispatch is intentional, source bounded, and
# exposes native R-level Python 1.2 product order, schemas and errors.
# Does not award source-gap closure or independent certification.

.b30base <- function(...) {
  args <- list(name="source_probe",truth_grid=c(0,.5,1),
    eigenvalues=c(1,.25),n_participants=3L,replicates=2L,seed_start=31L)
  overrides <- list(...)
  for(nm in names(overrides))args[nm]<-overrides[nm]
  do.call(etr_functional_simulation_scenario,args)
}

.b30compare <- function(base,factors,seed_policy="shared") {
  a <- etr_expand_functional_simulation_scenarios(base,factors,seed_policy)
  b <- etr_expand_functional_simulation_scenarios_b29(base,factors,seed_policy)
  testthat::expect_equal(a,b,tolerance=0)
  a
}

test_that("Batch 30 public expansion follows Python product order for nested levels",{
  x <- .b30compare(.b30base(),list(
    n_participants=c(3L,5L),
    eigenvalues=list(c(1,.35),c(1,.15))),"disjoint")
  expect_identical(vapply(x,function(z)z$n_participants,integer(1L)),
    c(3L,3L,5L,5L))
  expect_equal(vapply(x,function(z)z$eigenvalues[[2L]],numeric(1L)),
    c(.35,.15,.35,.15),tolerance=0)
  expect_identical(vapply(x,function(z)z$seed_start,integer(1L)),
    c(31L,33L,35L,37L))
})

test_that("Batch 30 public expansion preserves mapping, arrays and explicit NULL",{
  b <- .b30base()
  z <- .b30compare(b,list(
    truth_grid=list(c(0,.5,1),seq(0,1,length.out=5L))))
  expect_identical(vapply(z,function(x)length(x$truth_grid),integer(1L)),
    c(3L,5L))
  z <- .b30compare(b,list(measurement_noise_sd=list(0.0,NULL)))
  expect_null(z[[2L]]$measurement_noise_sd)
  z <- .b30compare(b,list(missingness=list(
    list(kind="mcar",probability=.2),
    list(kind="block",fraction=.2))))
  expect_identical(z[[1L]]$missingness$kind,"mcar")
  z <- .b30compare(b,list(labels=list(list(kind="diagnostic",source="test"))))
  expect_identical(z[[1L]]$labels$kind,"diagnostic")
  covb <- .b30base(dimension_names=c("x","y"),measurement_noise_sd=NULL)
  z <- .b30compare(covb,list(measurement_noise_covariance=list(
    matrix(c(.04,.018,.018,.09),nrow=2L))))
  expect_equal(z[[1L]]$measurement_noise_covariance,
    matrix(c(.04,.018,.018,.09),nrow=2L),tolerance=0)
})

test_that("Batch 30 public expansion controls seeds and rejects invalid source inputs",{
  b <- .b30base()
  z <- .b30compare(b,list(replicates=c(2L,3L)),"disjoint")
  expect_identical(vapply(z,function(x)x$seed_start,integer(1L)),c(31L,33L))
  expect_error(etr_expand_functional_simulation_scenarios(
    b,list(seed_start=c(1L,2L))),"seed_start")
  expect_error(etr_expand_functional_simulation_scenarios(
    b,list(eigenvalues=list(c(1,-.1)))),"positive")
  expect_true(is.function(.etr_b30_legacy_public_scenario_expansion))
})
