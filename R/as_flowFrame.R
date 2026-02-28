#' Coerce to flowFrame
#'
#' Generic function for coercing flowFrame-like objects to flowFrame.
#' The \code{@barcodes} slot is dropped; this is a one-way extraction of
#' the expression data.
#'
#' @param x A flowFrame-like object.
#' @param ... Additional arguments passed to specific methods.
#' @return A \code{flowFrame} object.
#' @seealso \code{\link{fcbFlowFrame}} to create an fcbFlowFrame,
#'   \code{\link{as.cytoframe}} for Cytoverse workflows
#' @examples
#' data(jurkatFCB)
#' fcb <- fcbFlowFrame(jurkatFCB)
#' ff  <- as.flowFrame(fcb)
#' class(ff)
#' @export
#' @import methods
#' @include fcbFlowFrame.R
setGeneric("as.flowFrame", function(x, ...) {
  standardGeneric("as.flowFrame")
})

#' @describeIn as.flowFrame Coerce an fcbFlowFrame to a flowFrame
#' @param x An \code{fcbFlowFrame} object.
#' @param ... Not used.
#' @export
setMethod("as.flowFrame", "fcbFlowFrame", function(x, ...) {
  if (!inherits(x, "fcbFlowFrame")) {
    stop("Input must be an object of class fcbFlowFrame")
  }
  as(x, "flowFrame")
})
