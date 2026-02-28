test_that("assign_fcbFlowFrame produces valid assignments", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "pacific_blue_a")

  expect_true("assignment" %in% names(fcb@barcodes[["pacific_blue_a"]]))

  vals <- fcb@barcodes[["pacific_blue_a"]][["assignment"]][["values"]]
  expect_length(vals, nrow(test_ff))
  # Assignments should be characters: "0" for unassigned, or level numbers
  expect_type(vals, "character")
  # Should have some assigned and some unassigned cells
  expect_true("0" %in% vals)
  expect_true(sum(vals != "0") > 0)
})

test_that("assign_fcbFlowFrame rejects input without clustering", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  expect_error(assign_fcbFlowFrame(fcb, channel = "pacific_blue_a"),
               "cluster")
})

test_that("assign_fcbFlowFrame stores cutoff parameters", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             likelihoodcut = 10, ambiguitycut = 0.05)

  asgn <- fcb@barcodes[["pacific_blue_a"]][["assignment"]]
  expect_equal(asgn[["likelihood"]], 10)
  expect_equal(asgn[["ambiguity"]], 0.05)
})
