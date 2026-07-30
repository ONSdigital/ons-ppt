# ============================================================
# File: utils_helpers.R
# ------------------------------------------------------------
# Description: Numeric utility functions and safe ODE wrapper
# for SEIR model integration. Provides general-purpose helpers
# for mathematical operations and error-safe model execution.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: clamp()
# Description:
#   Restricts a numeric value to a given interval.
# Parameters:
#   x – numeric vector.
#   minv – minimum allowed value.
#   maxv – maximum allowed value.
# Returns:
#   Clamped numeric vector.
# ------------------------------------------------------------
clamp <- function(x, minv, maxv) pmax(minv, pmin(x, maxv))

# ------------------------------------------------------------
# Function: percent_to_prop()
# Description:
#   Converts percentage values to proportions (0–1 scale).
# Parameters:
#   x_pct – numeric percentage value.
# Returns:
#   Numeric proportion.
# ------------------------------------------------------------
percent_to_prop <- function(x_pct) x_pct / 100

# ------------------------------------------------------------
# Function: not_null()
# Description:
#   Returns TRUE if object is not NULL.
# Parameters:
#   x – any R object.
# Returns:
#   Logical TRUE/FALSE.
# ------------------------------------------------------------
not_null <- function(x) !is.null(x)

# ------------------------------------------------------------
# Function: safe_ode()
# Description:
#   Executes ODE integration safely, catching errors and logging
#   runtime messages. Wraps deSolve::ode() and integrates
#   SEIR differential equations under monitored conditions.
# Parameters:
#   y – initial state vector.
#   times – numeric vector of time points.
#   func – differential equation function.
#   parms – model parameters.
#   method – integration method (default "lsoda").
#   .module – string label for logging context.
# Returns:
#   Data frame of ODE integration results.
# ------------------------------------------------------------
safe_ode <- function(y, times, func, parms, method = "lsoda", .module = "MODEL") {
  tryCatch({
    with_timing({
      deSolve::ode(y = y, times = times, func = func, parms = parms, method = method)
    }, .module = .module, .label = "ode_integration")
  }, error = function(e) {
    log_message("ERROR", "ODE integration failed", .module,
                error = conditionMessage(e))
    stop("Error solving SEIR system. Check parameters and initial states.",
         call. = FALSE)
  })
}
