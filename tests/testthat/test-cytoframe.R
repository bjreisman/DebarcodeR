skip_if_not_installed("flowWorkspace")
library(flowWorkspace)

# Create cytoframe/cytoset fixtures
test_cf <- flowFrame_to_cytoframe(test_ff)
test_cs <- flowSet_to_cytoset(flowSet(list(sample1 = test_ff)))

# -- Construction ---------------------------------------------------------

test_that("fcbFlowFrame can be constructed from a cytoframe", {
  fcb <- fcbFlowFrame(test_cf)
  expect_s4_class(fcb, "fcbFlowFrame")
  expect_equal(nrow(fcb), nrow(test_ff))
  expect_equal(ncol(fcb), ncol(test_ff))
})

test_that("fcbFlowFrame from cytoframe preserves expression data", {
  fcb <- fcbFlowFrame(test_cf)
  expect_equal(dim(exprs(fcb)), dim(exprs(test_ff)))
})

test_that("fcbFlowSet can be constructed from a cytoset", {
  fcbfs <- fcbFlowSet(test_cs)
  expect_s4_class(fcbfs, "fcbFlowSet")
  expect_equal(length(fcbfs), 1)
})

# -- Deskew pipeline ------------------------------------------------------

test_that("deskew_fcbFlowFrame accepts cytoframe input", {
  suppressWarnings({
    result <- deskew_fcbFlowFrame(test_cf,
                                  channel = "pacific_blue_a",
                                  predictors = c("fsc_a", "ssc_a"),
                                  subsample = 1000)
  })
  expect_s4_class(result, "fcbFlowFrame")
  expect_true("deskewing" %in% names(result@barcodes[["pacific_blue_a"]]))
  expect_equal(nrow(result), nrow(test_ff))
})

test_that("deskew_fcbFlowFrame accepts cytoframe as uptake", {
  uptake_cf <- flowFrame_to_cytoframe(test_ff)
  suppressWarnings({
    result <- deskew_fcbFlowFrame(test_ff,
                                  uptake = uptake_cf,
                                  channel = "pacific_blue_a",
                                  predictors = c("fsc_a", "ssc_a"),
                                  subsample = 1000)
  })
  expect_s4_class(result, "fcbFlowFrame")
  expect_true("deskewing" %in% names(result@barcodes[["pacific_blue_a"]]))
})

# -- Conversion back to cytoframe/cytoset --------------------------------

test_that("as.cytoframe converts fcbFlowFrame to cytoframe", {
  fcb <- fcbFlowFrame(test_ff)
  cf_out <- as.cytoframe(fcb)
  expect_s4_class(cf_out, "cytoframe")
  expect_equal(nrow(cf_out), nrow(test_ff))
  expect_equal(ncol(cf_out), ncol(test_ff))
})

test_that("as.cytoset converts fcbFlowSet to cytoset", {
  fs <- flowSet(list(sample1 = test_ff))
  fcbfs <- fcbFlowSet(fs)
  cs_out <- as.cytoset(fcbfs)
  expect_s4_class(cs_out, "cytoset")
  expect_equal(length(cs_out), 1)
})

test_that("as.cytoframe rejects non-fcbFlowFrame input", {
  expect_error(as.cytoframe(test_ff))
})
