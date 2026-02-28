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
#' Constructor function to create an fcbFlowFrame from a flowFrame.
#'
#' @rdname fcbFlowFrame-class
#' @param x A \code{flowFrame} object.
#' @param barcodes A list of barcode data (default: empty list).
#' @return An object of class \code{fcbFlowFrame}.
#' @export
fcbFlowFrame <- function(x, barcodes = list()) {
  if (!inherits(x, "flowFrame")) {
    stop("x must be an object of class flowFrame")
  }
  as(x, "fcbFlowFrame")
}
