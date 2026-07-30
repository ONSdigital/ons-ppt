# ============================================================
# File: utils_logging.R
# ------------------------------------------------------------
# Description: Lightweight logging utilities for the SEIR Shiny
# application. Provides structured console output with levels,
# timing wrappers, and contextual information for debugging.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# ------------------------------------------------------------
# Function: log_message()
# Description:
#   Prints formatted log messages to console with timestamp,
#   severity level, and optional context or module name.
# Parameters:
#   level – character; one of "DEBUG", "INFO", "WARN", "ERROR".
#   msg – character message to display.
#   .module – optional string identifying source module.
#   ... – additional key=value pairs for context.
# Returns:
#   Invisibly returns NULL.
# ------------------------------------------------------------
log_message <- function(level = "INFO", msg = "", .module = NULL, ...) {
  levels <- c("DEBUG", "INFO", "WARN", "ERROR")
  level <- toupper(level)
  if (!level %in% levels) level <- "INFO"
  
  # Retrieve active log level from environment
  env_level <- Sys.getenv("LOG_LEVEL", "INFO")
  env_idx <- match(toupper(env_level), levels)
  lvl_idx <- match(level, levels)
  
  # Skip messages below current log level
  if (!is.na(env_idx) && lvl_idx < env_idx)
    return(invisible(NULL))
  
  # Format timestamp and context
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  context <- list(...)
  ctx_str <- if (length(context)) {
    paste(paste0(names(context), "=", unlist(context)), collapse = " | ")
  } else ""
  module_str <- if (!is.null(.module)) paste0("[", .module, "] ") else ""
  
  # Print formatted log line
  cat(sprintf(
    "%s | %-5s | %s%s%s\n",
    ts, level, module_str, msg,
    if (nzchar(ctx_str)) paste0(" | ", ctx_str) else ""
  ))
  
  invisible(NULL)
}

# ------------------------------------------------------------
# Function: set_log_level()
# Description:
#   Sets global log level (environment variable).
# Parameters:
#   level – one of "DEBUG", "INFO", "WARN", "ERROR".
# Returns:
#   None.
# ------------------------------------------------------------
set_log_level <- function(level = c("DEBUG", "INFO", "WARN", "ERROR")) {
  level <- match.arg(level)
  Sys.setenv(LOG_LEVEL = level)
}

# ------------------------------------------------------------
# Function: with_timing()
# Description:
#   Measures and logs execution time of an expression.
# Parameters:
#   expr – R expression to evaluate.
#   .module – optional string for logging context.
#   .label – label for timing entry.
# Returns:
#   Result of evaluated expression, with timing logged.
# ------------------------------------------------------------
with_timing <- function(expr, .module = NULL, .label = "timed_block") {
  t0 <- proc.time()[["elapsed"]]
  on.exit({
    t1 <- proc.time()[["elapsed"]]
    log_message(
      "DEBUG",
      paste0(.label, " completed"),
      .module,
      elapsed_sec = round(t1 - t0, 3)
    )
  })
  force(expr)
}
