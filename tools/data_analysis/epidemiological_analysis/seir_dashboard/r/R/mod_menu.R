# ============================================================
# File: mod_menu.R
# ------------------------------------------------------------
# Description: Top navigation menu module. Renders an Analysis for
#   Action–branded dark green navbar that persists across all non-entry views.
#   Provides:
#     - Brand name.
#     - Active dataset indicator (italic, muted).
#     - Three view buttons: Home, Simple, Advanced.
#   Simple and Advanced buttons use uiOutput so the server can
#   apply the correct active-state border colour depending on
#   the current screen.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-03-19 — Simple View button enabled;
#   dynamic active-state highlight added for both view buttons.
# ============================================================


# ------------------------------------------------------------
# Function: mod_menu_ui()
# Description:
#   Renders the top navigation bar as an Analysis for Action dark green navbar.
#   Injected above main content by app.R when screen() != "entry".
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() containing the <nav> element.
# ------------------------------------------------------------
mod_menu_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$nav(
      style = paste(
        "background-color:#324027;",
        "border-bottom:1px solid #1E2A16;",
        "padding:0 1rem;",
        "height:52px;",
        "display:flex;",
        "align-items:center;",
        "justify-content:space-between;"
      ),

      # Left: brand name
      tags$span(
        style = "font-size:14px; font-weight:500; color:#F4F6F5;",
        "SEIR Dashboard"
      ),

      # Centre: active dataset indicator
      tags$span(
        textOutput(ns("active_dataset"), inline = TRUE),
        style = paste(
          "font-size:11px;",
          "color:rgba(244,246,245,0.55);",
          "font-style:italic;"
        )
      ),

      # Right: navigation buttons
      tags$div(
        style = "display:flex; gap:6px; align-items:center;",

        # Home — static, no active-state needed
        actionButton(
          ns("btn_home"), "Home",
          style = paste(
            "font-size:11px;",
            "padding:4px 12px;",
            "border-radius:5px;",
            "background:transparent;",
            "border:0.5px solid rgba(244,246,245,0.3);",
            "color:#F4F6F5;"
          )
        ),

        # Simple — dynamic active-state via uiOutput
        uiOutput(ns("btn_simple_ui"), inline = TRUE),

        # Advanced — dynamic active-state via uiOutput
        uiOutput(ns("btn_advanced_ui"), inline = TRUE)
      )
    )
  )
}


# ------------------------------------------------------------
# Function: mod_menu_server()
# Description:
#   Server logic for the navigation menu. Renders the active
#   dataset label, applies the correct active-state highlight
#   to the current view button, and wires navigation.
# Parameters:
#   id               – Shiny module identifier.
#   screen           – reactiveVal(character); active view.
#   dataset_selector – reactiveVal(character); active source key.
# Returns:
#   None (side effects only).
# ------------------------------------------------------------
mod_menu_server <- function(id, screen, dataset_selector) {
  moduleServer(id, function(input, output, session) {

    # --- Reactive block: render active dataset label ---
    output$active_dataset <- renderText({
      ds <- dataset_selector()
      if (is.null(ds)) return("No dataset loaded")

      # Human-readable label for each source key.
      # toupper() is not used — "CSV" is not meaningful to
      # a decision-maker; the full label is more informative.
      label <- switch(ds,
        "mock" = "Simulated (mock)",
        "csv"  = "Custom dataset",
        toupper(ds)   # fallback for any future source keys
      )
      paste("Dataset:", label)
    })
    # --- End of reactive block ---

    # --------------------------------------------------------
    # Dynamic Simple button
    # Orange accent border when active, muted otherwise.
    # --------------------------------------------------------
    output$btn_simple_ui <- renderUI({
      is_active  <- isTRUE(screen() == "simple")
      border_col <- if (is_active) "#F59342" else "rgba(244,246,245,0.3)"
      text_col   <- if (is_active) "#F59342" else "#F4F6F5"

      actionButton(
        session$ns("btn_simple"), "Simple",
        style = paste0(
          "font-size:11px;",
          "padding:4px 12px;",
          "border-radius:5px;",
          "background:transparent;",
          "border:0.5px solid ", border_col, ";",
          "color:", text_col, ";"
        )
      )
    })

    # --------------------------------------------------------
    # Dynamic Advanced button
    # Orange accent border when active, muted otherwise.
    # --------------------------------------------------------
    output$btn_advanced_ui <- renderUI({
      is_active  <- isTRUE(screen() == "advanced")
      border_col <- if (is_active) "#F59342" else "rgba(244,246,245,0.3)"
      text_col   <- if (is_active) "#F59342" else "#F4F6F5"

      actionButton(
        session$ns("btn_advanced"), "Advanced",
        style = paste0(
          "font-size:11px;",
          "padding:4px 12px;",
          "border-radius:5px;",
          "background:transparent;",
          "border:0.5px solid ", border_col, ";",
          "color:", text_col, ";"
        )
      )
    })

    # --- Reactive block: Home button ---
    observeEvent(input$btn_home, {
      screen("entry")
    })
    # --- End of reactive block ---

    # --- Reactive block: Simple button ---
    observeEvent(input$btn_simple, {
      screen("simple")
      log_message("INFO", "User navigated to Simple View via menu",
                  .module = "MENU")
    })
    # --- End of reactive block ---

    # --- Reactive block: Advanced button ---
    observeEvent(input$btn_advanced, {
      screen("advanced")
    })
    # --- End of reactive block ---
  })
}
