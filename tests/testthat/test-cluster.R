test_that("cluster_fcbFlowFrame works with mixture method", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "mixture",
                              subsample = 2000)

  expect_true("clustering" %in% names(fcb@barcodes[["pacific_blue_a"]]))

  probs <- fcb@barcodes[["pacific_blue_a"]][["clustering"]][["probabilities"]]
  expect_true(is.matrix(probs) || is.data.frame(probs))
  expect_equal(nrow(probs), nrow(test_ff))
  expect_equal(ncol(probs), 8)
  expect_true(all(probs >= 0, na.rm = TRUE))
})

test_that("cluster_fcbFlowFrame works with fisher method", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "fisher",
                              subsample = 2000)

  probs <- fcb@barcodes[["pacific_blue_a"]][["clustering"]][["probabilities"]]
  expect_equal(nrow(probs), nrow(test_ff))
  expect_true(all(probs >= 0, na.rm = TRUE))
})

test_that("cluster_fcbFlowFrame rejects input without deskewing", {
  fcb <- fcbFlowFrame(test_ff)
  expect_error(cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a", levels = 8),
               "deskew")
})
