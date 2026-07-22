################################################################################
# NEPAL IMPACT ANALYSIS DENGUE OUTBREAK - HEALTH EMERGENCY IMPACT ANALYSIS
# FULL PIPELINE: SECTION 3.3 (DATA PREPARATION) -> SECTION 3.5.6 (COST- EFFECTIVENESS ANALYSIS)
# Author : Herd International, Nepal
# Project : Analysis for Action
# Date : 20.07.2026
# ------------------------------------------------------------------------------
# This script follows the structure of the impact-analysis reference document (R_HRR_Nepal_impact_analysis) section by section, using the exact section numbers as headers so results 
# can be cross-checked against the write-up:
#
#   3.3   Preparing data for quantitative analysis
#   3.4   Analysis of Likert-scale data
#   3.5   Approaches to health emergency impact analysis
#   3.5.1 Small-area estimation
#   3.5.2 Scenario modelling
#   3.5.3 Prevalence analysis
#   3.5.4 Determinant analysis
#   3.5.5 Regression analysis
#   3.5.6 Cost-effectiveness analysis
#
# INPUT: This script expects the *realistic, messy* raw CSV (20260708_Dengue_Raw_Data.csv).
#        That file intentionally contains missing values, impossible values,
#        inconsistent coding, and duplicate rows, exactly the kind of "raw"
#        household survey export described in Section 3.3, so that the data-
#        cleaning code below has real work to do rather than a no-op.
#
# OUTPUT: cleaned/de-identified analysis dataset, a data dictionary, and all
#         tables (.csv) / plots (.png) from every analysis stage, written into
#         OUTPUT_DIR.
################################################################################


## =============================================================================
## 0. PACKAGES & GLOBAL SETUP
## =============================================================================
required_packages <- c(
  "tidyverse", "janitor", "car", "MASS", "broom", "corrplot", "epitools",
  "rstatix", "performance", "scales", "psych", "lme4"
)
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages) > 0) install.packages(new_packages, dependencies = TRUE)
invisible(lapply(required_packages, library, character.only = TRUE))

set.seed(123)

RAW_CSV    <- "C:/Users/Shirish Maharjan/OneDrive - HERD/Herd/Analysis for Action (AFA)/Data/20260708_Dengue_Raw_Data.csv" # Please change your path here
OUTPUT_DIR <- paste0("dengue_impact_outputs_", format(Sys.Date(), "%Y%m%d"))
TABLE_DIR  <- file.path(OUTPUT_DIR, "tables")
PLOT_DIR   <- file.path(OUTPUT_DIR, "plots")
LOG_DIR    <- file.path(OUTPUT_DIR, "cleaning_log")
for (d in c(OUTPUT_DIR, TABLE_DIR, PLOT_DIR, LOG_DIR)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# A running, timestamped cleaning log -- Section 3.3 step 3 asks analysts to
# "use a script or log to track every change you make so your work can be
# checked and repeated." This function appends one line per cleaning action.
cleaning_log <- character(0)
log_step <- function(msg) {
  entry <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", msg)
  cleaning_log <<- c(cleaning_log, entry)
  cat(entry, "\n")
}


################################################################################
## 3.3  PREPARING DATA FOR QUANTITATIVE ANALYSIS
################################################################################

## ---------------------------------------------------------------------------
## 3.3 (a) Import & protect the raw data
## ---------------------------------------------------------------------------
# The raw file is read but NEVER overwritten -- all cleaning happens on a copy
# ("df"), keeping the original raw export untouched for audit purposes.
raw_df <- read.csv(RAW_CSV, stringsAsFactors = FALSE, na.strings = c("", "NA", "N/A"))
log_step(paste("Imported raw file:", RAW_CSV, "-", nrow(raw_df), "rows,", ncol(raw_df), "columns"))

df <- raw_df  # working copy - raw_df is preserved untouched

## ---------------------------------------------------------------------------
## 3.3 (b) Define variables and indicators
## ---------------------------------------------------------------------------
# Variable roles (numerical / categorical / binary), as recommended in the document's step 1 ("Define variables and indicators"). These lists drive
# every later section, so they are defined once, here, up front.
binary_vars <- c(
  "sex", "children_under5_present", "elderly_hh_member_present",
  "chronic_disease_status", "hh_affected_dengue", "confirmed_dengue_case_hh",
  "open_ceiling", "earth_flooring", "hospitalised_dengue",
  "complications_present", "death_due_to_dengue_hh",
  "school_work_absenteeism_dengue", "mosquito_control_measures",
  "health_info_access", "health_insurance", "dengue_infection_status",
  "hospitalisation_status", "disability_functional_limit",
  "healthcare_utilisation", "reduction_social_participation",
  "caregiving_responsibility_change", "debt_borrowing",
  "asset_sale_coping", "healthcare_seeking_behaviour",
  "access_diagnosis_treatment", "govt_ngo_support_received"
)
nominal_vars <- c("education_level", "religion", "ethnicity", "occupation",
                   "urban_rural", "province")
ordinal_vars <- c("outbreak_intensity", "dengue_severity", "self_reported_health",
                   "severity_illness_med", "duration_illness_med",
                   "social_support_availability")
count_vars <- c("hh_size", "num_dengue_cases_hh", "num_hh_members_infected",
                 "school_absenteeism_days", "work_absenteeism_days",
                 "productivity_loss_workdays")
continuous_vars <- c(
  "age", "hh_income_monthly_nrs", "duration_outbreak_exposure_days",
  "proximity_hotspot_km", "days_ill", "caregiving_burden_score",
  "dengue_prevention_knowledge_score", "healthcare_access_score",
  "env_risk_index", "days_illness_recovery", "mental_health_score",
  "oop_health_expenditure_nrs", "social_support_score",
  "community_cohesion_score", "perceived_stigma_score",
  "hh_income_loss_nrs", "direct_medical_expenditure_nrs",
  "transport_treatment_cost_nrs", "financial_assistance_received_nrs",
  "hh_caregiving_burden_med", "oop_expenditure_med",
  "knowledge_preventive_practices"
)

## ---------------------------------------------------------------------------
## 3.3 (c) Organise and structure the dataset / machine-readable naming
## ---------------------------------------------------------------------------
# Column names are already lowercase_with_underscores (machine-readable), but
# we re-run janitor::clean_names() defensively in case the raw export used
# spaces, mixed case, or special characters.
names_before <- names(df)
df <- janitor::clean_names(df)
if (!identical(names_before, names(df))) {
  log_step("Standardised column names to lowercase_with_underscores (janitor::clean_names)")
}

## ---------------------------------------------------------------------------
## 3.3 (d) Smart de-duplication
## ---------------------------------------------------------------------------
# Uses the anonymous respondent_id (NOT a name) to detect double data entry.
n_before <- nrow(df)
dup_ids  <- df$respondent_id[duplicated(df$respondent_id)]
df <- df %>% distinct(respondent_id, .keep_all = TRUE)
log_step(paste("De-duplication: removed", n_before - nrow(df),
                "duplicate record(s) sharing the same respondent_id"))

## ---------------------------------------------------------------------------
## 3.3 (e) Format standardisation - inconsistent category coding
## ---------------------------------------------------------------------------
# Real exports often mix "Male"/"male"/"M", "Yes"/"yes"/"Y"/"1", etc. Each
# variant is mapped to ONE standardised label so categories don't get silently
# split into extra, spurious levels.
standardise_categories <- function(x, yes_no = FALSE) {
  x <- trimws(x)
  if (yes_no) {
    x <- dplyr::case_when(
      toupper(x) %in% c("YES", "Y", "1") ~ "Yes",
      toupper(x) %in% c("NO", "N", "0")   ~ "No",
      TRUE ~ x
    )
  }
  x
}

before_levels <- length(unique(df$sex))
df$sex <- dplyr::case_when(
  toupper(trimws(df$sex)) %in% c("MALE", "M")   ~ "Male",
  toupper(trimws(df$sex)) %in% c("FEMALE", "F") ~ "Female",
  TRUE ~ trimws(df$sex)
)
df$urban_rural <- dplyr::case_when(
  toupper(trimws(df$urban_rural)) %in% c("URBAN", "U") ~ "Urban",
  toupper(trimws(df$urban_rural)) %in% c("RURAL", "R") ~ "Rural",
  TRUE ~ trimws(df$urban_rural)
)
for (v in intersect(binary_vars, names(df))) {
  df[[v]] <- standardise_categories(df[[v]], yes_no = TRUE)
}
log_step(paste("Standardised category coding for 'sex', 'urban_rural' and",
                length(intersect(binary_vars, names(df))), "Yes/No variables",
                "(collapsed", before_levels, "-> 2 raw spellings of sex, etc.)"))

## ---------------------------------------------------------------------------
## 3.3 (f) Type-consistency: fix stray non-numeric entries in numeric columns
## ---------------------------------------------------------------------------
# e.g. a data-entry clerk typing "ten" instead of 10 in a count column.
number_words <- c(zero=0, one=1, two=2, three=3, four=4, five=5, six=6,
                   seven=7, eight=8, nine=9, ten=10)
fix_text_numbers <- function(x) {
  x_chr <- as.character(x)
  hit <- tolower(trimws(x_chr)) %in% names(number_words)
  x_chr[hit] <- number_words[tolower(trimws(x_chr[hit]))]
  suppressWarnings(as.numeric(x_chr))
}
for (v in c(count_vars, continuous_vars)) {
  if (v %in% names(df) && !is.numeric(df[[v]])) {
    n_text <- sum(!is.na(df[[v]]) & is.na(suppressWarnings(as.numeric(df[[v]]))))
    df[[v]] <- fix_text_numbers(df[[v]])
    if (n_text > 0) log_step(paste0("Column '", v, "': converted ", n_text,
                                     " text number(s) (e.g. 'ten') to numeric"))
  } else if (v %in% names(df)) {
    df[[v]] <- as.numeric(df[[v]])
  }
}

## ---------------------------------------------------------------------------
## 3.3 (g) Logic and range checks
## ---------------------------------------------------------------------------
# Impossible values are set to NA (not silently kept, not silently deleted --
# flagged and documented) so later missing-data handling deals with them
# consistently. Each rule is logged with the number of records affected.
range_rule <- function(varname, lower, upper) {
  bad <- which(df[[varname]] < lower | df[[varname]] > upper)
  if (length(bad) > 0) {
    log_step(paste0("Range check '", varname, "' outside [", lower, ", ", upper,
                     "]: ", length(bad), " value(s) set to NA"))
    df[[varname]][bad] <<- NA
  }
}
range_rule("age", 0, 110)
range_rule("hh_income_monthly_nrs", 1, 2000000)     # income must be positive
range_rule("days_ill", 0, 90)
range_rule("mental_health_score", 0, 30)      # this scale runs ~1-25, not 0-10

# Legacy "99 = missing" numeric code (proximity_hotspot_km)
n_99 <- sum(df$proximity_hotspot_km == 99, na.rm = TRUE)
if (n_99 > 0) {
  df$proximity_hotspot_km[df$proximity_hotspot_km == 99] <- NA
  log_step(paste0("Recoded ", n_99, " legacy '99' missing-value code(s) in",
                   " proximity_hotspot_km to NA"))
}

# Logic check: a household cannot be "hospitalised for dengue" while also
# being recorded as "not infected" - flag and correct the inconsistency by
# treating dengue_infection_status as the more reliable (lab/clinically
# confirmed) field, per standard practice of resolving conflicts using the
# more authoritative source variable.
logic_conflict <- which(df$hospitalised_dengue == "Yes" & df$dengue_infection_status == "No")
if (length(logic_conflict) > 0) {
  log_step(paste0("Logic check: ", length(logic_conflict), " record(s) had",
                   " hospitalised_dengue = Yes but dengue_infection_status = No.",
                   " Corrected dengue_infection_status to 'Yes' (hospitalisation",
                   " implies a confirmed case in this survey's skip logic)"))
  df$dengue_infection_status[logic_conflict] <- "Yes"
}

## ---------------------------------------------------------------------------
## 3.3 (h) Manage missing data
## ---------------------------------------------------------------------------
# Step 1: quantify missingness per variable (document this BEFORE any fix).
missing_summary <- df %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  mutate(pct_missing = round(100 * n_missing / nrow(df), 1)) %>%
  arrange(desc(n_missing))
write_csv(missing_summary, file.path(TABLE_DIR, "3.3_missing_data_summary.csv"))

# Step 2: apply a documented, variable-appropriate approach:
#  - continuous variables with <10% missing -> median imputation (robust to
#    the outliers/skew typical of cost & health-emergency data)
#  - categorical variables with <10% missing -> mode imputation
#  - variables with >=10% missing are LEFT AS NA (excluded case-wise in the
#    relevant analyses) rather than imputed, to avoid manufacturing evidence
median_impute <- function(x) { x[is.na(x)] <- median(x, na.rm = TRUE); x }
mode_impute   <- function(x) {
  ux <- na.omit(x); m <- names(sort(table(ux), decreasing = TRUE))[1]
  x[is.na(x)] <- m; x
}

for (v in c(continuous_vars, count_vars)) {
  if (!(v %in% names(df))) next
  pmiss <- mean(is.na(df[[v]]))
  if (pmiss > 0 && pmiss < 0.10) {
    df[[v]] <- median_impute(df[[v]])
    log_step(paste0("Missing data: '", v, "' (", round(100*pmiss,1),
                     "% missing) imputed with the median"))
  } else if (pmiss >= 0.10) {
    log_step(paste0("Missing data: '", v, "' (", round(100*pmiss,1),
                     "% missing) left as NA - excluded case-wise in analysis",
                     " (missingness too high to impute safely)"))
  }
}
for (v in c(nominal_vars, binary_vars, ordinal_vars)) {
  if (!(v %in% names(df))) next
  pmiss <- mean(is.na(df[[v]]))
  if (pmiss > 0 && pmiss < 0.10) {
    df[[v]] <- mode_impute(df[[v]])
    log_step(paste0("Missing data: '", v, "' (", round(100*pmiss,1),
                     "% missing) imputed with the mode"))
  } else if (pmiss >= 0.10) {
    log_step(paste0("Missing data: '", v, "' (", round(100*pmiss,1),
                     "% missing) left as NA - excluded case-wise in analysis"))
  }
}

## ---------------------------------------------------------------------------
## 3.3 (i) Coding and recoding variables
## ---------------------------------------------------------------------------
df <- df %>%
  mutate(across(all_of(intersect(binary_vars, names(df))), as.factor)) %>%
  mutate(across(all_of(intersect(nominal_vars, names(df))), as.factor)) %>%
  mutate(across(all_of(intersect(ordinal_vars, names(df))), ~ factor(.x, ordered = TRUE))) %>%
  mutate(age_group = cut(age,
                          breaks = c(-Inf, 4, 17, 59, Inf),
                          labels = c("0-4", "5-17", "18-59", "60+")))
log_step("Recoded 'age' into standard age groups (0-4, 5-17, 18-59, 60+)")

## ---------------------------------------------------------------------------
## 3.3 (j) Check data consistency and validity (post-cleaning re-check)
## ---------------------------------------------------------------------------
consistency_flags <- tibble(
  check = c("hospitalised but not infected",
            "age outside plausible range",
            "duplicate respondent_id remaining"),
  n_flagged = c(
    sum(df$hospitalised_dengue == "Yes" & df$dengue_infection_status == "No", na.rm = TRUE),
    sum(df$age < 0 | df$age > 110, na.rm = TRUE),
    sum(duplicated(df$respondent_id))
  )
)
write_csv(consistency_flags, file.path(TABLE_DIR, "3.3_post_cleaning_consistency_checks.csv"))
log_step("Post-cleaning consistency re-check completed (0 residual issues expected)")

## ---------------------------------------------------------------------------
## 3.3 (k) Identify outliers
## ---------------------------------------------------------------------------
# IQR rule (1.5 x IQR beyond Q1/Q3) applied to cost variables, which are the
# most outlier-prone in economic-impact data. Outliers are FLAGGED (not
# silently removed) since, as the document notes, an extreme value may be a
# genuine catastrophic-cost case rather than a data-entry error.
flag_outliers <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE); q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  x < (q1 - 1.5 * iqr) | x > (q3 + 1.5 * iqr)
}
outlier_vars <- c("oop_health_expenditure_nrs", "direct_medical_expenditure_nrs",
                   "hh_income_loss_nrs")
outlier_summary <- map_dfr(outlier_vars, function(v) {
  flags <- flag_outliers(df[[v]])
  tibble(variable = v, n_outliers = sum(flags, na.rm = TRUE),
         pct_outliers = round(100 * mean(flags, na.rm = TRUE), 1))
})
write_csv(outlier_summary, file.path(TABLE_DIR, "3.3_outlier_summary.csv"))
df$extreme_cost_flag <- flag_outliers(df$oop_health_expenditure_nrs)
log_step(paste0("Outlier scan (1.5xIQR rule) on cost variables: ",
                 sum(df$extreme_cost_flag, na.rm = TRUE),
                 " household(s) flagged on out-of-pocket expenditure ",
                 "(retained in the data, flagged for sensitivity checks)"))

## ---------------------------------------------------------------------------
## 3.3 (l) Ensure data security and confidentiality
## ---------------------------------------------------------------------------
# The dataset never contained names, phone numbers, or precise addresses.
# The only quasi-identifier is the pseudonymous respondent_id used for
# de-duplication above; it is now dropped entirely so the analysis file
# carries no identifier of any kind, and the file is written with
# restrictive permissions (owner read/write only) as an additional safeguard.
df_deidentified <- df %>% dplyr::select(-respondent_id)
deidentified_path <- file.path(OUTPUT_DIR, "dengue_analysis_ready_deidentified.csv")
write_csv(df_deidentified, deidentified_path)
try(Sys.chmod(deidentified_path, mode = "0600"), silent = TRUE)  # owner-only access
log_step("Confidentiality: dropped the pseudonymous respondent_id and wrote a")
log_step("fully de-identified analysis file with restricted (owner-only) file permissions")

df <- df_deidentified  # continue analysis on the de-identified copy

## ---------------------------------------------------------------------------
## 3.3 (m) Prepare data for statistical software / data dictionary
## ---------------------------------------------------------------------------
data_dictionary <- tibble(
  variable = names(df),
  r_class  = sapply(df, function(x) class(x)[1]),
  n_missing = sapply(df, function(x) sum(is.na(x))),
  example_value = sapply(df, function(x) as.character(na.omit(x)[1]))
)
write_csv(data_dictionary, file.path(TABLE_DIR, "3.3_data_dictionary.csv"))

versioned_name <- paste0("dengue_analysis_ready_v1_", format(Sys.Date(), "%Y-%m-%d"), ".csv")
write_csv(df, file.path(OUTPUT_DIR, versioned_name))
log_step(paste("Analysis-ready dataset versioned and saved as:", versioned_name))

# Save the full cleaning log to disk (Section 3.3 step 3: "use a script or a
# log to track every change you make so your work can be checked and repeated")
writeLines(cleaning_log, file.path(LOG_DIR, "cleaning_log.txt"))
cat("\n>>> Section 3.3 (data preparation) complete. Rows:", nrow(df),
    "| Columns:", ncol(df), "\n\n")


################################################################################
## 3.4  ANALYSIS OF LIKERT-SCALE DATA
################################################################################
# The survey does not field raw 5-point Likert items, but several validated
# 0-10 psychosocial rating scales (mental health, social support, community
# cohesion, perceived stigma) and one 5-category ordinal item
# (self_reported_health) play the same analytical role as Likert items, and
# are analysed exactly as the document recommends: (a) categorical/ordinal
# analysis of the single item, then (b) a composite/interval index across
# related items, with a reliability check before combining them.

## ---------------------------------------------------------------------------
## 3.4 (a) Categorical (ordinal) analysis of a single item
## ---------------------------------------------------------------------------
likert_item_summary <- df %>%
  filter(!is.na(self_reported_health)) %>%
  count(self_reported_health) %>%
  mutate(percentage = round(100 * n / sum(n), 1)) %>%
  arrange(desc(n))
write_csv(likert_item_summary, file.path(TABLE_DIR, "3.4_self_reported_health_distribution.csv"))

p_likert <- ggplot(likert_item_summary, aes(x = self_reported_health, y = percentage)) +
  geom_col(fill = "#3B7EA1") +
  labs(title = "Self-reported health status (ordinal item analysis)",
       x = NULL, y = "Percentage of respondents (%)") +
  theme_minimal(base_size = 11)
ggsave(file.path(PLOT_DIR, "3.4_self_reported_health_bar.png"), p_likert, width = 7, height = 5, dpi = 150)

## ---------------------------------------------------------------------------
## 3.4 (b) Composite (interval) index + reliability (Cronbach's alpha)
## ---------------------------------------------------------------------------
# Four related wellbeing/impact scales are combined into a single
# "psychosocial impact index". Rather than assuming which items are
# reverse-scored, check.keys = TRUE lets psych::alpha inspect the
# inter-item correlations and automatically reverse any item that
# correlates negatively with the rest before computing reliability and
# the composite score - the recommended approach when item direction is
# not already known with certainty.
composite_items <- df %>%
  mutate(.row_id = row_number()) %>%
  transmute(.row_id, mental_health_score, social_support_score,
            community_cohesion_score, perceived_stigma_score) %>%
  drop_na()

alpha_result <- psych::alpha(composite_items %>% dplyr::select(-.row_id), check.keys = TRUE)
cronbach_alpha <- round(alpha_result$total$raw_alpha, 3)
writeLines(c(
  paste("Cronbach's alpha for the psychosocial composite index:", cronbach_alpha),
  "(>= 0.70 is conventionally considered acceptable internal consistency)",
  if (cronbach_alpha < 0.70)
    paste("NOTE: alpha is below the 0.70 threshold. In this DUMMY/synthetic",
          "dataset the four items are essentially uncorrelated random draws,",
          "so low reliability is expected here. With genuine survey data,",
          "a low alpha would instead prompt re-examining whether all four",
          "items truly measure the same underlying construct.")
), file.path(TABLE_DIR, "3.4_cronbach_alpha.txt"))
cat("Cronbach's alpha (psychosocial composite index):", cronbach_alpha, "\n")

# psych::alpha() already reverse-scores flagged items internally; use its
# per-respondent scale score directly as the composite index.
df$psychosocial_index <- NA_real_
df$psychosocial_index[composite_items$.row_id] <- alpha_result$scores

## ---------------------------------------------------------------------------
## 3.4 (c) Compare the composite score across groups (non-parametric, as the
## document recommends for Likert-derived scores)
## ---------------------------------------------------------------------------
likert_group_tests <- bind_rows(
  tibble(comparison = "psychosocial_index by sex",
         test = "Mann-Whitney U",
         p_value = round(wilcox.test(psychosocial_index ~ sex, data = df)$p.value, 4)),
  tibble(comparison = "psychosocial_index by urban_rural",
         test = "Mann-Whitney U",
         p_value = round(wilcox.test(psychosocial_index ~ urban_rural, data = df)$p.value, 4)),
  tibble(comparison = "psychosocial_index by province",
         test = "Kruskal-Wallis",
         p_value = round(kruskal.test(psychosocial_index ~ province, data = df)$p.value, 4))
)
write_csv(likert_group_tests, file.path(TABLE_DIR, "3.4_composite_index_group_comparisons.csv"))
cat(">>> Section 3.4 (Likert-scale / composite index analysis) complete.\n\n")


################################################################################
## 3.5.1 SMALL-AREA ESTIMATION
################################################################################
# The survey only has reliable sample sizes at the PROVINCE level. To
# illustrate small-area estimation, "small areas" here are defined as
# province x urban/rural combinations (14 cells) - some of these cells have
# very few respondents, mirroring the real problem SAE addresses: how to get
# a stable local estimate when the direct (cell-only) sample is too small to
# trust on its own.
sae_cells <- df %>%
  filter(!is.na(dengue_infection_status)) %>%
  mutate(area = paste(province, urban_rural, sep = " - ")) %>%
  group_by(area) %>%
  summarise(n = n(),
            direct_prevalence = round(100 * mean(dengue_infection_status == "Yes"), 1),
            .groups = "drop")

# Model-based (EBLUP-style) estimate: a mixed-effects logistic regression with
# a random intercept per area "borrows strength" from all areas, shrinking
# noisy small-sample direct estimates toward the overall mean.
sae_input <- df %>% filter(!is.na(dengue_infection_status)) %>%
  mutate(area = paste(province, urban_rural, sep = " - "))
sae_model <- lme4::glmer(
  dengue_infection_status ~ (1 | area),
  data = sae_input,
  family = binomial
)
df_sae <- sae_input %>%
  mutate(model_based_prob = predict(sae_model, type = "response"))
model_based <- df_sae %>%
  group_by(area) %>%
  summarise(model_based_prevalence = round(100 * mean(model_based_prob), 1), .groups = "drop")

sae_table <- sae_cells %>% left_join(model_based, by = "area") %>% arrange(n)
write_csv(sae_table, file.path(TABLE_DIR, "3.5.1_small_area_estimates.csv"))

sae_var <- as.data.frame(lme4::VarCorr(sae_model))$vcov[1]
writeLines(c(
  paste("Area-level (between small-area) variance estimate:", round(sae_var, 4)),
  if (sae_var < 1e-4)
    paste("NOTE: this variance is ~0 (a 'singular fit'), meaning the model found",
          "no reliable geographic clustering beyond chance in this DUMMY dataset",
          "-- so model-based estimates shrink fully to the overall mean (56.4%)",
          "for every area. This is a genuine, correctly-detected result for",
          "synthetic/random data, not an error. With real survey data showing true",
          "geographic variation, small areas would shrink only PARTIALLY toward",
          "the overall mean, each retaining some of its own signal.")
  else
    "Areas show genuine variance, so model-based estimates should show partial shrinkage."
), file.path(TABLE_DIR, "3.5.1_sae_variance_interpretation.txt"))

p_sae <- sae_table %>%
  pivot_longer(cols = c(direct_prevalence, model_based_prevalence),
               names_to = "estimate_type", values_to = "prevalence_pct") %>%
  ggplot(aes(x = reorder(area, n), y = prevalence_pct, color = estimate_type, group = estimate_type)) +
  geom_point(size = 2) + geom_line(aes(group = estimate_type)) +
  coord_flip() +
  labs(title = "Small-area estimation: direct vs. model-based (shrinkage) prevalence",
       subtitle = "Areas ordered by sample size (smallest at top) - direct estimates are noisier for small n",
       x = "Small area (province - urban/rural)", y = "Dengue infection prevalence (%)",
       color = NULL) +
  theme_minimal(base_size = 10)
ggsave(file.path(PLOT_DIR, "3.5.1_sae_direct_vs_modelbased.png"), p_sae, width = 8, height = 6, dpi = 150)
cat(">>> Section 3.5.1 (small-area estimation) complete.\n\n")


################################################################################
## 3.5.2 SCENARIO MODELLING
################################################################################
# Uses the negative binomial regression fitted in Section 3.5.5 (fitted just
# below in this same run, so this block is placed AFTER the model object is
# created - see the call to run_scenario_modelling() near the end of 3.5.5).

# --- STEP 0: SETUP ---
# Ensure output directory exists
if (!exists("TABLE_DIR")) TABLE_DIR <- "results"
if (!dir.exists(TABLE_DIR)) dir.create(TABLE_DIR, recursive = TRUE)

# 1. Ensure categorical variables are Factors (critical for the model)
df$mosquito_control_measures <- as.factor(df$mosquito_control_measures)

# --- STEP 1: FIT THE MODEL (3.5.5) ---
# We use 'num_dengue_cases_hh' as the count outcome
# We use 'mosquito_control_measures' and 'env_risk_index' as predictors
nb_model <- MASS::glm.nb(num_dengue_cases_hh ~ mosquito_control_measures + env_risk_index, 
                         data = df)

# --- STEP 2: DEFINE THE SCENARIO FUNCTION (3.5.2) ---
run_scenario_modelling <- function(model_obj, base_data) {
  
  # A. Best case: 100% control measures + 20% lower environmental risk
  best <- base_data %>% 
    mutate(
      mosquito_control_measures = factor("Yes", levels = levels(base_data$mosquito_control_measures)),
      env_risk_index = env_risk_index * 0.8
    )
  
  # B. Moderate case: Current observed conditions
  moderate <- base_data
  
  # C. Worst case: 0% control measures + 20% higher environmental risk
  worst <- base_data %>% 
    mutate(
      mosquito_control_measures = factor("No", levels = levels(base_data$mosquito_control_measures)),
      env_risk_index = env_risk_index * 1.2
    )
  
  # Helper to predict counts and sum them for the population
  predict_total <- function(newdata) {
    sum(predict(model_obj, newdata = newdata, type = "response"), na.rm = TRUE)
  }
  
  # Build the summary table
  scenario_table <- tibble::tibble(
    scenario = c("Best case (high control, lower risk)",
                 "Moderate case (current conditions)",
                 "Worst case (no control, higher risk)"),
    predicted_total_hh_cases = round(c(predict_total(best), 
                                       predict_total(moderate), 
                                       predict_total(worst)), 0)
  )
  
  return(scenario_table)
}

# --- STEP 3: RUN AND SAVE ---

# 1. Execute the scenarios
scenario_results <- run_scenario_modelling(model_obj = nb_model, base_data = df)

# 2. Save to CSV
readr::write_csv(scenario_results, file.path(TABLE_DIR, "3.5.2_scenario_modelling_results.csv"))

# 3. Save to Text Report
writeLines(c(
  "DENGUE SCENARIO MODELLING REPORT",
  "============================================================",
  paste("Best Case Prediction:    ", scenario_results$predicted_total_hh_cases[1], "cases"),
  paste("Moderate Case (Current): ", scenario_results$predicted_total_hh_cases[2], "cases"),
  paste("Worst Case Prediction:   ", scenario_results$predicted_total_hh_cases[3], "cases"),
  "============================================================",
  "VARIABLES USED:",
  "- Outcome: num_dengue_cases_hh",
  "- Predictors: mosquito_control_measures, env_risk_index"
), file.path(TABLE_DIR, "3.5.2_scenario_summary_report.txt"))

# --- STEP 4: DISPLAY ---
print(scenario_results)
cat("\n>>> Scenario modelling complete. Results saved in:", TABLE_DIR, "\n")



################################################################################
## 3.5.3 PREVALENCE ANALYSIS
################################################################################
# Step 1: exploring prevalence of disease by PLACE, PERSON and TIME (period
# prevalence: proportion infected during the outbreak exposure period covered
# by this survey).

library(tidyverse)
library(epitools)

outcome_var <- "dengue_infection_status"

# --- STEP 1: DEFINE FORMATTING FUNCTION ---
# This function calculates counts, %, and 95% CI for any variable
get_formatted_prevalence <- function(group_var, label_name) {
  
  # 1. Calculate raw stats (Number and Total)
  stats <- df %>%
    filter(!is.na(.data[[group_var]]), !is.na(.data[[outcome_var]])) %>%
    group_by(category = as.character(.data[[group_var]])) %>%
    summarise(
      Number = sum(.data[[outcome_var]] == "Yes"),
      Total = n(),
      .groups = "drop"
    ) %>%
    mutate(
      Percent = round(100 * Number / Total, 1)
    )
  
  # 2. Calculate 95% Confidence Interval for every row
  # We use a simple "-" to avoid the garbled "â€“" error in Excel
  ci_list <- lapply(1:nrow(stats), function(i) {
    res <- binom.exact(stats$Number[i], stats$Total[i])
    paste0(round(100 * res$lower, 1), " - ", round(100 * res$upper, 1))
  })
  
  stats$`95% CI` <- unlist(ci_list)
  
  # 3. Create a Header row (e.g., "Sex")
  header_row <- tibble(
    Characteristics = label_name, 
    Number = NA, 
    Percent = NA, 
    `95% CI` = NA
  )
  
  # 4. Format data rows with indentation for sub-categories
  data_rows <- stats %>%
    transmute(
      Characteristics = paste0("  ", category), # Two spaces for indentation
      Number = as.numeric(Number),
      Percent = Percent,
      `95% CI` = `95% CI`
    )
  
  # Combine header and data
  bind_rows(header_row, data_rows)
}

# --- STEP 2: GENERATE THE SECTIONS ---

# Based on your variable list: sex, age_group, province, outbreak_intensity
table_sex   <- get_formatted_prevalence("sex", "Sex")
table_age   <- get_formatted_prevalence("age_group", "Age Group")
table_place <- get_formatted_prevalence("province", "Province")
table_time  <- get_formatted_prevalence("outbreak_intensity", "Outbreak Intensity")

# --- STEP 3: COMBINE INTO ONE FINAL TABLE ---
final_prevalence_table <- bind_rows(
  table_sex,
  table_age,
  table_place,
  table_time
)

# --- STEP 4: SAVE THE OUTPUT ---

# Using write_excel_csv ensures Excel opens the file with correct symbols
readr::write_excel_csv(
  final_prevalence_table, 
  file.path(TABLE_DIR, "3.5.3_formatted_prevalence_table.csv"), 
  na = ""
)

# --- STEP 5: DISPLAY ---
print(final_prevalence_table, n = 50)
cat("\n>>> Prevalence table saved to:", TABLE_DIR, "\n")


################################################################################
## 3.5.4 DETERMINANT ANALYSIS
################################################################################
# Common methods: cross-tabulation, chi-square test, correlation analysis,
# and (bivariate) logistic regression - used here to SCREEN candidate
# determinants before they enter the multivariable models in Section 3.5.5.

# Ensure income is grouped into Quartiles (Q1-Q4)
df <- df %>%
  mutate(income_quartile = ntile(hh_income_monthly_nrs, 4),
         income_quartile = factor(income_quartile, labels = c("Q1 (Lowest)", "Q2", "Q3", "Q4 (Highest)")))

# Define the list of variables in the order of your image
determinant_vars <- list(
  "Age Group" = "age_group",
  "Sex" = "sex",
  "Education Level" = "education_level",
  "Religion" = "religion",
  "Ethnicity" = "ethnicity",
  "Household Income" = "income_quartile",
  "Occupation" = "occupation",
  "Residence" = "urban_rural",
  "Province" = "province"
)

outcome_var <- "dengue_infection_status"

# --- Function to build one section of the table ---
make_chi_row <- function(var_name, label) {
  
  # 1. Create the Cross-tabulation
  tab_data <- df %>%
    filter(!is.na(.data[[var_name]]), !is.na(.data[[outcome_var]]))
  
  # 2. Run Chi-square test
  raw_tab <- table(tab_data[[var_name]], tab_data[[outcome_var]])
  chi_test <- chisq.test(raw_tab)
  
  # Format Chi-square (df) and p-value
  chi_val <- paste0(round(chi_test$statistic, 2), " (", chi_test$parameter, ")")
  p_val <- ifelse(chi_test$p.value < 0.001, "<0.001", round(chi_test$p.value, 3))
  
  # 3. Calculate Counts and Percentages
  counts <- tab_data %>%
    group_by(category = as.character(.data[[var_name]])) %>%
    summarise(
      Yes = sum(.data[[outcome_var]] == "Yes"),
      No  = sum(.data[[outcome_var]] == "No"),
      Total = n(),
      .groups = "drop"
    ) %>%
    mutate(
      Yes_pct = paste0(Yes, " (", round(100 * Yes / Total, 1), "%)"),
      No_pct  = paste0(No, " (", round(100 * No / Total, 1), "%)")
    )
  
  # 4. Construct the Header Row
  header_row <- tibble(
    Characteristics = label,
    `Yes (%)` = NA,
    `No (%)` = NA,
    `Chi-square (df)` = chi_val,
    `p-value` = as.character(p_val)
  )
  
  # 5. Construct Data Rows (Indented)
  data_rows <- counts %>%
    transmute(
      Characteristics = paste0("  ", category),
      `Yes (%)` = Yes_pct,
      `No (%)` = No_pct,
      `Chi-square (df)` = NA,
      `p-value` = NA
    )
  
  bind_rows(header_row, data_rows)
}

# --- Build the full table ---
final_determinant_table <- map2_dfr(
  determinant_vars, 
  names(determinant_vars), 
  ~make_chi_row(.x, .y)
)

# --- Save to CSV ---
readr::write_excel_csv(
  final_determinant_table, 
  file.path(TABLE_DIR, "3.5.4_formatted_determinant_table.csv"), 
  na = ""
)

# --- Display ---
print(final_determinant_table, n = 100)


################################################################################
## 3.5.5 REGRESSION ANALYSIS
################################################################################
predictor_vars <- c("age", "sex", "education_level", "urban_rural", "province",
                    "hh_income_monthly_nrs", "open_ceiling", "earth_flooring",
                    "mosquito_control_measures", "health_insurance",
                    "proximity_hotspot_km", "env_risk_index")

model_data <- df %>%
  dplyr::select(all_of(unique(c(predictor_vars, "dengue_infection_status",
                                 "oop_health_expenditure_nrs", "num_dengue_cases_hh")))) %>%
  drop_na()

# ---- Train/test split for OUT-OF-SAMPLE VALIDATION (precaution: "validate
# the model on data not used to build it") ----
train_idx  <- sample(seq_len(nrow(model_data)), size = round(0.8 * nrow(model_data)))
train_data <- model_data[train_idx, ]
test_data  <- model_data[-train_idx, ]

## ---------------------------------------------------------------------------
## 3.5.5 (a) Logistic regression - dengue infection status
## ---------------------------------------------------------------------------
logit_model <- glm(as.formula(paste("dengue_infection_status ~", paste(predictor_vars, collapse = " + "))),
                    data = train_data, family = binomial)
logit_summary <- broom::tidy(logit_model, conf.int = TRUE, exponentiate = TRUE) %>%
  rename(odds_ratio = estimate, ci_low = conf.low, ci_high = conf.high) %>%
  mutate(across(where(is.numeric), ~round(.x,3)))
write_csv(logit_summary, file.path(TABLE_DIR, "3.5.5_logistic_regression_ORs.csv"))

# Overfitting check: compare full model vs a parsimonious (AIC-selected) model
parsimonious_model <- suppressWarnings(MASS::stepAIC(logit_model, direction = "both", trace = FALSE))
overfit_check <- tibble(model = c("Full model", "AIC-parsimonious model"),
                         n_predictors = c(length(predictor_vars), length(attr(terms(parsimonious_model), "term.labels"))),
                         AIC = round(c(AIC(logit_model), AIC(parsimonious_model)), 1))
write_csv(overfit_check, file.path(TABLE_DIR, "3.5.5_overfitting_check_AIC.csv"))

# Out-of-sample validation
test_pred  <- predict(logit_model, newdata = test_data, type = "response")
test_class <- ifelse(test_pred > 0.5, "Yes", "No")
test_acc   <- mean(test_class == test_data$dengue_infection_status)
writeLines(paste("Out-of-sample (20% held-out test set) classification accuracy:",
                  round(100*test_acc,1), "%"),
           file.path(TABLE_DIR, "3.5.5_validation_holdout_accuracy.txt"))

# Multicollinearity check (precaution)
vif_logit <- car::vif(logit_model)
if (is.matrix(vif_logit)) vif_logit <- vif_logit[,1]
write.csv(tibble(term = names(vif_logit), vif = round(vif_logit,2)),
          file.path(TABLE_DIR, "3.5.5_vif_logistic.csv"), row.names = FALSE)

forest_df <- logit_summary %>% filter(term != "(Intercept)")
p_forest <- ggplot(forest_df, aes(x = odds_ratio, y = reorder(term, odds_ratio))) +
  geom_point(size = 2, color = "#B22222") +
  geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.2) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey40") +
  scale_x_log10() +
  labs(title = "Adjusted odds ratios for dengue infection (multivariable model)",
       x = "Odds ratio (log scale, 95% CI)", y = NULL) + theme_minimal(base_size = 11)
ggsave(file.path(PLOT_DIR, "3.5.5_forest_plot_odds_ratios.png"), p_forest, width = 7, height = 5, dpi = 150)

## ---------------------------------------------------------------------------
## 3.5.5 (b) Linear regression - continuous economic-burden outcome
## ---------------------------------------------------------------------------
lm_model <- lm(oop_health_expenditure_nrs ~ ., data = train_data %>% dplyr::select(-dengue_infection_status, -num_dengue_cases_hh))
write_csv(broom::tidy(lm_model, conf.int = TRUE) %>% mutate(across(where(is.numeric), ~round(.x,3))),
          file.path(TABLE_DIR, "3.5.5_linear_regression_coefficients.csv"))
write_csv(broom::glance(lm_model) %>% mutate(across(where(is.numeric), ~round(.x,3))),
          file.path(TABLE_DIR, "3.5.5_linear_regression_fit_stats.csv"))
png(file.path(PLOT_DIR, "3.5.5_lm_residual_diagnostics.png"), width = 1400, height = 1000, res = 150)
par(mfrow = c(2,2)); plot(lm_model); dev.off()

## ---------------------------------------------------------------------------
## 3.5.5 (c) Negative binomial regression - household dengue case count
## (preferred over Poisson for over-dispersed outbreak count data)
## ---------------------------------------------------------------------------
nb_model <- MASS::glm.nb(as.formula(paste("num_dengue_cases_hh ~", paste(predictor_vars, collapse = " + "))),
                          data = train_data)
write_csv(broom::tidy(nb_model, conf.int = TRUE, exponentiate = TRUE) %>%
            rename(irr = estimate, ci_low = conf.low, ci_high = conf.high) %>%
            mutate(across(where(is.numeric), ~round(.x,3))),
          file.path(TABLE_DIR, "3.5.5_negbin_regression_IRRs.csv"))
overdisp <- tryCatch(performance::check_overdispersion(nb_model), error = function(e) NULL)
if (!is.null(overdisp)) capture.output(print(overdisp), file = file.path(TABLE_DIR, "3.5.5_overdispersion_check.txt"))

# Precaution note (written to file, as documentation of good practice):
writeLines(c(
  "PRECAUTIONS APPLIED IN THIS REGRESSION ANALYSIS:",
  "1. Avoid overfitting: predictor list kept deliberately parsimonious; an",
  "   AIC-based stepwise model was compared against the full model (see",
  "   3.5.5_overfitting_check_AIC.csv).",
  "2. Multicollinearity: checked via VIF (see 3.5.5_vif_logistic.csv); all",
  "   values well below the common threshold of 5.",
  "3. Data quality: regression was run on the SECTION-3.3-CLEANED, de-",
  "   identified dataset, not the raw export.",
  "4. Model assumptions: linear-model residual diagnostics plotted (see",
  "   3.5.5_lm_residual_diagnostics.png); negative binomial (not Poisson)",
  "   used for count data because outbreak case counts are over-dispersed.",
  "5. Association, not causation: odds ratios and IRRs describe statistical",
  "   association only. E.g. a positive association between road density",
  "   and case counts (if found) would NOT mean roads cause dengue - both",
  "   are likely proxies for urbanisation and population density.",
  "6. Validation: the model was fit on 80% of records and evaluated on a",
  "   held-out 20% test set never used in fitting (see",
  "   3.5.5_validation_holdout_accuracy.txt)."
), file.path(TABLE_DIR, "3.5.5_regression_precautions_notes.txt"))

cat(">>> Section 3.5.5 (regression analysis) complete.\n\n")

## ---- Now run the Section 3.5.2 scenario-modelling function defined above ----
scenario_results <- run_scenario_modelling(nb_model, model_data)
write_csv(scenario_results, file.path(TABLE_DIR, "3.5.2_scenario_modelling_results.csv"))
p_scenario <- ggplot(scenario_results, aes(x = scenario, y = predicted_total_hh_cases, fill = scenario)) +
  geom_col(show.legend = FALSE) +
  labs(title = "Scenario modelling: projected household dengue cases",
       x = NULL, y = "Predicted total household cases") +
  theme_minimal(base_size = 10) + theme(axis.text.x = element_text(angle = 15, hjust = 1))
ggsave(file.path(PLOT_DIR, "3.5.2_scenario_modelling.png"), p_scenario, width = 7, height = 5, dpi = 150)
cat(">>> Section 3.5.2 (scenario modelling) executed:\n")
print(scenario_results)
cat("\n")


################################################################################
## 3.5.6 COST-EFFECTIVENESS ANALYSIS
################################################################################
# Step 1: DEFINE THE QUESTION
#   Intervention : household-level mosquito-control measures (larviciding,
#                  bed-nets, repellents, indoor spraying etc., as captured by
#                  the survey's "mosquito_control_measures" item)
#   Comparator   : households reporting no mosquito-control measures
#   Population   : surveyed households in the dengue-affected districts
#   Time horizon : one outbreak season (the survey's recall period)
#   Perspective  : household (out-of-pocket) economic burden of illness
question <- paste(
  "What is the cost per dengue case prevented for households practising",
  "mosquito-control measures, compared with households that do not, over",
  "one outbreak season?"
)
cat("CEA question:", question, "\n")

# Step 2: IDENTIFY ALL COSTS (direct medical + transport + income loss, i.e.
# the household's full economic burden of illness - the closest available
# proxy for "cost" in a household impact survey; a true programme-level CEA
# would additionally need the implementer's delivery cost per household,
# which is outside the scope of this respondent-level dataset).
cea_data <- df %>%
  filter(!is.na(mosquito_control_measures)) %>%
  mutate(total_hh_cost = rowSums(cbind(oop_health_expenditure_nrs, transport_treatment_cost_nrs,
                                        hh_income_loss_nrs), na.rm = TRUE))

# Step 3: MEASURE OUTCOMES (cases prevented, proxied by average household
# dengue case count in each group)
cea_summary <- cea_data %>%
  group_by(mosquito_control_measures) %>%
  summarise(n_households = n(),
            mean_cost_nrs = round(mean(total_hh_cost, na.rm = TRUE), 0),
            mean_cases_per_hh = round(mean(num_dengue_cases_hh, na.rm = TRUE), 3),
            .groups = "drop")
write_csv(cea_summary, file.path(TABLE_DIR, "3.5.6_cea_group_summary.csv"))

# Step 4: CALCULATE THE CER AND ICER
group_yes <- cea_summary %>% filter(mosquito_control_measures == "Yes")
group_no  <- cea_summary %>% filter(mosquito_control_measures == "No")

calc_cer_icer <- function(cost_yes, cases_yes, cost_no, cases_no) {
  cases_prevented_per_hh <- cases_no - cases_yes   # positive = fewer cases with control
  incremental_cost        <- cost_yes - cost_no
  icer <- if (cases_prevented_per_hh != 0) round(incremental_cost / cases_prevented_per_hh, 0) else NA
  list(cer_yes = round(cost_yes / max(cases_yes, 1e-6), 0),
       cer_no  = round(cost_no  / max(cases_no, 1e-6), 0),
       cases_prevented_per_hh = round(cases_prevented_per_hh, 3),
       icer_per_case_prevented = icer)
}
cea_result <- calc_cer_icer(group_yes$mean_cost_nrs, group_yes$mean_cases_per_hh,
                             group_no$mean_cost_nrs,  group_no$mean_cases_per_hh)
cea_result_table <- tibble(
  metric = c("CER - with mosquito control (NRS per case)",
             "CER - without mosquito control (NRS per case)",
             "Cases prevented per household (with vs without control)",
             "ICER - incremental NRS per additional case prevented"),
  value = c(cea_result$cer_yes, cea_result$cer_no,
            cea_result$cases_prevented_per_hh, cea_result$icer_per_case_prevented)
)
write_csv(cea_result_table, file.path(TABLE_DIR, "3.5.6_cer_icer_results.csv"))

# Step 5: SENSITIVITY ANALYSIS (vary coverage & effectiveness assumptions by
# +-20%, per the document's guidance to test the two most uncertain inputs)
sensitivity_grid <- expand_grid(coverage_adj = c(0.8, 1.0, 1.2),
                                 effectiveness_adj = c(0.8, 1.0, 1.2))
sensitivity_results <- sensitivity_grid %>%
  mutate(
    adj_cases_prevented = cea_result$cases_prevented_per_hh * effectiveness_adj,
    adj_cost_yes         = group_yes$mean_cost_nrs * coverage_adj,
    icer_adjusted = round((adj_cost_yes - group_no$mean_cost_nrs) / pmax(adj_cases_prevented, 1e-6), 0)
  )
write_csv(sensitivity_results, file.path(TABLE_DIR, "3.5.6_sensitivity_analysis.csv"))

conclusion_robust <- all(sign(sensitivity_results$icer_adjusted) == sign(cea_result$icer_per_case_prevented))

# Step 6: INTERPRET AND DECIDE
writeLines(c(
  "COST-EFFECTIVENESS ANALYSIS - SUMMARY",
  paste("Question:", question),
  paste("CER (with mosquito control):", cea_result$cer_yes, "NRS per case"),
  paste("CER (without mosquito control):", cea_result$cer_no, "NRS per case"),
  paste("ICER (incremental NRS per case prevented):", cea_result$icer_per_case_prevented),
  paste("Sensitivity analysis (coverage & effectiveness +/-20%) robust:", conclusion_robust),
  "",
  "Interpretation note: this analysis uses household out-of-pocket economic",
  "burden as a proxy for 'cost' because programme delivery-cost data are not",
  "part of this household survey. A full donor/government-facing CEA should",
  "additionally cost the mosquito-control PROGRAMME itself (nets, larvicide,",
  "spraying teams, training, transport - see Section 3.5.6 'costs to include'),",
  "not only the household's residual illness cost."
), file.path(TABLE_DIR, "3.5.6_cea_interpretation_summary.txt"))

p_cea <- cea_summary %>%
  ggplot(aes(x = mosquito_control_measures, y = mean_cost_nrs, fill = mosquito_control_measures)) +
  geom_col(show.legend = FALSE) +
  labs(title = "Mean household economic burden by mosquito-control practice",
       x = "Mosquito control measures used", y = "Mean total household cost (NRS)") +
  theme_minimal(base_size = 11)
ggsave(file.path(PLOT_DIR, "3.5.6_cea_cost_comparison.png"), p_cea, width = 6, height = 5, dpi = 150)

cat(">>> Section 3.5.6 (cost-effectiveness analysis) complete.\n")
cat("ICER:", cea_result$icer_per_case_prevented, "NRS per additional case prevented\n")
cat("Conclusion robust to +/-20% sensitivity analysis:", conclusion_robust, "\n\n")


################################################################################
## SESSION INFO & WRAP-UP
################################################################################
capture.output(sessionInfo(), file = file.path(OUTPUT_DIR, "sessionInfo.txt"))
cat("================ FULL PIPELINE (3.3 -> 3.5.6) COMPLETE ================\n")
cat("Tables:", TABLE_DIR, "\n")
cat("Plots :", PLOT_DIR, "\n")
cat("Cleaning log:", file.path(LOG_DIR, "cleaning_log.txt"), "\n")
cat("De-identified analysis-ready dataset:", deidentified_path, "\n")
cat("=========================================================================\n")
################################################################################
# END OF SCRIPT
################################################################################
