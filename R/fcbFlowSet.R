#' fcbFlowSet class
#'
#' A container for debarcoded flow cytometry data, extending flowCore's
#' \code{flowSet} class. Contains a collection of flowFrames, one per
#' debarcoded sample.
#'
#' @name fcbFlowSet-class
#' @importClassesFrom flowCore flowFrame
#' @exportClass fcbFlowSet
.fcbFlowSet <- setClass("fcbFlowSet",
                          contains = "flowSet"
)

#' Create an fcbFlowSet
#'
#' Constructor function to create an fcbFlowSet from a flowSet.
#'
#' @param x A \code{flowSet} object.
#' @return An object of class \code{fcbFlowSet}.
#' @export
fcbFlowSet <- function(x) {
  if (!inherits(x, "flowSet")) {
    stop("x must be an object of class flowSet")
  }
  as(x, "fcbFlowSet")
}
