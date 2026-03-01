test_that("fcbFlowSet can be constructed from a flowSet", {
    fs <- flowSet(list(sample1 = test_ff))
    fcbfs <- fcbFlowSet(fs)
    expect_s4_class(fcbfs, "fcbFlowSet")
    expect_s4_class(fcbfs, "flowSet")
    expect_equal(length(fcbfs), 1)
})

test_that("fcbFlowSet rejects non-flowSet input", {
    expect_error(fcbFlowSet(data.frame(x = 1:10)), "FlowFrame|flowSet")
})
