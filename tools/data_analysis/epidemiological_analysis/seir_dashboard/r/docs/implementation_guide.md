# Implementation Guide — SEIR Epidemiological Dashboard

**Analysis for Action · Argentina Unit · Product 3**

| | |
|---|---|
| **Author** | Cristian Paez |
| **Version** | 2.0 |
| **Date** | May 2026 |
| **Related documents** | `README.md` |

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Requirements](#2-system-requirements)
3. [Repository Structure](#3-repository-structure)
4. [Installation and Local Setup](#4-installation-and-local-setup)
5. [Configuration](#5-configuration)
6. [Module Architecture](#6-module-architecture)
7. [SEIR Model — Equations and Parameters](#7-seir-model--equations-and-parameters)
8. [Dataset Sources](#8-dataset-sources)
9. [Visual Design System](#9-visual-design-system)
10. [Deployment](#10-deployment)
11. [Known Limitations](#11-known-limitations)
12. [References](#12-references)

---

## 1. Overview

The SEIR Epidemiological Dashboard is a modular, interactive web application built with the R
Shiny framework. It implements a Susceptible–Exposed–Infectious–Recovered (SEIR) compartmental
model for infectious disease scenario simulation, with real-time parameter adjustment and
healthcare resource pressure analysis.

The application is deployed as a public web application at:
<https://cpaez.shinyapps.io/afa-dashboard-arg/>

Source code is available at:
<https://github.com/XtnPaez/afa-dashboard-arg>

---

## 2. System Requirements

### 2.1 Development environment

- R >= 4.4.0 (tested on R 4.4.0, 2024-04-24 ucrt)
- RStudio (recommended) or any R-compatible IDE
- Git

### 2.2 Required R packages

All dependencies are declared in the project `DESCRIPTION` file. Install them from an R session:

```r
install.packages(c(
  "shiny",      # Web application framework
  "shinyjs",    # Dynamic UI manipulation
  "bslib",      # Bootstrap 5 themes
  "ggplot2",    # Static visualisations (>= 3.4.0 required)
  "dplyr",      # Data manipulation
  "tidyr",      # Data reshaping
  "purrr",      # Functional programming utilities
  "scales",     # Axis formatting
  "lubridate",  # Date manipulation
  "deSolve",    # ODE integration (SEIR equations)
  "RcppRoll",   # Rolling window for ICU occupancy
  "plotly",     # Interactive layer (reserved for future use)
  "rsconnect",  # Deployment to shinyapps.io
  "stringr"     # String utilities
))
```

> **Note on ggplot2:** ggplot2 >= 3.4.0 is required. Earlier versions use the deprecated
> `size` aesthetic for line width; the codebase uses `linewidth` throughout.

### 2.3 Software infrastructure

- Web server: shinyapps.io (current deployment) or self-hosted Shiny Server
- No database management system is required. Datasets are stored as `.rds` files in the
  `data/` directory.
  
---

## 3. Repository Structure

```
afa-dashboard-arg/
├── app.R                        # Application entry point
├── DESCRIPTION                  # R package metadata and dependencies
├── LICENSE                      # MIT licence
├── NAMESPACE                    # R package namespace
├── README.md                    # Project overview
├── CODESTYLE.md                 # Coding and commenting standards
│
├── R/
│   ├── global.R                 # Global constants and library loading
│   ├── data_interface.R         # Data Hub: loading, validation, caching
│   ├── mod_entry.R              # Entry screen and CSV upload module
│   ├── mod_menu.R               # Top navigation menu module
│   ├── mod_ui.R                 # Advanced View UI layout and panels
│   ├── mod_ui_simple.R          # Simplified View UI layout and KPI cards
│   ├── mod_server.R             # Main server: parameter wiring, model orchestration
│   ├── mod_server_simple.R      # Simplified View server: isolated SEIR + alarm logic
│   ├── mod_helpers_simple.R     # Shared helpers: alarm shapes, state labels, metrics
│   ├── mod_model.R              # SEIR ODE model logic
│   ├── mod_viz.R                # Visualisation module (ggplot2)
│   ├── mod_data.R               # Data simulation module
│   └── utils/
│       ├── utils_logging.R      # Structured logging utilities
│       ├── utils_validation.R   # Parameter and schema validation
│       ├── utils_helpers.R      # Numeric helpers and safe ODE wrapper
│       └── utils_dependencies.R # Automatic dependency detection and loading
│
├── data/
│   ├── mock_dataset.rds         # Simulated default dataset
│
├── docs/
│   └── implementation_guide.md  # This document
│
└── www/
    └── custom.css               # Visual overrides — AfA brand palette
```

---

## 4. Installation and Local Setup

### 4.1 Clone the repository

```bash
git clone https://github.com/XtnPaez/afa-dashboard-arg.git
cd afa-dashboard-arg
```

### 4.2 Install dependencies

```r
# Option A — manual install
install.packages(c(
  "shiny", "shinyjs", "bslib", "ggplot2", "dplyr", "tidyr",
  "purrr", "scales", "lubridate", "deSolve", "RcppRoll",
  "plotly", "rsconnect", "stringr"
))

# Option B — resolve from DESCRIPTION (requires pak)
pak::pak()
```

### 4.3 Run locally

```r
shiny::runApp()
```

The application will open in the default browser at `http://127.0.0.1:PORT`.

### 4.4 Automatic dependency loading

`utils_dependencies.R` scans all project source files for `library()`, `require()`, and
`pkg::function()` calls, then installs and loads any missing packages automatically at startup.

---

## 5. Configuration

All global constants are defined in `R/global.R`. Modifying this file is the single point
of change for default simulation parameters.

### 5.1 Epidemiological parameters

| Constant | Default | Description |
|----------|---------|-------------|
| `INITIAL_R0` | 2.5 | Basic reproduction number |
| `INITIAL_INCUBATION_PERIOD` | 5 days | Incubation period |
| `INITIAL_INFECTIOUS_PERIOD` | 7 days | Infectious period |
| `INITIAL_IFR` | 0.01 | Infection Fatality Rate (proportion) |

### 5.2 Healthcare resource parameters

| Constant | Default | Source | Description |
|----------|---------|--------|-------------|
| `INITIAL_ICU_RATE` | 0.136 | IECS | Proportion of infected requiring ICU |
| `INITIAL_VENTILATOR_RATE` | 0.02 | International studies | Proportion requiring ventilation |
| `INITIAL_HOSPITAL_STAY_DAYS` | 10 days | IECS / CDC | Average hospital stay |
| `INITIAL_ICU_CAPACITY` | 6,000 | SATI | Available ICU beds |
| `INITIAL_VENTILATOR_AVAILABILITY` | 2,000 | SATI | Available ventilators |
| `INITIAL_HEALTHCARE_STAFF` | 10,000 | CONICET | Staff in critical care |

### 5.3 Population and simulation dates

| Constant | Default | Description |
|----------|---------|-------------|
| `POPULATION_ARGENTINA` | 45,000,000 | Total population baseline (INDEC) |
| `START_DATE` | `Sys.Date()` | Simulation start — initialised dynamically at startup |
| `END_DATE` | `Sys.Date() + 365L` | Simulation end — initialised dynamically at startup |

> **Note on simulation dates:** `START_DATE` and `END_DATE` are computed at app startup,
> not hardcoded. This ensures the default simulation window is always relative to the current
> date. Users can override both dates via the `dateInput()` controls in the Advanced View
> Simulation Scope panel. The `dateInput()` widget was chosen over separate numeric fields
> because it renders a native calendar picker — the most intuitive interaction for non-technical
> users (design decision documented in `mod_ui.R`).

### 5.4 Log level

Logging verbosity is controlled by the `LOG_LEVEL` environment variable.
Accepted values: `DEBUG`, `INFO`, `WARN`, `ERROR`. Default: `INFO`.

```r
Sys.setenv(LOG_LEVEL = "DEBUG")  # verbose output during development
Sys.setenv(LOG_LEVEL = "WARN")   # minimal output in production
```

---

## 6. Module Architecture

The application follows a strict modular pipeline:

```
data_interface  →  mod_data  →  mod_model  →  mod_viz
                                    ↑
                               mod_server
                             ↗          ↖
                       mod_entry      mod_menu
                             ↖          ↗
                                 app.R
                                   ↑
                              mod_ui / mod_ui_simple
```

All modules are loaded automatically by Shiny's `loadSupport()` mechanism because the project
contains a `DESCRIPTION` file.

### 6.1 Key modules

| Module | File | Responsibility |
|--------|------|----------------|
| Entry screen | `mod_entry.R` | Dataset selection, CSV upload modal, navigation |
| Navigation menu | `mod_menu.R` | Persistent navbar, dataset indicator, view switching |
| Advanced View UI | `mod_ui.R` | Sidebar parameter panels and tabbed output area |
| Simplified View UI | `mod_ui_simple.R` | KPI card layout, scenario sliders, Settings panel |
| Main server | `mod_server.R` | Parameter wiring, ODE orchestration, CSV export |
| Simple View server | `mod_server_simple.R` | Isolated SEIR model, alarm state computation |
| Simple View helpers | `mod_helpers_simple.R` | Alarm SVG shapes, state labels, metric values |
| SEIR model | `mod_model.R` | Differential equations, post-processing, resource demand |
| Visualisation | `mod_viz.R` | Three ggplot2 panels with AfA brand theme |
| Data simulation | `mod_data.R` | Initial time-series structure for ODE solver |
| Data Hub | `data_interface.R` | Dataset loading, validation, schema checks, caching |

> **Critical namespace note:** `viz_plot_server()` must be called from the top-level server
> function in `app.R`, not from inside `mod_server()`. See Implementation Guide section 6.1
> for full explanation.

### 6.2 Dual-view initialisation contract

When a dataset is loaded, `mod_entry_server()` populates a `dataset_params` reactiveVal in
`app.R` with the calibrated parameters (`$parametros`, `$recursos`, `$poblacion`). This
reactive is passed to both `mod_server()` (Advanced View) and `mod_server_simple()`
(Simplified View), which initialise their isolated parameter stores from the same snapshot.
After initialisation, each view evolves independently — changes in one never affect the other.

### 6.3 Utility modules

| Module | Responsibility |
|--------|---------------|
| `utils_logging.R` | Structured log lines with timestamp, level, and module context |
| `utils_validation.R` | Parameter range checks and compartment consistency validation |
| `utils_helpers.R` | `clamp()`, `percent_to_prop()`, `safe_ode()` and other numeric helpers |
| `utils_dependencies.R` | Automatic package detection, installation, and loading at startup |

---

## 7. SEIR Model — Equations and Parameters

### 7.1 Compartmental structure

| Compartment | Symbol | Description |
|-------------|--------|-------------|
| Susceptible | S | Individuals with no immunity who may become infected |
| Exposed | E | Individuals infected but not yet infectious |
| Infectious | I | Individuals actively infectious |
| Recovered | R | Individuals who have recovered and are assumed to be immune |

### 7.2 Differential equations

The model is governed by the following system of ODEs, integrated numerically using
`deSolve::ode()`:

```
dS/dt = -β · (S · I) / N
dE/dt =  β · (S · I) / N  −  σ · E
dI/dt =  σ · E  −  γ · I
dR/dt =  γ · I

Where:
  N = S + E + I + R   (total population)
  β = R₀ · γ          (transmission rate)
  σ = 1 / λE          (progression rate: exposed → infectious)
  γ = 1 / λI          (recovery rate)
  λE = incubation period (days)
  λI = infectious period (days)
```

### 7.3 Effective R₀ under policy

When a public health intervention is active, the effective reproduction number is reduced
proportionally to the compliance level:

```
R₀_eff = R₀ · (1 − 0.5 · c)
```

Where `c` is the compliance level as a proportion in [0, 1]. At full compliance (c = 1),
R₀ is reduced by 50%. The effective value is clamped to a minimum of 0.5.

### 7.4 Healthcare resource demand

```
ICU_Daily_Demand_t    = I_t · r_ICU
Vent_Daily_Demand_t   = I_t · r_vent
ICU_Occupancy_Sim_t   = Σ ICU_Daily_Demand_k  (k = t−h+1 to t)
Vent_Usage_Sim_t      = Σ Vent_Daily_Demand_k (k = t−h+1 to t)
```

Where `h = INITIAL_HOSPITAL_STAY_DAYS` (default: 10 days).

> **Approximation note:** ICU and ventilator occupancy are estimated using a rolling sum,
> which is a computational simplification. A more precise model would use a queueing model
> with individual-level data, which is not available at this stage.

---

## 8. Dataset Sources

### 8.1 Simulated dataset (mock)

Constructed by `build_dataset()` using global defaults from `global.R`. Initial state:
`S = POPULATION_ARGENTINA − 10,000`, `I = 10,000`, `E = 0`, `R = 0`.

### 8.2 User-uploaded CSV

Users can upload their own regional parameter snapshot via the entry screen. The CSV must
follow this two-column format:

```csv
parameter,value
r0,2.8
incubation_period,5
infectious_period,7
ifr,0.012
icu_capacity,3200
ventilator_availability,800
healthcare_staff,6500
icu_admission_rate,0.14
ventilator_usage_rate,0.02
population,18000000
```

The CSV is validated by `validate_user_csv()` in `data_interface.R`, which checks column
names, required parameter presence, and numeric validity. On success, the parameters are
applied to both views via `dataset_params`.

**Design rationale:** The dataset is a parameter snapshot — a "photo" of the user's health
system and epidemiological context. The platform uses it as the starting point for simulation.
Users then adjust sliders to explore "what if" scenarios. Dates are not part of the dataset;
they are simulation parameters controlled via the Simulation Scope panel.

## 9. Visual Design System

The interface follows the Analysis for Action (AfA) brand guidelines.
All chart styling is centralised in the `afa_theme()` function inside `mod_viz.R`.

### 9.1 UI colour palette

| Role | Name | Hex |
|------|------|-----|
| Primary / navbar | Dark green | `#324027` |
| Secondary surface | Earthy green | `#48553F` |
| Accent (sparingly) | Orange | `#F59342` |
| Body text | Near black | `#1E2A16` |
| Page background | Green grey tint | `#F4F6F5` |
| Panel / input background | Earthy tint | `#F8F5F1` |
| Border | Grey | `#D0D4CE` |

### 9.2 Chart colours — SEIR compartments

| Compartment | Colour | Hex |
|-------------|--------|-----|
| Susceptible | Near black | `#1E2A16` |
| Exposed | Burnt orange | `#D17E38` |
| Infectious | Dark stone | `#444443` |
| Recovered | Sea green | `#3EA27F` |

### 9.3 Simplified View alarm palette

| State | Shape | Colour | Hex |
|-------|-------|--------|-----|
| Controlled | Circle | AfA sea green | `#3EA27F` |
| Warning | Triangle | AfA orange | `#F59342` |
| Critical | Square | AfA dark red | `#752111` |

---

## 10. Deployment

### 10.1 shinyapps.io

```r
library(rsconnect)
rsconnect::deployApp(
  appDir      = ".",
  appName     = "afa-dashboard-arg",
  forceUpdate = TRUE
)
```

Ensure `rsconnect` is configured with a valid shinyapps.io account token before deploying.

### 10.2 Self-hosted Shiny Server

Copy the repository to the Shiny Server apps directory (typically `/srv/shiny-server/`)
and ensure all R package dependencies are installed in the server's R library path.

### 10.3 Environment variables for production

```bash
LOG_LEVEL=WARN   # suppress DEBUG and INFO output in production
```

---

## 11. Known Limitations

| Limitation | Status |
|------------|--------|
| External data connectivity (WHO, OWID APIs) | Deferred — architecture documented in section 8.4 |
| Sociodemographic data layer | Out of scope — relevant fields should be included in user CSV |
| ICU / ventilator occupancy uses rolling sum approximation | By design — queueing model requires individual-level data not available |
| IFR applied as a global value | By design — age-stratified IFR is outside current ToR scope |
