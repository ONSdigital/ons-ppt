# ============================================================
# File: R/mod_server.R
# ------------------------------------------------------------
# Description:
#   Main server module for the Shiny application. Integrates:
#     - Dataset selection (mock / user-uploaded CSV)
#     - Parameter management and validation
#     - SEIR model execution
#     - Visualisation module wiring (viz_plot_server)
#
# Notes (design decisions):
#   - Internal contract: ifr_value is ALWAYS a percentage in [0, 100].
#   - Simulation trigger: trigger_sim is incremented ONLY on:
#       * dataset change
#       * explicit user action (Run Simulation)
#       * user parameter edits (field-level events)
#     This avoids reactive feedback loops.
#   - Resource parameters (ICU capacity, ventilators) affect the
#     Resource Pressure plot directly via reactive values passed
#     to viz_plot_server. They do not re-run the ODE solver.
#   - Calibrated parameter sets (currently: user CSV) are applied
#     via apply_calibrated_params(), shared with the dataset_params
#     observer below.
#
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

mod_server <- function(id, dataset_selector,
                      dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {

    # --------------------------------------------------------
    # Local helpers
    # --------------------------------------------------------

    # Convert IFR to a percentage in [0, 100] with strict rules.
    # - If IFR <= 1  : treat as proportion and convert to percent.
    # - If IFR <= 100: treat as percent already.
    # - Otherwise    : fail explicitly (wrong scale).
    # Used by apply_calibrated_params() for any calibrated dataset
    # source (currently: user-uploaded CSV).
    normalise_ifr_to_pct <- function(ifr_raw) {
      if (!is.numeric(ifr_raw) || length(ifr_raw) != 1 || is.na(ifr_raw)) {
        stop("Calibrated dataset invalid: IFR must be a non-NA scalar numeric value.")
      }
      if (ifr_raw <= 1)   return(ifr_raw * 100)
      if (ifr_raw <= 100) return(ifr_raw)
      stop(sprintf(
        "Calibrated dataset invalid: IFR out of scale (value=%s). Expected proportion (<=1) or percent (<=100).",
        as.character(ifr_raw)
      ))
    }

    # Apply a full parameter refresh from a calibrated dataset
    # (currently: user-uploaded CSV) into app_params. The input
    # follows the canonical $parametros / $recursos / $poblacion
    # structure produced by validate_user_csv() in data_interface.R.
    # isolate() is used to avoid intermediate reactive states.
    apply_calibrated_params <- function(calibrated_data, app_params) {
      ifr_pct <- normalise_ifr_to_pct(calibrated_data$parametros$IFR)
      isolate({
        app_params$r0_value           <- calibrated_data$parametros$R0
        app_params$incubation_period  <- calibrated_data$parametros$incubation_period
        app_params$infectious_period  <- calibrated_data$parametros$infectious_period
        app_params$ifr_value          <- ifr_pct
        app_params$icu_capacity       <- calibrated_data$recursos$INITIAL_ICU_CAPACITY
        app_params$ventilator_availability <- calibrated_data$recursos$INITIAL_VENTILATOR_AVAILABILITY
        app_params$healthcare_staff   <- calibrated_data$recursos$INITIAL_HEALTHCARE_STAFF
        # Rates stored as percentages for UI + validation consistency
        app_params$icu_admission_rate    <- calibrated_data$recursos$INITIAL_ICU_RATE * 100
        app_params$ventilator_usage_rate <- calibrated_data$recursos$INITIAL_VENTILATOR_RATE * 100
        app_params$population            <- calibrated_data$poblacion
      })
    }

    # --------------------------------------------------------
    # Logging on module start (best-effort)
    # --------------------------------------------------------
    log_message(
      "INFO",
      paste0("mod_server started; dataset_selector() = ", dataset_selector()),
      .module = "SERVER"
    )

    # --------------------------------------------------------
    # ReactiveValues: global simulation parameters
    # --------------------------------------------------------
    app_params <- reactiveValues(
      r0_value             = INITIAL_R0,
      incubation_period    = INITIAL_INCUBATION_PERIOD,
      infectious_period    = INITIAL_INFECTIOUS_PERIOD,
      ifr_value            = INITIAL_IFR * 100,   # percent [0,100]

      icu_capacity              = INITIAL_ICU_CAPACITY,
      ventilator_availability   = INITIAL_VENTILATOR_AVAILABILITY,
      healthcare_staff          = INITIAL_HEALTHCARE_STAFF,
      icu_admission_rate        = INITIAL_ICU_RATE * 100,       # percent [0,100]
      ventilator_usage_rate     = INITIAL_VENTILATOR_RATE * 100,# percent [0,100]

      policy_type      = "no_intervention",
      compliance_level = 50,

      start_date  = START_DATE,
      end_date    = END_DATE,
      population  = POPULATION_ARGENTINA,

      trigger_sim = 0L   # integer counter used as simulation trigger
    )

    # --------------------------------------------------------
    # Dataset loading based on user selection
    # --------------------------------------------------------
    observeEvent(dataset_selector(), {
      req(dataset_selector())

      if (dataset_selector() == "csv") {
        # CSV: parameters already applied to app_params via
        # dataset_params reactive in app.R. Advanced View sliders
        # are updated here from the same parameter set.
        log_message("INFO", "CSV dataset selected — parameters applied via dataset_params",
                    .module = "SERVER")

      } else {
        log_message("INFO", "Using simulated mock dataset", .module = "SERVER")
      }

      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = FALSE)

    # --------------------------------------------------------
    # Dataset params observer — applies calibrated parameters
    # from a calibrated dataset source (currently: user-uploaded
    # CSV) to app_params and updates all Advanced View sliders
    # via updateSliderInput(). Fires when dataset_params changes
    # — i.e. when a calibrated dataset is loaded. Ignored for
    # mock (NULL).
    # --------------------------------------------------------
    observeEvent(dataset_params(), {
      dp <- dataset_params()
      req(!is.null(dp), !is.null(dp$parametros))

      apply_calibrated_params(dp, app_params)

      # Update UI sliders to reflect loaded parameters
      updateSliderInput(session, "r0_value",
                        value = dp$parametros$R0)
      updateSliderInput(session, "incubation_period",
                        value = dp$parametros$incubation_period)
      updateSliderInput(session, "infectious_period",
                        value = dp$parametros$infectious_period)
      updateSliderInput(session, "ifr_value",
                        value = dp$parametros$IFR * 100)
      updateNumericInput(session, "icu_capacity",
                         value = dp$recursos$INITIAL_ICU_CAPACITY)
      updateNumericInput(session, "ventilator_availability",
                         value = dp$recursos$INITIAL_VENTILATOR_AVAILABILITY)
      updateNumericInput(session, "healthcare_staff",
                         value = dp$recursos$INITIAL_HEALTHCARE_STAFF)
      updateSliderInput(session, "icu_admission_rate",
                        value = dp$recursos$INITIAL_ICU_RATE * 100)
      updateSliderInput(session, "ventilator_usage_rate",
                        value = dp$recursos$INITIAL_VENTILATOR_RATE * 100)
      if (!is.null(dp$poblacion)) {
        updateNumericInput(session, "population",
                           value = dp$poblacion)
      }

      log_message("INFO",
                  "Advanced View updated from dataset parameters",
                  .module = "SERVER")
    }, ignoreNULL = TRUE)

    # --------------------------------------------------------
    # Parameter observers — SEIR epidemiological parameters
    # Each observer updates app_params and increments trigger_sim
    # to re-run the ODE solver automatically.
    # --------------------------------------------------------

    observeEvent(input$r0_value, {
      app_params$r0_value <- input$r0_value
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$incubation_period, {
      app_params$incubation_period <- input$incubation_period
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$infectious_period, {
      app_params$infectious_period <- input$infectious_period
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$ifr_value, {
      if (!is.null(input$ifr_value) && is.numeric(input$ifr_value)) {
        if (input$ifr_value < 0 || input$ifr_value > 100) {
          stop("'ifr_value' must be within range [0, 100]")
        }
      }
      app_params$ifr_value <- input$ifr_value
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Public Policy
    # Policy and compliance affect the effective R0 inside the
    # ODE solver (see mod_model.R Step 3), so trigger_sim fires.
    # --------------------------------------------------------

    observeEvent(input$policy_type, {
      app_params$policy_type <- input$policy_type
      app_params$trigger_sim <- app_params$trigger_sim + 1L
      log_message("INFO",
                  paste("Policy changed to:", input$policy_type),
                  .module = "SERVER")
    }, ignoreInit = TRUE)

    observeEvent(input$compliance_level, {
      app_params$compliance_level <- input$compliance_level
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Healthcare resources
    # ICU capacity and ventilator availability do NOT re-run
    # the ODE solver — they only affect the Resource Pressure
    # plot threshold lines. ICU/ventilator RATES do re-run the
    # solver because they change the demand calculation.
    # --------------------------------------------------------

    observeEvent(input$icu_capacity, {
      req(!is.null(input$icu_capacity), input$icu_capacity >= 0)
      app_params$icu_capacity <- input$icu_capacity
      # Note: no trigger_sim increment — capacity only affects plot thresholds
    }, ignoreInit = TRUE)

    observeEvent(input$ventilator_availability, {
      req(!is.null(input$ventilator_availability), input$ventilator_availability >= 0)
      app_params$ventilator_availability <- input$ventilator_availability
      # Note: no trigger_sim increment — availability only affects plot thresholds
    }, ignoreInit = TRUE)

    observeEvent(input$healthcare_staff, {
      req(!is.null(input$healthcare_staff))
      app_params$healthcare_staff <- input$healthcare_staff
    }, ignoreInit = TRUE)

    observeEvent(input$icu_admission_rate, {
      app_params$icu_admission_rate <- input$icu_admission_rate
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$ventilator_usage_rate, {
      app_params$ventilator_usage_rate <- input$ventilator_usage_rate
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Simulation date range and population
    # --------------------------------------------------------

    observeEvent(input$start_date, {
      app_params$start_date <- input$start_date
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$end_date, {
      app_params$end_date <- input$end_date
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$population, {
      app_params$population <- input$population
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Policy description: dynamic text below the selector
    # Explains to the user what each policy does in the model.
    # --------------------------------------------------------
    output$policy_description <- renderUI({
      desc <- switch(input$policy_type,
        "no_intervention"   = "No measures applied. R\u2080 remains at its base value.",
        "phased_mitigation" = "Gradual restrictions reduce R\u2080 proportional to compliance.",
        "intermittent"      = "On/off interventions applied based on compliance level.",
        "icu_triggered"     = "Restrictions activate when ICU demand exceeds capacity.",
        ""
      )
      tags$small(style = "color:#48553F; font-style:italic;", desc)
    })

    # --------------------------------------------------------
    # Manual simulation trigger (Run Simulation button)
    # Forces a full re-run regardless of what changed.
    # --------------------------------------------------------
    observeEvent(input$run_simulation, {
      app_params$trigger_sim <- app_params$trigger_sim + 1L
      log_message("INFO", "Simulation manually triggered", .module = "SERVER")
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Data Module: generate initial raw dataset for ODE solver
    # --------------------------------------------------------
    simulated_raw_data <- mod_data_server(
      "data_sim",
      params = reactive({
        list(
          start_date  = app_params$start_date,
          end_date    = app_params$end_date,
          population  = app_params$population,
          trigger_sim = app_params$trigger_sim
        )
      })
    )

    # --------------------------------------------------------
    # Model Module: run SEIR simulation
    # --------------------------------------------------------
    seir_model_output <- model_seir_server(
      "seir_model",
      input_params = reactive({
        list(
          r0_value          = app_params$r0_value,
          incubation_period = app_params$incubation_period,
          infectious_period = app_params$infectious_period,
          ifr_value         = app_params$ifr_value,

          icu_capacity             = app_params$icu_capacity,
          ventilator_availability  = app_params$ventilator_availability,
          healthcare_staff         = app_params$healthcare_staff,

          icu_admission_rate    = app_params$icu_admission_rate,
          ventilator_usage_rate = app_params$ventilator_usage_rate,

          policy_type      = app_params$policy_type,
          compliance_level = app_params$compliance_level,

          start_date  = app_params$start_date,
          end_date    = app_params$end_date,
          population  = app_params$population,

          trigger_sim = app_params$trigger_sim
        )
      }),
      raw_data_df = simulated_raw_data
    )

    # --------------------------------------------------------
    # Visualisation Module: NOT called here.
    # viz_plot_server() must be called from the top-level server
    # function in app.R, NOT from inside this moduleServer() block.
    # If called here, the namespace would accumulate as
    # "viz_advanced-viz_advanced-seir_plot", which does not match
    # the plotOutput ids generated by ui_main(). See app.R for
    # the correct wiring.
    # --------------------------------------------------------
    # Render data preview table (top 10 rows)
    # --------------------------------------------------------
    output$simulated_data_table <- renderTable({
      req(seir_model_output())

      data_for_table <- seir_model_output()
      data_for_table$date <- format(data_for_table$date, "%d-%m-%Y")

      data_for_table <- data_for_table %>%
        dplyr::select(
          Date                  = date,
          Susceptible           = S,
          Exposed               = E,
          Infected              = I,
          Recovered             = R,
          `Cumulative Cases`    = Cumulative_Cases,
          `Cumulative Deaths`   = Cumulative_Deaths,
          `ICU Occupancy (Sim)` = ICU_Occupancy_Sim,
          `Ventilator Use (Sim)`= Vent_Usage_Sim
        ) %>%
        dplyr::mutate(
          dplyr::across(
            where(is.numeric),
            ~format(round(., 0), big.mark = ",")
          )
        )

      head(data_for_table, 10)
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    # --------------------------------------------------------
    # Download handler: exports full simulation results as CSV
    # Uses write.csv2() (semicolon separator, comma decimal)
    # for compatibility with European locale settings.
    # Numbers are exported raw (no formatting) so each user's
    # spreadsheet application applies its own locale correctly.
    # Filename includes dataset source and date for easy
    # scenario comparison.
    # --------------------------------------------------------
    output$download_csv <- downloadHandler(
      filename = function() {
        paste0(
          "SEIR_scenario_",
          dataset_selector(),
          "_",
          format(Sys.Date(), "%Y%m%d"),
          ".csv"
        )
      },
      content = function(file) {
        req(seir_model_output())

        export_df <- seir_model_output() %>%
          dplyr::mutate(date = format(date, "%d-%m-%Y")) %>%
          dplyr::select(
            Date                 = date,
            Susceptible          = S,
            Exposed              = E,
            Infected             = I,
            Recovered            = R,
            Daily_New_Infections,
            Cumulative_Cases,
            Daily_Deaths,
            Cumulative_Deaths,
            ICU_Occupancy_Sim,
            Vent_Usage_Sim
          ) %>%
          dplyr::mutate(
            dplyr::across(where(is.numeric), ~round(., 0))
          )

        # write.csv2: semicolon separator, comma decimal point
        # Standard for European locale — avoids Excel misreading
        # numeric columns when opened with regional settings.
        write.csv2(export_df, file, row.names = FALSE)

        log_message("INFO", paste("CSV exported:", basename(file)),
                    .module = "SERVER")
      }
    )

    # --------------------------------------------------------
    # Return outputs for downstream integration
    # --------------------------------------------------------
    return(list(
      model_data              = seir_model_output,
      icu_capacity            = reactive(app_params$icu_capacity),
      ventilator_availability = reactive(app_params$ventilator_availability)
    ))
  })
}
