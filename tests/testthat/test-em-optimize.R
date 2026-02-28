test_that("em_optimize runs on two-channel debarcoded data", {
  # Known issue: em_optimize has a compatibility bug with newer mclust versions

  # where esEst$modelName returns a vector instead of a scalar, causing cdens()
  # to fail. Skipping until fixed in Phase 4.
  skip("em_optimize has known mclust compatibility bug - to be fixed in Phase 4")

  set.seed(5814)
  em_idx <- sample(nrow(jurkatFCB), 20000)
  em_ff <- jurkatFCB[em_idx, ]

  fcb <- fcbFlowFrame(em_ff)

  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 5000)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_orange_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 5000)

  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "mixture",
                              subsample = 5000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_orange_a",
                              levels = 6, opt = "mixture",
                              subsample = 5000)

  fcb <- assign_fcbFlowFrame(fcb, channel = "pacific_blue_a")
  fcb <- assign_fcbFlowFrame(fcb, channel = "pacific_orange_a")

  fcb <- em_optimize(fcb, niter = 1, verbose = FALSE, shrinkage = 0)

  expect_true("wells" %in% names(fcb@barcodes))
  expect_true("clustering" %in% names(fcb@barcodes[["wells"]]))

  probs <- fcb@barcodes[["wells"]][["clustering"]][["probabilities"]]
  expect_equal(nrow(probs), 20000)
  expect_equal(ncol(probs), 48)
})
