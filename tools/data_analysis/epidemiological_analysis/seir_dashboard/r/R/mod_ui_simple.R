# ============================================================
# File: mod_ui_simple.R
# ------------------------------------------------------------
# Description: Simple View UI module for the SEIR Dashboard.
#   Renders a decision-maker interface consisting of three
#   independent KPI cards, each with a geometric alarm
#   indicator (circle / triangle / square) drawn in SVG using
#   the Analysis for Action (AfA) brand colour palette.
#
#   Layout (top to bottom):
#     1. Three KPI cards in a responsive row:
#          Card 1 – Epidemic Trajectory (weekly growth rate of I)
#          Card 2 – ICU Pressure       (ICU occupancy vs capacity)
#          Card 3 – Cumulative Impact  (deaths as % of population)
#     2. Two parameter sliders: R₀ and Compliance Level.
#        State is fully isolated from the Advanced View and
#        always initialised from global.R defaults.
#     3. Collapsible "Settings" panel with six numeric inputs
#        for overriding the default alarm thresholds. Changes
#        are reactive — they update indicators immediately
#        without re-running the ODE solver.
#
#   Shared helper functions (alarm_shape_svg, state_label_ui,
#   metric_value_ui) are defined in mod_helpers_simple.R, which
#   is sourced first by loadSupport() due to alphabetical order.
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
# Helper: kpi_card_ui()
# Description:
#   Renders a single KPI card with a dynamic alarm indicator,
#   a metric label, and a formatted metric value. Alarm shape,
#   state label, and metric value are all server-rendered via
#   uiOutput so they react to slider and threshold changes.
# Parameters:
#   card_id  – character; unique HTML id for the card container.
#   title    – character; card heading.
#   subtitle – character; brief description of what is measured.
#   shape_id – character; id of the uiOutput for the alarm SVG.
#   value_id – character; id of the uiOutput for the metric value.
#   label_id – character; id of the uiOutput for the state label.
# Returns:
#   A tags$div() styled as an AfA-branded card.
# ------------------------------------------------------------
kpi_card_ui <- function(card_id, title, subtitle, shape_id,
                        value_id, label_id) {

  tags$div(
    id    = card_id,
    style = paste(
      "flex:1;",
      "min-width:220px;",
      "background:#FFFFFF;",
      "border:0.5px solid #D0D4CE;",
      "border-radius:14px;",
      "padding:28px 24px 22px;",
      "display:flex;",
      "flex-direction:column;",
      "align-items:center;",
      "text-align:center;"
    ),

    # Alarm indicator — rendered server-side so it reacts to
    # threshold and slider changes without page reload
    uiOutput(shape_id),

    # State label (e.g. "Controlled", "Warning", "Critical")
    uiOutput(label_id),

    # Card title
    tags$h3(
      title,
      style = paste(
        "font-size:1rem;",
        "font-weight:600;",
        "color:#1E2A16;",
        "margin:10px 0 4px;"
      )
    ),

    # Card subtitle — what is being measured
    tags$p(
      subtitle,
      style = paste(
        "font-size:0.75rem;",
        "color:#7A8A72;",
        "margin-bottom:14px;",
        "line-height:1.4;"
      )
    ),

    # Divider
    tags$hr(style = "width:100%; border-color:#D0D4CE; margin:0 0 14px;"),

    # Metric value — rendered server-side (reactive)
    uiOutput(value_id)
  )
}


# ------------------------------------------------------------
# Function: mod_ui_simple()
# Description:
#   Renders the full Simple View layout. Includes the three KPI
#   cards, the two parameter sliders (R₀ and Compliance Level),
#   and the collapsible Settings panel with six threshold inputs.
#   No server logic here — all reactivity is in mod_server_simple.R.
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() with the complete Simple View body.
# ------------------------------------------------------------
mod_ui_simple <- function(id) {
  ns <- NS(id)

  tagList(

    # --------------------------------------------------------
    # Main body container — AfA light tint background
    # --------------------------------------------------------
    tags$div(
      style = paste(
        "min-height:calc(100vh - 52px);",   # 52 px = navbar height
        "background-color:#F4F6F5;",
        "padding:32px 24px 48px;"
      ),

      # Page heading
      tags$div(
        style = "text-align:center; margin-bottom:32px;",
        tags$h2(
          "Epidemic Status \u2014 Simplified View",
          style = paste(
            "font-size:1.6rem;",
            "font-weight:600;",
            "color:#1E2A16;",
            "margin-bottom:6px;"
          )
        ),
        tags$p(
          paste(
            "Key indicators are computed from the current simulation.",
            "Adjust R\u2080 and compliance below to explore scenarios."
          ),
          style = "font-size:0.875rem; color:#48553F; max-width:520px; margin:0 auto;"
        )
      ),

      # ----------------------------------------------------
      # Section 1: KPI Cards row
      # ----------------------------------------------------
      tags$div(
        style = paste(
          "display:flex;",
          "flex-wrap:wrap;",
          "gap:18px;",
          "justify-content:center;",
          "margin-bottom:32px;"
        ),

        # Card 1 — Epidemic Trajectory
        kpi_card_ui(
          card_id  = "card_trajectory",
          title    = "Epidemic Trajectory",
          subtitle = "Weekly growth rate of infectious cases (I compartment) \u2014 computed over the most recent 7 simulated days",
          shape_id = ns("shape_trajectory"),
          value_id = ns("value_trajectory"),
          label_id = ns("label_trajectory")
        ),

        # Card 2 — ICU Pressure
        kpi_card_ui(
          card_id  = "card_icu",
          title    = "ICU Pressure",
          subtitle = "ICU occupancy on the final simulation day as % of capacity",
          shape_id = ns("shape_icu"),
          value_id = ns("value_icu"),
          label_id = ns("label_icu")
        ),

        # Card 3 — Cumulative Impact
        kpi_card_ui(
          card_id  = "card_deaths",
          title    = "Cumulative Impact",
          subtitle = "Cumulative deaths as % of total population (final simulation day)",
          shape_id = ns("shape_deaths"),
          value_id = ns("value_deaths"),
          label_id = ns("label_deaths")
        )
      ),

      # ----------------------------------------------------
      # Section 2: Parameter sliders
      # Fully isolated from the Advanced View — always
      # initialised from global.R defaults (INITIAL_R0, 50).
      # ----------------------------------------------------
      tags$div(
        style = paste(
          "background:#FFFFFF;",
          "border:0.5px solid #D0D4CE;",
          "border-radius:12px;",
          "padding:24px 28px;",
          "max-width:600px;",
          "margin:0 auto 28px;"
        ),

        tags$div(
          style = paste(
            "font-size:11px;",
            "font-weight:500;",
            "color:#48553F;",
            "text-transform:uppercase;",
            "letter-spacing:0.05em;",
            "margin-bottom:18px;"
          ),
          "Scenario Parameters"
        ),

        # R₀ slider — range and default from global.R
        sliderInput(
          inputId = ns("simple_r0"),
          label   = HTML("R\u2080 \u2014 Basic Reproduction Number"),
          min     = 0.5,
          max     = 6.0,
          value   = INITIAL_R0,
          step    = 0.1,
          width   = "100%"
        ),

        # Compliance Level slider — fixed default 50 per roadmap spec
        sliderInput(
          inputId = ns("simple_compliance"),
          label   = "Compliance Level (%)",
          min     = 0,
          max     = 100,
          value   = 50,
          step    = 1,
          width   = "100%"
        )
      ),

      # ----------------------------------------------------
      # Section 3: Collapsible Settings panel
      # Six numeric inputs for alarm threshold overrides.
      # Toggle handled via inline JavaScript — no extra
      # Shiny dependency required.
      # ----------------------------------------------------
      tags$div(
        style = "max-width:600px; margin:0 auto;",

        # Toggle button — AfA earthy outline style
        tags$button(
          id      = "simple_settings_toggle",
          onclick = paste0(
            "var p = document.getElementById('simple_settings_panel');",
            "p.style.display = (p.style.display === 'none') ? 'block' : 'none';"
          ),
          style = paste(
            "width:100%;",
            "background:transparent;",
            "border:0.5px solid #A8B09F;",
            "border-radius:8px;",
            "padding:10px 16px;",
            "font-size:0.875rem;",
            "color:#48553F;",
            "cursor:pointer;",
            "text-align:left;",
            "margin-bottom:8px;"
          ),
          "\u25BC  Settings \u2014 Alarm Thresholds"
        ),

        # Settings panel — hidden by default
        tags$div(
          id    = "simple_settings_panel",
          style = paste(
            "display:none;",
            "background:#FFFFFF;",
            "border:0.5px solid #D0D4CE;",
            "border-radius:12px;",
            "padding:22px 28px;"
          ),

          tags$div(
            style = paste(
              "font-size:11px;",
              "font-weight:500;",
              "color:#48553F;",
              "text-transform:uppercase;",
              "letter-spacing:0.05em;",
              "margin-bottom:18px;"
            ),
            "Alarm Threshold Configuration"
          ),

          # --- ICU thresholds ---
          tags$p(
            tags$strong("ICU Pressure",
                        style = "color:#324027; font-size:0.85rem;"),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap; margin-bottom:20px;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_icu_warn"),
                label   = "Warning threshold (% of capacity)",
                value   = 70, min = 0, max = 200, step = 5,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_icu_crit"),
                label   = "Critical threshold (% of capacity)",
                value   = 100, min = 0, max = 200, step = 5,
                width   = "100%"
              )
            )
          ),

          # --- Epidemic Trajectory thresholds ---
          tags$p(
            tags$strong("Epidemic Trajectory",
                        style = "color:#324027; font-size:0.85rem;"),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap; margin-bottom:20px;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_growth_warn"),
                label   = "Warning threshold (weekly growth %)",
                value   = 1, min = 0, max = 100, step = 0.5,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_growth_crit"),
                label   = "Critical threshold (weekly growth %)",
                value   = 20, min = 0, max = 100, step = 1,
                width   = "100%"
              )
            )
          ),

          # --- Cumulative Impact thresholds ---
          tags$p(
            tags$strong("Cumulative Impact",
                        style = "color:#324027; font-size:0.85rem;"),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_deaths_warn"),
                label   = "Warning threshold (% of population)",
                value   = 0.05, min = 0, max = 10, step = 0.01,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_deaths_crit"),
                label   = "Critical threshold (% of population)",
                value   = 0.20, min = 0, max = 10, step = 0.01,
                width   = "100%"
              )
            )
          )
        )
      ),

      # --------------------------------------------------------
      # Footer attribution strip
      # --------------------------------------------------------
      tags$div(
        style = paste(
          "margin-top:48px;",
          "border-top:0.5px solid #D0D4CE;",
          "padding-top:12px;",
          "display:flex;",
          "justify-content:space-between;",
          "align-items:center;"
        ),
        tags$span(
          "Analysis for Action \u00b7 Argentina Unit",
          style = "font-size:11px; color:#7A8A72;"
        )
      )
    )
  )
}
