# ============================================================
# File: mod_viz.R
# ------------------------------------------------------------
# Description: Handles generation of SEIR model visualisations,
# including compartment curves, cumulative cases/deaths, and
# critical resource demand vs. capacity plots.
#
# Colour palette: aligned with Analysis for Action (AfA
# Toolkit) brand guidelines.
#   Categorical data visualisation palette (in order):
#     Near black   #1E2A16  – Susceptible
#     Burnt orange #D17E38  – Exposed
#     Dark stone   #444443  – Infected
#     Sea green    #3EA27F  – Recovered
#   Accent / alert:
#     Orange       #F59342  – Cumulative Deaths, Demand line
#     Dark green   #324027  – Cumulative Cases, Capacity line
#   Ribbon fill (excess demand alert):
#     Earthy warm  #F0D9C8  – translucent warning fill
#
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: viz_plot_server()
# Description:
#   Manages interactive plots derived from SEIR model output.
#   Generates three visualisation panels:
#     1. SEIR compartment dynamics
#     2. Cumulative cases and deaths
#     3. Critical resource demand and capacity
# Parameters:
#   id – Shiny module identifier.
#   model_data – reactive dataset from SEIR model.
#   icu_capacity_input – reactive numeric input for ICU capacity.
#   ventilator_availability_input – reactive numeric input for
#     ventilator availability.
# Returns:
#   Server-side visualisation outputs.
# ------------------------------------------------------------
viz_plot_server <- function(id, model_data, icu_capacity_input,
                            ventilator_availability_input) {
  moduleServer(id, function(input, output, session) {

    # --------------------------------------------------------
    # Shared ggplot2 theme — AfA palette, X-axis guide lines
    # --------------------------------------------------------
    # Applied consistently across all three plots.
    # panel.grid.major.x adds vertical guide lines at each
    # major date break, helping users read values on the X axis.
    # panel.grid.minor.x adds finer guides between major breaks.
    afa_theme <- function() {
      theme_minimal() +
        theme(
          plot.title         = element_text(hjust = 0.5, face = "bold",
                                            size = 16, colour = "#1E2A16"),
          axis.title         = element_text(size = 12, colour = "#48553F"),
          axis.text          = element_text(size = 10, colour = "#48553F"),
          legend.position    = "bottom",
          legend.title       = element_blank(),
          legend.text        = element_text(size = 10, colour = "#48553F"),
          panel.background   = element_rect(fill = "#F8F5F1", colour = NA),
          plot.background    = element_rect(fill = "#F8F5F1", colour = NA),
          # Major vertical grid lines — orient the X axis
          panel.grid.major.x = element_line(colour = "#D0D4CE", linewidth = 0.35),
          # Minor vertical grid lines — finer reference
          panel.grid.minor.x = element_line(colour = "#E4E7E2", linewidth = 0.2),
          # Horizontal grid lines — keep for Y axis readability
          panel.grid.major.y = element_line(colour = "#D0D4CE", linewidth = 0.35),
          panel.grid.minor.y = element_blank(),
          strip.text         = element_text(size = 12, face = "bold",
                                            colour = "#1E2A16")
        )
    }

    # --------------------------------------------------------
    # --- SEIR compartment curves plot ---
    # --------------------------------------------------------
    output$seir_plot <- renderPlot({
      plot_data <- model_data()

      if (is.null(plot_data) || nrow(plot_data) == 0) {
        cat("VIZ_MODULE: model_data() is NULL or empty for seir_plot.\n")
        return(
          ggplot() +
            annotate("text", x = 0.5, y = 0.5,
                     label = "No data available", size = 8,
                     colour = "#48553F") +
            theme_void()
        )
      }
      req(plot_data)

      # Categorical colours follow AfA data visualisation order:
      # near black → burnt orange → dark stone → sea green
      # linewidth replaces the deprecated size aesthetic (ggplot2 >= 3.4.0)
      ggplot(plot_data, aes(x = date)) +
        geom_line(aes(y = S, colour = "Susceptible"), linewidth = 1) +
        geom_line(aes(y = E, colour = "Exposed"),     linewidth = 1) +
        geom_line(aes(y = I, colour = "Infected"),    linewidth = 1) +
        geom_line(aes(y = R, colour = "Recovered"),   linewidth = 1) +
        labs(
          title  = "Population Dynamics (SEIR)",
          x      = "Date",
          y      = "Number of Individuals",
          colour = "Compartment"
        ) +
        scale_y_continuous(labels = scales::comma) +
        scale_colour_manual(
          values = c(
            "Susceptible" = "#1E2A16",
            "Exposed"     = "#D17E38",
            "Infected"    = "#444443",
            "Recovered"   = "#3EA27F"
          )
        ) +
        afa_theme()
    })

    # --------------------------------------------------------
    # --- Cumulative cases and deaths plot ---
    # --------------------------------------------------------
    output$cases_deaths_plot <- renderPlot({
      plot_data <- model_data()

      if (is.null(plot_data) || nrow(plot_data) == 0) {
        return(
          ggplot() +
            annotate("text", x = 0.5, y = 0.5,
                     label = "No data available", size = 8,
                     colour = "#48553F") +
            theme_void()
        )
      }
      req(plot_data)

      # Cases: dark green (primary AfA colour)
      # Deaths: orange accent (AfA standard accent)
      # linewidth replaces the deprecated size aesthetic (ggplot2 >= 3.4.0)
      ggplot(plot_data, aes(x = date)) +
        geom_line(aes(y = Cumulative_Cases,  colour = "Cumulative Cases"),
                  linewidth = 1) +
        geom_line(aes(y = Cumulative_Deaths, colour = "Cumulative Deaths"),
                  linewidth = 1) +
        labs(
          title  = "Simulated Cumulative Cases and Deaths",
          x      = "Date",
          y      = "Cumulative Number",
          colour = "Metric"
        ) +
        scale_y_continuous(labels = scales::comma) +
        scale_colour_manual(
          values = c(
            "Cumulative Cases"  = "#324027",
            "Cumulative Deaths" = "#F59342"
          )
        ) +
        afa_theme()
    })

    # --------------------------------------------------------
    # --- Critical resource pressure plot ---
    # --------------------------------------------------------
    output$resource_pressure_plot <- renderPlot({
      cat("VIZ_MODULE: resource_pressure_plot rendering.\n")
      plot_data_raw <- model_data()

      current_icu_capacity            <- icu_capacity_input()
      current_ventilator_availability <- ventilator_availability_input()

      if (is.null(plot_data_raw) || nrow(plot_data_raw) == 0) {
        cat("VIZ_MODULE: model_data() is NULL or empty for resource plot.\n")
        return(
          ggplot() +
            annotate("text", x = 0.5, y = 0.5,
                     label = "No data available", size = 8,
                     colour = "#48553F") +
            theme_void()
        )
      }
      req(plot_data_raw)

      # Prepare demand dataset
      demand_plot_data <- plot_data_raw %>%
        select(date, ICU_Occupancy_Sim, Vent_Usage_Sim) %>%
        pivot_longer(
          cols      = -date,
          names_to  = "Metric",
          values_to = "Value"
        ) %>%
        mutate(
          Resource_Category = case_when(
            grepl("ICU",  Metric) ~ "ICU",
            grepl("Vent", Metric) ~ "Ventilators",
            TRUE                  ~ NA_character_
          ),
          Metric_Label = "Demand"
        ) %>%
        filter(!is.na(Resource_Category))

      # Capacity reference lines
      capacity_data_icu <- data.frame(
        date              = unique(demand_plot_data$date),
        Value             = current_icu_capacity,
        Metric            = "ICU_Capacity_Current",
        Resource_Category = "ICU",
        Metric_Label      = "Capacity"
      )

      capacity_data_vent <- data.frame(
        date              = unique(demand_plot_data$date),
        Value             = current_ventilator_availability,
        Metric            = "Ventilator_Availability_Current",
        Resource_Category = "Ventilators",
        Metric_Label      = "Capacity"
      )

      combined_plot_data <- bind_rows(demand_plot_data,
                                      capacity_data_icu,
                                      capacity_data_vent)

      # Identify periods where simulated demand exceeds capacity
      ribbon_data <- combined_plot_data %>%
        filter(Metric_Label %in% c("Demand", "Capacity")) %>%
        pivot_wider(
          names_from  = Metric_Label,
          values_from = Value,
          id_cols     = c(date, Resource_Category),
          values_fill = list(Value = 0)
        ) %>%
        mutate(
          Demand   = as.numeric(Demand),
          Capacity = as.numeric(Capacity)
        ) %>%
        filter(Demand > Capacity)

      # Demand line: orange accent — signals alert state
      # Capacity line: dark green — stable reference threshold
      # Ribbon fill: earthy warm tint — excess demand warning zone
      # linewidth replaces deprecated size aesthetic (ggplot2 >= 3.4.0)
      ggplot(combined_plot_data,
             aes(x = date, y = Value,
                 colour   = Metric_Label,
                 linetype = Metric_Label)) +
        geom_line(linewidth = 1) +
        geom_ribbon(
          data        = ribbon_data,
          aes(ymin = Capacity, ymax = Demand,
              x = date, fill = "Demand Exceeded"),
          alpha       = 0.4,
          inherit.aes = FALSE
        ) +
        facet_wrap(~Resource_Category, scales = "free_y", ncol = 1) +
        labs(
          title    = "Critical Resource Demand and Capacity",
          x        = "Date",
          y        = "Number of Units",
          colour   = "Metric Type",
          linetype = "Metric Type",
          fill     = "Alert"
        ) +
        scale_y_continuous(labels = scales::comma) +
        scale_colour_manual(
          values = c(
            "Demand"   = "#F59342",
            "Capacity" = "#324027"
          )
        ) +
        scale_linetype_manual(
          values = c(
            "Demand"   = "solid",
            "Capacity" = "dashed"
          )
        ) +
        scale_fill_manual(
          values = c("Demand Exceeded" = "#F0D9C8"),
          name   = "Alert"
        ) +
        afa_theme()
    })
  })
}
