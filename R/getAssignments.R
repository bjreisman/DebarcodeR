#' Extract assignments from an fcbFlowFrame or fcbFlowSet
#'
#' @param x An fcbFlowFrame or fcbFlowSet that has been assigned.
#' @param platemap Data frame, a lookup table from barcoding levels to well assignments (optional).
#' @param simplify Logical, return factor instead of list (not yet implemented).
#' @return A list of factors, one for each barcoding channel that has been assigned.
#' @export
getAssignments <- function(x, platemap = NULL, simplify = FALSE) {
  getAssignments.ff <- function(x) {
    assignments <- lapply(x@barcodes, `[[`, "assignment")
    assignments <- lapply(assignments, `[[`, "values")
    assignments <- lapply(assignments, as.factor)
  }
  if (inherits(x, "fcbFlowFrame")) {
    assignments <- getAssignments.ff(x)
  } else if (inherits(x, "fcbFlowSet")) {
    assignments <- fsApply(x, getAssignments.ff)
  }
  if (!is.null(platemap)) {
    #return wells instead of levels
  }

  if (simplify) {
    #some sort of unlist operation
  }

  assignments <- assignments[!names(assignments)== "wells"]
  return(assignments)
}
