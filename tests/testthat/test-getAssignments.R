test_that("getAssignments extracts assignments from fcbFlowFrame", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A")

  assignments <- getAssignments(fcb)
  expect_type(assignments, "list")
  expect_true("Pacific Blue-A" %in% names(assignments))
  expect_s3_class(assignments[["Pacific Blue-A"]], "factor")
  expect_length(assignments[["Pacific Blue-A"]], nrow(test_ff))
})
