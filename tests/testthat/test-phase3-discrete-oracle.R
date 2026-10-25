test_that("discrete TE agrees with an independently counted Python CMI oracle", {
  bits <- function(n, seed) {
    state <- as.numeric(seed)
    out <- integer(n)
    for (i in seq_len(n)) {
      state <- (48271 * state) %% 2147483647
      out[i] <- as.integer(state %% 2)
    }
    out
  }
  x <- bits(401L,12345L)
  y <- c(0L,head(x,-1L))
  z <- bits(401L,987654L)
  ref <- utils::read.csv(testthat::test_path(
    "fixtures","phase3_discrete_te_oracle.csv"))
  find <- function(label) ref$expected_bits[match(label,ref$scenario)]
  forward <- etr_transfer_entropy(x,y)$transfer_entropy_bits
  backward <- etr_transfer_entropy(y,x)$transfer_entropy_bits
  independent <- etr_transfer_entropy(x,z)$transfer_entropy_bits
  expect_equal(forward,find("forward_coupled"), tolerance = 1e-10)
  expect_equal(backward,find("reverse_coupled"), tolerance = 1e-10)
  expect_equal(independent,find("independent_source"), tolerance = 1e-10)
  expect_equal(etr_transfer_entropy(rep(0L,100L),
                rep(c(0L,1L),50L))$transfer_entropy_bits, 0, tolerance = 1e-10)
  expect_gt(forward, backward + .5)
})
