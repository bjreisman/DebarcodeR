#' Corrects morphology based on scatter or uptake control for fcbFlowSet
#'
#' Applies \code{\link{deskew_fcbFlowFrame}} to each frame in an fcbFlowSet.
#'
#' @param fcbFlowSet An fcbFlowSet, flowSet, or cytoset object.
#' @param uptake A flowFrame to use as the uptake control (default NULL).
#' @param channel The name (string) of the channel to be corrected.
#' @param method The morphology correction method: "earth" (default), "lm", or "knijnenburg".
#' @param predictors Character vector of channel names for the regression model.
#' @param subsample Integer, number of cells to subsample (default 20000).
#' @param ret.model Logical, whether to retain fitted models (default TRUE).
#' @param verbose Logical, whether to print progress messages (default FALSE).
#' @param updateProgress Callback function for Shiny progress updates (default NULL).
#' @param ... Additional arguments passed to the morphology correction method.
#'
#' @return An fcbFlowSet with barcode slots populated for the specified channel.
#' @seealso \code{\link{deskew_fcbFlowFrame}} for single-frame processing,
#'   \code{\link{cluster_fcbFlowSet}} for the next pipeline step
#' @examples
#' data(jurkatFCB)
#' data(jurkatFCB_std)
#' library(flowCore)
#' fcbfs <- fcbFlowSet(flowSet(list(A = jurkatFCB)))
#' fcbfs <- deskew_fcbFlowSet(
#'   fcbfs,
#'   uptake     = jurkatFCB_std,
#'   channel    = "Pacific Blue-A",
#'   predictors = c("FSC-A", "SSC-A", "APC-H7-A")
#' )
#' @import earth janitor
#' @export

deskew_fcbFlowSet <- function(fcbFlowSet,
                                uptake = NULL,
                                channel,
                                #channel name (char)
                                method = "earth",
                                #default to earth
                                predictors = c('FSC-A', 'SSC-A'),
                                #defaults to fsc/ssc
                                subsample = 20e3,
                                ret.model = TRUE,
                                verbose = FALSE,
                                updateProgress = NULL,
                                ...)
{


  #validation of inputs -------------------------
  if (inherits(fcbFlowSet, "cytoset")) {
    if (!requireNamespace("flowWorkspace", quietly = TRUE))
      stop("Package 'flowWorkspace' is required to convert cytoset objects")
    fcbFlowSet <- flowWorkspace::cytoset_to_flowSet(fcbFlowSet)
  }
  if (inherits(fcbFlowSet, "fcbFlowSet")) {
    # already correct class, proceed
  } else if (inherits(fcbFlowSet, "flowSet")) {
    fcbFlowSet <- fcbFlowSet(fcbFlowSet)
  } else {
    stop("Input must be a flowSet or fcbFlowSet")
  }

  fcbFlowSet.deskewed <- fsApply(fcbFlowSet, deskew_fcbFlowFrame,
          uptake = uptake, channel = channel,
          method = method,
          predictors = predictors,
          subsample = subsample,
          ret.model = ret.model,
          verbose = verbose,
          updateProgress = updateProgress,
          ...)

return(fcbFlowSet(fcbFlowSet.deskewed))
}
