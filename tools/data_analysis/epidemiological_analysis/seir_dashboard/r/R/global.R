# ============================================================
# File: global.R
# ------------------------------------------------------------
# Description: Global configuration file. Loads libraries,
# defines constants, and sources shared utility functions.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# --- Core libraries ---
library(shiny)
library(dplyr)
library(bslib)       # For UI themes
library(deSolve)     # For solving differential equations (ODEs)
library(ggplot2)     # For static visualisations
library(lubridate)   # For date manipulation
library(RcppRoll)    # For rolling window operations (e.g. ICU occupancy)
library(tidyr)       # For data reshaping (pivot, replace_na, etc.)
library(scales)      # For axis formatting (comma separators)
library(purrr)       # For list and parameter mapping
library(plotly)      # For interactive charts
library(shinyjs)     # For dynamic UI manipulation

# Prevent scientific notation for large numbers
options(scipen = 999)

# ============================================================
# --- Global constants ---
# ============================================================

# Population baseline (Argentina)
POPULATION_ARGENTINA <- 45000000

# --- SEIR model base parameters ---
INITIAL_R0 <- 2.5
INITIAL_INCUBATION_PERIOD <- 5
INITIAL_INFECTIOUS_PERIOD <- 7
INITIAL_IFR <- 0.01  # 1%

# --- Healthcare resource parameters ---
INITIAL_ICU_RATE <- 0.136
INITIAL_VENTILATOR_RATE <- 0.02
INITIAL_HOSPITAL_STAY_DAYS <- 10
INITIAL_ICU_CAPACITY <- 6000
INITIAL_VENTILATOR_AVAILABILITY <- 2000
INITIAL_HEALTHCARE_STAFF <- 10000

# --- Default simulation dates ---
# Initialised dynamically at app startup so the default
# simulation window is always relative to the current date.
# Users can override these via the dateInput() controls in
# the Advanced View parameter panel (ui_scope_params()).
START_DATE <- Sys.Date()
END_DATE   <- Sys.Date() + 365L

# ============================================================
# --- Load shared utility functions ---
# ------------------------------------------------------------
# Dynamically sources all scripts from /R/utils if available.
# These include functions for logging, validation, and helpers.
# ============================================================

utils_path <- file.path("R", "utils")

if (dir.exists(utils_path)) {
  utils_files <- list.files(utils_path, pattern = "\\.R$", full.names = TRUE)
  sapply(utils_files, source)
  message(sprintf("✅ %d utility files loaded from %s",
                  length(utils_files), utils_path))
} else {
  warning("⚠️ Directory R/utils/ not found. Functions like log_message() or validate_params() may be unavailable.")
}
