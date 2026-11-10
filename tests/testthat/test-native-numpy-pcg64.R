test_that("native PCG64 uses an isolated, reproducible integer-seeded stream", {
  set.seed(94L)
  before <- .Random.seed
  rng <- .etr_numpy_pcg64(0)
  expect_identical(rng$uniform(3L),
    c(.6369616873214543, .2697867137638703, .04097352393619469))
  expect_identical(.etr_numpy_seeded_case_indices(1L, 3L, 1L), matrix(0L, 3L, 1L))
  expect_identical(.Random.seed, before)
  expect_error(.etr_numpy_pcg64(-1), "nonnegative integer")
  expect_error(.etr_numpy_pcg64(1.5), "nonnegative integer")
  expect_error(.etr_numpy_pcg64(2^53), "nonnegative integer")
})

test_that("native PCG64 agrees exactly on seeded uniforms, integers and permutations", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("NumPy source stream oracle is opt-in")
  np <- reticulate::import("numpy", convert = TRUE)
  builtin <- reticulate::import_builtins(convert = FALSE)
  for (seed in c(0, 1, 42, .Machine$integer.max, 2^32 - 1, 2^32, 2^53 - 1)) {
    native <- .etr_numpy_pcg64(seed)
    reference <- np$random$default_rng(builtin$int(sprintf("%.0f", seed)))
    expect_identical(native$uniform(23L), as.numeric(reference$random(23L)))
    for (high in c(1L, 2L, 3L, 7L, 25L, 65537L, 1431655766L, .Machine$integer.max)) {
      expect_identical(native$integers(111L, high),
        as.integer(reference$integers(0L, high, 111L)))
    }
    # An odd number of 32-bit draws leaves half a word cached.
    expect_identical(native$uniform(2L), as.numeric(reference$random(2L)))
    for (n in c(0L, 1L, 3L, 8L, 16L, 17L, 200L))
      expect_identical(native$permutation(n), as.integer(reference$permutation(n)) + 1L)
  }
})
