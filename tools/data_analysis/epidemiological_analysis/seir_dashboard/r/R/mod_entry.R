# ============================================================
# File: mod_entry.R
# ------------------------------------------------------------
# Description: Entry screen module for dataset selection and
#              navigation to the Advanced or Simple views.
#              Layout aligned with Analysis for Action brand guidelines:
#              dark green navbar, card-centred layout, Analysis for Action
#              colour palette throughout.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-03-19 — Simple View button enabled.
# ============================================================


# ------------------------------------------------------------
# Function: mod_entry_ui()
# Description:
#   Renders the full entry screen. Includes an Analysis for Action–branded
#   navbar at the top and a centred card containing the
#   dataset selector, load button, status badge, and view
#   mode buttons. The footer bar anchors the page at the
#   bottom with project attribution.
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() with navbar, body, and footer elements.
# ------------------------------------------------------------
mod_entry_ui <- function(id) {
  ns <- NS(id)

  tagList(
    useShinyjs(),

    # --------------------------------------------------------
    # Top navbar — AfA dark green, no Bootstrap fluidPage
    # wrapper so the navbar sits flush at the top of the page
    # --------------------------------------------------------
    tags$nav(
      class = "navbar",
      style = paste(
        "background-color:#324027;",
        "padding:0 1rem;",
        "height:52px;",
        "display:flex;",
        "align-items:center;",
        "justify-content:space-between;",
        "border-bottom:1px solid #1E2A16;"
      ),
      tags$span(
        style = "font-size:14px; font-weight:500; color:#F4F6F5;",
        "SEIR Dashboard"
      ),
      tags$span(
        style = paste(
          "font-size:11px;",
          "color:rgba(244,246,245,0.55);",
          "font-style:italic;"
        ),
        "Analysis for Action \u00b7 Argentina Unit"
      )
    ),

    # --------------------------------------------------------
    # Main body — centred card layout on AfA tint background
    # --------------------------------------------------------
    tags$div(
      style = paste(
        "min-height:calc(100vh - 100px);",
        "background-color:#F4F6F5;",
        "display:flex;",
        "flex-direction:column;",
        "align-items:center;",
        "justify-content:center;",
        "padding:40px 16px;"
      ),

      # Header text above the card
      tags$div(
        style = "text-align:center; margin-bottom:28px;",
        tags$h1(
          "Epidemiological Modelling Platform",
          style = paste(
            "font-size:2.4rem;",
            "font-weight:600;",
            "color:#1E2A16;",
            "margin-bottom:8px;"
          )
        ),
        tags$p(
          "Select a dataset to initialise the simulation,",
          "then choose a view mode to explore epidemic scenarios.",
          style = "font-size:1rem; color:#48553F; max-width:440px;"
        )
      ),

      # Central card
      tags$div(
        style = paste(
          "background:#ffffff;",
          "border:0.5px solid #D0D4CE;",
          "border-radius:12px;",
          "padding:28px 32px;",
          "width:100%;",
          "max-width:480px;"
        ),

        # --- Dataset selector ---
        tags$div(
          style = "margin-bottom:16px;",
          tags$div(
            "Dataset source",
            style = paste(
              "font-size:11px;",
              "font-weight:500;",
              "color:#48553F;",
              "text-transform:uppercase;",
              "letter-spacing:0.05em;",
              "margin-bottom:6px;"
            )
          ),
          selectInput(
            inputId  = ns("dataset_selector"),
            label    = NULL,
            choices  = c(
              "Simulated (mock)"          = "mock",
              "Upload your own dataset (CSV)" = "csv"
            ),
            selected = "mock",
            width    = "100%"
          )
        ),

        # --- Load Dataset button ---
        actionButton(
          ns("load_dataset"),
          "Load dataset",
          class = "btn btn-primary w-100",
          style = "margin-bottom:12px;"
        ),

        # --- Status message (success / error badge) ---
        uiOutput(ns("status_message")),

        tags$hr(style = "border-color:#D0D4CE; margin:16px 0;"),

        # --- View mode label ---
        tags$div(
          "View mode",
          style = paste(
            "font-size:11px;",
            "font-weight:500;",
            "color:#48553F;",
            "text-transform:uppercase;",
            "letter-spacing:0.05em;",
            "margin-bottom:8px;"
          )
        ),

        # --- View buttons row ---
        # Both buttons active — Simple View enabled.
        tags$div(
          style = "display:flex; gap:10px;",

          actionButton(
            ns("go_advanced"),
            "Advanced view",
            class = "btn btn-primary flex-fill"
          ),

          actionButton(
            ns("go_simple"),
            "Simple view",
            class = "btn btn-outline-secondary flex-fill"
          )
        )
      )
    ),

    # --------------------------------------------------------
    # Footer bar — attribution strip
    # --------------------------------------------------------
    tags$div(
      style = paste(
        "background:#F8F5F1;",
        "border-top:0.5px solid #D0D4CE;",
        "padding:10px 24px;",
        "display:flex;",
        "justify-content:space-between;",
        "align-items:center;"
      ),
      tags$span(
        tags$span(
          style = paste(
            "display:inline-block;",
            "width:6px; height:6px;",
            "border-radius:50%;",
            "background:#F59342;",
            "margin-right:6px;",
            "vertical-align:middle;"
          )
        ),
        tags$span(
          "Analysis for Action \u00b7 Argentina Unit",
          style = "font-size:11px; color:#7A8A72;"
        )
      )
    )
  )
}


# ------------------------------------------------------------
# Function: mod_entry_server()
# Description:
#   Server logic for the entry screen. Handles dataset loading,
#   status feedback, and navigation to the Advanced or Simple
#   views. Resets state when the user returns to the entry
#   screen.
# Parameters:
#   id               – Shiny module identifier.
#   screen           – reactiveVal(character); controls active view.
#   dataset_selector – reactiveVal(character); active source key.
#   dataset_loaded   – reactiveVal(data.frame); loaded dataset.
#   trigger_sim      – reactiveVal(integer); simulation trigger.
# Returns:
#   None (side effects only).
# ------------------------------------------------------------
mod_entry_server <- function(id, screen, dataset_selector,
                             dataset_loaded, trigger_sim,
                             dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {
    ns         <- session$ns
    first_load <- reactiveVal(TRUE)

    # --------------------------------------------------------
    # Local dataset loader
    # Delegates to get_data() from data_interface.R, which
    # handles all sources via build_dataset(). No hardcoded
    # dates or manual data frame construction here.
    # --------------------------------------------------------
    safe_load_dataset <- function(source) {
      log_message("INFO",
                  paste("Loading dataset (local call):", source),
                  .module = "ENTRY")
      result <- get_data(source)
      result$data
    }

    # --------------------------------------------------------
    # Reset UI when returning to entry screen
    # --------------------------------------------------------
    observeEvent(screen(), {
      if (screen() == "entry") {
        output$status_message <- renderUI(NULL)
        if (!first_load()) {
          dataset_selector(NULL)
          dataset_loaded(NULL)
        }
        first_load(FALSE)
      }
    })

    # --------------------------------------------------------
    # Load dataset — shows status badge inside the card.
    # For CSV source: opens a modal with upload instructions
    # and a fileInput. For mock: loads directly.
    # --------------------------------------------------------
    observeEvent(input$load_dataset, {

      # CSV source — show upload modal before loading
      if (isTRUE(input$dataset_selector == "csv")) {
        showModal(modalDialog(
          title     = "Upload your own dataset",
          size      = "m",
          easyClose = FALSE,

          tags$p(
            style = "color:#48553F; margin-bottom:16px;",
            "Upload a CSV file with your epidemiological and ",
            "healthcare resource parameters. The platform will ",
            "use these values as the starting point for the simulation ",
            "— your own regional ‘photo’."
          ),

          tags$div(
            style = paste(
              "background:#F8F5F1;",
              "border:0.5px solid #D0D4CE;",
              "border-radius:8px;",
              "padding:14px 16px;",
              "margin-bottom:16px;"
            ),
            tags$p(
              tags$strong("Required format:"),
              " two columns — ",
              tags$code("parameter"),
              " and ",
              tags$code("value"),
              " — with the following rows:",
              style = "margin-bottom:10px; font-size:0.9rem;"
            ),
            tags$table(
              style = "width:100%; font-size:0.85rem; border-collapse:collapse;",
              tags$thead(tags$tr(
                tags$th("parameter",   style = "text-align:left; padding:4px 8px; background:#324027; color:#F4F6F5;"),
                tags$th("value",       style = "text-align:left; padding:4px 8px; background:#324027; color:#F4F6F5;"),
                tags$th("description", style = "text-align:left; padding:4px 8px; background:#324027; color:#F4F6F5;")
              )),
              tags$tbody(
                tags$tr(tags$td("r0",                    style="padding:3px 8px;"), tags$td("2.5",      style="padding:3px 8px;"), tags$td("Basic reproduction number",                 style="padding:3px 8px; color:#48553F;")),
                tags$tr(style="background:#F4F6F5;",
                  tags$td("incubation_period",           style="padding:3px 8px;"), tags$td("5",        style="padding:3px 8px;"), tags$td("Days from exposure to infectious",           style="padding:3px 8px; color:#48553F;")),
                tags$tr(tags$td("infectious_period",     style="padding:3px 8px;"), tags$td("7",        style="padding:3px 8px;"), tags$td("Days an individual remains infectious",      style="padding:3px 8px; color:#48553F;")),
                tags$tr(style="background:#F4F6F5;",
                  tags$td("ifr",                         style="padding:3px 8px;"), tags$td("0.01",     style="padding:3px 8px;"), tags$td("Infection fatality rate (proportion)",       style="padding:3px 8px; color:#48553F;")),
                tags$tr(tags$td("icu_capacity",          style="padding:3px 8px;"), tags$td("6000",     style="padding:3px 8px;"), tags$td("Total ICU beds available",                   style="padding:3px 8px; color:#48553F;")),
                tags$tr(style="background:#F4F6F5;",
                  tags$td("ventilator_availability",     style="padding:3px 8px;"), tags$td("2000",     style="padding:3px 8px;"), tags$td("Total ventilators available",                style="padding:3px 8px; color:#48553F;")),
                tags$tr(tags$td("healthcare_staff",      style="padding:3px 8px;"), tags$td("10000",    style="padding:3px 8px;"), tags$td("Staff in critical care",                     style="padding:3px 8px; color:#48553F;")),
                tags$tr(style="background:#F4F6F5;",
                  tags$td("icu_admission_rate",          style="padding:3px 8px;"), tags$td("0.136",    style="padding:3px 8px;"), tags$td("Proportion of cases requiring ICU",          style="padding:3px 8px; color:#48553F;")),
                tags$tr(tags$td("ventilator_usage_rate", style="padding:3px 8px;"), tags$td("0.02",     style="padding:3px 8px;"), tags$td("Proportion requiring ventilation",           style="padding:3px 8px; color:#48553F;")),
                tags$tr(style="background:#F4F6F5;",
                  tags$td("population",                  style="padding:3px 8px;"), tags$td("45000000", style="padding:3px 8px;"), tags$td("Total population",                          style="padding:3px 8px; color:#48553F;"))
              )
            )
          ),

          tags$p(
            style = "font-size:0.85rem; color:#7A8A72; margin-bottom:12px;",
            "Argentina reference defaults are shown below as a guide — ",
            "replace them with your own regional figures."
          ),

          fileInput(
            ns("csv_upload"),
            label    = "Select CSV file",
            accept   = ".csv",
            multiple = FALSE
          ),

          footer = tagList(
            modalButton("Cancel"),
            actionButton(
              ns("confirm_csv_upload"),
              "Load dataset",
              class = "btn btn-primary"
            )
          )
        ))
        return()
      }

      # mock — load directly
      shinyjs::disable("load_dataset")
      shinyjs::runjs("document.body.style.opacity = 0.6;")

      dataset_selector(input$dataset_selector)

      tryCatch({
        result <- get_data(input$dataset_selector)
        req(result$data)
        dataset_loaded(result$data)

        if (!is.null(dataset_params)) {
          dataset_params(list(
            parametros = result$parametros,
            recursos   = result$recursos,
            poblacion  = result$poblacion
          ))
        }

        # Success badge
        output$status_message <- renderUI({
          tags$div(
            id    = ns("alert_box"),
            style = paste(
              "display:flex; align-items:center; gap:8px;",
              "padding:10px 14px;",
              "background:#C0DD97;",
              "border:0.5px solid #3B6D11;",
              "border-radius:6px;",
              "margin-bottom:12px;"
            ),
            tags$span(style = paste(
              "width:8px; height:8px; border-radius:50%;",
              "background:#27500A; flex-shrink:0; display:inline-block;"
            )),
            tags$span(
              "Dataset loaded successfully.",
              style = "font-size:13px; color:#27500A; font-weight:500;"
            )
          )
        })

        shinyjs::delay(3000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))

      }, error = function(e) {
        output$status_message <- renderUI({
          tags$div(
            id    = ns("alert_box"),
            style = paste(
              "display:flex; align-items:center; gap:8px;",
              "padding:10px 14px;",
              "background:#F9EDEA;",
              "border:0.5px solid #E8B8AD;",
              "border-radius:6px;",
              "margin-bottom:12px;"
            ),
            tags$span(style = paste(
              "width:8px; height:8px; border-radius:50%;",
              "background:#752111; flex-shrink:0; display:inline-block;"
            )),
            tags$span(
              paste("Error loading dataset:", e$message),
              style = "font-size:13px; color:#752111;"
            )
          )
        })
        shinyjs::delay(4000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))
      })

      shinyjs::runjs("document.body.style.opacity = 1;")
      shinyjs::enable("load_dataset")
    })

    # --------------------------------------------------------
    # CSV upload confirmation — fired when user clicks
    # "Load dataset" inside the modal.
    # Validates the uploaded file via validate_user_csv(),
    # builds the dataset, updates reactive state, and closes
    # the modal. Shows a success or error badge on completion.
    # --------------------------------------------------------
    observeEvent(input$confirm_csv_upload, {
      req(input$csv_upload)

      shinyjs::disable("confirm_csv_upload")

      tryCatch({
        result <- get_data(
          source = "csv",
          params = list(path = input$csv_upload$datapath)
        )
        req(result$data)

        dataset_selector("csv")
        dataset_loaded(result$data)

        if (!is.null(dataset_params)) {
          dataset_params(list(
            parametros = result$parametros,
            recursos   = result$recursos,
            poblacion  = result$poblacion
          ))
        }

        removeModal()

        output$status_message <- renderUI({
          tags$div(
            id    = ns("alert_box"),
            style = paste(
              "display:flex; align-items:center; gap:8px;",
              "padding:10px 14px;",
              "background:#C0DD97;",
              "border:0.5px solid #3B6D11;",
              "border-radius:6px;",
              "margin-bottom:12px;"
            ),
            tags$span(style = paste(
              "width:8px; height:8px; border-radius:50%;",
              "background:#27500A; flex-shrink:0; display:inline-block;"
            )),
            tags$span(
              "Custom dataset loaded successfully.",
              style = "font-size:13px; color:#27500A; font-weight:500;"
            )
          )
        })

        shinyjs::delay(3000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))

        log_message("INFO", "User CSV loaded successfully", .module = "ENTRY")

      }, error = function(e) {
        removeModal()
        output$status_message <- renderUI({
          tags$div(
            id    = ns("alert_box"),
            style = paste(
              "display:flex; align-items:center; gap:8px;",
              "padding:10px 14px;",
              "background:#F9EDEA;",
              "border:0.5px solid #E8B8AD;",
              "border-radius:6px;",
              "margin-bottom:12px;"
            ),
            tags$span(style = paste(
              "width:8px; height:8px; border-radius:50%;",
              "background:#752111; flex-shrink:0; display:inline-block;"
            )),
            tags$span(
              paste("Error loading CSV:", e$message),
              style = "font-size:13px; color:#752111;"
            )
          )
        })
        shinyjs::delay(4000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))
        log_message("ERROR", paste("CSV upload failed:", e$message),
                    .module = "ENTRY")
      })

      shinyjs::enable("confirm_csv_upload")
    })

        # --------------------------------------------------------
    # Navigation to Advanced view
    # --------------------------------------------------------
    observeEvent(input$go_advanced, {
      req(dataset_loaded())
      screen("advanced")
      log_message("INFO", "User navigated to Advanced View",
                  .module = "ENTRY")
    })

    # --------------------------------------------------------
    # Navigation to Simple view
    # --------------------------------------------------------
    observeEvent(input$go_simple, {
      req(dataset_loaded())
      screen("simple")
      log_message("INFO", "User navigated to Simple View",
                  .module = "ENTRY")
    })
  })
}
