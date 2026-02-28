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
  if (name %in% valid_names) return(name)

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
  vapply(names, resolve_channel, character(1), valid_names = valid_names,
         USE.NAMES = FALSE)
}
