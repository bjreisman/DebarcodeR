test_that("split fcbFlowFrame produces fcbFlowSet", {
    fcb <- fcbFlowFrame(test_ff)
    fcb <- deskew_fcbFlowFrame(fcb,
        channel = "Pacific Blue-A",
        predictors = c("FSC-A", "SSC-A"),
        subsample = 2000
    )
    fcb <- cluster_fcbFlowFrame(fcb,
        channel = "Pacific Blue-A",
        levels = 8, opt = "mixture",
        subsample = 2000
    )
    fcb <- assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A")

    assignments <- getAssignments(fcb)
    result <- split(fcb, assignments)

    expect_s4_class(result, "fcbFlowSet")
    expect_true(length(result) > 1)

    # Total cells across all frames should equal original
    total_cells <- sum(fsApply(result, nrow))
    expect_equal(total_cells, nrow(test_ff))
})
