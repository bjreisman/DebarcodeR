#' Corrects morphology based on scatter or uptake control for fcbFlowFrame
#'
#' @param fcbFlowFrame An fcbFlowFrame, flowFrame, or cytoframe object, post compensation and preprocessing.
#' @param uptake A flowFrame or cytoframe to use as the uptake (external standard) control.
#'   If NULL (default), the barcoded sample itself is used.
#' @param channel The name (string) of the channel to be corrected (use original column name, e.g. "Pacific Blue-A").
#' @param method The morphology correction method: "earth" (default), "lm", or "knijnenburg".
#' @param predictors Character vector of channel names for the regression model.
#' @param subsample Integer, number of cells to subsample for model fitting (default 20000).
#' @param ret.model Logical, whether to retain the fitted model (default TRUE).
#' @param verbose Logical, whether to print progress messages (default FALSE).
#' @param updateProgress Callback function for Shiny progress updates (default NULL).
#' @param ... Additional arguments passed to the morphology correction method.
#'
#' @return An fcbFlowFrame with barcode slot populated for the specified channel.
#' @seealso \code{\link{cluster_fcbFlowFrame}} for the next pipeline step,
#'   \code{\link{deskew_fcbFlowSet}} to process an entire flowSet,
#'   \code{\link{morphology_corr.earth}} for details on the default method
#' @examples
#' \donttest{
#' data(jurkatFCB)
#' data(jurkatFCB_std)  # pre-extracted single-well uptake control
#'
#' # Deskew — APC-H7-A is the internal standard dye channel
#' fcb <- fcbFlowFrame(jurkatFCB)
#' fcb <- deskew_fcbFlowFrame(
#'   fcb,
#'   uptake     = jurkatFCB_std,
#'   channel    = "Pacific Blue-A",
#'   predictors = c("FSC-A", "SSC-A", "APC-H7-A")
#' )
#' fcb
#' }
#' @import earth janitor
#' @export

deskew_fcbFlowFrame <- function(fcbFlowFrame,
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
  if (inherits(fcbFlowFrame, "cytoframe") || inherits(fcbFlowFrame, "flowFrame")) {
    fcbFlowFrame <- coerce_to_flowFrame(fcbFlowFrame)
  }
  if (inherits(fcbFlowFrame, "fcbFlowFrame")) {
    # already correct class, proceed
  } else if (inherits(fcbFlowFrame, "flowFrame")) {
    fcbFlowFrame <- fcbFlowFrame(fcbFlowFrame)
  } else {
    stop("Input must be a flowFrame, cytoframe, or fcbFlowFrame")
  }


  method_selected <- match.arg(method, c("earth", "knijnenburg", "lm"))

  # Resolve channel and predictor names against actual flowFrame columns
  valid_names <- colnames(fcbFlowFrame)
  channel <- resolve_channel(channel, valid_names)
  predictors <- resolve_channels(predictors, valid_names)

  if (is.null(uptake)) {
    uptake <- fcbFlowFrame
    if (method != 'knijnenburg') {
      warning("Barcoded sample being used as uptake control, ",
              "`knijnenburg` method may provide best results")
    }
  }


  # fcb sample extracted
  fcb <- as.data.frame(exprs(fcbFlowFrame))
  # uptake sample extracted
  uptake <- coerce_to_flowFrame(uptake, arg_name = "Uptake control")
  uptake <- as.data.frame(exprs(uptake))

  # earth model
  if (method_selected == "earth") {
    fcb2 <- morphology_corr.earth(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      predictors = predictors,
      subsample = subsample,
      ret.model = ret.model,
      updateProgress = updateProgress,
      ...
    )

    # knijnenburg model
  } else if (method_selected == "knijnenburg") {
    fcb2 <- morphology_corr.knijnenburg(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      fsc_ssc = predictors,
      subsample = subsample,
      ret.model = ret.model,
      updateProgress = updateProgress
    )

    # linear model
  }  else if (method_selected == "lm") {
    fcb2 <- morphology_corr.lm(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      predictors = predictors,
      ret.model = ret.model,
      slope = 1,
      updateProgress = updateProgress
    )
  }

  fcbFlowFrame <- set_barcode_data(fcbFlowFrame, channel, "deskewing", fcb2)

  return(fcbFlowFrame)
}


