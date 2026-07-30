# ============================================================
# File: mod_model.R
# ------------------------------------------------------------
# Description: Implements the SEIR (Susceptible–Exposed–
# Infectious–Recovered) epidemiological model logic.
# Defines differential equations, simulation flow, and
# post-processing of model outputs.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: seir_equations()
# Description:
#   Defines the SEIR differential equations for transmission
#   dynamics. Returns derivatives and new infections at each
#   time step.
# Parameters:
#   time – numeric; current time step.
#   state – named vector with S, E, I, R values.
#   parameters – list containing effective_R0, incubation_period,
#                and infectious_period.
# Returns:
#   List of derivatives and new infections.
# ------------------------------------------------------------
seir_equations <- function(time, state, parameters) {
  with(as.list(c(state, parameters)), {
    N <- S + E + I + R
    
    beta  <- effective_R0 / infectious_period
    sigma <- 1 / incubation_period
    gamma <- 1 / infectious_period
    
    dS <- -beta * S * I / N
    dE <-  beta * S * I / N - sigma * E
    dI <-  sigma * E - gamma * I
    dR <-  gamma * I
    
    new_infections <- sigma * E
    
    list(c(dS, dE, dI, dR),
         new_infections = new_infections)
  })
}

# ------------------------------------------------------------
# Function: model_seir_server()
# Description:
#   Executes the SEIR model simulation using reactive inputs.
#   Integrates ODEs and produces time series of compartments,
#   cases, deaths, and healthcare demand.
# Parameters:
#   id – Shiny module identifier.
#   input_params – reactive list of model parameters.
#   raw_data_df – reactive dataset containing initial state.
# Returns:
#   reactiveVal with simulation results.
# ------------------------------------------------------------
model_seir_server <- function(id, input_params, raw_data_df) {
  moduleServer(id, function(input, output, session) {
    
    # Initialise container for model output
    model_results <- reactiveVal(NULL)
    
    # --- Reactive block: trigger simulation ---
    observeEvent(input_params()$trigger_sim, {
      req(raw_data_df())
      
      # Ensure critical parameters exist before validation
      req(
        !is.null(input_params()$r0_value),
        !is.null(input_params()$incubation_period),
        !is.null(input_params()$infectious_period),
        !is.null(input_params()$ifr_value)
      )
      
      # --- Step 1: Build and validate parameters ---
      params <- list(
        r0_value = input_params()$r0_value,
        incubation_period = input_params()$incubation_period,
        infectious_period = input_params()$infectious_period,
        ifr_value = input_params()$ifr_value,
        icu_admission_rate = input_params()$icu_admission_rate,
        ventilator_usage_rate = input_params()$ventilator_usage_rate,
        start_date = input_params()$start_date,
        end_date = input_params()$end_date,
        population = input_params()$population
      )
      validate_params(params)
      
      # --- Step 2: Numeric conversions ---
      ifr_value             <- percent_to_prop(params$ifr_value)
      icu_admission_rate    <- percent_to_prop(params$icu_admission_rate)
      ventilator_usage_rate <- percent_to_prop(params$ventilator_usage_rate)
      hospital_stay_days    <- INITIAL_HOSPITAL_STAY_DAYS
      
      policy_type      <- input_params()$policy_type
      compliance_level <- percent_to_prop(input_params()$compliance_level)
      req(policy_type, compliance_level)
      
      # --- Step 3: Compute effective R0 under policy ---
      effective_R0 <- params$r0_value
      if (!is.null(policy_type) && policy_type != "no_intervention") {
        effective_R0 <- params$r0_value * (1 - (compliance_level * 0.5))
        effective_R0 <- clamp(effective_R0, 0.5, Inf)
        log_message("DEBUG", "Policy applied: R0 reduction", .module = "MODEL",
                    policy = policy_type,
                    compliance = input_params()$compliance_level,
                    R0_base = params$r0_value,
                    R0_effective = effective_R0)
      } else {
        log_message("DEBUG", "No intervention: effective R0 equals base R0",
                    .module = "MODEL", R0_base = params$r0_value)
      }
      
      # --- Step 4: Define initial state ---
      initial_state_df <- raw_data_df() %>% dplyr::filter(time == 0)
      initial_state <- c(
        S = initial_state_df$S[1],
        E = initial_state_df$E[1],
        I = initial_state_df$I[1],
        R = initial_state_df$R[1]
      )

      # Use the actual sum of the initial state as the reference
      # population for validation. This avoids a race condition
      # where app_params$population is updated by dataset_params
      # after mod_data_server() has already built the frame with
      # a different population value (e.g. CSV upload with a
      # population different from POPULATION_ARGENTINA).
      # params$population is then normalised to match in Step 7.
      actual_population <- sum(initial_state)
      validate_initial_state(initial_state["S"], initial_state["E"],
                             initial_state["I"], initial_state["R"],
                             population = actual_population)
      
      # --- Step 5: Time steps and ODE parameters ---
      times <- raw_data_df()$time
      ode_parms <- c(
        effective_R0 = effective_R0,
        incubation_period = params$incubation_period,
        infectious_period = params$infectious_period
      )
      
      # --- Step 6: Solve ODE system ---
      out <- safe_ode(
        y = initial_state,
        times = times,
        func = seir_equations,
        parms = ode_parms,
        method = "lsoda",
        .module = "MODEL"
      )
      
      # --- Step 7: Post-process results ---
      results_df <- as.data.frame(out)
      names(results_df)[names(results_df) == "new_infections"] <- "Daily_New_Infections"
      
      # Normalise to preserve population
      results_df <- results_df %>%
        dplyr::mutate(
          Total_Population = S + E + I + R,
          S = S * params$population / Total_Population,
          E = E * params$population / Total_Population,
          I = I * params$population / Total_Population,
          R = R * params$population / Total_Population
        ) %>%
        dplyr::select(-Total_Population)
      
      # Compute cumulative metrics
      results_df <- results_df %>%
        dplyr::mutate(
          date = params$start_date + time,
          Cumulative_Cases = cumsum(Daily_New_Infections),
          Daily_Deaths = Daily_New_Infections * ifr_value,
          Cumulative_Deaths = cumsum(Daily_Deaths)
        )
      
      # --- Step 8: ICU and ventilator demand ---
      results_df <- results_df %>%
        dplyr::mutate(
          ICU_Daily_Demand = I * icu_admission_rate,
          Vent_Daily_Demand = I * ventilator_usage_rate,
          ICU_Occupancy_Sim = RcppRoll::roll_sum(
            ICU_Daily_Demand, n = hospital_stay_days,
            align = "right", fill = NA
          ),
          Vent_Usage_Sim = RcppRoll::roll_sum(
            Vent_Daily_Demand, n = hospital_stay_days,
            align = "right", fill = NA
          )
        ) %>%
        dplyr::mutate(
          ICU_Occupancy_Sim = ifelse(is.na(ICU_Occupancy_Sim),
                                     cumsum(tidyr::replace_na(ICU_Daily_Demand, 0)),
                                     ICU_Occupancy_Sim),
          Vent_Usage_Sim = ifelse(is.na(Vent_Usage_Sim),
                                  cumsum(tidyr::replace_na(Vent_Daily_Demand, 0)),
                                  Vent_Usage_Sim)
        )
      
      # Prevent negative values
      results_df$ICU_Occupancy_Sim[results_df$ICU_Occupancy_Sim < 0] <- 0
      results_df$Vent_Usage_Sim[results_df$Vent_Usage_Sim < 0] <- 0
      
      # Log summary of simulation
      log_message("INFO", "SEIR simulation completed", .module = "MODEL",
                  n_steps = nrow(results_df),
                  start = as.character(params$start_date),
                  end = as.character(params$end_date))
      
      model_results(results_df)
    })
    # --- End of reactive block ---
    
    # Return model outputs
    return(model_results)
  })
}
