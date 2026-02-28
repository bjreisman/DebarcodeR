#' Extract assignments from an fcbFlowFrame or fcbFlowSet
#'
#' Returns the discrete cell-level assignments as a named list of factors,
#' one per barcoding channel.  The result is suitable for passing directly
#' to \code{\link{split}} to generate one flowFrame per barcode combination.
#'
#' @param x An fcbFlowFrame or fcbFlowSet that has been assigned.
#' @param platemap Data frame, a lookup table from barcoding levels to well
#'   assignments (optional; not yet implemented).
#' @param simplify Logical, return a single factor rather than a list
#'   (not yet implemented; default FALSE).
#' @return A named list of factors, one per barcoding channel that has been
#'   assigned.  The \code{"wells"} entry (from \code{\link{em_optimize}}) is
#'   excluded — use \code{channel = "wells"} in \code{assign_fcbFlowFrame}
#'   to include multivariate well labels.
#' @seealso \code{\link{assign_fcbFlowFrame}} to generate assignments,
#'   \code{\link[base]{split}} to split data by the returned factors,
#'   \code{\link{apply_platemap}} to map level combinations to well names
#' @examples
#' \dontrun{
#' # After all pipeline steps are complete:
#' assignments <- getAssignments(fcb)
#' # assignments is a named list of factors, e.g.:
#' # $`Pacific Blue-A`   : factor with levels 0..8
#' # $`Pacific Orange-A` : factor with levels 0..6
#' fcbfs <- split(fcb, assignments)
#' }
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
