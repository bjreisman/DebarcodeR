#' Compute histogram-based probability matrix from break points
#'
#' Shared helper for the "fisher" and "manual.breaks" clustering methods.
#' Given a vector of values and pre-computed break points, classifies each
#' cell into a level, fits a per-level histogram, and returns a probability
#' matrix (cells x levels).
#'
#' @param vec Numeric vector of deskewed values for all cells.
#' @param breaks Numeric vector of break points (length levels + 1).
#' @param levels Integer, number of barcoding levels.
#' @return A numeric matrix with nrow = length(vec) and ncol = levels.
#' @importFrom graphics hist
#' @keywords internal
compute_histogram_probs <- function(vec, breaks, levels) {
  classif <- unlist(lapply(vec, FUN = function(x) findInterval(x, breaks)))
  classif <- levels + 1 - classif
  classif[classif > levels] <- 0

  vec.split <- split(vec, classif)

  hist.probs <- list()
  for (i in as.character(1:max(as.numeric(names(vec.split))))) {
    myhist <- hist(vec.split[[i]], 100, plot = FALSE)
    binprobs <- myhist$counts / sum(myhist$counts)
    hist.probs.i <- rep(0, times = length(vec))
    bin.assingments <- findInterval(vec, myhist$breaks)
    hist.probs.i[which(bin.assingments != 0)] <- binprobs[bin.assingments]
    hist.probs.i[which(is.na(hist.probs.i))] <- 0
    hist.probs[[i]] <- hist.probs.i
  }
  do.call(cbind, hist.probs)
}

#' Defines populations on barcoded datasets
#'
#'This function allows you to calculate the probability of a cell originating from a given population using
#'either gaussian mixture modeling or jenks natural breaks classification
#'
#' @param fcbFlowFrame An fcbFlowFrame object post deskewing (at least one channel in the barcodes slot).
#' @param channel The name (string) of the channel to be clustered.
#' @param levels Integer, the number of barcoding intensities present in the channel.
#' @param opt String: \code{"mixture"} (default) for Gaussian mixture modeling,
#'   \code{"fisher"} for Fisher-Jenks natural breaks, or \code{"manual.breaks"}
#'   for manually specified breakpoints.
#' @param dist String, one of \code{c("Normal", "Skew.normal", "Tdist")}, passed
#'   to \code{mixsmsn::smsn.mix}. Ignored for \code{opt = "fisher"} and
#'   \code{opt = "manual.breaks"}.
#' @param subsample Integer, number of cells to subsample for model fitting
#'   (default 3000).
#' @param trim Numeric between 0 and 1; trims the upper and lower extremes
#'   to exclude outliers. E.g., \code{trim = 0.01} excludes the most extreme
#'   1\% of cells (default 0).
#' @param ret.model Logical, whether to retain the fitted model (default TRUE).
#' @param manbreaks Numeric vector of length \code{levels + 1} specifying manual
#'   breakpoints; required when \code{opt = "manual.breaks"}.
#' @param updateProgress Callback function used in a Shiny context to report
#'   progress (default NULL).
#'
#' @return An fcbFlowFrame with the clustering slot populated for the specified
#'   channel. The slot contains a probability matrix with \code{nrow = ncells}
#'   and \code{ncol = levels}. For Gaussian mixture modeling, probabilities
#'   reflect each cell's probability of originating from each level under the
#'   fitted distribution. For Jenks/manual breaks, probabilities are estimated
#'   empirically from per-level histograms.
#'
#' @seealso \code{\link{deskew_fcbFlowFrame}} for the preceding pipeline step,
#'   \code{\link{assign_fcbFlowFrame}} for the next pipeline step,
#'   \code{\link{cluster_fcbFlowSet}} to process an entire flowSet
#' @examples
#' \dontrun{
#' # Requires a deskewed fcbFlowFrame — see deskew_fcbFlowFrame()
#' fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Blue-A",   levels = 8)
#' fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Orange-A", levels = 6)
#' fcb
#' }
#' @export
#' @import classInt mixsmsn sn
#' @importFrom stats quantile median

# aspirational --> v2?
# find sd and mean of uptake - use for probabilities
# bounds as 5th and 95th, separation of each level --> find probability
# uptake for two channels - use as model (Prior)
# READ smsn.mix paper and function
cluster_fcbFlowFrame <- function(fcbFlowFrame, #flowFrame FCB, output of deskwe_fcbFlowFrame
                       channel, #channel name (char)
                       levels, #number of levels
                       opt = "mixture", #mixture (guassian mixture models) or fisher (univariate k-means)
                       dist = NULL, #for gaussian mixture models, Skew.normal, normal, T.dist
                       subsample = 3e3,
                       trim = 0,
                       ret.model = TRUE,
                       manbreaks = NULL,
                       updateProgress = NULL){


  assert_fcbFlowFrame(fcbFlowFrame, needs = "deskewing")

  # Resolve channel name against barcodes slot (which uses original names)
  channel <- resolve_channel(channel, names(fcbFlowFrame@barcodes))

  opt_selected <- match.arg(opt, c("mixture", "fisher", "manual.breaks"))
  dist_selected <- match.arg(dist, c("Normal", "Skew.normal", "Tdist"))


  vec <- get_barcode_data(fcbFlowFrame, channel, "deskewing", "values")

  quantiles <- quantile(vec, c(trim/2, 1 - trim/2))
  vec.trim <- vec[quantiles[1] < vec & quantiles[2] > vec]
  vecss <- sample(vec.trim, subsample, replace = TRUE)

  if (opt_selected == "mixture") {

    if (levels > 1) {
      #?classInt::classIntervals
      mod.int <- classInt::classIntervals(vecss, levels, style = "fisher")   #fisher-jenks (breaks in data)
      classif <- sapply(vecss, function(x) pracma::findintervals(x, mod.int$brks))
      classif <- unlist(classif)
      classif <- levels + 1 - classif
      mu.i <- as.numeric(unlist(lapply(split(vecss, classif), median))[-1])
    }
    if (is.function(updateProgress)) {
      updateProgress(detail = "Optimizing Mixture Model")
    }
    Snorm.analysis <- mixsmsn::smsn.mix(vecss, nu = 3,
                                        g = levels,
                                        shape = rep(0, levels),
                                        mu = mu.i,
                                        get.init = TRUE, group = TRUE, family = dist_selected, calc.im = FALSE,
                                        kmeans.param = list(iter.max = 20, n.start = 10, algorithm = "Hartigan-Wong"))   #sigma 2 parameter = mu.i
    loc <- Snorm.analysis$mu
    scale <- sqrt(Snorm.analysis$sigma2)
    shape <- Snorm.analysis$shape
    Snorm.df <- data.frame(loc, scale, shape)
    probs.x <- data.frame(x = vec)
    probs.y <- apply(Snorm.df, 1, function(i) sn::dsn(vec, dp = as.numeric(i)))
    colnames(probs.y) <- as.character(1:nrow(Snorm.df))
    probs <- cbind(probs.x, probs.y)

    if (levels > 1) {
      probs.scaled <- t(t(as.matrix(probs[,-1])) * Snorm.analysis$pii)
      probs.scaled.df <- as.data.frame(t(probs.scaled))[,rev(order(loc))]
    } else {
      probs.scaled <- probs[,-1]
      probs.scaled.df <- as.data.frame(probs.scaled)
    }

  } else if (opt_selected == "fisher") {
    mod.int <- classInt::classIntervals(vecss, levels, style = "fisher")
    probs.scaled <- compute_histogram_probs(vec, mod.int$brks, levels)

  } else if (opt_selected == "manual.breaks") {
    if (is.null(manbreaks)) stop("Please specifiy manual breakpoints")
    if (length(manbreaks) != (levels + 1)) stop("Please ensure breakpoints n+1 breakpoints are provided as a vector")
    probs.scaled <- compute_histogram_probs(vec, manbreaks, levels)
  }

  clustering_data <- list(probabilities = probs.scaled)
  if (ret.model && opt == "mixture") clustering_data$model <- Snorm.analysis
  else if (ret.model && opt == "fisher") clustering_data$model <- mod.int

  fcbFlowFrame <- set_barcode_data(fcbFlowFrame, channel, "clustering", clustering_data)
  return(fcbFlowFrame)
}

# plot as histogram and show fit overlay (Ben has code?)
# overlay gaussian fit on histogram
# look at colored count vs PO plot or count vs PB plot
