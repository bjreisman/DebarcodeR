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
#' @seealso \code{\link{as.cytoframe}} for converting back to cytoframe
#' @export
fcbFlowFrame <- function(x, barcodes = list()) {
  if (inherits(x, "cytoframe")) {
    if (!requireNamespace("flowWorkspace", quietly = TRUE))
      stop("Package 'flowWorkspace' is required to convert cytoframe objects")
    x <- flowWorkspace::cytoframe_to_flowFrame(x)
  }
  if (!inherits(x, "flowFrame")) {
    stop("x must be an object of class flowFrame")
  }
  as(x, "fcbFlowFrame")
}
