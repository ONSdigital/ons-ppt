# ============================================================
# File: utils_dependencies.R
# ------------------------------------------------------------
# Description: Detects all R packages used across the project,
# installs missing dependencies, and loads them automatically.
#
# Known limitation (addressed here):
#   The pkg:: regex also matches CSS pseudo-selectors embedded
#   inside tags$style(HTML("...")) blocks, e.g.
#   "#controls-col::-webkit-scrollbar" yields "col" as a false
#   positive. The fix applies two filters after detection:
#     1. A curated blocklist of known false positives.
#     2. A format check: valid CRAN package names contain only
#        letters, digits, and dots, and must start with a letter
#        or digit. Tokens that fail this check are discarded.
#
# Author: Cristian Paez
# Created: 2025-11-07
# ============================================================


# ------------------------------------------------------------
# Step 1. Scan project for relevant R source files
# ------------------------------------------------------------
project_files <- list.files(
  path      = ".",
  pattern   = "\\.(R|Rmd|r|Rproj|qmd)$",
  recursive = TRUE,
  full.names = TRUE
)

# ------------------------------------------------------------
# Step 2. Read all code lines from detected files
# ------------------------------------------------------------
code <- unlist(lapply(project_files, readLines,
                      warn = FALSE, encoding = "UTF-8"))

# ------------------------------------------------------------
# Step 3. Detect package calls
# ------------------------------------------------------------
# Matches: library(xxx), require(xxx), and pkg::function()
# ⚠️ The pkg:: pattern also captures CSS pseudo-selectors
# embedded in inline style strings — see filter steps below.
library_calls <- unique(c(
  stringr::str_match(
    code,
    "(?<=library\\()\\s*['\"]?([A-Za-z0-9\\.]+)['\"]?\\s*\\)?"
  )[, 2],
  stringr::str_match(
    code,
    "(?<=require\\()\\s*['\"]?([A-Za-z0-9\\.]+)['\"]?\\s*\\)?"
  )[, 2],
  stringr::str_match(code, "([A-Za-z0-9\\.]+)::")[, 2]
))

# Remove NAs produced by non-matching lines
library_calls <- library_calls[!is.na(library_calls)]

# ------------------------------------------------------------
# Step 4. Filter false positives
# ------------------------------------------------------------

# --- 4a. Curated blocklist ---
# Tokens that are syntactically valid package names but are
# known non-packages in this codebase (CSS fragments, examples)
blocklist <- c("pkg", "xxx", "", "base", "col")

library_calls <- setdiff(library_calls, blocklist)

# --- 4b. CRAN package name format check ---
# Valid package names: start with a letter or digit, contain
# only letters [A-Za-z], digits [0-9], and dots [.].
# Tokens with hyphens, underscores in leading position, or
# other characters are not installable CRAN packages.
valid_pkg_pattern <- "^[A-Za-z][A-Za-z0-9\\.]*$"
library_calls <- library_calls[
  grepl(valid_pkg_pattern, library_calls, perl = TRUE)
]

# Final deduplication and sort
library_calls <- sort(unique(library_calls))

cat("\U0001f50d Detected project libraries:\n")
print(library_calls)

# ------------------------------------------------------------
# Step 5. Identify missing packages
# ------------------------------------------------------------
installed_packages <- rownames(installed.packages())
missing_packages   <- setdiff(library_calls, installed_packages)

# ------------------------------------------------------------
# Step 6. Install missing dependencies
# ------------------------------------------------------------
if (length(missing_packages) > 0) {
  cat("\n\U0001f4e6 Installing missing packages:\n")
  print(missing_packages)
  install.packages(
    missing_packages,
    dependencies = TRUE,
    repos        = "https://cloud.r-project.org"
  )
} else {
  cat("\n\u2705 All required packages are already installed.\n")
}

# ------------------------------------------------------------
# Step 7. Load all detected libraries
# ------------------------------------------------------------
cat("\n\U0001f680 Loading libraries...\n")
sapply(library_calls, function(pkg) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
})
