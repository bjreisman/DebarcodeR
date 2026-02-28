#' Coerce to cytoframe
#'
#' Converts an \code{fcbFlowFrame} to a \code{cytoframe} object from the
#' \code{flowWorkspace} package. Note that the \code{@barcodes} slot is not
#' carried over — this is a one-way extraction of the expression data for
#' use in Cytoverse workflows.
#'
#' Requires the \code{flowWorkspace} package to be installed.
#'
#' @param x An \code{fcbFlowFrame} object.
#' @param ... Additional arguments (not used).
#' @return A \code{cytoframe} object.
#' @export
#' @import methods
setGeneric("as.cytoframe", function(x, ...) {
  standardGeneric("as.cytoframe")
})

#' @describeIn as.cytoframe Coerce an fcbFlowFrame to a cytoframe
#' @export
setMethod("as.cytoframe", "fcbFlowFrame", function(x, ...) {
  if (!requireNamespace("flowWorkspace", quietly = TRUE))
    stop("Package 'flowWorkspace' is required for cytoframe conversion")
  flowWorkspace::flowFrame_to_cytoframe(as(x, "flowFrame"))
})

#' Coerce to cytoset
#'
#' Converts an \code{fcbFlowSet} to a \code{cytoset} object from the
#' \code{flowWorkspace} package. Note that any DebarcodeR-specific slots
#' are not carried over — this is a one-way extraction for use in
#' Cytoverse workflows.
#'
#' Requires the \code{flowWorkspace} package to be installed.
#'
#' @param x An \code{fcbFlowSet} object.
#' @param ... Additional arguments (not used).
#' @return A \code{cytoset} object.
#' @export
#' @import methods
setGeneric("as.cytoset", function(x, ...) {
  standardGeneric("as.cytoset")
})

#' @describeIn as.cytoset Coerce an fcbFlowSet to a cytoset
#' @export
setMethod("as.cytoset", "fcbFlowSet", function(x, ...) {
  if (!requireNamespace("flowWorkspace", quietly = TRUE))
    stop("Package 'flowWorkspace' is required for cytoset conversion")
  flowWorkspace::flowSet_to_cytoset(as(x, "flowSet"))
})
