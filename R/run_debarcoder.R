#' Launch the DebarcodeR Shiny GUI
#'
#' Opens an interactive Shiny application that walks through the DebarcodeR
#' debarcoding pipeline step by step: load data, configure channels, deskew,
#' cluster, assign, and export.
#'
#' @param launch.browser Logical; passed to \code{\link[shiny]{runApp}}.
#'   Default \code{TRUE} opens the app in the system browser.
#' @return Called for its side effect (launches a Shiny app). Returns the
#'   value of \code{\link[shiny]{runApp}} invisibly.
#' @examples
#' if (interactive()) {
#'     run_debarcoder()
#' }
#' @export
run_debarcoder <- function(launch.browser = TRUE) {
    if (!requireNamespace("shiny", quietly = TRUE)) {
        stop("Package 'shiny' is required. Install it with install.packages('shiny').")
    }
    if (!requireNamespace("bslib", quietly = TRUE)) {
        stop("Package 'bslib' is required. Install it with install.packages('bslib').")
    }
    if (!requireNamespace("bsicons", quietly = TRUE)) {
        stop("Package 'bsicons' is required. Install it with install.packages('bsicons').")
    }

    app <- shiny::shinyApp(
        ui = debarcoder_ui(),
        server = debarcoder_server
    )
    shiny::runApp(app, launch.browser = launch.browser)
}


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

debarcoder_ui <- function() {
    bslib::page_sidebar(
        title = "DebarcodeR",
        theme = bslib::bs_theme(version = 5, preset = "shiny"),

        sidebar = bslib::sidebar(
            width = 350,
            bslib::accordion(
                id = "wizard",
                open = "step_load",
                multiple = FALSE,

                # --- Step 1: Load Data ---
                bslib::accordion_panel(
                    title = "1. Load Data",
                    value = "step_load",
                    icon = bsicons::bs_icon("upload"),
                    shiny::fileInput("fcs_file", "Barcoded FCS file",
                        accept = ".fcs"
                    ),
                    shiny::fileInput("std_file",
                        "External standard FCS (optional)",
                        accept = ".fcs"
                    ),
                    shiny::selectInput("is_channel", "Internal standard channel",
                        choices = NULL
                    ),
                    shiny::numericInput("is_threshold",
                        "IS filter threshold",
                        value = 2.5, min = 0, step = 0.1
                    ),
                    shiny::actionButton("btn_load", "Load & Filter",
                        class = "btn-primary w-100"
                    )
                ),

                # --- Step 2: Configure Channels ---
                bslib::accordion_panel(
                    title = "2. Configure Channels",
                    value = "step_config",
                    icon = bsicons::bs_icon("sliders"),
                    shiny::uiOutput("config_ui"),
                    shiny::actionButton("btn_config", "Save Configuration",
                        class = "btn-primary w-100"
                    )
                ),

                # --- Step 3: Deskew ---
                bslib::accordion_panel(
                    title = "3. Deskew",
                    value = "step_deskew",
                    icon = bsicons::bs_icon("bar-chart-steps"),
                    shiny::selectInput("deskew_method", "Method",
                        choices = c("earth", "lm", "knijnenburg"),
                        selected = "earth"
                    ),
                    shiny::numericInput("deskew_subsample", "Subsample",
                        value = 20000, min = 100, step = 1000
                    ),
                    shiny::actionButton("btn_deskew", "Run Deskew",
                        class = "btn-primary w-100"
                    )
                ),

                # --- Step 4: Cluster ---
                bslib::accordion_panel(
                    title = "4. Cluster",
                    value = "step_cluster",
                    icon = bsicons::bs_icon("diagram-3"),
                    shiny::selectInput("cluster_method", "Method",
                        choices = c("mixture", "fisher"),
                        selected = "mixture"
                    ),
                    shiny::conditionalPanel(
                        condition = "input.cluster_method == 'mixture'",
                        shiny::selectInput("cluster_dist", "Distribution",
                            choices = c("Normal", "Skew.normal", "Tdist")
                        )
                    ),
                    shiny::numericInput("cluster_subsample", "Subsample",
                        value = 3000, min = 100, step = 500
                    ),
                    shiny::numericInput("cluster_trim", "Trim",
                        value = 0, min = 0, max = 0.5, step = 0.01
                    ),
                    shiny::actionButton("btn_cluster", "Run Cluster",
                        class = "btn-primary w-100"
                    )
                ),

                # --- Step 5: Assign ---
                bslib::accordion_panel(
                    title = "5. Assign",
                    value = "step_assign",
                    icon = bsicons::bs_icon("check2-square"),
                    shiny::sliderInput("likelihood_cut",
                        "Likelihood cutoff",
                        min = 1, max = 50, value = 8, step = 1
                    ),
                    shiny::sliderInput("ambiguity_cut",
                        "Ambiguity cutoff",
                        min = 0, max = 0.5, value = 0.02, step = 0.01
                    ),
                    shiny::actionButton("btn_assign", "Run Assign",
                        class = "btn-primary w-100"
                    )
                ),

                # --- Step 6: Export ---
                bslib::accordion_panel(
                    title = "6. Export",
                    value = "step_export",
                    icon = bsicons::bs_icon("download"),
                    shiny::textInput("export_prefix", "Filename prefix",
                        value = "debarcoded"
                    ),
                    shiny::downloadButton("btn_download",
                        "Download FCS (zip)",
                        class = "btn-primary w-100"
                    )
                )
            )
        ),

        # --- Main panel ---
        bslib::layout_column_wrap(
            width = 1 / 3,
            fill = FALSE,
            bslib::value_box(
                title = "Cells",
                value = shiny::textOutput("vb_cells"),
                theme = "primary",
                showcase = bsicons::bs_icon("circle-fill")
            ),
            bslib::value_box(
                title = "Assigned",
                value = shiny::textOutput("vb_assigned"),
                theme = "success",
                showcase = bsicons::bs_icon("check-circle")
            ),
            bslib::value_box(
                title = "% Assigned",
                value = shiny::textOutput("vb_pct"),
                theme = "info",
                showcase = bsicons::bs_icon("percent")
            )
        ),
        bslib::navset_card_underline(
            full_screen = TRUE,
            bslib::nav_panel(
                "Scatter Plot",
                shiny::plotOutput("plot_scatter", height = "500px")
            ),
            bslib::nav_panel(
                "Channel Histograms",
                shiny::plotOutput("plot_histograms", height = "500px")
            ),
            bslib::nav_panel(
                "Summary Table",
                shiny::tableOutput("table_summary")
            )
        )
    )
}


# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

debarcoder_server <- function(input, output, session) {
    # Reactive state
    fcb_rv <- shiny::reactiveVal(NULL)
    raw_ff_rv <- shiny::reactiveVal(NULL) # original flowFrame (pre-filter)
    std_rv <- shiny::reactiveVal(NULL)
    step_rv <- shiny::reactiveVal(0L)

    config <- shiny::reactiveValues(
        bc_channels = character(),
        levels = list(),
        predictors = character()
    )

    # --- Helpers ---
    fluorescence_channels <- function(ff) {
        all_names <- flowCore::colnames(ff)
        # Exclude common scatter/time channels
        scatter_pat <- "^(FSC|SSC|Time)"
        all_names[!grepl(scatter_pat, all_names)]
    }

    scatter_channels <- function(ff) {
        all_names <- flowCore::colnames(ff)
        scatter_pat <- "^(FSC|SSC)"
        all_names[grepl(scatter_pat, all_names)]
    }

    # --- Step 1: Load Data ---
    shiny::observeEvent(input$fcs_file, {
        req_file <- input$fcs_file
        ff <- flowCore::read.FCS(req_file$datapath, transformation = FALSE)
        raw_ff_rv(ff)
        fluor <- fluorescence_channels(ff)
        shiny::updateSelectInput(session, "is_channel",
            choices = c("(none)" = "", fluor)
        )
    })

    shiny::observeEvent(input$std_file, {
        req_file <- input$std_file
        std_ff <- flowCore::read.FCS(req_file$datapath, transformation = FALSE)
        std_rv(std_ff)
    })

    shiny::observeEvent(input$btn_load, {
        shiny::req(raw_ff_rv())
        ff <- raw_ff_rv()

        # Apply IS filter if selected
        if (!is.null(input$is_channel) && nzchar(input$is_channel)) {
            is_ch <- input$is_channel
            threshold <- input$is_threshold
            keep <- flowCore::exprs(ff)[, is_ch] > threshold
            ff <- ff[keep, ]
        }

        fcb <- fcbFlowFrame(ff)
        fcb_rv(fcb)
        step_rv(1L)

        # Open next accordion panel
        bslib::accordion_panel_open(
            id = "wizard", values = "step_config"
        )
    })

    # --- Step 2: Configure Channels ---
    output$config_ui <- shiny::renderUI({
        shiny::req(step_rv() >= 1L)
        ff <- fcb_rv()
        fluor <- fluorescence_channels(ff)
        scatter <- scatter_channels(ff)
        all_ch <- flowCore::colnames(ff)

        shiny::tagList(
            shiny::checkboxGroupInput("bc_channels",
                "Barcoding channels",
                choices = fluor
            ),
            shiny::uiOutput("levels_ui"),
            shiny::checkboxGroupInput("pred_channels",
                "Predictor channels (for deskewing)",
                choices = all_ch[all_ch != "Time"],
                selected = intersect(
                    c("FSC-A", "SSC-A"),
                    all_ch
                )
            )
        )
    })

    output$levels_ui <- shiny::renderUI({
        shiny::req(input$bc_channels)
        lapply(input$bc_channels, function(ch) {
            safe_id <- gsub("[^a-zA-Z0-9]", "_", ch)
            shiny::numericInput(
                inputId = paste0("levels_", safe_id),
                label = paste("Levels for", ch),
                value = 6, min = 1, max = 20, step = 1
            )
        })
    })

    shiny::observeEvent(input$btn_config, {
        shiny::req(input$bc_channels)
        config$bc_channels <- input$bc_channels
        config$predictors <- input$pred_channels

        lvls <- list()
        for (ch in input$bc_channels) {
            safe_id <- gsub("[^a-zA-Z0-9]", "_", ch)
            lvls[[ch]] <- input[[paste0("levels_", safe_id)]]
        }
        config$levels <- lvls
        step_rv(2L)

        bslib::accordion_panel_open(
            id = "wizard", values = "step_deskew"
        )
    })

    # --- Step 3: Deskew ---
    shiny::observeEvent(input$btn_deskew, {
        shiny::req(step_rv() >= 2L)
        fcb <- fcb_rv()
        std <- std_rv() # may be NULL

        n_channels <- length(config$bc_channels)
        shiny::withProgress(
            message = "Deskewing...", value = 0,
            {
                for (i in seq_along(config$bc_channels)) {
                    ch <- config$bc_channels[i]
                    shiny::incProgress(
                        amount = 0,
                        detail = paste("Channel:", ch)
                    )

                    progress_cb <- function(detail) {
                        shiny::incProgress(
                            amount = 0,
                            detail = detail
                        )
                    }

                    fcb <- deskew_fcbFlowFrame(
                        fcb,
                        uptake = std,
                        channel = ch,
                        method = input$deskew_method,
                        predictors = config$predictors,
                        subsample = input$deskew_subsample,
                        updateProgress = progress_cb
                    )
                    shiny::incProgress(amount = 1 / n_channels)
                }
            }
        )
        fcb_rv(fcb)
        step_rv(3L)
        bslib::accordion_panel_open(
            id = "wizard", values = "step_cluster"
        )
    })

    # --- Step 4: Cluster ---
    shiny::observeEvent(input$btn_cluster, {
        shiny::req(step_rv() >= 3L)
        fcb <- fcb_rv()

        n_channels <- length(config$bc_channels)
        shiny::withProgress(
            message = "Clustering...", value = 0,
            {
                for (i in seq_along(config$bc_channels)) {
                    ch <- config$bc_channels[i]
                    shiny::incProgress(
                        amount = 0,
                        detail = paste("Channel:", ch)
                    )

                    progress_cb <- function(detail) {
                        shiny::incProgress(
                            amount = 0,
                            detail = detail
                        )
                    }

                    dist_arg <- if (input$cluster_method == "mixture") {
                        input$cluster_dist
                    } else {
                        NULL
                    }

                    fcb <- cluster_fcbFlowFrame(
                        fcb,
                        channel = ch,
                        levels = config$levels[[ch]],
                        opt = input$cluster_method,
                        dist = dist_arg,
                        subsample = input$cluster_subsample,
                        trim = input$cluster_trim,
                        updateProgress = progress_cb
                    )
                    shiny::incProgress(amount = 1 / n_channels)
                }
            }
        )
        fcb_rv(fcb)
        step_rv(4L)
        bslib::accordion_panel_open(
            id = "wizard", values = "step_assign"
        )
    })

    # --- Step 5: Assign ---
    shiny::observeEvent(input$btn_assign, {
        shiny::req(step_rv() >= 4L)
        fcb <- fcb_rv()

        for (ch in config$bc_channels) {
            fcb <- assign_fcbFlowFrame(
                fcb,
                channel = ch,
                likelihoodcut = input$likelihood_cut,
                ambiguitycut = input$ambiguity_cut
            )
        }
        fcb_rv(fcb)
        step_rv(5L)
        bslib::accordion_panel_open(
            id = "wizard", values = "step_export"
        )
    })

    # --- Value Boxes ---
    output$vb_cells <- shiny::renderText({
        fcb <- fcb_rv()
        if (is.null(fcb)) return("--")
        format(nrow(fcb), big.mark = ",")
    })

    output$vb_assigned <- shiny::renderText({
        if (step_rv() < 5L) return("--")
        fcb <- fcb_rv()
        asgn <- getAssignments(fcb)
        # A cell is "assigned" if none of its channel assignments are "0"
        assigned_mask <- Reduce(`&`, lapply(asgn, function(a) a != "0"))
        format(sum(assigned_mask), big.mark = ",")
    })

    output$vb_pct <- shiny::renderText({
        if (step_rv() < 5L) return("--")
        fcb <- fcb_rv()
        asgn <- getAssignments(fcb)
        assigned_mask <- Reduce(`&`, lapply(asgn, function(a) a != "0"))
        pct <- round(100 * sum(assigned_mask) / length(assigned_mask), 1)
        paste0(pct, "%")
    })

    # --- Plots ---
    output$plot_scatter <- shiny::renderPlot({
        fcb <- fcb_rv()
        shiny::req(fcb)

        if (step_rv() >= 5L) {
            # Explicit S3 call — S4 plot,flowFrame-method takes precedence
            plot.fcbFlowFrame(fcb, plot = "assignments")
        } else if (step_rv() >= 3L && length(config$bc_channels) >= 2L) {
            # Post-deskew: scatter of deskewed values
            ch1 <- config$bc_channels[1]
            ch2 <- config$bc_channels[2]
            v1 <- get_barcode_data(fcb, ch1, "deskewing", "values")
            v2 <- get_barcode_data(fcb, ch2, "deskewing", "values")
            df <- data.frame(x = v2, y = v1)
            ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
                ggplot2::geom_bin2d(bins = 150) +
                ggplot2::scale_fill_viridis_c(
                    option = "A", trans = "sqrt", name = "Count"
                ) +
                ggplot2::labs(x = ch2, y = ch1, title = "Deskewed channels") +
                ggplot2::theme_classic()
        } else if (step_rv() >= 1L && length(config$bc_channels) >= 2L) {
            # Pre-deskew: raw scatter
            ch1 <- config$bc_channels[1]
            ch2 <- config$bc_channels[2]
            expr_mat <- flowCore::exprs(fcb)
            df <- data.frame(x = expr_mat[, ch2], y = expr_mat[, ch1])
            ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
                ggplot2::geom_bin2d(bins = 150) +
                ggplot2::scale_fill_viridis_c(
                    option = "A", trans = "sqrt", name = "Count"
                ) +
                ggplot2::labs(x = ch2, y = ch1, title = "Raw channels") +
                ggplot2::theme_classic()
        } else if (step_rv() >= 1L) {
            # Loaded but <2 barcoding channels configured: show first two fluor
            fluor <- fluorescence_channels(fcb)
            if (length(fluor) >= 2L) {
                expr_mat <- flowCore::exprs(fcb)
                df <- data.frame(
                    x = expr_mat[, fluor[2]],
                    y = expr_mat[, fluor[1]]
                )
                ggplot2::ggplot(
                    df,
                    ggplot2::aes(x = .data[["x"]], y = .data[["y"]])
                ) +
                    ggplot2::geom_bin2d(bins = 150) +
                    ggplot2::scale_fill_viridis_c(
                        option = "A", trans = "sqrt", name = "Count"
                    ) +
                    ggplot2::labs(
                        x = fluor[2], y = fluor[1],
                        title = "Raw fluorescence channels"
                    ) +
                    ggplot2::theme_classic()
            }
        }
    })

    output$plot_histograms <- shiny::renderPlot({
        fcb <- fcb_rv()
        shiny::req(fcb)
        shiny::req(step_rv() >= 3L)

        channels <- config$bc_channels
        plots_data <- lapply(channels, function(ch) {
            raw_vals <- flowCore::exprs(fcb)[, ch]
            deskewed_vals <- get_barcode_data(
                fcb, ch, "deskewing", "values"
            )

            df <- rbind(
                data.frame(
                    channel = ch, step = "Before",
                    value = raw_vals
                ),
                data.frame(
                    channel = ch, step = "After",
                    value = deskewed_vals
                )
            )

            if (step_rv() >= 4L) {
                # Add clustering coloring for "After" panel
                probs <- get_barcode_data(
                    fcb, ch, "clustering", "probabilities"
                )
                level <- colnames(probs)[max.col(probs)]
                df$level <- c(
                    rep(NA_character_, length(raw_vals)),
                    level
                )
            } else {
                df$level <- NA_character_
            }
            df
        })

        plot_df <- do.call(rbind, plots_data)
        plot_df$step <- factor(plot_df$step, levels = c("Before", "After"))

        if (step_rv() >= 4L) {
            # Colored by cluster level (After panels)
            after_df <- plot_df[plot_df$step == "After", ]
            before_df <- plot_df[plot_df$step == "Before", ]

            p <- ggplot2::ggplot() +
                ggplot2::geom_histogram(
                    data = before_df,
                    ggplot2::aes(x = .data[["value"]]),
                    bins = 100, fill = "steelblue4", color = NA
                ) +
                ggplot2::geom_histogram(
                    data = after_df,
                    ggplot2::aes(
                        x = .data[["value"]],
                        fill = .data[["level"]]
                    ),
                    bins = 100, color = NA,
                    position = "stack"
                ) +
                ggplot2::facet_grid(
                    channel ~ step, scales = "free"
                ) +
                ggplot2::labs(
                    x = "Intensity", y = "Count",
                    fill = "Level"
                ) +
                ggplot2::theme_classic()
        } else {
            p <- ggplot2::ggplot(
                plot_df,
                ggplot2::aes(x = .data[["value"]])
            ) +
                ggplot2::geom_histogram(
                    bins = 100, fill = "steelblue4", color = NA
                ) +
                ggplot2::facet_grid(
                    channel ~ step, scales = "free"
                ) +
                ggplot2::labs(x = "Intensity", y = "Count") +
                ggplot2::theme_classic()
        }
        p
    })

    # --- Summary Table ---
    output$table_summary <- shiny::renderTable({
        shiny::req(step_rv() >= 5L)
        fcb <- fcb_rv()
        asgn <- getAssignments(fcb)

        # Collapse to well-level labels
        asgn_df <- as.data.frame(asgn)
        well_label <- apply(asgn_df, 1, paste0, collapse = ".")
        well_label[grepl("0", well_label)] <- "Unassigned"

        counts <- as.data.frame(table(well_label), stringsAsFactors = FALSE)
        names(counts) <- c("Well", "Cells")
        counts <- counts[order(counts$Well), ]
        counts
    })

    # --- Export ---
    output$btn_download <- shiny::downloadHandler(
        filename = function() {
            paste0(input$export_prefix, "_debarcoded.zip")
        },
        content = function(file) {
            shiny::req(step_rv() >= 5L)
            fcb <- fcb_rv()
            asgn <- getAssignments(fcb)

            # Split the filtered flowFrame (same length as assignments)
            ff <- methods::as(fcb, "flowFrame")
            debarcoded_fs <- split(ff, asgn)

            tmpdir <- tempfile("debarcoded_")
            dir.create(tmpdir)
            flowCore::write.flowSet(debarcoded_fs, outdir = tmpdir)

            # write.flowSet creates files without .fcs extension
            wd <- getwd()
            on.exit(setwd(wd))
            setwd(tmpdir)
            all_files <- list.files(".", recursive = FALSE)
            # Exclude annotation.txt from zip
            fcs_files <- all_files[all_files != "annotation.txt"]
            utils::zip(file, files = fcs_files)
        },
        contentType = "application/zip"
    )
}
