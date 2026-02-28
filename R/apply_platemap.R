#' Apply a plate map to a debarcoded flowSet
#'
#' Joins barcoding level assignments to human-readable well names, updates
#' \code{pData}, and renames each flowFrame to \code{<prefix>_<well>}.
#'
#' @param fcbFlowSet An fcbFlowSet produced by \code{\link[base]{split}}.
#' @param platemap A data.frame mapping barcoding level combinations to well
#'   names.  Must contain a \code{well} column plus one column per barcoding
#'   channel (using cleaned names as produced by \code{janitor::clean_names}).
#' @param drop0 Logical. If \code{TRUE}, drop unassigned (level 0) cells.
#'   Default \code{FALSE} concatenates all unassigned cells into a single
#'   \code{"Unassigned"} flowFrame.
#' @param prefix Character, prefix for output FCS filenames.  If \code{NA}
#'   (default), the prefix is taken from the \code{$FILENAME} keyword in
#'   each FCS file.
#' @return An fcbFlowSet with updated \code{sampleNames} and \code{pData},
#'   where each sample is named \code{<prefix>_<well>}.
#' @seealso \code{\link{getAssignments}} and \code{\link[base]{split}} for
#'   the preceding steps
#' @examples
#' \dontrun{
#' # Build a platemap: Pacific Blue (8 levels) x Pacific Orange (6 levels)
#' myplatemap <- data.frame(
#'   pacific_blue_a   = as.character(rep(1:8, times = 6)),
#'   pacific_orange_a = as.character(rep(1:6, each  = 8)),
#'   well             = paste0(rep(LETTERS[1:8], times = 6),
#'                             formatC(rep(1:6, each = 8), width = 2, flag = "0"))
#' )
#'
#' fcbfs <- apply_platemap(fcbfs, myplatemap, prefix = "Jurkat_FCB")
#' sampleNames(fcbfs)
#' }
#' @import flowCore janitor
#' @importFrom dplyr left_join mutate across everything if_else
#' @export
apply_platemap <- function(fcbFlowSet, platemap, drop0 = FALSE, prefix = NA) {
  if (!inherits(fcbFlowSet, "fcbFlowSet")) {
    stop("Input must be a fcbFlowSet")
  }

  if (!inherits(platemap, "data.frame")) {
    stop("Input must be a data.frame")
  }

  platemap_clean <- janitor::clean_names(platemap)
  platemap_clean <- dplyr::mutate(platemap_clean, across(everything(), as.character))

  pData.orig <- pData(fcbFlowSet)
  suppressMessages({
    pData.new <- left_join(pData.orig, platemap_clean)
  })
  assigned.fs <- fcbFlowSet[!is.na(pData.new$well)]
  if (drop0 == FALSE) {
    unassigned.fs <- fcbFlowSet[is.na(pData.new$well)]
    unassigned.list <- flowSet_to_list(unassigned.fs)
    unassigned.concat <- do.call(rbind, lapply(unassigned.list, exprs))
    unassigned.ff <- unassigned.list[[1]]
    exprs(unassigned.ff) <- unassigned.concat
    out.list <- flowSet_to_list(assigned.fs)
    out.list <- c(out.list, "Unassigned" = unassigned.ff)
    out.fs <- flowSet(out.list)
    suppressMessages({suppressWarnings({
      pData.new <- left_join(pData(out.fs), pData(fcbFlowSet))
      pData.new <- left_join(pData.new, platemap_clean)
      pData.new <- dplyr::mutate(pData.new, well = if_else(is.na(.data$well), "Unassigned", .data$well))
    })})
    rownames(pData.new) <- rownames(pData(out.fs))
    pData(out.fs) <- pData.new
  } else {
    out.fs <- assigned.fs
  }
  if (is.na(prefix)) {
    pData(out.fs)$Prefix <- tools::file_path_sans_ext(unlist(fsApply(out.fs, keyword, "FILENAME")))
  } else {
    pData(out.fs)$Prefix <- prefix
  }
  pData(out.fs)$Filename <- apply(pData(out.fs)[, c("Prefix", "well")], 1, paste0, collapse = "_")
  sampleNames(out.fs) <- pData(out.fs)$Filename
  return(out.fs)
}
