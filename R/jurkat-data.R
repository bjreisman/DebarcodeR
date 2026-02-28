#' 48 Jurkat Samples Barcoded using Fluorescent Cell Barcoding
#'
#' Dataset consisting of 48 Jurkat samples stained with combinations of
#' Pacific Orange (6 levels), Pacific Blue (8 levels), and Alexa Fluor 750
#' (1 level, on channel APC-H7-A) for a total of 48 wells. Samples were
#' acquired as separate FCS files and concatenated into a single file, with
#' \code{row} and \code{col} channels added to record each cell's original
#' sample of origin.
#'
#' @docType data
#' @usage data(jurkatFCB)
#' @format An object of class \code{"flowFrame"} with 24,000 cells and 16
#'   channels; see \code{\link[flowCore]{flowFrame-class}}.
#' @keywords datasets
#' @seealso \code{\link{jurkatFCB_std}} for the companion external standard
#' @references Reisman et al. (2021) \doi{10.1002/cyto.a.24363}
#' @examples
#' data(jurkatFCB)
#' jurkatFCB
"jurkatFCB"

#' External Standard for the jurkatFCB Dataset
#'
#' A single-well subset of \code{\link{jurkatFCB}} (row 1, column 1) intended
#' for use as an external standard (uptake control) in the DebarcodeR tutorial.
#' This population was stained with a single level of each barcoding dye, so it
#' provides a direct measurement of dye uptake per cell unconfounded by
#' multi-level mixing.
#'
#' @docType data
#' @usage data(jurkatFCB_std)
#' @format An object of class \code{"flowFrame"} with 500 cells and 16
#'   channels; see \code{\link[flowCore]{flowFrame-class}}.
#' @keywords datasets
#' @seealso \code{\link{jurkatFCB}} for the full pooled dataset,
#'   \code{\link{deskew_fcbFlowFrame}} for the \code{uptake} parameter that
#'   accepts this object
#' @references Reisman et al. (2021) \doi{10.1002/cyto.a.24363}
#' @examples
#' data(jurkatFCB_std)
#' jurkatFCB_std
"jurkatFCB_std"
