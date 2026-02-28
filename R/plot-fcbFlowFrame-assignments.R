# `level` is a ggplot2 computed variable referenced via after_stat()
utils::globalVariables("level")

#' Plot debarcoding assignments
#'
#' @param x An fcbFlowFrame with completed assignments.
#' @param plot Character, plot type: "assignments" (default), "density", "chull", or "data".
#' @param seed Deprecated; no longer used.
#' @param ... Additional arguments (not used).
#' @return A ggplot2 object.
#' @method plot fcbflowframe
#' @export
#' @import ggplot2 ggnewscale scales ggforce
#' @importFrom grDevices chull
plot.fcbflowframe <- function(x, ..., plot = "assignments", seed = 1) {
  fcbFlowFrame <- x

  if (!inherits(fcbFlowFrame, "fcbFlowFrame")) {
    stop("Input must be a fcbFlowFrame")
  }
  barcodes <- fcbFlowFrame@barcodes[!(names(fcbFlowFrame@barcodes) == "wells")]
  deskewed <- as.data.frame(lapply(barcodes, function(bc) bc[['deskewing']][['values']]))
  assignment <- as.data.frame(lapply(barcodes, function(bc) bc[['assignment']][['values']]))
  assignment <- apply(assignment, 1, paste0, collapse = ".")
  assignment[grepl(0, assignment)] <- "0.0"
  assignment[grepl("0", assignment)] <- "0.0"
  mypal <- hue_pal()(length(table(assignment)) - 1)
  mypal <- c("grey50", mypal)
  mydata <- cbind(deskewed, assignment = assignment)
  mydata.assigned <- mydata[mydata$assignment != "0.0",]

  y_var <- colnames(deskewed)[1]
  x_var <- colnames(deskewed)[2]

  if (plot == 'data') {
    myplot <- mydata.assigned
  }
  if (plot == "assignments") {

    myplot <- ggplot(mydata,
      aes(
        y = .data[[y_var]],
        x = .data[[x_var]],
        col  = .data[["assignment"]]
      )
    ) +
      geom_point(shape = ".") +
      scale_color_manual(values = mypal)
  } else if (plot == 'density') {
    myplot <- ggplot(
      mydata,
      aes(
        y = .data[[y_var]],
        x = .data[[x_var]]
      )
    ) +
      geom_point(shape = ".", color = "grey30") +
      stat_density_2d(aes(fill = .data[["assignment"]], alpha = after_stat(level)),
                      data = mydata.assigned,
                      geom = "polygon", color = NA, bins = 8) +
      scale_fill_manual(values = mypal[-1])

  } else if (plot == 'chull') {
    mydata.chull <- mydata.assigned |>
      dplyr::group_by(.data[["assignment"]]) |>
      dplyr::slice(chull(.data[[y_var]], .data[[x_var]]))

    myplot <- ggplot(
      mydata,
      aes(
        y = .data[[y_var]],
        x = .data[[x_var]]
      )
    ) +
    geom_point(shape = ".", color = "grey30") +
      geom_shape(data = mydata.chull, aes(fill = .data[["assignment"]]),
                 expand = unit(0.25, "mm"),
                 radius = unit(1, 'mm'), alpha = 0.25) +
      scale_fill_manual(values = mypal[-1])
  }

  return(myplot)
  }
