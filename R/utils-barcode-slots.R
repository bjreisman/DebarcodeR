# Unexported utility functions for barcode slot management

#' Get data from the barcodes slot
#'
#' Retrieves pipeline results stored in the \code{barcodes} slot of an
#' \code{fcbFlowFrame}. Preferred over direct \code{@@barcodes} access.
#'
#' @param fcbFF An fcbFlowFrame object.
#' @param channel Channel name.
#' @param step Pipeline step: \code{"deskewing"}, \code{"clustering"}, or
#'   \code{"assignment"}.
#' @param field Optional field within the step (e.g., \code{"values"},
#'   \code{"probabilities"}, \code{"model"}).
#' @return The requested data, or \code{NULL} if the field does not exist.
#' @seealso \code{\link{fcbFlowFrame}}, \code{\link{deskew_fcbFlowFrame}},
#'   \code{\link{cluster_fcbFlowFrame}}, \code{\link{assign_fcbFlowFrame}}
#' @examples
#' data(jurkatFCB)
#' fcb <- fcbFlowFrame(jurkatFCB)
#' fcb <- deskew_fcbFlowFrame(fcb,
#'     channel = "Pacific Blue-A",
#'     predictors = c("FSC-A", "SSC-A")
#' )
#' deskewed <- get_barcode_data(fcb, "Pacific Blue-A", "deskewing", "values")
#' head(deskewed)
#' @export
get_barcode_data <- function(fcbFF, channel, step, field = NULL) {
    bc <- fcbFF@barcodes[[channel]]
    if (is.null(bc)) {
        stop(
            "Channel '", channel, "' not found in barcodes slot. ",
            "Available: ", paste(names(fcbFF@barcodes), collapse = ", "),
            call. = FALSE
        )
    }
    data <- bc[[step]]
    if (!is.null(field)) data <- data[[field]]
    data
}

#' Set data in the barcodes slot
#'
#' Creates intermediate list structure as needed. Returns the modified
#' fcbFlowFrame.
#'
#' @param fcbFF An fcbFlowFrame object.
#' @param channel Channel name.
#' @param step Pipeline step: "deskewing", "clustering", or "assignment".
#' @param data The data to store.
#' @return The modified fcbFlowFrame.
#' @keywords internal
set_barcode_data <- function(fcbFF, channel, step, data) {
    if (is.null(fcbFF@barcodes[[channel]])) {
        fcbFF@barcodes[[channel]] <- list()
    }
    fcbFF@barcodes[[channel]][[step]] <- data
    fcbFF
}
