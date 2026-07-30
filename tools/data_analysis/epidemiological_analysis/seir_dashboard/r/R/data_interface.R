# ============================================================
# File: data_interface.R
# ------------------------------------------------------------
# Description: Central Data Hub Interface.
# Provides unified functions to load, validate, and persist
# datasets from different sources (mock, CSV/API).
# Ensures schema compatibility for SEIR models.
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================

# --- Dependencies ---
source_if_exists <- function(path) if (file.exists(path)) source(path)
source_if_exists("R/utils/utils_validation.R")
source_if_exists("R/utils/utils_logging.R")

# --- Base directories ---
DATA_DIR  <- "data"
CACHE_DIR <- file.path(DATA_DIR, "cache")
if (!dir.exists(CACHE_DIR)) dir.create(CACHE_DIR, recursive = TRUE)

# ============================================================
# Function: build_dataset()
# ------------------------------------------------------------
# Description:
#   Constructs the SEIR-compatible initialisation data frame
#   from a parameter set. This is the single point of
#   construction for all dataset sources — mock and
#   user-uploaded CSV. Ensures a consistent structure
#   regardless of origin.
#
#   Design note: dates are NOT stored in the dataset.
#   Simulation dates are parameters of the run, controlled
#   by the user via dateInput() in the Advanced View and
#   initialised from global.R (START_DATE, END_DATE).
#
# Parameters:
#   population – numeric; total population (N in the SEIR).
#   start_date – Date; simulation start (default: START_DATE).
#   end_date   – Date; simulation end   (default: END_DATE).
#   n_infected – numeric; initial infectious count (default: 10000).
# Returns:
#   Data frame with columns: time, date, S, E, I, R.
# ============================================================
build_dataset <- function(population,
                          start_date = NULL,
                          end_date   = NULL,
                          n_infected = 10000) {

  # Fall back to global constants if dates not supplied.
  # Using NULL defaults instead of START_DATE/END_DATE directly
  # prevents errors when build_dataset() is defined before
  # global.R is sourced (e.g. during the self-test block).
  if (is.null(start_date)) start_date <- START_DATE
  if (is.null(end_date))   end_date   <- END_DATE

  days        <- as.numeric(end_date - start_date)
  time_points <- 0:days

  data.frame(
    time = time_points,
    date = start_date + time_points,
    S    = population - n_infected,  # all others susceptible at t = 0
    E    = 0,                         # no exposed at t = 0
    I    = n_infected,                # seed infectious count
    R    = 0                          # no recovered at t = 0
  )
}


# ============================================================
# Function: get_data()
# ------------------------------------------------------------
# Description:
#   Returns a SEIR-compatible initialisation data frame based
#   on the selected source. For the parameter-based mock
#   source, delegates construction to build_dataset(). For
#   user-uploaded CSV, validates the parameter file and calls
#   build_dataset() with the user-supplied values.
#
# Parameters:
#   source     – character; one of "mock", "csv".
#   params     – list; additional arguments per source:
#                  csv: params$path — path to uploaded CSV file.
#   start_date – Date; simulation start (default: START_DATE).
#   end_date   – Date; simulation end   (default: END_DATE).
# Returns:
#   Named list with:
#     $data       – data frame for ODE initialisation.
#     $parametros – epidemiological parameters (NULL for mock).
#     $recursos   – healthcare resource parameters (NULL for mock).
#     $poblacion  – total population numeric value.
# ============================================================
get_data <- function(source     = "mock",
                     params     = list(),
                     start_date = NULL,
                     end_date   = NULL) {

  if (is.null(start_date)) start_date <- START_DATE
  if (is.null(end_date))   end_date   <- END_DATE

  log_message("INFO", paste("get_data() loading source:", source),
              .module = "DATA_INTERFACE")

  if (source == "mock") {
    # Mock: use global defaults — no calibrated parameters.
    # build_dataset() constructs the initialisation frame.
    data <- build_dataset(
      population = POPULATION_ARGENTINA,
      start_date = start_date,
      end_date   = end_date
    )
    result <- list(data       = data,
                   parametros = NULL,
                   recursos   = NULL,
                   poblacion  = POPULATION_ARGENTINA)

  } else if (source == "csv") {
    # User CSV: validate parameter file, then build dataset.
    # Handled by validate_user_csv() — see below.
    if (is.null(params$path))
      stop("params$path is required for source = 'csv'")
    user_params <- validate_user_csv(params$path)
    data <- build_dataset(
      population = user_params$poblacion,
      start_date = start_date,
      end_date   = end_date
    )
    result <- list(data       = data,
                   parametros = user_params$parametros,
                   recursos   = user_params$recursos,
                   poblacion  = user_params$poblacion)

  } else {
    stop(paste("Unknown data source:", source))
  }

  validate_schema(result$data)
  return(result)
}
# ============================================================
# Function: validate_schema()
# ------------------------------------------------------------
# Description:
#   Validates dataset structure for SEIR model compatibility.
# Parameters:
#   data – data frame to validate.
# Returns:
#   TRUE if schema is valid, stops otherwise.
# ============================================================
validate_schema <- function(data) {
  required_cols <- c("time", "S", "E", "I", "R")
  missing <- setdiff(required_cols, names(data))

  if (length(missing) > 0) {
    log_message("ERROR",
                paste("Missing columns:", paste(missing, collapse = ", ")),
                .module = "DATA_INTERFACE")
    stop(paste("Dataset schema invalid:",
               paste(missing, collapse = ", ")))
  }

  for (col in required_cols) {
    if (!is.numeric(data[[col]])) {
      stop(paste("Column", col, "must be numeric"))
    }
  }

  log_message("INFO", "Schema validated successfully",
              .module = "DATA_INTERFACE")
  return(TRUE)
}

# ============================================================
# Function: validate_user_csv()
# ------------------------------------------------------------
# Description:
#   Reads and validates a user-uploaded CSV parameter file.
#   The CSV must follow the canonical two-column format:
#     parameter,value
#   with the required parameters listed below. Returns a
#   named list following the canonical calibrated-dataset
#   structure ($parametros / $recursos / $poblacion),
#   compatible with build_dataset() and mod_server.R.
#
#   Required CSV columns: parameter, value
#   Required parameters (see User Guide for definitions):
#     r0, incubation_period, infectious_period, ifr,
#     icu_capacity, ventilator_availability,
#     healthcare_staff, icu_admission_rate,
#     ventilator_usage_rate, population
#
# Parameters:
#   path – character; path to the uploaded CSV file.
# Returns:
#   Named list with elements: parametros, recursos, poblacion.
# ============================================================
validate_user_csv <- function(path) {

  if (!file.exists(path))
    stop(paste("Uploaded file not found at:", path))

  # Accept both comma and semicolon delimiters
  raw <- tryCatch(
    read.csv(path, stringsAsFactors = FALSE),
    error = function(e) read.csv2(path, stringsAsFactors = FALSE)
  )

  required_cols <- c("parameter", "value")
  missing_cols  <- setdiff(required_cols, names(raw))
  if (length(missing_cols) > 0) {
    stop(paste(
      "CSV must have columns: parameter, value. Missing:",
      paste(missing_cols, collapse = ", ")
    ))
  }

  # Build named vector for easy lookup
  params <- setNames(as.numeric(raw$value), raw$parameter)

  required_params <- c(
    "r0", "incubation_period", "infectious_period", "ifr",
    "icu_capacity", "ventilator_availability",
    "healthcare_staff", "icu_admission_rate",
    "ventilator_usage_rate", "population"
  )

  missing_params <- setdiff(required_params, names(params))
  if (length(missing_params) > 0) {
    stop(paste(
      "Missing required parameters in CSV:",
      paste(missing_params, collapse = ", ")
    ))
  }

  if (any(is.na(params[required_params]))) {
    na_params <- required_params[is.na(params[required_params])]
    stop(paste(
      "Non-numeric or missing values in CSV for:",
      paste(na_params, collapse = ", ")
    ))
  }

  log_message("INFO", "User CSV validated successfully",
              .module = "DATA_INTERFACE")

  # Return in canonical calibrated-dataset structure
  list(
    parametros = list(
      R0                = params[["r0"]],
      incubation_period = params[["incubation_period"]],
      infectious_period = params[["infectious_period"]],
      IFR               = params[["ifr"]]
    ),
    recursos = list(
      INITIAL_ICU_CAPACITY             = params[["icu_capacity"]],
      INITIAL_VENTILATOR_AVAILABILITY  = params[["ventilator_availability"]],
      INITIAL_HEALTHCARE_STAFF         = params[["healthcare_staff"]],
      INITIAL_ICU_RATE                 = params[["icu_admission_rate"]],
      INITIAL_VENTILATOR_RATE          = params[["ventilator_usage_rate"]],
      INITIAL_HOSPITAL_STAY_DAYS       = 10  # not user-configurable at this stage
    ),
    poblacion = params[["population"]]
  )
}


# ============================================================
# Function: save_dataset()
# ------------------------------------------------------------
# Description:
#   Saves a validated dataset into /data/cache/.
# Parameters:
#   data – data frame already validated.
#   name – optional custom dataset name.
# Returns:
#   Full file path of the saved dataset.
# ============================================================
save_dataset <- function(data, name = NULL) {
  validate_schema(data)
  if (is.null(name))
    name <- paste0("dataset_", format(Sys.time(), "%Y%m%d_%H%M%S"))

  file_path <- file.path(CACHE_DIR, paste0(name, ".rds"))
  saveRDS(data, file_path)

  log_message("INFO", paste("Dataset saved to cache:", file_path),
              .module = "DATA_INTERFACE")

  return(file_path)
}

# ============================================================
# Function: list_datasets()
# ------------------------------------------------------------
# Description:
#   Lists all cached datasets within /data/cache/.
# Returns:
#   Data frame with Name, Path, and Size_MB.
# ============================================================
list_datasets <- function() {
  files <- list.files(CACHE_DIR, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0)
    return(data.frame(Name = NA, Path = NA, Size_MB = NA))

  data.frame(
    Name    = basename(files),
    Path    = normalizePath(files),
    Size_MB = round(file.info(files)$size / 1024^2, 3)
  )
}

# ============================================================
# Local self-test (interactive sessions only)
# ------------------------------------------------------------
# Guards: only runs in interactive sessions AND only when the
# global constants from global.R are already available.
# This prevents errors when data_interface.R is sourced by
# Shiny before global.R has been loaded.
# ============================================================
if (interactive() &&
    exists("START_DATE") &&
    exists("END_DATE")   &&
    exists("POPULATION_ARGENTINA")) {
  log_message("INFO", "=== Data Hub self-test ===", .module = "DATA_INTERFACE")
  df   <- get_data("mock")
  validate_schema(df$data)
  path <- save_dataset(df$data, "test_mock")
  print(list_datasets())
}
