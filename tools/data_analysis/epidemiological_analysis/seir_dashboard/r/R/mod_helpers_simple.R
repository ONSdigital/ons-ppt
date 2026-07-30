# ============================================================
# File: mod_helpers_simple.R
# ------------------------------------------------------------
# Description: Shared helper functions for the Simple View
#   Simplified View. Contains all pure functions used by both
#   mod_ui_simple.R and mod_server_simple.R.
#
#   Placing these helpers in a dedicated file guarantees they
#   are available when the other two modules load, because
#   Shiny's loadSupport() sources R/ files in alphabetical
#   order:
#     mod_helpers_simple.R  ← loaded first
#     mod_server_simple.R   ← loaded second
#     mod_ui_simple.R       ← loaded third
#
#   Functions defined here:
#     alarm_shape_svg()     – SVG geometric alarm indicator
#     state_label_ui()      – coloured alarm state text label
#     metric_value_ui()     – formatted KPI value display
#     resolve_alarm_state() – classifies a metric into alarm state
#     coalesce_num()        – NULL/NA-safe numeric fallback
#                             (sole definition in the project;
#                             a duplicate in utils_helpers.R was
#                             removed — it was never called)
#
# AfA alarm palette:
#   Controlled  – circle   – #3EA27F (AfA sea green)
#   Warning     – triangle – #F59342 (AfA orange)
#   Critical    – square   – #752111 (AfA dark red)
#
# Author: Cristian Paez
# Created: 2026-03-19
# ============================================================


# ------------------------------------------------------------
# Function: alarm_shape_svg()
# Description:
#   Returns an inline SVG element representing the geometric
#   alarm indicator. Shape and colour depend on the alarm state.
# Parameters:
#   state – character; one of "controlled", "warning", "critical".
#   size  – numeric; pixel dimensions for the bounding square.
# Returns:
#   A tags$span() containing an <svg> element.
# Notes:
#   All three shapes are centred within the same viewBox so
#   they align consistently across cards regardless of state.
# ------------------------------------------------------------
alarm_shape_svg <- function(state = "controlled", size = 64) {

  # AfA alarm palette — never Bootstrap defaults
  colour <- switch(
    state,
    "controlled" = "#3EA27F",   # AfA sea green
    "warning"    = "#F59342",   # AfA orange
    "critical"   = "#752111",   # AfA dark red
    "#CCCCCC"                   # fallback — should never occur
  )

  shape_svg <- switch(
    state,

    # Controlled: filled circle, centred at (32, 32), radius 22
    "controlled" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Controlled",
      tags$circle(cx = "32", cy = "32", r = "22", fill = colour)
    ),

    # Warning: upward-pointing equilateral triangle
    # Vertices calculated for a centred, balanced appearance
    "warning" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Warning",
      tags$polygon(points = "32,10 56,54 8,54", fill = colour)
    ),

    # Critical: filled square, inset 10 px on each side
    "critical" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Critical",
      tags$rect(x = "10", y = "10", width = "44", height = "44",
                fill = colour)
    ),

    # Fallback — grey circle
    tags$svg(
      xmlns   = "http://www.w3.org/2000/svg",
      width   = size, height = size,
      viewBox = "0 0 64 64",
      tags$circle(cx = "32", cy = "32", r = "22", fill = "#CCCCCC")
    )
  )

  tags$span(
    style = "display:flex; justify-content:center; margin-bottom:12px;",
    shape_svg
  )
}


# ------------------------------------------------------------
# Function: state_label_ui()
# Description:
#   Returns a styled tags$p() with the human-readable alarm
#   state label, coloured with the matching AfA palette colour.
# Parameters:
#   state – character; "controlled", "warning", or "critical".
# Returns:
#   A tags$p() element.
# ------------------------------------------------------------
state_label_ui <- function(state) {
  conf <- list(
    controlled = list(text = "Controlled", colour = "#3EA27F"),
    warning    = list(text = "Warning",    colour = "#F59342"),
    critical   = list(text = "Critical",   colour = "#752111")
  )
  cfg <- conf[[state]]
  if (is.null(cfg)) cfg <- conf[["controlled"]]

  tags$p(
    cfg$text,
    style = paste0(
      "font-size:0.7rem;",
      "font-weight:700;",
      "letter-spacing:0.08em;",
      "text-transform:uppercase;",
      "color:", cfg$colour, ";",
      "margin:0 0 4px;"
    )
  )
}


# ------------------------------------------------------------
# Function: metric_value_ui()
# Description:
#   Returns a styled tags$div() displaying the formatted metric
#   value and its unit label.
# Parameters:
#   formatted_value – character; pre-formatted numeric string.
#   unit_label      – character; short unit descriptor.
# Returns:
#   A tags$div() element.
# ------------------------------------------------------------
metric_value_ui <- function(formatted_value, unit_label) {
  tags$div(
    tags$span(
      formatted_value,
      style = paste(
        "font-size:2rem;",
        "font-weight:700;",
        "color:#1E2A16;",
        "line-height:1;"
      )
    ),
    tags$br(),
    tags$span(
      unit_label,
      style = "font-size:0.7rem; color:#7A8A72;"
    )
  )
}


# ------------------------------------------------------------
# Function: resolve_alarm_state()
# Description:
#   Classifies a numeric value into one of three alarm states
#   using two monotone thresholds (warn < crit).
# Parameters:
#   value     – numeric; metric value to classify.
#   warn      – numeric; lower threshold (warning boundary).
#   crit      – numeric; upper threshold (critical boundary).
#   direction – character; "above" (default) or "below".
#                "above"  → high values trigger warning/critical.
#                "below"  → low values trigger warning/critical
#                           (not currently used; included for
#                           extensibility).
# Returns:
#   character; "controlled", "warning", or "critical".
# Notes:
#   When direction == "above":
#     value <= warn           → "controlled"
#     warn  < value <= crit  → "warning"
#     value > crit           → "critical"
# ------------------------------------------------------------
resolve_alarm_state <- function(value, warn, crit,
                                direction = "above") {
  if (is.na(value) || !is.finite(value)) return("controlled")

  if (direction == "above") {
    if (value <= warn) return("controlled")
    if (value <= crit) return("warning")
    return("critical")
  }

  # direction == "below"
  if (value >= warn) return("controlled")
  if (value >= crit) return("warning")
  return("critical")
}


# ------------------------------------------------------------
# Function: coalesce_num()
# Description:
#   Returns `value` if it is a non-NA numeric scalar, otherwise
#   returns `default`. Guards against NULL/NA while the user
#   is editing a numericInput field mid-keystroke.
# Parameters:
#   value   – any; value to test.
#   default – numeric; fallback value.
# Returns:
#   numeric scalar.
# ------------------------------------------------------------
coalesce_num <- function(value, default) {
  if (is.null(value) || length(value) != 1 ||
      !is.numeric(value) || is.na(value)) {
    return(default)
  }
  value
}
