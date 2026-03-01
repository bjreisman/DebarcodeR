#' fcbFlowSet class
#'
#' A container for debarcoded flow cytometry data, extending flowCore's
#' \code{flowSet} class. Contains a collection of flowFrames, one per
#' debarcoded sample.
#'
#' @name fcbFlowSet-class
#' @examples
#' data(jurkatFCB)
#' library(flowCore)
#' fcbfs <- fcbFlowSet(flowSet(list(sample1 = jurkatFCB)))
#' class(fcbfs)
#' @importClassesFrom flowCore flowFrame
#' @exportClass fcbFlowSet
.fcbFlowSet <- setClass("fcbFlowSet",
                          contains = "flowSet"
)

#' Create an fcbFlowSet
#'
#' Constructor function to create an fcbFlowSet from a flowSet or cytoset.
#' If a \code{cytoset} is provided (from the \code{flowWorkspace} package),
#' it is automatically converted to a \code{flowSet} first.
#'
#' @param x A \code{flowSet} or \code{cytoset} object.
#' @return An object of class \code{fcbFlowSet}.
#' @seealso \code{\link{split}} to produce an fcbFlowSet from an assigned
#'   fcbFlowFrame, \code{as(x, "flowSet")} for coercion back to flowSet
#' @examples
#' data(jurkatFCB)
#' library(flowCore)
#' fs <- flowSet(list(sample1 = jurkatFCB))
#' fcbfs <- fcbFlowSet(fs)
#' @export
fcbFlowSet <- function(x) {
  if (inherits(x, "cytoset")) {
    if (!requireNamespace("flowWorkspace", quietly = TRUE))
      stop("Package 'flowWorkspace' is required to convert cytoset objects")
    x <- flowWorkspace::cytoset_to_flowSet(x)
  }
  if (!inherits(x, "flowSet")) {
    stop("x must be an object of class flowSet")
  }
  as(x, "fcbFlowSet")
}
