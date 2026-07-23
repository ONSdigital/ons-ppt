# ──────────────────────────────────────────────────────────────────────────────
# Forecasting monthly diarrhoea cases under 5 in Malawi – 2026
# Using auto.arima from the forecast package
# Last updated: February 2026
# ──────────────────────────────────────────────────────────────────────────────

# 1. Load required packages
library(rio)         # import data flexibly
library(tidyverse)   # data wrangling & ggplot
library(forecast)    # ARIMA & forecasting
library(tseries)     # ADF test
library(lubridate)   # date handling

# ──────────────────────────────────────────────────────────────────────────────
# 2. Define the exact file path (your file)
# ──────────────────────────────────────────────────────────────────────────────

file_path <- "C:/Users/Shirish Maharjan/OneDrive - HERD/Herd/Samikshya Ji (Tools Testing)/Data/24.02.2026/ARIMA/Data/ARIMA_Demo_Data.csv"

# Safety check – does the file exist?
if (!file.exists(file_path)) {
  stop(paste0(
    "File not found!\n",
    "Checked path: ", file_path, "\n",
    "Please verify:\n",
    "  - File name is correct (Book1.csv)\n",
    "  - Path has no typos\n",
    "  - OneDrive is synced and accessible"
  ))
}

cat("File found at:", file_path, "\n")

# ──────────────────────────────────────────────────────────────────────────────
# 3. Read and clean the data
# ──────────────────────────────────────────────────────────────────────────────


diarrhoea_df <- import(file_path) |> 
  # Try to convert the 'year' (or similar) column to proper date
    mutate(
    date = case_when(
      grepl("^[0-9]{4}-[0-9]{2}$", year)        ~ ym(year),          # 2023-01
      grepl("^[0-9]{4}-[A-Za-z]{3}$", year)     ~ ym(year),          # 2023-Jan
      grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", year) ~ ymd(year),       # 2023-01-15
      grepl("^[0-9]{4}/[0-9]{2}/[0-9]{2}$", year) ~ ymd(year),       # 2023/01/15
      TRUE ~ as.Date(NA)
    )
  ) |>
  # Keep only date and cases – rename if needed
  select(date, cases) |>
  arrange(date) |>
  filter(!is.na(date), !is.na(cases), cases >= 0)

# Basic checks
cat("Number of rows loaded:", nrow(diarrhoea_df), "\n")
cat("Date range:", min(diarrhoea_df$date), "to", max(diarrhoea_df$date), "\n")
cat("Missing values in cases:", sum(is.na(diarrhoea_df$cases)), "\n")
cat("First 6 rows:\n")
print(head(diarrhoea_df, 6))

# ──────────────────────────────────────────────────────────────────────────────
# 4. Convert to monthly time series
# ──────────────────────────────────────────────────────────────────────────────

diarrhoea_ts <- ts(
  diarrhoea_df$cases,
  start = c(min(year(diarrhoea_df$date)), min(month(diarrhoea_df$date))),
  frequency = 12
)

# Handle any NAs (should be rare with your data)
if (anyNA(diarrhoea_ts)) {
  cat("Interpolating", sum(is.na(diarrhoea_ts)), "missing values...\n")
  diarrhoea_ts <- na.interp(diarrhoea_ts)
}

# ──────────────────────────────────────────────────────────────────────────────
# 5. Stationarity test (ADF)
# ──────────────────────────────────────────────────────────────────────────────

adf_result <- adf.test(diarrhoea_ts, alternative = "stationary")
print(adf_result)

if (adf_result$p.value > 0.05) {
  cat("→ p-value > 0.05 → appears non-stationary\n")
  cat("→ auto.arima will handle differencing\n")
} else {
  cat("→ p-value ≤ 0.05 → appears stationary\n")
}

# ──────────────────────────────────────────────────────────────────────────────
# 6. Fit ARIMA model (auto.arima)
# ──────────────────────────────────────────────────────────────────────────────

fit <- auto.arima(
  diarrhoea_ts,
  stepwise    = FALSE,         # more thorough
  approximation = FALSE,
  seasonal    = TRUE,
  trace       = TRUE,          # shows which models are tried
  ic          = "aicc",        # good for smaller samples
  max.order   = 10             # avoid overly complex models
)

# Show results
summary(fit)
cat("\nSelected ARIMA model order:", fit$arma, "\n")

# ──────────────────────────────────────────────────────────────────────────────
# 7. Model diagnostics
# ──────────────────────────────────────────────────────────────────────────────

checkresiduals(fit, lag = 24)

# ──────────────────────────────────────────────────────────────────────────────
# 8. Forecast next 12 months (2026)
# ──────────────────────────────────────────────────────────────────────────────

fc <- forecast(fit, h = 12, level = c(80, 95))

# Print forecast summary
print(summary(fc))

# ──────────────────────────────────────────────────────────────────────────────
# 9. Plot the forecast
# ──────────────────────────────────────────────────────────────────────────────

autoplot(fc, PI = TRUE) +
  labs(
    title    = "Forecast of Monthly Diarrhoea Cases Under 5 – Malawi 2026",
    subtitle = paste("ARIMA model:", paste(fit$arma, collapse = ",")),
    x        = "Year – Month",
    y        = "Reported Cases"
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))

# Optional: save the plot
# ggsave("diarrhoea_forecast_2026.png", width = 10, height = 6, dpi = 300)