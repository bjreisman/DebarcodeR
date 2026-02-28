#' Multivariate EM optimization of well assignments
#'
#' Refines univariate cluster assignments using a multivariate Gaussian
#' mixture model that accounts for correlations between barcoding channels.
#' Requires that all channels have been deskewed, clustered, and assigned.
#'
#' @param fcbFlowFrame An fcbFlowFrame with completed deskewing, clustering,
#'   and assignment for all barcoding channels.
#' @param modelName Character, mclust model name (default "VEE").
#' @param subsample Numeric, number of cells to subsample during M step (default 50000).
#' @param verbose Logical, print progress messages (default TRUE).
#' @param niter Integer, number of EM iterations (default 1).
#' @param shrinkage Numeric, fraction of simulated data for shrinkage regularization
#'   (default 0.05). Set to 0 to disable.
#' @return An fcbFlowFrame with a \code{"wells"} entry in the barcodes slot
#'   containing multivariate clustering probabilities. Pass \code{"wells"} as
#'   the \code{channel} argument to \code{\link{assign_fcbFlowFrame}} to
#'   convert these probabilities into discrete well assignments.
#' @seealso \code{\link{assign_fcbFlowFrame}} for the assignment step (use
#'   \code{channel = "wells"}), \code{\link{cluster_fcbFlowFrame}} for the
#'   preceding univariate clustering
#' @examples
#' \donttest{
#' # Requires all barcoding channels deskewed, clustered, and assigned
#' # See deskew_fcbFlowFrame(), cluster_fcbFlowFrame(), assign_fcbFlowFrame()
#' fcb <- em_optimize(fcb, niter = 3)
#'
#' # Then assign well labels from the multivariate model
#' fcb <- assign_fcbFlowFrame(fcb, channel = "wells",
#'                            likelihoodcut = 12, ambiguitycut = 0.05)
#' }
#' @export
#' @import mclust
#' @importFrom data.table tstrsplit
em_optimize <- function(fcbFlowFrame,
                        modelName = "VEE",
                        subsample  = 50e3,
                        verbose = TRUE,
                        niter = 1,
                        shrinkage = 0.05) {

  assert_fcbFlowFrame(fcbFlowFrame, needs = c("deskewing", "clustering", "assignment"))
  if (verbose) message("Initializing...")

  barcodes <- fcbFlowFrame@barcodes[!(names(fcbFlowFrame@barcodes) == "wells")]
#  bc_initial.df <- as.data.frame(lapply(lapply(barcodes,`[[`, "assignment"), `[[`, "values"))
  #assigned.ind <- which(!apply(bc_initial.df == 0, 1 ,any))
  deskewed_cols <- as.data.frame(lapply(lapply(barcodes,`[[`, "deskewing"), `[[`, "values"))
  deskewed_models <- lapply(lapply(barcodes,`[[`, "clustering"), `[[`, "model")
  deskewed_probs  <- lapply(lapply(lapply(barcodes,`[[`, "clustering"), `[[`, "probabilities"), as.matrix)
  # as_tibble(x = barcodes$pacific_blue$deskewing$values) %>%
  #   bind_cols(as_tibble(barcodes$pacific_blue_a$clustering$probabilities)) %>%
  #   sample_n(1e3) %>%
  #   gather(cat, prob, -value) %>%
  #   ggplot(aes(x=value, y = prob, col = cat))  +
  #   geom_point()
  deskewed.dims <- lapply(deskewed_probs, ncol)
  deskewed.dims.vec <- as.numeric(deskewed.dims)
  deskewed.rep.mat <- kronecker(deskewed.dims.vec, t(rep(1, length(deskewed.dims.vec))))
  deskewed.rep.mat.each <- deskewed.rep.mat
  deskewed.rep.mat.times  <- deskewed.rep.mat
  deskewed.rep.mat.times[upper.tri(deskewed.rep.mat.times, diag = TRUE)] <- 1
  deskewed.rep.mat.each[lower.tri(deskewed.rep.mat.times, diag = TRUE)] <- 1
  deskewed.reps <- split(cbind(apply(deskewed.rep.mat.each, 2, prod),
                               apply(deskewed.rep.mat.times, 2, prod)),
                         seq(length(deskewed.dims.vec)))
  # deskewed.reps <- list()
  # for (i in seq(length(deskewed.dims.vec))) {
  #   deskewed.reps[[names(deskewed.dims)[i]]][['times']] <- prod(deskewed.dims.vec[seq(length(deskewed.dims.vec)) > i])
  #   deskewed.reps[[names(deskewed.dims)[i]]][['each']] <- prod(deskewed.dims.vec[seq(length(deskewed.dims.vec)) < i])
  # }
  # })
  #

  deskewed_names_expanded <-
    mapply(function(mat, reps) {
      t(rep(1, reps[[1]])) %x% mat %x% t(rep(1, reps[[2]]))
    },
    lapply(lapply(deskewed.dims, seq), `t`),
    deskewed.reps, SIMPLIFY = FALSE)
  deskewed_names_expanded$sep <- "."
  cl.names <- do.call(paste, deskewed_names_expanded)
  deskewed_probs_expanded <-
    mapply(function(mat, reps) {
      t(rep(1, reps[[1]])) %x% mat %x% t(rep(1, reps[[2]]))
    },
    deskewed_probs,
    deskewed.reps, SIMPLIFY = FALSE)
  cl.mat <- do.call('*', deskewed_probs_expanded)
  cl.mat <- cl.mat/rowSums(cl.mat)
  cl.mat[is.na(cl.mat)] <- 0
  n <- round(nrow(deskewed_cols)*shrinkage)
  data.i <- deskewed_cols#[assigned.ind, ]
  # combn()
  #
  # #str((as.matrix(deskewed_probs$pacific_blue_a)) %o% (as.matrix(deskewed_probs$pacific_orange_a)))
  # #x <- 1:9; names(x) <- x
  if (shrinkage > 0) {
    shrinkage.list <- lapply(deskewed_models, function(mod) {
      mixsmsn::rmix(
        n,
        mod$pii,
        family = class(mod),
        arg = split(data.frame(mod[c("mu", "sigma2", "shape", "nu")]), seq(length(mod$pii))),
        cluster = TRUE
      )
    })
    shrinkage.y <- as.data.frame(lapply(shrinkage.list, `[[`, "y"))
    shrinkage.cl <- as.data.frame(lapply(shrinkage.list, `[[`, "cluster"))
    shrinkage.cl.mat <- mclust::unmap(as.factor(apply(shrinkage.cl, 1, paste0, collapse = ".")))
    data.ii <- rbind(data.i, shrinkage.y)
    cl.mat <-
      rbind(cl.mat, shrinkage.cl.mat)
  } else {
    cl.mat <- cl.mat
    data.ii <- data.i
  }
#  nrow(bc_initial.df_assigned)

#  bc_initial.f_assigned <- as.factor(apply(bc_initial.df_assigned, 1, paste0, collapse = "."))

#  cl <- bc_initial.f_assigned
#  cl.mat <- mclust::unmap(bc_initial.f_assigned)

  for (i in seq(niter)) {
    if (verbose) message("EM Round ", i, " of ", niter, "...", appendLF = FALSE)
    ## EM fitting -------------------------------------------------------------
    msEst <- mclust::mstep(modelName = modelName,
                   data = data.ii,
                   z = cl.mat)
    esEst <- mclust::estep(modelName = msEst$modelName[1],
                   data = deskewed_cols,
                   parameters = msEst$parameters)
    if (verbose) message(" loglik: ", round(esEst$loglik))
  #  print(esEst$loglik)
    cl.mat <- esEst$z

    ## shrinkage---------------------------------------------------------------
    if (shrinkage > 0) {
      simdata <- mclust::sim(esEst$modelName[1], esEst$parameters, n)
      colnames(simdata)[-1] <- colnames(deskewed_cols)
      data.ii <- rbind(deskewed_cols, simdata[,-1])
      cl.mat <- rbind(cl.mat, unmap(simdata[,1]))
    } else {
      data.ii <- deskewed_cols
    }
  }
  if (verbose) message("Calculating probabilities...", appendLF = FALSE)

  mvgmm.cdens <- esEst$parameters$pro * cdens(data = deskewed_cols, modelName = esEst$modelName[1], parameters = esEst$parameters) # component densities
  mvgmm.tdens <- dens(data = deskewed_cols, modelName = esEst$modelName[1], parameters = esEst$parameters) # total density
  probs <- mvgmm.cdens/sum(mvgmm.tdens) # density normalized to 1
  colnames(probs) <- cl.names
  # # Assignment------------------------------------------------------------------
  # cl <- apply(probs, 1, which.max)
  # cl <- cl.names[cl]
  #
  # probs.norm.row <- calculate.ambiguity(probs)
  # probs.norm.col <- calculate.likelihood(probs)
  #
  # non.ambigious <- apply(probs.norm.row, 1, max) > (1 - ambiguitycut)
  # cl[!non.ambigious] <- paste0(rep(0, ncol(deskewed_cols)), collapse = ".")
  # likely <- apply(probs.norm.col > 1/likelihoodcut, 1, any)
  # cl[!likely] <- paste0(rep(0, ncol(deskewed_cols)), collapse = ".")
 # new.assignments.l <- data.table::tstrsplit(cl, ".", fixed = TRUE, names = colnames(deskewed_cols), type.convert = T)

#
#   fcbFlowFrame@barcodes <- mapply(function(bc, assignments) {
#     bc[['assignment']][['values']] <- assignments
#     return(bc)
#   },
#   fcbFlowFrame@barcodes,
#   new.assignments.l,
#   SIMPLIFY = FALSE)

  # fcbFlowFrame@barcodes[['wells']][['assignment']][['values']] <- cl
  # fcbFlowFrame@barcodes[['wells']][['assignment']][['ambiguity']] <- ambiguitycut
  # fcbFlowFrame@barcodes[['wells']][['assignment']][['likelihoodcut']] <- likelihoodcut
  #
  #
  # Clustering------------------------------------------------------------------
  fcbFlowFrame@barcodes[['wells']][['clustering']][['probabilities']] <- probs
  fcbFlowFrame@barcodes[['wells']][['clustering']][['channels']] <- deskewed.dims
  fcbFlowFrame@barcodes[['wells']][['clustering']][['model']] <- esEst
  # fcbFlowFrame@barcodes[['wells']][['assignment']][['dims']] <- colnames(bc_initial.df)
  if (verbose) message("Done!")

  return(fcbFlowFrame)
}
