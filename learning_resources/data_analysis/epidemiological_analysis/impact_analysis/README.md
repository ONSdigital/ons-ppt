# Nepal Dengue Outbreak : Household Impact Analysis Pipeline

This project prepares, cleans, and analyses household-level survey data on the
health, economic, and social impact of dengue outbreaks in Nepal. It follows
the structure of the impact-analysis reference document (Sections 3.3–3.5.6)
and is built as R script run in sequence, plus their generated outputs.

## 1. How to run


1. Run `02_20260708_Dengue_Impact_Analysis.R`, which reads that raw file (`20260708_Dengue_Raw_Data.csv`), cleans
   it, and runs every analysis stage, saving all tables and plots into a
   dated `dengue_impact_outputs_YYYYMMDD/` folder.
2. Edit the file paths (`INPUT_CSV`/`OUTPUT_CSV` in script 1, `RAW_CSV` in
   script 2) to point at your own data when you're ready to use real survey
   data instead of the dummy set.

Required R packages (installed automatically if missing): tidyverse,
janitor, car, MASS, broom, corrplot, epitools, rstatix, performance, scales,
psych, lme4.

## 2. Code files

| File | Purpose |
|---|---|
| `02_20260708_Dengue_Impact_Analysis.R` | The full analysis pipeline, organised into the exact sections of the reference document (see below). Reads the messy raw file, cleans and de-identifies it, then runs every analysis stage, writing all results to `dengue_impact_outputs_YYYYMMDD/`. |

### Sections implemented in script 02

- **3.3** Preparing data for quantitative analysis — import, de-duplication,
  category standardisation, type fixes, range/logic checks, missing-data
  handling, recoding, consistency checks, outlier flagging, anonymisation,
  data dictionary, versioned export, full cleaning log
- **3.4** Analysis of Likert-scale data — ordinal item analysis, composite
  index with Cronbach's alpha, group comparisons
- **3.5.1** Small-area estimation — direct vs. mixed-model (shrinkage)
  prevalence by province × urban/rural
- **3.5.2** Scenario modelling — best/moderate/worst-case case projections
- **3.5.3** Prevalence analysis — by person, place, and time
- **3.5.4** Determinant analysis — chi-square/Fisher, cross-tabs,
  correlations, bivariate odds ratios
- **3.5.5** Regression analysis — logistic, linear, negative binomial, with
  overfitting/multicollinearity/validation checks
- **3.5.6** Cost-effectiveness analysis — CER/ICER and sensitivity analysis

## 3. Data files

| File | Description |
|---|---|
| `20260708_Dengue_Raw_Data.csv` | The original, clean dummy dataset (input to script 01). Not included in this delivery — supplied by you. |
| `dengue_raw_realistic.csv` | Output of script 01: the same data with realistic anomalies added, and a pseudonymous respondent code in place of any identifier. This is the "raw" file script 02 expects as input. |
| `dengue_analysis_ready_deidentified.csv` | Output of script 02, Section 3.3: the cleaned dataset after de-duplication, error correction, and imputation, with the pseudonymous code removed entirely. Fully anonymous. |
| `dengue_analysis_ready_v1_YYYY-MM-DD.csv` | Same as above, saved with a versioned filename for audit/traceability. |

**Note on confidentiality:** at no point does any file in this pipeline contain
names, phone numbers, or precise addresses. The only quasi-identifier
(`respondent_id`) is a randomly generated code used solely to detect duplicate
entries during cleaning, and it is dropped before the analysis-ready file is
written.

## 4. Output files

All outputs are written into `dengue_impact_outputs_YYYYMMDD/`, in three
sub-folders:

- **`tables/`** — one or more `.csv`/`.txt` file per analysis step, prefixed
  with its section number (e.g. `3.5.4_chisq_fisher_results.csv`,
  `3.5.6_cer_icer_results.csv`), so each table can be traced back to the
  section of the document it implements.
- **`plots/`** — `.png` charts, similarly prefixed (e.g.
  `3.5.1_sae_direct_vs_modelbased.png`, `3.5.5_forest_plot_odds_ratios.png`).
- **`cleaning_log/cleaning_log.txt`** — a timestamped, line-by-line record of
  every change made to the data during cleaning (duplicates removed, values
  corrected, missing data imputed, etc.), so the cleaning is fully
  reproducible and auditable.
- **`sessionInfo.txt`** — the R version and package versions used, for
  reproducibility.

### Interpreting results on this dummy dataset

Because the underlying dummy data is randomly generated (no real
relationship between variables), several results are expected to show "no
signal" — e.g. regression predictors with p > 0.05, a low Cronbach's alpha,
or a small-area model that shrinks fully to the overall mean. These are
correct outputs given random input, not bugs. Once real survey data is used
in place of the dummy CSV, the same code will surface genuine patterns.
