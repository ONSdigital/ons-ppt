# ============================================================
# File: utils_validation.R
# ------------------------------------------------------------
# Description: Validation utilities for epidemiological and
# healthcare resource parameters used in SEIR model execution.
# Includes checks for numeric ranges, logical consistency, and
# valid initial states.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: validate_params()
# Description:
#   Validates epidemiological and resource parameters provided
#   to the SEIR model. Ensures numeric ranges, existence of
#   required keys, and chronological consistency.
# Parameters:
#   params – named list containing SEIR model parameters.
# Returns:
#   Invisibly returns params if valid; stops execution otherwise.
# ------------------------------------------------------------
validate_params <- function(params) {
  
  # --- Helper: ensure parameter existence ---
  stop_if_missing <- function(nm) {
    if (is.null(params[[nm]]))
      stop(sprintf("Missing parameter: %s", nm), call. = FALSE)
  }
  
  # Required parameter names
  req_names <- c(
    "r0_value", "incubation_period", "infectious_period", "ifr_value",
    "icu_admission_rate", "ventilator_usage_rate",
    "start_date", "end_date", "population"
  )
  lapply(req_names, stop_if_missing)
  
  # Validate positive numeric parameters
  num_pos <- c("r0_value", "incubation_period", "infectious_period", "population")
  for (nm in num_pos) {
    if (!is.numeric(params[[nm]]) || params[[nm]] <= 0)
      stop(sprintf("'%s' must be numeric and greater than 0", nm), call. = FALSE)
  }
  
  # Validate percentage parameters within [0, 100]
  pct_01 <- c("ifr_value", "icu_admission_rate", "ventilator_usage_rate")
  for (nm in pct_01) {
    if (!is.numeric(params[[nm]]) || params[[nm]] < 0 || params[[nm]] > 100)
      stop(sprintf("'%s' must be within range [0, 100]", nm), call. = FALSE)
  }
  
  # Check chronological order of dates
  if (as.Date(params$end_date) < as.Date(params$start_date))
    stop("'end_date' cannot be earlier than 'start_date'", call. = FALSE)
  
  invisible(params)
}

# ------------------------------------------------------------
# Function: validate_initial_state()
# Description:
#   Ensures initial SEIR compartment values are valid and
#   consistent with the total population.
# Parameters:
#   S, E, I, R – numeric initial state values.
#   population – total population for consistency check.
#   tol – numeric tolerance for floating-point comparison.
# Returns:
#   TRUE if validation passes; stops otherwise.
# ------------------------------------------------------------
validate_initial_state <- function(S, E, I, R, population, tol = 1e-6) {
  
  # Validate non-negative numeric values
  for (v in c(S, E, I, R)) {
    if (!is.numeric(v) || v < 0)
      stop("Initial states must be numeric and ≥ 0", call. = FALSE)
  }
  
  # Validate population balance
  tot <- S + E + I + R
  if (abs(tot - population) > max(population * 1e-6, tol))
    stop("S + E + I + R must equal 'population' within tolerance", call. = FALSE)
  
  TRUE
}
