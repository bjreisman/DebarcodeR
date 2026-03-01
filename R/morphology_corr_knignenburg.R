#' Morphology correction using Knijnenburg constrained regression
#'
#' Implements the constrained regression approach from Knijnenburg et al. (2011).
#'
#' @param fcb The barcoded data frame.
#' @param uptake Data frame of uptake control cells.
#' @param channel The channel name to correct.
#' @param fsc_ssc Named character vector with FSC and SSC channel names.
#' @param subsample Integer, cells to subsample (default 10000).
#' @param updateProgress Callback for Shiny progress updates.
#' @param ret.model Logical, retain the fitted model (default FALSE).
#' @return A list with corrected values and optionally the fitted model.
#'
#' @seealso \code{\link{selectDenseScatterArea}} \code{\link{doRegressConstrained}}
#' @keywords internal

morphology_corr.knijnenburg <- function(fcb,
                                        uptake,
                                        channel,
                                        fsc_ssc = c(fsc = "FSC-A", ssc = "SSC-A"),
                                        subsample = 10e3,
                                        updateProgress = NULL,
                                        ret.model = FALSE) {
    if (is.function(updateProgress)) {
        updateProgress(detail = "Mapping cellular Density")
    }

    area_density <- selectDenseScatterArea(uptake,
        subsample = subsample,
        fsc_ssc = fsc_ssc
    )


    if (is.function(updateProgress)) {
        updateProgress(detail = "Performing Morphology Correction")
    }
    regression.output <- doRegressConstrained(
        uptake,
        fcb,
        fsc_ssc = fsc_ssc,
        Loc = area_density$loc,
        weight = area_density$c,
        trans = "none",
        columns = c(channel),
        monodir = c(1, 1)
    )
    cor.data <- regression.output[[1]]
    fcb[, channel] <- cor.data[, channel]

    if (ret.model == FALSE) {
        return(list(values = fcb[, channel]))
    } else {
        return(list(
            values = fcb[, channel],
            model = regression.output
        ))
    }
}
