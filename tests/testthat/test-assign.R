test_that("assign_fcbFlowFrame produces valid assignments", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A")

  expect_true("assignment" %in% names(fcb@barcodes[["Pacific Blue-A"]]))

  vals <- fcb@barcodes[["Pacific Blue-A"]][["assignment"]][["values"]]
  expect_length(vals, nrow(test_ff))
  # Assignments should be characters: "0" for unassigned, or level numbers
  expect_type(vals, "character")
  # Should have some assigned and some unassigned cells
  expect_true("0" %in% vals)
  expect_true(sum(vals != "0") > 0)
})

test_that("assign_fcbFlowFrame rejects input without clustering", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  expect_error(assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A"),
               "cluster")
})

test_that("assign_fcbFlowFrame stores cutoff parameters", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                              levels = 8, opt = "mixture",
                              subsample = 2000)
  fcb <- assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             likelihoodcut = 10, ambiguitycut = 0.05)

  asgn <- fcb@barcodes[["Pacific Blue-A"]][["assignment"]]
  expect_equal(asgn[["likelihood"]], 10)
  expect_equal(asgn[["ambiguity"]], 0.05)
})
