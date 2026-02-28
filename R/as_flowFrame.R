#' Coerce to flowFrame
#'
#' Generic function for coercing flowFrame-like objects to flowFrame.
#'
#' @param x A flowFrame-like object.
#' @param ... Additional arguments passed to specific methods.
#' @return A \code{flowFrame} object.
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
