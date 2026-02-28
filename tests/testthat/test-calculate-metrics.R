test_that("calculate.ambiguity row-normalizes correctly", {
  probs <- matrix(c(0.8, 0.2,
                     0.3, 0.7), nrow = 2, byrow = TRUE)
  result <- calculate.ambiguity(probs)

  # Each row should sum to 1
  expect_equal(rowSums(result), c(1, 1))
  expect_equal(result[1, 1], 0.8)
  expect_equal(result[2, 2], 0.7)
})

test_that("calculate.likelihood column-normalizes correctly", {
  probs <- matrix(c(0.8, 0.2,
                     0.4, 0.6), nrow = 2, byrow = TRUE)
  result <- calculate.likelihood(probs)

  # Column maxima should be 1
  expect_equal(apply(result, 2, max), c(1, 1))
  # First column: 0.8 is max -> 1.0, 0.4 -> 0.5
  expect_equal(result[1, 1], 1.0)
  expect_equal(result[2, 1], 0.5)
})

test_that("calculate.ambiguity handles single-column matrix", {
  probs <- matrix(c(0.5, 0.3, 0.8), ncol = 1)
  result <- calculate.ambiguity(probs)
  expect_equal(result, matrix(c(1, 1, 1), ncol = 1))
})
