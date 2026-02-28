#' Defines populations on barcoded datasets
#'
#' @param fcbFlowFrame a fcbFlowFrame object with barcoded flowframe and uptake flowframe post deskewing
#' and clustering \(at least one barcodes slot filled\)
#' @param channel The name \(string\) of the channel that has been corrected and clustered
#' @param likelihoodcut numeric, a likelihood cutoff for discarding unlikely cells, less than 1/k as likely
#' as the most likely cell from that population
#' @param ambiguitycut numeric from 0 to 1, threshhold below which to discard ambigious cells, eg: 0.02,
#'  discards cells with more than 2\% chance of originating from another population

#' @return a fcbFlowFrame object with a barcode slot filled with deskewing, clustering, cell assignment as
#' a vector of integers from 0:ncol\(probs\), cells assigned a classification of 0 remained unassigned,
#' otherwise number corresponds to the barcoding level assignment of that cell
#' @export
assign_fcbFlowFrame <- function(fcbFlowFrame,
                                channel,
                                likelihoodcut = 8 ,
                                ambiguitycut = 0.02) {

  assert_fcbFlowFrame(fcbFlowFrame, needs = c("deskewing", "clustering"))

  # Resolve channel name against barcodes slot (which uses original names)
  channel <- resolve_channel(channel, names(fcbFlowFrame@barcodes))
  probs <- get_barcode_data(fcbFlowFrame, channel, "clustering", "probabilities")
  if (channel == "wells") {
    channel <- names(fcbFlowFrame@barcodes[['wells']][['clustering']]$channels)
  }
  probs.norm.row <- calculate.ambiguity(probs)
  probs.norm.col <- calculate.likelihood(probs)

  classif <- rep(0, nrow(fcbFlowFrame))

  if (ncol(probs) > 1) { # if assigning more than one level
    classif <- max.col(probs.norm.row)
  } else {# if assigning only one level
    classif <- rep(1, nrow(probs))
  }

    classif <- colnames(probs)[classif]
    unclass <- paste(rep(0, length(channel)), collapse = ".")

    classif[which(is.na(classif))] <- unclass #catches the few cells with 0 probability of belonging to any pop
    likely <- probs.norm.col > 1/likelihoodcut

  if (ncol(probs) > 1) { # if assigning more than one level
    likely.sum <- apply(likely, 1, sum) #converts logical to numeri
   # print(paste0(round(sum(apply(likely, 1, any))/nrow(likely)*100, 3), "% above likelihood cutoff"))
    classif[which(likely.sum < 1)] <- unclass
    non.ambigious <- apply(probs.norm.row, 1, max) > (1 - ambiguitycut)
    classif[which(!non.ambigious)] <- unclass
  } else {
    likely.sum <- as.numeric(likely)
    classif[which(likely.sum != 1)] <- unclass
  }
  if (length(channel) > 1) {
    classif.ls <- data.table::tstrsplit(classif, ".", fixed = TRUE, names = channel, type.convert = T)
    fcbFlowFrame@barcodes[channel] <- mapply(function(bc, assignments) {
      bc[['assignment']][['values']] <- assignments
      bc[['assignment']][['ambiguity']] <- ambiguitycut
      bc[['assignment']][['likelihood']] <- likelihoodcut
      return(bc)
    },
    fcbFlowFrame@barcodes[channel],
    classif.ls,
    SIMPLIFY = FALSE)
  } else {
    fcbFlowFrame <- set_barcode_data(fcbFlowFrame, channel, "assignment",
                                     list(values = classif,
                                          ambiguity = ambiguitycut,
                                          likelihood = likelihoodcut))
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
#' @export
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
#' @export
#' @importFrom matrixStats colMaxs
calculate.likelihood <- function(probs) {
  col.max <- matrixStats::colMaxs(probs)
  probs.norm.col <- t(t(probs) / col.max)
  return(probs.norm.col)
}

