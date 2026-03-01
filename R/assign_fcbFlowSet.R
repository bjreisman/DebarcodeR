#' Assign cells to barcoding levels for a fcbFlowSet
#'
#' Applies \code{\link{assign_fcbFlowFrame}} to each frame in an fcbFlowSet.
#'
#' @param fcbFlowSet An fcbFlowSet object with deskewing and clustering completed.
#' @param channel The name (string) of the channel to assign.
#' @param likelihoodcut Numeric, a likelihood cutoff for discarding unlikely cells.
#'   Cells less than \code{1/likelihoodcut} as likely as the most likely cell from
#'   that population are left unassigned (default 8).
#' @param ambiguitycut Numeric from 0 to 1, threshold below which to leave cells
#'   unassigned. E.g., \code{0.02} unassigns cells with more than 2\% chance of
#'   originating from another population (default 0.02).
#' @return An fcbFlowSet object with assignment slots populated.
#' @seealso \code{\link{assign_fcbFlowFrame}} for single-frame processing,
#'   \code{\link{cluster_fcbFlowSet}} for the preceding step
#' @examples
#' data(jurkatFCB)
#' data(jurkatFCB_std)
#' library(flowCore)
#' fcbfs <- fcbFlowSet(flowSet(list(A = jurkatFCB)))
#' fcbfs <- deskew_fcbFlowSet(fcbfs,
#'     uptake = jurkatFCB_std,
#'     channel = "Pacific Blue-A",
#'     predictors = c("FSC-A", "SSC-A", "APC-H7-A")
#' )
#' fcbfs <- cluster_fcbFlowSet(fcbfs,
#'     channel = "Pacific Blue-A",
#'     levels = 8, opt = "fisher"
#' )
#' fcbfs <- assign_fcbFlowSet(fcbfs, channel = "Pacific Blue-A")
#' @export
assign_fcbFlowSet <- function(fcbFlowSet,
                              channel,
                              likelihoodcut = 8,
                              ambiguitycut = 0.02) {
    if (!inherits(fcbFlowSet, "fcbFlowSet")) {
        stop("Input must be a fcbFlowSet")
    }

    fcbFlowSet.assigned <- fsApply(fcbFlowSet, assign_fcbFlowFrame,
        channel = channel,
        likelihoodcut = likelihoodcut,
        ambiguitycut = ambiguitycut
    )

    return(fcbFlowSet(fcbFlowSet.assigned))
}
