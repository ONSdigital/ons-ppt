# ============================================================
# File: mod_server_simple.R
# ------------------------------------------------------------
# Description: Simple View server module for the SEIR Dashboard.
#   Handles isolated SEIR model execution and reactive alarm
#   logic for the three KPI cards.
#
#   Design contract:
#     - State is FULLY ISOLATED from the Advanced View.
#       Both views initialise from the same dataset snapshot
#       (dataset_params), then evolve independently as the
#       user adjusts their own controls. Changes in one view
#       never affect the other.
#     - The ODE solver is re-run when either slider changes
#       (simple_r0, simple_compliance).
#     - Alarm thresholds (six numeric inputs) do NOT re-run
#       the ODE solver — they only update the indicators.
#     - mod_data_server() and model_seir_server() are called
#       internally under the "simple_data" and "simple_seir"
#       namespace ids to avoid collisions with the Advanced View.
#
#   Shared helpers (alarm_shape_svg, state_label_ui,
#   metric_value_ui, resolve_alarm_state, coalesce_num) are
#   defined in mod_helpers_simple.R, which loadSupport() sources
#   before this file (alphabetical order: h < s).
#
#   Alarm states per card:
#     "controlled" | "warning" | "critical"
#
#   AfA palette used for alarm shapes:
#     #3EA27F (sea green) | #F59342 (orange) | #752111 (dark red)
#
# Author: Cristian Paez
# Created: 2026-03-19
# ============================================================


# ------------------------------------------------------------
# Function: mod_server_simple()
# Description:
#   Server logic for the Simple View. Maintains isolated SEIR
#   model state initialised from global.R. Runs the ODE solver
#   when sliders change and updates KPI card alarm states
#   reactively when thresholds change.
# Parameters:
#   id               – Shiny module identifier.
#   dataset_selector – reactiveVal(character); active source key,
#                      passed through for logging only.
#   dataset_params   – reactiveVal(list); calibrated parameters
#                      from the loaded dataset ($parametros,
#                      $recursos, $poblacion). NULL for mock.
#                      Used to initialise simple_params once on
#                      dataset load; sliders take over after that.
# Returns:
#   None (side effects only: renderUI calls for the three cards).
# ------------------------------------------------------------
mod_server_simple <- function(id, dataset_selector,
                              dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {

    # --------------------------------------------------------
    # Log module start
    # --------------------------------------------------------
    log_message("INFO", "mod_server_simple started", .module = "SIMPLE")

    # --------------------------------------------------------
    # Dataset parameter initialisation
    # When a calibrated dataset is loaded (user CSV),
    # apply its parameters to simple_params so the Simple View
    # starts from the same snapshot as the Advanced View.
    # ignoreNULL = TRUE prevents this firing for mock datasets.
    # --------------------------------------------------------
    observeEvent(dataset_params(), {
      dp <- dataset_params()
      req(!is.null(dp), !is.null(dp$parametros))

      isolate({
        simple_params$r0_value        <- dp$parametros$R0
        simple_params$incubation_period <- dp$parametros$incubation_period
        simple_params$infectious_period <- dp$parametros$infectious_period
        simple_params$ifr_value       <- dp$parametros$IFR * 100

        simple_params$icu_capacity            <- dp$recursos$INITIAL_ICU_CAPACITY
        simple_params$ventilator_availability <- dp$recursos$INITIAL_VENTILATOR_AVAILABILITY
        simple_params$healthcare_staff        <- dp$recursos$INITIAL_HEALTHCARE_STAFF
        simple_params$icu_admission_rate      <- dp$recursos$INITIAL_ICU_RATE * 100
        simple_params$ventilator_usage_rate   <- dp$recursos$INITIAL_VENTILATOR_RATE * 100

        if (!is.null(dp$poblacion)) {
          simple_params$population <- dp$poblacion
        }

        # Update sliders to reflect new parameter values
        updateSliderInput(session, "simple_r0",
                          value = dp$parametros$R0)

        simple_params$trigger_sim <- simple_params$trigger_sim + 1L
      })

      log_message("INFO",
                  "Simple View initialised from dataset parameters",
                  .module = "SIMPLE")
    }, ignoreNULL = TRUE)

    # --------------------------------------------------------
    # Isolated parameter store
    # Initialised from dataset_params when a calibrated dataset
    # is loaded; falls back to global.R constants for mock.
    # Sliders in the Simple View write ONLY to these values.
    # The Advanced View has no access to this reactiveValues.
    # --------------------------------------------------------
    simple_params <- reactiveValues(
      r0_value         = INITIAL_R0,
      compliance_level = 50,

      # Fixed parameters — not exposed in Simple View sliders
      incubation_period = INITIAL_INCUBATION_PERIOD,
      infectious_period = INITIAL_INFECTIOUS_PERIOD,
      ifr_value         = INITIAL_IFR * 100,    # percent [0, 100]

      icu_capacity            = INITIAL_ICU_CAPACITY,
      icu_admission_rate      = INITIAL_ICU_RATE * 100,    # percent
      ventilator_availability = INITIAL_VENTILATOR_AVAILABILITY,
      ventilator_usage_rate   = INITIAL_VENTILATOR_RATE * 100, # percent
      healthcare_staff        = INITIAL_HEALTHCARE_STAFF,

      # phased_mitigation: compliance slider has meaningful effect
      policy_type = "phased_mitigation",

      start_date  = START_DATE,
      end_date    = END_DATE,
      population  = POPULATION_ARGENTINA,

      trigger_sim = 0L
    )

    # --------------------------------------------------------
    # Slider observers — update isolated params and trigger sim
    # ignoreInit = FALSE so the initial slider value fires
    # immediately on load and the first simulation runs.
    # --------------------------------------------------------
    observeEvent(input$simple_r0, {
      req(!is.null(input$simple_r0))
      simple_params$r0_value    <- input$simple_r0
      simple_params$trigger_sim <- simple_params$trigger_sim + 1L
      log_message("DEBUG",
                  paste("Simple View R0 changed to:", input$simple_r0),
                  .module = "SIMPLE")
    }, ignoreInit = FALSE)

    observeEvent(input$simple_compliance, {
      req(!is.null(input$simple_compliance))
      simple_params$compliance_level <- input$simple_compliance
      simple_params$trigger_sim      <- simple_params$trigger_sim + 1L
    }, ignoreInit = FALSE)

    # --------------------------------------------------------
    # Data module — generates raw initial state for the ODE.
    # Uses "simple_data" namespace to avoid collision with the
    # Advanced View data module ("data_sim").
    # --------------------------------------------------------
    simple_raw_data <- mod_data_server(
      "simple_data",
      params = reactive({
        list(
          start_date  = simple_params$start_date,
          end_date    = simple_params$end_date,
          population  = simple_params$population,
          trigger_sim = simple_params$trigger_sim
        )
      })
    )

    # --------------------------------------------------------
    # SEIR model — runs under "simple_seir" namespace.
    # Receives only the isolated simple_params; the Advanced
    # View parameters are never referenced here.
    # --------------------------------------------------------
    simple_model_output <- model_seir_server(
      "simple_seir",
      input_params = reactive({
        list(
          r0_value          = simple_params$r0_value,
          incubation_period = simple_params$incubation_period,
          infectious_period = simple_params$infectious_period,
          ifr_value         = simple_params$ifr_value,

          icu_capacity            = simple_params$icu_capacity,
          ventilator_availability = simple_params$ventilator_availability,
          healthcare_staff        = simple_params$healthcare_staff,

          icu_admission_rate    = simple_params$icu_admission_rate,
          ventilator_usage_rate = simple_params$ventilator_usage_rate,

          policy_type      = simple_params$policy_type,
          compliance_level = simple_params$compliance_level,

          start_date  = simple_params$start_date,
          end_date    = simple_params$end_date,
          population  = simple_params$population,

          trigger_sim = simple_params$trigger_sim
        )
      }),
      raw_data_df = simple_raw_data
    )

    # --------------------------------------------------------
    # Computed KPI metrics
    # Kept as separate reactive expressions so threshold changes
    # re-evaluate alarm states without re-running the ODE solver.
    # --------------------------------------------------------

    # --- KPI 1: Weekly growth rate of I ---
    # Compares the mean of the infectious compartment (I) over
    # the final 7 simulation days to the preceding 7 days.
    # Returns a percentage change; negative values = declining.
    kpi_growth_rate <- reactive({
      df <- simple_model_output()
      req(df, nrow(df) >= 14)

      n     <- nrow(df)
      last7 <- mean(df$I[(n - 6):n],        na.rm = TRUE)
      prev7 <- mean(df$I[(n - 13):(n - 7)], na.rm = TRUE)

      if (is.na(prev7) || prev7 == 0) return(0)
      ((last7 - prev7) / prev7) * 100
    })

    # --- KPI 2: ICU occupancy on the final simulation day as % of capacity ---
    # Uses the last row of ICU_Occupancy_Sim rather than the historical
    # peak. The rolling-sum nature of ICU_Occupancy_Sim means the peak
    # can be orders of magnitude above capacity under high-transmission
    # scenarios, producing misleading percentages for a decision-maker
    # card. The final-day value reflects the current epidemic status,
    # which is the intended signal of this view.
    kpi_icu_pct <- reactive({
      df <- simple_model_output()
      req(df)

      last_icu <- df$ICU_Occupancy_Sim[nrow(df)]
      cap      <- simple_params$icu_capacity
      if (is.na(cap) || cap == 0) return(NA_real_)
      (last_icu / cap) * 100
    })

    # --- KPI 3: Cumulative deaths on the final simulation day as % of population ---
    # Uses the last row of Cumulative_Deaths (the end-of-simulation total).
    kpi_deaths_pct <- reactive({
      df <- simple_model_output()
      req(df)

      last_deaths <- df$Cumulative_Deaths[nrow(df)]
      pop         <- simple_params$population
      if (is.na(pop) || pop == 0) return(NA_real_)
      (last_deaths / pop) * 100
    })

    # --------------------------------------------------------
    # Alarm state computations
    # Each reactive calls resolve_alarm_state() (defined in
    # mod_helpers_simple.R) using the current metric and the
    # threshold numericInput values from the Settings panel.
    # These do NOT depend on trigger_sim — they react only to
    # kpi_* changes and threshold input changes.
    # --------------------------------------------------------

    alarm_trajectory <- reactive({
      resolve_alarm_state(
        value = kpi_growth_rate(),
        warn  = coalesce_num(input$thr_growth_warn, 1),
        crit  = coalesce_num(input$thr_growth_crit, 20)
      )
    })

    alarm_icu <- reactive({
      resolve_alarm_state(
        value = kpi_icu_pct(),
        warn  = coalesce_num(input$thr_icu_warn,  70),
        crit  = coalesce_num(input$thr_icu_crit, 100)
      )
    })

    alarm_deaths <- reactive({
      resolve_alarm_state(
        value = kpi_deaths_pct(),
        warn  = coalesce_num(input$thr_deaths_warn, 0.05),
        crit  = coalesce_num(input$thr_deaths_crit, 0.20)
      )
    })

    # --------------------------------------------------------
    # Rendered outputs — Card 1: Epidemic Trajectory
    # --------------------------------------------------------
    output$shape_trajectory <- renderUI({
      alarm_shape_svg(alarm_trajectory(), size = 64)
    })

    output$label_trajectory <- renderUI({
      state_label_ui(alarm_trajectory())
    })

    output$value_trajectory <- renderUI({
      val <- kpi_growth_rate()
      if (is.na(val) || !is.finite(val)) {
        metric_value_ui("N/A", "weekly growth rate of I")
      } else {
        formatted <- paste0(ifelse(val >= 0, "+", ""), round(val, 2), "%")
        metric_value_ui(formatted, "weekly growth rate of I")
      }
    })

    # --------------------------------------------------------
    # Rendered outputs — Card 2: ICU Pressure
    # --------------------------------------------------------
    output$shape_icu <- renderUI({
      alarm_shape_svg(alarm_icu(), size = 64)
    })

    output$label_icu <- renderUI({
      state_label_ui(alarm_icu())
    })

    output$value_icu <- renderUI({
      val <- kpi_icu_pct()
      if (is.na(val) || !is.finite(val)) {
        metric_value_ui("N/A", "ICU occupancy vs capacity (final day)")
      } else {
        metric_value_ui(paste0(round(val, 2), "%"),
                        "ICU occupancy vs capacity (final day)")
      }
    })

    # --------------------------------------------------------
    # Rendered outputs — Card 3: Cumulative Impact
    # --------------------------------------------------------
    output$shape_deaths <- renderUI({
      alarm_shape_svg(alarm_deaths(), size = 64)
    })

    output$label_deaths <- renderUI({
      state_label_ui(alarm_deaths())
    })

    output$value_deaths <- renderUI({
      val <- kpi_deaths_pct()
      if (is.na(val) || !is.finite(val)) {
        metric_value_ui("N/A", "cumulative deaths as % of population (final day)")
      } else {
        metric_value_ui(paste0(round(val, 2), "%"),
                        "cumulative deaths as % of population (final day)")
      }
    })

    log_message("INFO", "mod_server_simple observers registered",
                .module = "SIMPLE")
  })
}
