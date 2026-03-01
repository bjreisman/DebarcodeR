#' Defines populations on barcoded datasets
#'
#' This function allows you to calculate the probability of a cell originating from a given population using
#' either gaussian mixture modeling or jenks natural breaks classification
#'
#' @param fcbFlowSet An fcbFlowSet object post deskewing (at least one channel in the barcodes slot).
#' @param channel The name (string) of the channel to be clustered.
#' @param levels Integer, the number of barcoding intensities present in the channel.
#' @param opt String: \code{"mixture"} (default) for Gaussian mixture modeling,
#'   or \code{"fisher"} for Fisher-Jenks natural breaks.
#' @param dist String, one of \code{c("Normal", "Skew.normal", "Tdist")}, passed
#'   to \code{mixsmsn::smsn.mix}. Ignored for \code{opt = "fisher"}.
#' @param subsample Integer, number of cells to subsample for model fitting
#'   (default 10000).
#' @param trim Numeric between 0 and 1; trims the upper and lower extremes
#'   to exclude outliers (default 0).
#' @param ret.model Logical, whether to retain the fitted model (default TRUE).
#' @param updateProgress Callback function used in a Shiny context to report
#'   progress (default NULL).
#'
#' @return An fcbFlowSet with clustering slots populated for all frames.
#'
#' @examples
#' data(jurkatFCB)
#' data(jurkatFCB_std)
#' library(flowCore)
#' fcbfs <- fcbFlowSet(flowSet(list(A = jurkatFCB)))
#' fcbfs <- deskew_fcbFlowSet(fcbfs,
#'     uptake = jurkatFCB_std,
#'     channel = "Pacific Blue-A",
#'     predictors = c("FSC-A", "SSC-A", "APC-H7-A")
#' )
#' fcbfs <- cluster_fcbFlowSet(fcbfs,
#'     channel = "Pacific Blue-A",
#'     levels = 8, opt = "fisher"
#' )
#' @seealso \code{\link{cluster_fcbFlowFrame}} for single-frame processing,
#'   \code{\link{deskew_fcbFlowSet}} for the preceding step,
#'   \code{\link{assign_fcbFlowSet}} for the next step
#' @export
#' @import classInt mixsmsn sn

# aspirational --> v2?
# find sd and mean of uptake - use for probabilities
# bounds as 5th and 95th, separation of each level --> find probability
# uptake for two channels - use as model (Prior)
# READ smsn.mix paper and function

cluster_fcbFlowSet <- function(fcbFlowSet, # flowFrame FCB, output of deskwe_fcbFlowFrame
                               channel, # channel name (char)
                               levels, # number of levels
                               opt = "mixture", # mixture (guassian mixture models) or fisher (univariate k-means)
                               dist = NULL, # for gaussian mixture models, Skew.normal, normal, T.dist
                               subsample = 10e3,
                               trim = 0,
                               ret.model = TRUE,
                               updateProgress = NULL) {
    # validation of inputs -------------------------
    if (!inherits(fcbFlowSet, "fcbFlowSet")) {
        stop("Input must be a fcbFlowSet")
    }

    fcbFlowSet.clustered <- fsApply(fcbFlowSet, cluster_fcbFlowFrame,
        channel = channel,
        levels = levels,
        opt = opt,
        dist = dist,
        subsample = subsample,
        trim = trim,
        ret.model = ret.model,
        updateProgress = updateProgress
    )

    return(fcbFlowSet(fcbFlowSet.clustered))
}

# plot as histogram and show fit overlay (Ben has code?)
# overlay gaussian fit on histogram
# look at colored count vs PO plot or count vs PB plot
