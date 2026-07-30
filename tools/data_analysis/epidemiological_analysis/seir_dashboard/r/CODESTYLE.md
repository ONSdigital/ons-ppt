# CODESTYLE.md  
**SEIR Epidemiological Dashboard – Coding and Commenting Standards**

## 1. Language and General Rules
- All code **and comments** must be written in **English (UK)**.  
- Encoding: **UTF-8**.  
- Indentation: **2 spaces**, no tabs.  
- Maximum line length: **80 characters**.  
- Use **snake_case** for variables and functions.  
- Use **UpperCamelCase** only for classes or special objects.  
- Constants in **UPPER_CASE**.  
- Line endings: LF (`\n`).

---

## 2. File Header
Each R file begins with a descriptive header:

```r
# ============================================================
# File: mod_model.R
# ------------------------------------------------------------
# Description: Implements the SEIR epidemiological model logic.
# Author: [Full name]
# Created: YYYY-MM-DD
# ============================================================
```

---

## 3. Section Headers
Use visible separators to identify code blocks:

```r
# --- SEIR Model Equations ---
# Defines the differential equations for the SEIR system.
```

---

## 4. Function Documentation
Each function includes a documentation header describing purpose, inputs, and outputs.

```r
# ------------------------------------------------------------
# Function: model_seir_server()
# Description: Executes SEIR simulation using reactive inputs.
# Parameters:
#   input_params (reactive) – user-defined model parameters
#   raw_data_df  (reactive) – initial simulated dataset
# Returns:
#   reactiveVal containing model outputs.
# ------------------------------------------------------------
```

If migrating to `roxygen2`, the equivalent format is:

```r
#' Executes SEIR simulation using reactive inputs.
#' @param input_params reactive user-defined parameters
#' @param raw_data_df reactive dataset
#' @return reactiveVal with SEIR model output
```

---

## 5. Inline Comments
- Explain *intent*, not syntax.  
- Use concise English sentences starting with a capital letter.  
- Place above the code block, not beside it.

```r
# Compute number of days for simulation
days <- as.numeric(params()$end_date - params()$start_date) + 1
```

Avoid inline clutter:
```r
days <- as.numeric(params()$end_date - params()$start_date) + 1  # avoid this style
```

---

## 6. Structural Comments
Clearly mark logical blocks and control structures:

```r
# --- Reactive block: trigger simulation ---
observeEvent(input$run_simulation, {
  app_params$trigger_sim <- app_params$trigger_sim + 1
})
# --- End of reactive block ---
```

---

## 7. Logging and Risk Flags
Use standard emoji markers sparingly to indicate important runtime or review notes:

- `# ⚠️` – Warning or potential issue.  
- `# ✅` – Validation success (optional).  
- `# ❌` – Known limitation or pending implementation.

Example:
```r
# ⚠️ Validate dataset structure before loading
```

---

## 8. Naming Conventions
| Element Type     | Convention         | Example                    |
|------------------|--------------------|----------------------------|
| Functions        | `snake_case()`     | `load_dataset()`           |
| Reactives        | `snake_case()`     | `model_results <- reactiveVal()` |
| Constants        | `UPPER_CASE`       | `INITIAL_R0 <- 2.5`        |
| Parameters list  | `snake_case`       | `input_params$r0_value`    |
| Modules          | `mod_*` prefix     | `mod_server()`             |

---

## 9. Module Header Comments
Every Shiny module must declare its scope and role:

```r
# This module handles interactive visualisations for the SEIR model.
# It generates SEIR, cumulative, and resource plots using ggplot2.
```

---

## 10. Validation, Testing, and Style Enforcement
- Style check: `lintr::lint()` (Tidyverse/Google style).  
- Auto-format: `styler::style_file()`.  
- Unit tests: `testthat`.  
- Minimum 80% of non-trivial lines documented.

---

## 11. Example of Correct Commenting Style
```r
# ============================================================
# File: mod_data.R
# Description: Simulates or loads input datasets for SEIR model.
# ============================================================

# --- Server function for data simulation ---
mod_data_server <- function(id, params) {
  moduleServer(id, function(input, output, session) {

    # Initialise reactive container for simulated data
    simulated_data <- reactiveVal(NULL)

    # Generate new dataset whenever simulation is triggered
    observeEvent(params()$trigger_sim, {
      req(params()$start_date, params()$end_date, params()$population)

      # Compute simulation time steps
      days <- as.numeric(params()$end_date - params()$start_date) + 1
      time_points <- 0:days

      # Build default dataset structure for MVP
      dummy_data <- data.frame(
        time = time_points,
        date = params()$start_date + time_points,
        S = numeric(length(time_points)),
        E = numeric(length(time_points)),
        I = numeric(length(time_points)),
        R = numeric(length(time_points))
      )

      # Initialise initial conditions for visibility
      dummy_data$S[1] <- params()$population - 10000
      dummy_data$I[1] <- 10000

      simulated_data(dummy_data)
    })

    # Return reactive dataset
    return(simulated_data)
  })
}
```

---

## 12. Documentation and Localisation Strategy
- This commenting structure is fully compatible with `roxygen2`, `devtools::document()`, and `pkgdown::build_site()`.  
- Comments remain in **English (UK)** in all translations.  
- User and developer documentation (guides, README, manuals) may be translated separately (e.g., to French, Spanish).  
- Code comments remain invariant to preserve reproducibility and traceability across versions.

---

**Maintainer:** Cristian Paez  
**Project:** SEIR Epidemiological Dashboard  
**Version:** 1.0 (November 2025)

