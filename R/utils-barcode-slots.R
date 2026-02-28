# Unexported utility functions for barcode slot management

#' Get data from the barcodes slot
#'
#' @param fcbFF An fcbFlowFrame object.
#' @param channel Channel name.
#' @param step Pipeline step: "deskewing", "clustering", or "assignment".
#' @param field Optional field within the step (e.g., "values", "probabilities", "model").
#' @return The requested data.
#' @keywords internal
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
