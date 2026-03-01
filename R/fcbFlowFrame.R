#' fcbFlowFrame class
#'
#' A container for barcoded flow cytometry data, extending flowCore's
#' \code{flowFrame} class with a \code{barcodes} slot that stores
#' deskewing, clustering, and assignment results.
#'
#' @name fcbFlowFrame-class
#' @rdname fcbFlowFrame-class
#' @slot barcodes A named list storing debarcoding results per channel.
#'   Each element is named by channel and contains sublists for
#'   \code{deskewing}, \code{clustering}, and \code{assignment}.
#' @import methods
#' @importClassesFrom flowCore flowFrame
#' @exportClass fcbFlowFrame
fcbFlowFrame <- setClass("fcbFlowFrame",
    contains = "flowFrame",
    slots = c(barcodes = "list")
)

#' Create an fcbFlowFrame
#'
#' Constructor function to create an fcbFlowFrame from a flowFrame or
#' cytoframe. If a \code{cytoframe} is provided (from the \code{flowWorkspace}
#' package), it is automatically converted to a \code{flowFrame} first.
#'
#' @rdname fcbFlowFrame-class
#' @param x A \code{flowFrame} or \code{cytoframe} object.
#' @param barcodes A list of barcode data (default: empty list).
#' @return An object of class \code{fcbFlowFrame}.
#' @seealso \code{\link{deskew_fcbFlowFrame}} to begin the debarcoding pipeline,
#'   \code{as(x, "flowFrame")} for coercion back to flowFrame
#' @examples
#' data(jurkatFCB)
#' fcb <- fcbFlowFrame(jurkatFCB)
#' fcb
#' @export
fcbFlowFrame <- function(x, barcodes = list()) {
    if (inherits(x, "cytoframe")) {
        if (!requireNamespace("flowWorkspace", quietly = TRUE)) {
            stop("Package 'flowWorkspace' is required to convert cytoframe objects")
        }
        x <- flowWorkspace::cytoframe_to_flowFrame(x)
    }
    if (!inherits(x, "flowFrame")) {
        stop("x must be an object of class flowFrame")
    }
    as(x, "fcbFlowFrame")
}

#' Show method for fcbFlowFrame
#'
#' Prints a concise summary of the fcbFlowFrame including cell count, channel
#' count, and the debarcoding state (which pipeline steps have been completed)
#' for each barcoded channel.
#'
#' @param object An fcbFlowFrame object.
#' @return Invisibly returns \code{object}.
#' @examples
#' data(jurkatFCB)
#' fcb <- fcbFlowFrame(jurkatFCB)
#' show(fcb)
#' @importFrom methods show
#' @export
setMethod("show", "fcbFlowFrame", function(object) {
    n_cells <- nrow(object)
    n_channels <- ncol(object)
    cat(sprintf(
        "fcbFlowFrame with %s cells x %d channels\n",
        format(n_cells, big.mark = ","), n_channels
    ))

    bc <- object@barcodes
    if (length(bc) == 0) {
        cat("Barcodes: none (run deskew_fcbFlowFrame to begin)\n")
    } else {
        cat("Barcodes:\n")
        for (ch in names(bc)) {
            steps <- names(bc[[ch]])
            state <- character(0)

            if ("deskewing" %in% steps) {
                state <- c(state, "deskewed")
            }
            if ("clustering" %in% steps) {
                probs <- bc[[ch]][["clustering"]][["probabilities"]]
                n_levels <- if (!is.null(probs)) ncol(probs) else "?"
                state <- c(state, sprintf("clustered (%d levels)", n_levels))
            }
            if ("assignment" %in% steps) {
                state <- c(state, "assigned")
            }

            pipeline_str <- if (length(state) > 0) paste(state, collapse = " -> ") else "no steps completed"
            cat(sprintf("  %s: %s\n", ch, pipeline_str))
        }
    }
    invisible(object)
})
