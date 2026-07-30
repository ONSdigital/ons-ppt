# ============================================================
# File: mod_data.R
# ------------------------------------------------------------
# Description: Simulates data ingestion and provides a structured
# dataset for SEIR model use. Acts as the default data source
# when no external dataset is selected.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: mod_data_ui()
# Description:
#   Data module UI function. Returns NULL as this module
#   performs backend operations only (no visible UI elements).
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   NULL.
# ------------------------------------------------------------
mod_data_ui <- function(id) {
  NULL
}

# ------------------------------------------------------------
# Function: mod_data_server()
# Description:
#   Server logic for the data simulation module. Generates a
#   default SEIR-compatible dataset or simulates ingestion from
#   external sources.
# Parameters:
#   id – Shiny module identifier.
#   params – reactive list containing:
#     start_date, end_date, population, trigger_sim.
# Returns:
#   reactiveVal containing the simulated dataset.
# ------------------------------------------------------------
mod_data_server <- function(id, params) {
  moduleServer(id, function(input, output, session) {
    
    # Initialise reactive container for simulated dataset
    simulated_data <- reactiveVal(NULL)
    
    # --- Reactive block: trigger new simulation ---
    observeEvent(params()$trigger_sim, {
      req(params()$start_date, params()$end_date, params()$population)
      
      # Compute number of days in simulation range
      days <- as.numeric(params()$end_date - params()$start_date) + 1
      time_points <- 0:days
      
      # Build dataset structure expected by SEIR model
      dummy_data <- data.frame(
        time = time_points,
        date = params()$start_date + time_points,
        S = numeric(length(time_points)),
        E = numeric(length(time_points)),
        I = numeric(length(time_points)),
        R = numeric(length(time_points)),
        Cases = numeric(length(time_points)),
        Deaths = numeric(length(time_points)),
        ICU_Occupancy = numeric(length(time_points)),
        Vent_Usage = numeric(length(time_points))
      )
      
      # Initialise first row for visibility in plots
      dummy_data$S[1] <- params()$population - 10000
      dummy_data$I[1] <- 10000
      
      # ⚠️ In a future version, replace with API or file ingestion
      simulated_data(dummy_data)
    })
    # --- End of reactive block ---
    
    # Return reactive dataset to server modules
    return(simulated_data)
  })
}
