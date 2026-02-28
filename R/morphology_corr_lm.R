#' Morphology correction using linear model
#'
#' Simple linear regression approach for morphology correction.
#'
#' @param fcb The barcoded data frame.
#' @param uptake Data frame of uptake control cells.
#' @param channel The channel name to correct.
#' @param predictors A single predictor channel name.
#' @param subsample Integer, cells to subsample (default 10000).
#' @param slope Numeric, fixed slope for regression (default 1).
#' @param updateProgress Callback for Shiny progress updates.
#' @param ret.model Logical, retain the fitted model (default FALSE).
#' @return A list with corrected values and optionally the fitted model.
#' @importFrom stats as.formula lm median
#' @export

morphology_corr.lm <- function(fcb,
                               uptake,
                               channel,
                               predictors = NULL,
                               subsample = 10e3,
                               slope = 1,
                               updateProgress = NULL,
                               ret.model = FALSE) {

  if(length(predictors) != 1){
    stop('Please select a single predictor')}

  if(is.null(slope)){
    lm.formula <- as.formula(paste0("`", channel, "` ~ `", predictors, "`"))
  } else {
    lm.formula <- as.formula(paste0("`", channel,
                                    "` ~ 1 + offset(",
                                    slope, "*`",
                                    predictors, "`)"))
  }
  lm.model <- lm(lm.formula, data = uptake)
  fcb[,channel]<- fcb[,channel] - predict(lm.model, newdata = fcb) +   median(unlist(fcb[,channel]))

  if(ret.model == FALSE){
    return(list(values = fcb[,channel]))
  } else{
    return(list(values = fcb[,channel],
                model = lm.model))
  }
}
