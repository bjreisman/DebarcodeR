#' Assign cells to barcoding levels
#'
#' Applies likelihood and ambiguity cutoffs to the probability matrix from
#' \code{\link{cluster_fcbFlowFrame}} (or \code{\link{em_optimize}}) to
#' discretely assign each cell to a barcoding level.  Unassigned cells are
#' given a level of 0 rather than being discarded.
#'
#' @param fcbFlowFrame An fcbFlowFrame with completed deskewing and clustering
#'   for the target channel.
#' @param channel The name (string) of the channel to assign, or \code{"wells"}
#'   to assign from the multivariate \code{em_optimize} result.
#' @param likelihoodcut Numeric. Cells less than \code{1/likelihoodcut} as
#'   likely as the most likely cell in their population are left unassigned
#'   (default 8).
#' @param ambiguitycut Numeric between 0 and 1. Cells whose highest population
#'   probability is below \code{1 - ambiguitycut} are left unassigned. E.g.,
#'   \code{0.02} unassigns cells with more than a 2\% chance of belonging to a
#'   different population (default 0.02).
#'
#' @return An fcbFlowFrame with the assignment slot populated for the specified
#'   channel. Assigned level values are stored as a character vector; 0 indicates
#'   unassigned.
#' @seealso \code{\link{cluster_fcbFlowFrame}} for the preceding step,
#'   \code{\link{em_optimize}} for multivariate refinement before assigning
#'   \code{"wells"}, \code{\link{getAssignments}} to extract the result
#' @examples
#' data(jurkatFCB)
#' data(jurkatFCB_std)
#' fcb <- fcbFlowFrame(jurkatFCB)
#' fcb <- deskew_fcbFlowFrame(fcb,
#'     uptake = jurkatFCB_std,
#'     channel = "Pacific Blue-A",
#'     predictors = c("FSC-A", "SSC-A", "APC-H7-A")
#' )
#' fcb <- cluster_fcbFlowFrame(fcb, channel = "Pacific Blue-A", levels = 8)
#' fcb <- assign_fcbFlowFrame(fcb, channel = "Pacific Blue-A")
#' @export
assign_fcbFlowFrame <- function(fcbFlowFrame,
                                channel,
                                likelihoodcut = 8,
                                ambiguitycut = 0.02) {
    assert_fcbFlowFrame(fcbFlowFrame, needs = c("deskewing", "clustering"))

    # Resolve channel name against barcodes slot (which uses original names)
    channel <- resolve_channel(channel, names(fcbFlowFrame@barcodes))
    probs <- get_barcode_data(
        fcbFlowFrame, channel, "clustering", "probabilities"
    )
    if (channel == "wells") {
        wells_clust <- fcbFlowFrame@barcodes[["wells"]][["clustering"]]
        channel <- names(wells_clust$channels)
    }
    probs.norm.row <- calculate.ambiguity(probs)
    probs.norm.col <- calculate.likelihood(probs)

    classif <- rep(0, nrow(fcbFlowFrame))

    if (ncol(probs) > 1) { # if assigning more than one level
        classif <- max.col(probs.norm.row)
    } else { # if assigning only one level
        classif <- rep(1, nrow(probs))
    }

    classif <- colnames(probs)[classif]
    unclass <- paste(rep(0, length(channel)), collapse = ".")

    # Cells with 0 probability of belonging to any population
    classif[which(is.na(classif))] <- unclass
    likely <- probs.norm.col > 1 / likelihoodcut

    if (ncol(probs) > 1) { # if assigning more than one level
        likely.sum <- apply(likely, 1, sum) # converts logical to numeri
        # print(paste0(round(sum(apply(likely, 1, any))/nrow(likely)*100, 3), "% above likelihood cutoff"))
        classif[which(likely.sum < 1)] <- unclass
        non.ambigious <- apply(probs.norm.row, 1, max) > (1 - ambiguitycut)
        classif[which(!non.ambigious)] <- unclass
    } else {
        likely.sum <- as.numeric(likely)
        classif[which(likely.sum != 1)] <- unclass
    }
    if (length(channel) > 1) {
        classif.ls <- data.table::tstrsplit(
            classif, ".", fixed = TRUE,
            names = channel, type.convert = TRUE
        )
        fcbFlowFrame@barcodes[channel] <- mapply(
            function(bc, assignments) {
                bc[["assignment"]][["values"]] <- assignments
                bc[["assignment"]][["ambiguity"]] <- ambiguitycut
                bc[["assignment"]][["likelihood"]] <- likelihoodcut
                return(bc)
            },
            fcbFlowFrame@barcodes[channel],
            classif.ls,
            SIMPLIFY = FALSE
        )
    } else {
        fcbFlowFrame <- set_barcode_data(
            fcbFlowFrame, channel, "assignment",
            list(
                values = classif,
                ambiguity = ambiguitycut,
                likelihood = likelihoodcut
            )
        )
    }
    return(fcbFlowFrame)
}

#' Calculate ambiguity (row-normalize probability matrix)
#'
#' Row-normalizes the probability matrix so each cell's probabilities sum to 1.
#' Used to identify cells that are ambiguously assigned between populations.
#'
#' @param probs A numeric matrix of probabilities (cells x populations).
#' @return The probability matrix normalized by row.
#' @seealso \code{\link{calculate.likelihood}}, \code{\link{assign_fcbFlowFrame}}
#' @keywords internal
calculate.ambiguity <- function(probs) {
    row.sum <- rowSums(probs)
    probs.norm.row <- probs / row.sum
    return(probs.norm.row)
}

#' Calculate likelihood (column-normalize probability matrix)
#'
#' Column-normalizes the probability matrix by dividing each column by its maximum.
#' Used to identify cells in low-density tails of each population.
#'
#' @param probs A numeric matrix of probabilities (cells x populations).
#' @return The probability matrix normalized by column (max = 1 per column).
#' @seealso \code{\link{calculate.ambiguity}}, \code{\link{assign_fcbFlowFrame}}
#' @keywords internal
#' @importFrom matrixStats colMaxs
calculate.likelihood <- function(probs) {
    col.max <- matrixStats::colMaxs(probs)
    probs.norm.col <- t(t(probs) / col.max)
    return(probs.norm.col)
}
