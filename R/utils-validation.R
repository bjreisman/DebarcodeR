# Unexported utility functions for input validation and channel name resolution

#' Resolve a channel name against a flowFrame's column names
#'
#' If the name matches a column directly, returns it. If not, attempts to match
#' it as a janitor-cleaned name and returns the original with a deprecation
#' warning. Errors if no match is found.
#'
#' @param name Character, the channel name to resolve.
#' @param valid_names Character vector of valid column names (from the flowFrame).
#' @return The resolved channel name (original form).
#' @keywords internal
resolve_channel <- function(name, valid_names) {
    if (name %in% valid_names) {
        return(name)
    }

    # Try matching as a cleaned name
    cleaned <- janitor::make_clean_names(valid_names)
    match_idx <- match(name, cleaned)
    if (!is.na(match_idx)) {
        original <- valid_names[match_idx]
        warning(
            "Cleaned channel name '", name, "' matched to '", original, "'. ",
            "Use original column names directly -- cleaned names are deprecated.",
            call. = FALSE
        )
        return(original)
    }

    stop(
        "Channel '", name, "' not found. Available channels: ",
        paste(valid_names, collapse = ", "),
        call. = FALSE
    )
}

#' Resolve multiple channel names (e.g., predictors)
#'
#' @param names Character vector of channel names to resolve.
#' @param valid_names Character vector of valid column names.
#' @return Character vector of resolved names.
#' @keywords internal
resolve_channels <- function(names, valid_names) {
    vapply(names, resolve_channel, character(1),
        valid_names = valid_names,
        USE.NAMES = FALSE
    )
}

#' Assert that an object is an fcbFlowFrame with required pipeline steps
#'
#' Stops with an informative error if \code{x} is not an \code{fcbFlowFrame},
#' or if the barcodes slot does not contain at least one channel with the
#' specified pipeline steps completed.
#'
#' @param x Object to check.
#' @param needs Character vector of pipeline steps that must be present in the
#'   barcodes slot (e.g. \code{c("deskewing", "clustering")}). \code{NULL}
#'   (default) skips the step check.
#' @param arg_name Character, name of the argument (for the error message).
#' @return Invisibly returns \code{x} if all checks pass.
#' @keywords internal
assert_fcbFlowFrame <- function(x, needs = NULL, arg_name = "Input") {
    if (!inherits(x, "fcbFlowFrame")) {
        stop(arg_name, " must be an fcbFlowFrame object.", call. = FALSE)
    }
    if (!is.null(needs)) {
        if (length(x@barcodes) == 0) {
            stop(
                arg_name, " must have channels in the barcodes slot that have been ",
                "run through deskew_fcbFlowFrame.",
                call. = FALSE
            )
        }
        for (step in needs) {
            step_present <- vapply(
                x@barcodes,
                function(bc) step %in% names(bc),
                logical(1)
            )
            if (!any(step_present)) {
                stop(
                    arg_name, " must have at least one channel with '", step,
                    "' completed. Available channels: ",
                    paste(names(x@barcodes), collapse = ", "),
                    call. = FALSE
                )
            }
        }
    }
    invisible(x)
}

#' Coerce a cytoframe or flowFrame to a plain flowFrame
#'
#' If \code{x} is a \code{cytoframe}, converts it via
#' \code{flowWorkspace::cytoframe_to_flowFrame()} (requiring that
#' \code{flowWorkspace} is installed). If \code{x} is already a
#' \code{flowFrame}, returns it unchanged.
#'
#' @param x A flowFrame or cytoframe object.
#' @param arg_name Character, name of the argument (for the error message).
#' @return A flowFrame.
#' @keywords internal
coerce_to_flowFrame <- function(x, arg_name = "Input") {
    if (inherits(x, "cytoframe")) {
        if (!requireNamespace("flowWorkspace", quietly = TRUE)) {
            stop(
                "Package 'flowWorkspace' is required to convert cytoframe objects.",
                call. = FALSE
            )
        }
        return(flowWorkspace::cytoframe_to_flowFrame(x))
    }
    if (inherits(x, "flowFrame")) {
        return(x)
    }
    stop(
        arg_name, " must be a flowFrame or cytoframe object.",
        call. = FALSE
    )
}
