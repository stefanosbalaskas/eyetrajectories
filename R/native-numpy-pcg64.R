# Native NumPy SeedSequence and PCG64 for scalar seeds. Split unsigned
# words into 16-bit limbs so all arithmetic stays exact in R doubles.
# Reference: NumPy 2.3.5 random/bit_generator.pyx and random/src/pcg64.

.etr_numpy_pcg64_seed <- function(seed, spawn_key) {
  .etr_assert(is.numeric(seed) && length(seed) == 1L && is.finite(seed) &&
    seed >= 0 && seed < 2^53 && seed == floor(seed),
    "random_state must be an exactly represented nonnegative integer")
  limb <- 2^16
  word <- 2^32
  .etr_assert(is.numeric(spawn_key) && is.null(dim(spawn_key)) &&
    all(is.finite(spawn_key) & spawn_key >= 0 & spawn_key < word &
      spawn_key == floor(spawn_key)),
    "spawn_key must contain unsigned 32-bit child indices")
  xor <- function(a, b) bitwXor(a %% limb, b %% limb) +
    limb * bitwXor(floor(a / limb), floor(b / limb))
  multiply <- function(a, b) {
    low_a <- a %% limb
    low_b <- b %% limb
    cross <- (floor(a / limb) * low_b + floor(b / limb) * low_a) %% limb
    (low_a * low_b + limb * cross) %% word
  }
  mix_word <- function(a) xor(a, floor(a / limb))
  key <- 0x43b0d7e5
  hash <- function(a) {
    mixed <- xor(a, key)
    key <<- multiply(key, 0x931e8875)
    mix_word(multiply(mixed, key))
  }
  mix <- function(a, b) {
    mix_word((multiply(a, 0xca01f9dd) - multiply(b, 0x4973f715)) %% word)
  }

  # Pad scalar entropy to the four-word pool before appending the spawn path.
  entropy <- c(seed %% word, floor(seed / word), 0, 0)
  pool <- vapply(entropy, hash, numeric(1L))
  for (source in seq_along(pool)) {
    for (target in seq_along(pool)[-source]) {
      pool[target] <- mix(pool[target], hash(pool[source]))
    }
  }
  for (child in spawn_key) {
    for (target in seq_along(pool))
      pool[target] <- mix(pool[target], hash(child))
  }

  output <- numeric(8L)
  key <- 0x8b51f9dd
  for (i in seq_along(output)) {
    input <- xor(pool[1L + (i - 1L) %% length(pool)], key)
    key <- multiply(key, 0x58f38ded)
    output[i] <- mix_word(multiply(input, key))
  }
  as.vector(rbind(output %% limb, floor(output / limb)))
}

.etr_numpy_pcg64 <- function(seed, spawn_key = integer()) {
  limb <- 2^16
  word <- 2^32
  multiplier <- c(0xf645, 0x9fcc, 0xdf64, 0x4385, 0x5da4, 0x1fc6, 0xed05, 0x2360)
  digits <- seq_along(multiplier)
  carry_limbs <- function(x) {
    for (i in digits[-length(digits)]) {
      x[i + 1L] <- x[i + 1L] + floor(x[i] / limb)
      x[i] <- x[i] %% limb
    }
    x[length(digits)] <- x[length(digits)] %% limb
    x
  }
  words <- .etr_numpy_pcg64_seed(seed, spawn_key)
  initial <- words[c(5:8, 1:4)]
  increment <- words[c(13:16, 9:12)] * 2
  increment[1L] <- increment[1L] + 1
  increment <- carry_limbs(increment)
  state <- numeric(8L)
  step <- function() {
    sums <- vapply(digits, function(i) sum(state[seq_len(i)] * multiplier[i:1L]),
      numeric(1L))
    state <<- carry_limbs(sums + increment)
  }
  step()
  state <- carry_limbs(state + initial)
  step()

  raw64 <- function() {
    step()
    mixed <- bitwXor(state[1:4], state[5:8])
    rotation <- floor(state[8L] / 2^10)
    index <- 1L + ((0:3 + floor(rotation / 16)) %% 4L)
    following <- 1L + index %% 4L
    shift <- 2^(rotation %% 16)
    floor(mixed[index] / shift) + (mixed[following] %% shift) * (limb / shift)
  }
  cached <- NULL
  raw32 <- function() {
    if (!is.null(cached)) {
      value <- cached
      cached <<- NULL
      return(value)
    }
    limbs <- raw64()
    cached <<- limbs[3L] + limb * limbs[4L]
    limbs[1L] + limb * limbs[2L]
  }
  draw_double <- function() {
    x <- raw64()
    (x[4L] * 2^37 + x[3L] * 2^21 + x[2L] * 2^5 + floor(x[1L] / 2^11)) / 2^53
  }
  uniform <- function(n) vapply(seq_len(n), function(i) draw_double(), numeric(1L))
  normal <- function(n) .etr_numpy_normal_draws(n, raw64, draw_double)

  integers <- function(n, high) {
    if (high == 1L) return(integer(n))
    threshold <- word %% high
    low_bound <- high %% limb
    high_bound <- floor(high / limb)
    vapply(seq_len(n), function(i) {
      repeat {
        draw <- raw32()
        # Split the Lemire product into unsigned high and low words.
        low_draw <- draw %% limb
        high_draw <- floor(draw / limb)
        product <- low_draw * low_bound
        cross <- floor(product / limb) + low_draw * high_bound + high_draw * low_bound
        low <- product %% limb + (cross %% limb) * limb
        if (low >= threshold)
          return(as.integer(high_draw * high_bound + floor(cross / limb)))
      }
    }, integer(1L))
  }
  permutation <- function(n) {
    result <- seq_len(n)
    if (n <= 1L) return(result)
    for (i in seq.int(n, 2L)) {
      bound <- 2^ceiling(log2(i))
      repeat {
        j <- 1 + raw32() %% bound
        if (j <= i) break
      }
      first <- result[i]
      result[i] <- result[j]
      result[j] <- first
    }
    result
  }
  children_spawned <- 0
  spawn <- function(n) {
    .etr_assert(is.numeric(n) && length(n) == 1L && is.finite(n) &&
      n == floor(n) && n >= 0 && n <= .Machine$integer.max &&
      children_spawned + n <= word,
      "n must be a nonnegative child count within the 32-bit spawn domain")
    children <- lapply(seq_len(n), function(i)
      .etr_numpy_pcg64(seed, c(spawn_key, children_spawned + i - 1)))
    children_spawned <<- children_spawned + n
    children
  }
  list(uniform = uniform, normal = normal, integers = integers,
    permutation = permutation, spawn = spawn)
}

.etr_numpy_seeded_case_indices <- function(seed, replicates, units) {
  rng <- .etr_numpy_pcg64(seed)
  matrix(rng$integers(as.double(replicates) * units, units),
    nrow = replicates, ncol = units, byrow = TRUE)
}
