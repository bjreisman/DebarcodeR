#' Corrects morphology based on scatter or uptake control
#'
#' Master function that dispatches to the appropriate morphology correction
#' method (earth, knijnenburg, or lm).
#'
#' @param fcb The barcoded data frame, post compensation and preprocessing.
#' @param uptake Optional: a data frame of cells barcoded with a single level.
#' @param channel The name (string) of the channel to be corrected.
#' @param method The morphology correction method: "earth", "knijnenburg", or "lm".
#' @param predictors Character vector of predictor channel names.
#' @param subsample Integer, number of cells to subsample (default 20000).
#' @param ret.model Logical, whether to retain the fitted model.
#' @param verbose Logical, whether to print progress messages.
#' @param updateProgress Callback for Shiny progress updates.
#' @param ... Additional arguments passed to the correction method.
#' @return A list with corrected values and optionally the fitted model.
#'
#' @keywords internal

#mybarcodedff$barcodes$pacificOrange$deskew

morphology_corr <- function(fcb, #takes a flowframe_fcb
                            uptake = NULL, #get rid of this
                            channel, #channel name (char)
                            method = c("earth", "knijnenburg", "lm"), #default to earth
                            predictors = c('FSC-A', 'SSC-A'), #defaults to FSC/SSC
                            subsample = 20e3,
                            ret.model = TRUE,
                            verbose = FALSE,
                            updateProgress = NULL,
                            ...) {


  #validation of inputs -------------------------
  method_selected <- match.arg(method, c("earth", "knijnenburg", "lm"))

  if (is.null(uptake)) {
    warning("No uptake control provided, using barcoded data to train model,
            `knihnenburg` method may provide best results'")
    uptake <- fcb
  }

  # if (apply_scales == TRUE) {
  #   fcb <- apply_scales(fcb, exp_info)
  #   uptake <- apply_scales(uptake, exp_info)
  # } else if (apply_scales == FALSE){
  #   fcb <- fcb
  #   uptake <- uptake
  # } else{
  #   stop("apply_scales was not TRUE/FALSE")
  # }


  if(method_selected == "earth") {
    fcb2 <- morphology_corr.earth(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      predictors = predictors,
      subsample = subsample,
      ret.model = ret.model,
      updateProgress = updateProgress,
      ...
    )

  } else if(method_selected == "knijnenburg") {
    fcb2 <- morphology_corr.knijnenburg(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      fsc_ssc = predictors,
      subsample = subsample,
      ret.model = ret.model,
      updateProgress = updateProgress,
      ...
    )


  }  else if(method_selected == "lm") {
    fcb2 <- morphology_corr.lm(
      fcb = fcb,
      uptake = uptake,
      channel = channel,
      predictors = predictors,
      slope = 1,
      ret.model = ret.model,
      updateProgress = updateProgress,
      ...
    )

  }

  if(ret.model == TRUE) {
    #print(str(fcb[["model"]]))
    fcb.mod <- fcb2[["model"]]
    fcb2 <- fcb2[["values"]]
   # print(str(fcb.mod))

  }

  # if (apply_scales == TRUE) {
  #   fcb3 <- apply_scales(fcb2, exp_info, inverse = TRUE)
  # } else{
     fcb3 <- fcb2
  #
  # }
  #print(str(fcb3))
  if(ret.model == TRUE){
   # print(99)
    return(list(values = fcb3, #focus on this:
                model = fcb.mod))
  } else{
    return(fcb3)
  }
}

#
# start <- proc.time()
# vec.pb2 <- morphology_corr(fcb = stained,
#                        uptake = uptake,
#                        channel = "pbx8",
#                        method = "knijnenburg",
#                        predictors = c("fsc_a", "ssc_a"),
#                        apply_scales = FALSE)
#
# vec.po2 <- morphology_corr(fcb = stained,
#                            uptake = uptake,
#                            channel = "pox6",
#                            method = "knijnenburg",
#                            predictors = c("fsc_a", "ssc_a"),
#                            apply_scales = FALSE)
#
#
# vec.pb <- morphology_corr(fcb = stained,
#                        uptake = uptake,
#                        channel = "pbx8",
#                        method = "earth",
#                        predictors = c("fsc_a", "ssc_a", "alexa750"),
#                        apply_scales = FALSE)
#
# vec.po <- morphology_corr(fcb = stained,
#                           uptake = uptake,
#                           channel = "pox6",
#                           method = "earth",
#                           predictors = c("fsc_a", "ssc_a", "alexa750"),
#                           apply_scales = FALSE)
# pan3 <- tibble(pb = vec.pb$pbx8, po = vec.po$pox6) %>%
#   #sample_n(200e3) %>%
#   mutate(method = 'earth')
#
# pan2 <- tibble(pb = vec.pb2$pbx8, po = vec.po2$pox6) %>%
#  # sample_n(00e3) %>%
#   mutate(method = 'knijnenburg')
#
# pan1 <- tibble(pb = stained$pbx8, po = stained$pox6) %>%
#   #sample_n(200e3) %>%
#   mutate(method = 'orig')
#
# myplot <- bind_rows(pan1, pan2, pan3)  %>%
#   mutate(method = as.factor(method)) %>%
#   mutate(method = fct_rev(method)) %>%
#   ggplot(aes(x= po, y = pb)) +
#   geom_bin2d(bins = 300, aes(fill = stat(ndensity))) +
#   scale_fill_viridis_c(option = "A") +
# #  scale_fill_distiller(palette = "Spectral") +
#   #geom_point(shape = ".", alpha = 0.2) +
#   scale_x_continuous(limits = c(0,7)) +
#   scale_y_continuous(limits = c(1,8)) +
#   facet_grid(~method) +
#   theme_bw()
# ggsave('20181031progress.png', myplot, width = 9, height = 3, units = "in", dpi = 300)
#
# library(scico)
# myplot <- bind_rows(pan1, pan2, pan3)  %>%
#   mutate(method = as.factor(method)) %>%
#   mutate(method = fct_rev(method)) %>%
#   filter(method == "earth") %>%
#   sample_n(50e3) %>%
#   ggplot(aes(x= po, y = pb)) +
#   stat_density_2d(h = c(0.1, 0.1), n = 1024, geom = "raster",
#                   contour = F, aes(fill = stat(density))) +
#   scale_fill_scico(palette = "oleron", name = "density", trans = "sqrt") +
#   #  scale_fill_distiller(palette = "Spectral") +
#   #geom_point(shape = ".", alpha = 0.2) +
#   scale_x_continuous(limits = c(0,7), expand = c(0,0)) +
#   scale_y_continuous(limits = c(1,8), expand = c(0,0)) +
#   facet_grid(~method) +
#   theme_bw()
#
# #myplot
# ggsave('20181030progress_map.png', myplot, width = 4, height = 3, units = "in", dpi = 300)
# tibble(pb = vec.pb2$pbx8, po = vec.po2$pox6) %>%
#   sample_n(200e3) %>%
#   ggplot(aes(x= po, y = pb)) +
#   geom_point(shape = ".", alpha = 0.2)
#
#
# stained %>%
#   sample_n(200e3) %>%
#   ggplot(aes(x= pox6, y = pbx8)) +
#   geom_point(shape = ".", alpha = 0.2)
# proc.time() - start
#
# hist(vec$pbx8, n = 200)



#' Option selector.
#'
#' @param arg a choice or a vector of choices

