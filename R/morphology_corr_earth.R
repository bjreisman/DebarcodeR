#' Morphology correction using MARS (earth)
#'
#' Corrects morphology using multivariate adaptive regression splines
#' as implemented in the earth package.
#'
#' @param fcb The barcoded data frame.
#' @param uptake Data frame of uptake control cells.
#' @param ret.model Logical, retain the fitted model (default FALSE).
#' @param what Character, what to return: "x" for corrected values only,
#'   "x + se" to also include standard errors.
#' @param nfold Integer, number of cross-validation folds (default 1).
#' @param ncross Integer, number of cross-validation repeats (default 0).
#' @param channel The channel name to correct.
#' @param predictors Character vector of predictor channel names.
#' @param subsample Integer, number of cells to subsample (default 30000).
#' @param updateProgress Callback for Shiny progress updates.
#' @param ... Additional arguments passed to \code{earth::earth}.
#' @return A list with corrected values and optionally the fitted model.
#' @import earth
#' @export

morphology_corr.earth <- function(fcb,
                                  uptake,
                                  ret.model = FALSE,
                                  what = c('x', 'x + se'),
                                  nfold = 1,
                                  ncross = 0,
                                  channel,
                                  predictors = c('FSC-A', 'SSC-A'),
                                  subsample = 30e3,
                                  updateProgress = NULL,
                                  ...) {
  what.options <- c("x", "x + se")
  what <- match.arg1(what, what.options)

  if (is.function(updateProgress)) {
    updateProgress(detail = "Training adaptive splines...")}

  lhs <- paste0("`", predictors, "`", collapse = " + ")
  earth.formula <- paste(channel, '~', lhs)
  if(what == "x"){
    earth.model <- earth(as.formula(earth.formula),
                         degree = 2,
                         nprune = 21,
                         nfold = nfold,
                         ncross = ncross,
                         keepxy = TRUE,
                         data = uptake,
                         ...)

    if (is.function(updateProgress)) {
      updateProgress(detail = "Fitting fcb data...")}
    fcb[,channel] <- fcb[,channel] - predict(earth.model, fcb) + median(unlist(uptake[,channel]))

  } else if(what == "x + se") {
    earth.model <- earth(as.formula(earth.formula),
                         degree = 2,
                         nprune = 21,
                         nfold = nfold,
                         ncross = ncross,
                         keepxy = TRUE,
                         varmod.method = "x.earth",
                         data = uptake,
                         trace = 0.3)

    fcb[,channel] <- fcb[,channel] - predict(earth.model, fcb) + median(unlist(uptake[,channel]))
    fcb[,paste0(channel,"se")]<- predict(earth.model, newdata = fcb, interval = "se")
  }

  if(ret.model == FALSE){
    return(list(values = as.numeric(fcb[,channel])))
  } else{
    return(list(values = as.numeric(fcb[,channel]),
                model = earth.model))
  }
}


