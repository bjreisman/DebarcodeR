#' Assign cells to barcoding levels for a fcbFlowSet
#'
#' @param fcbFlowSet An fcbFlowSet object with deskewing and clustering completed.
#' @param channel The name (string) of the channel that has been corrected and clustered.
#' @param likelihoodcut Numeric, a likelihood cutoff for discarding unlikely cells.
#'   Cells less than 1/k as likely as the most likely cell from that population are unassigned.
#' @param ambiguitycut Numeric from 0 to 1, threshold below which to discard ambiguous cells.
#'   E.g., 0.02 discards cells with more than 2\% chance of originating from another population.
#' @return An fcbFlowSet object with assignment slots populated.
#' @export
assign_fcbFlowSet <- function(fcbFlowSet,
                                channel,
                                likelihoodcut = 8 ,
                                ambiguitycut = 0.02){

  if (!inherits(fcbFlowSet, "fcbFlowSet")) {
    stop("Input must be a fcbFlowSet")
  }

  fcbFlowSet.assigned <- fsApply(fcbFlowSet, assign_fcbFlowFrame,
                                 channel = channel,
                                 likelihoodcut = likelihoodcut,
                                 ambiguitycut = ambiguitycut)

  return(fcbFlowSet(fcbFlowSet.assigned))
}
