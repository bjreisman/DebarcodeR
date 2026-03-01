test_that("fcbFlowFrame can be constructed from a flowFrame", {
    fcb <- fcbFlowFrame(test_ff)
    expect_s4_class(fcb, "fcbFlowFrame")
    expect_s4_class(fcb, "flowFrame")
    expect_equal(nrow(fcb), nrow(test_ff))
    expect_equal(ncol(fcb), ncol(test_ff))
    expect_type(fcb@barcodes, "list")
    expect_length(fcb@barcodes, 0)
})

test_that("fcbFlowFrame rejects non-flowFrame input", {
    expect_error(fcbFlowFrame(data.frame(x = 1:10)), "FlowFrame|flowFrame")
})

test_that("fcbFlowFrame preserves expression data", {
    fcb <- fcbFlowFrame(test_ff)
    expect_equal(exprs(fcb), exprs(test_ff))
})
