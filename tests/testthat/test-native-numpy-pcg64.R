test_that("native PCG64 uses an isolated, reproducible integer-seeded stream", {
  set.seed(94L)
  before <- .Random.seed
  rng <- .etr_numpy_pcg64(0)
  expect_identical(rng$uniform(3L),
    c(.6369616873214543, .2697867137638703, .04097352393619469))
  expect_identical(.etr_numpy_seeded_case_indices(1L, 3L, 1L), matrix(0L, 3L, 1L))
  expect_identical(.etr_numpy_pcg64(0)$normal(3L),
    c(.1257302210933933, -.1321048632913019, .6404226504432821))
  expect_identical(.Random.seed, before)
  expect_error(.etr_numpy_pcg64(-1), "nonnegative integer")
  expect_error(.etr_numpy_pcg64(1.5), "nonnegative integer")
  expect_error(.etr_numpy_pcg64(2^53), "nonnegative integer")
  expect_error(rng$spawn(-1L), "nonnegative child count")
  expect_error(rng$spawn(1.5), "nonnegative child count")
  expect_error(.etr_numpy_pcg64(0, 2^32), "32-bit child indices")
})

test_that("native PCG64 normal and child streams match NumPy draw consumption", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("NumPy normal and child stream oracle is opt-in")
  np <- reticulate::import("numpy", convert = TRUE)
  builtin <- reticulate::import_builtins(convert = FALSE)
  tail_count <- 0L
  for (seed in c(0, 1, 12345, 2^32, 2^53 - 1)) {
    py_seed <- builtin$int(sprintf("%.0f", seed))
    native <- .etr_numpy_pcg64(seed)
    reference <- np$random$default_rng(py_seed)
    first <- native$spawn(2L)
    py_first <- reference$spawn(2L)
    expect_identical(native$spawn(0L), list())
    second <- native$spawn(1L)
    py_second <- reference$spawn(1L)
    expect_identical(first[[1L]]$uniform(17L), as.numeric(py_first[[1L]]$random(17L)))
    expect_identical(second[[1L]]$integers(23L, 1431655766L),
      as.integer(py_second[[1L]]$integers(0L, 1431655766L, 23L)))
    grandchild <- first[[2L]]$spawn(3L)[[3L]]
    py_grandchild <- py_first[[2L]]$spawn(3L)[[3L]]
    expect_identical(grandchild$integers(7L, 17L),
      as.integer(py_grandchild$integers(0L, 17L, 7L)))
    expect_identical(grandchild$normal(19L), as.numeric(py_grandchild$normal(0, 1, 19L)))
    expect_identical(grandchild$permutation(17L),
      as.integer(py_grandchild$permutation(17L)) + 1L)
    expect_identical(native$normal(0L), numeric())
    draws <- native$normal(4096L)
    expected <- as.numeric(reference$normal(0, 1, 4096L))
    tail <- abs(expected) > .etr_numpy_normal_ziggurat$tail
    tail_count <- tail_count + sum(tail)
    expect_identical(draws[!tail], expected[!tail])
    # The tail uses platform log1p, so allow two relative double epsilons.
    expect_true(all(abs(draws[tail] - expected[tail]) <=
      2 * .Machine$double.eps * abs(expected[tail])))
    expect_identical(native$uniform(13L), as.numeric(reference$random(13L)))
    expect_identical(.etr_wild_fpcr_multipliers(3L, 5L, "normal", seed),
      np$random$default_rng(py_seed)$normal(0, 1, reticulate::tuple(3L, 5L)))
  }
  expect_gt(tail_count, 0L)
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
