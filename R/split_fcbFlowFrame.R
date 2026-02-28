#' Split an fcbFlowFrame into an fcbFlowSet by assignments
#'
#' Splits an fcbFlowFrame into separate flowFrames based on barcode
#' assignments, returned as an fcbFlowSet with updated pData.
#'
#' @param x An fcbFlowFrame object with completed assignments.
#' @param f A list of assignment factors (from \code{\link{getAssignments}}).
#' @param drop Not used.
#' @param prefix Not used.
#' @param flowSet Logical, whether to return a flowSet (default TRUE).
#' @param merge.na Not used.
#' @param ... Additional arguments (not used).
#' @return An fcbFlowSet with each flowFrame named by assignment level.
#' @import flowCore
#' @export
setMethod("split",
          signature = c(x = "fcbFlowFrame",
                        f = "list"),
          definition = function(x,
                                f,
                                drop = FALSE,
                                prefix = NULL,
                                flowSet = TRUE,
                                merge.na = TRUE,
                                ...) {

            # based off of the standard flowCore split method with some fine tuning
            f.df <- as.data.frame(f)
            ##FIX ME: add check to make sure none of the factor levels have a "." in them
            f.collapsed <- as.factor(apply(f.df, 1, paste0, collapse = "."))
            x <- as(x, "flowFrame")
            x.split <- split(x, as.factor(f.collapsed), flowSet = flowSet)
            if (flowSet) {
              #update pData with barcoding levels
              pData.orig <- pData(x.split)
              pData.new <- as.data.frame(do.call(rbind, strsplit(pData.orig$name, "\\.")))
              colnames(pData.new) <- colnames(f.df)
              rownames(pData.new) <- rownames(pData.orig)
              pData(x.split) <- pData.new
            }

            return(fcbFlowSet(x.split))
          }
)

#' Split an fcbFlowSet by assignments
#'
#' @param x An fcbFlowSet object.
#' @param f A list of assignment factors per sample.
#' @param assign0 Logical, whether to assign level 0 cells (default FALSE).
#' @param drop Not used.
#' @param prefix Not used.
#' @param flowSet Logical, whether to return a flowSet (default TRUE).
#' @param merge.na Not used.
#' @param ... Additional arguments (not used).
#' @return An fcbFlowSet with each flowFrame named by the assignments.
#' @import flowCore
#' @importFrom dplyr left_join
#' @export
setMethod("split",
          signature = c(x = "fcbFlowSet",
                        f = "list"),
          definition = function(x,
                                f,
                                assign0 = FALSE,
                                drop = FALSE,
                                prefix = NULL,
                                flowSet = TRUE,
                                merge.na = TRUE,
                                ...) {
            x.list <- fsApply(x, function(x) x, simplify = FALSE) #list of flowFrames
            if (!assign0) {
              f0 <- f[["0"]]
              f[["0"]] <- lapply(f0, function(x) rep(0, length(x)))
            }

            split(x.list[[3]], f[[3]])
            x.split <- mapply(split, x.list, f, flowSet = TRUE, SIMPLIFY = FALSE) #split by assignments
            x.split <- lapply(x.split, flowSet_to_list)
            x.split <- unlist(x.split) #flatten into a single list
            new.cols <- lapply(f, names)[[1]] #factor names from the newly split levels
            if (flowSet) {
              x.split <- flowSet(x.split) #convert to flowset
              #update pData with barcoding levels
              pData.orig <- pData(x.split)
              pData.new <- as.data.frame(do.call(rbind, strsplit(pData.orig$name, "\\.")))
              colnames(pData.new) <- c("name", new.cols)
              pData.new <- left_join(pData.new, pData(x))
              rownames(pData.new) <- rownames(pData.orig)
              pData.new$name <- rownames(pData.new)
              pData(x.split) <- pData.new
            }
            return(fcbFlowSet(x.split))
          }
)


#' Split a flowFrame by a list of factors
#'
#' @param x A flowFrame object.
#' @param f A list of factors for splitting.
#' @param drop Not used.
#' @param prefix Not used.
#' @param flowSet Logical, whether to return a flowSet (default TRUE).
#' @param merge.na Not used.
#' @param ... Additional arguments (not used).
#' @return An fcbFlowSet with each flowFrame named by the combined factor levels.
#' @import flowCore
#' @export
setMethod("split",
          signature = c(x = "flowFrame",
                        f = "list"),
          definition = function(x,
                                f,
                                drop = FALSE,
                                prefix = NULL,
                                flowSet = TRUE,
                                merge.na = TRUE,
                                ...) {

            # based off of the standard flowCore split method with some fine tuning
            f.df <- as.data.frame(f)
            ##FIX ME: add check to make sure none of the factor levels have a "." in them
            f.collapsed <- as.factor(apply(f.df, 1, paste0, collapse = "."))
            x <- as(x, "flowFrame")
            x.split <- split(x, as.factor(f.collapsed), flowSet = flowSet)
            if (flowSet) {
              #update pData with barcoding levels
              pData.orig <- pData(x.split)
              pData.new <- as.data.frame(do.call(rbind, strsplit(pData.orig$name, "\\.")))
              colnames(pData.new) <- colnames(f.df)
              rownames(pData.new) <- rownames(pData.orig)
              pData(x.split) <- pData.new
            }

            return(fcbFlowSet(x.split))
          }
)
