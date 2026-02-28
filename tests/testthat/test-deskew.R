test_that("deskew_fcbFlowFrame works with earth method", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)

  expect_s4_class(fcb, "fcbFlowFrame")
  expect_true("Pacific Blue-A" %in% names(fcb@barcodes))
  expect_true("deskewing" %in% names(fcb@barcodes[["Pacific Blue-A"]]))

  vals <- fcb@barcodes[["Pacific Blue-A"]][["deskewing"]][["values"]]
  expect_type(vals, "double")
  expect_length(vals, nrow(test_ff))
  expect_false(any(is.na(vals)))
})

test_that("deskew_fcbFlowFrame works with lm method", {
  fcb <- fcbFlowFrame(test_ff)
  # lm method requires a single predictor
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             method = "lm",
                             predictors = "FSC-A")

  vals <- fcb@barcodes[["Pacific Blue-A"]][["deskewing"]][["values"]]
  expect_type(vals, "double")
  expect_length(vals, nrow(test_ff))
})

test_that("deskew_fcbFlowFrame works with knijnenburg method", {
  fcb <- fcbFlowFrame(test_ff)
  # knijnenburg works without an uptake control (uses the barcoded data itself)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             method = "knijnenburg",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)

  vals <- fcb@barcodes[["Pacific Blue-A"]][["deskewing"]][["values"]]
  expect_type(vals, "double")
  expect_length(vals, nrow(test_ff))
})

test_that("deskew_fcbFlowFrame accepts plain flowFrame and auto-converts", {
  fcb <- deskew_fcbFlowFrame(test_ff, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  expect_s4_class(fcb, "fcbFlowFrame")
})

test_that("deskew_fcbFlowFrame can deskew multiple channels", {
  fcb <- fcbFlowFrame(test_ff)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Blue-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)
  fcb <- deskew_fcbFlowFrame(fcb, channel = "Pacific Orange-A",
                             predictors = c("FSC-A", "SSC-A"),
                             subsample = 2000)

  expect_true("Pacific Blue-A" %in% names(fcb@barcodes))
  expect_true("Pacific Orange-A" %in% names(fcb@barcodes))
})

test_that("deskew_fcbFlowFrame rejects invalid input", {
  expect_error(deskew_fcbFlowFrame("not_a_frame", channel = "x"),
               "flowFrame|fcbFlowFrame")
})

test_that("deskew_fcbFlowFrame accepts cleaned names with deprecation warning", {
  fcb <- fcbFlowFrame(test_ff)
  expect_warning(
    fcb <- deskew_fcbFlowFrame(fcb, channel = "pacific_blue_a",
                               predictors = c("fsc_a", "ssc_a"),
                               subsample = 2000),
    "cleaned names are deprecated"
  )
  # Slot should be stored under original name
  expect_true("Pacific Blue-A" %in% names(fcb@barcodes))
})
