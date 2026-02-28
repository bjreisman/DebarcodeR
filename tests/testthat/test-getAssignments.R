test_that("getAssignments extracts assignments from fcbFlowFrame", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                             predictors = c("fsc_a", "ssc_a"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "pacific_blue_a")

  assignments <- getAssignments(fcb)
  expect_type(assignments, "list")
  expect_true("pacific_blue_a" %in% names(assignments))
  expect_s3_class(assignments[["pacific_blue_a"]], "factor")
  expect_length(assignments[["pacific_blue_a"]], nrow(test_ff))
})
