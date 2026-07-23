# %% [markdown]
# # Prevalence and Incidence Codes (Python version)
# Converted from `Prevalence_and_incidence_Codes.Rmd`

# %%
# ---- Installing / importing required packages ----
# (Run once in your terminal if not already installed)
# pip install pandas numpy matplotlib scipy statsmodels

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from pathlib import Path
from scipy.stats import chi2_contingency
from statsmodels.stats.contingency_tables import Table2x2

# %% [markdown]
# ## Loading data set

# %%
# loading cholera data set
cholera_data = pd.read_csv(Path("data") / "cholera_data_2022.csv")

# clean column names (equivalent of janitor::clean_names())
cholera_data.columns = (
    cholera_data.columns.str.strip()
    .str.lower()
    .str.replace(r"[^0-9a-zA-Z]+", "_", regex=True)
)

# parse date column
cholera_data["date"] = pd.to_datetime(cholera_data["date"]).dt.tz_localize(None)

# loading mid-year population data set
# NOTE: mw_population.csv was not part of the files you shared, so this line
# will fail until that file is added to the data/ folder.
mw_population = pd.read_csv(Path("data") / "mw_population.csv")
mw_population.columns = (
    mw_population.columns.str.strip()
    .str.lower()
    .str.replace(r"[^0-9a-zA-Z]+", "_", regex=True)
)

# %% [markdown]
# ## Prevalence proportion

# %%
# This code shows the calculation of prevalence proportion using Malawi cholera-2022

# cleaning the district names in both data sets to have similar format
cholera_data["district"] = cholera_data["district"].str.lower()
mw_population["district"] = mw_population["district"].str.lower()

# aggregating the cases for first quarter (January to June) 2022
mask = (cholera_data["date"] >= "2022-01-01") & (cholera_data["date"] <= "2022-06-30")
first_quarter = (
    cholera_data.loc[mask]
    .groupby("district", as_index=False)
    .agg(first_quarter_cases=("cases", "sum"))
)

# merging the two data sets on district
first_quarter = first_quarter.merge(mw_population, on="district")

# calculating prevalence proportion for first quarter for each district
prev_district = first_quarter.copy()
prev_district["prevalence"] = (
    (prev_district["first_quarter_cases"] / prev_district["population"]) * 10000
).round(2)

# view the prevalence proportion for each district
print(prev_district)

# %% [markdown]
# ## Incidence Proportion

# %%
blantyre_mask = (
    (cholera_data["district"] == "blantyre")
    & (cholera_data["date"] >= "2022-01-01")
    & (cholera_data["date"] <= "2022-06-30")
)
blantyre_incidence = (
    cholera_data.loc[blantyre_mask]
    .groupby(["district", "epiweek"], as_index=False)
    .agg(first_quarter_cases=("cases", "sum"))
)

# merging with population data set
blantyre_incidence = blantyre_incidence.merge(mw_population, on="district")
blantyre_incidence["incidence_prop"] = (
    (blantyre_incidence["first_quarter_cases"] / blantyre_incidence["population"]) * 100000
).round(2)
blantyre_incidence = blantyre_incidence[["district", "epiweek", "incidence_prop"]]

# viewing incidence proportion for Blantyre district per week
print(blantyre_incidence)

# %% [markdown]
# ## Incidence Rate

# %%
total_days_obs = 816 * 21  # 816 days observed for 21 people
years_obs = np.ceil(total_days_obs / 365)  # assumption: not a leap year
incidence_rate = (5 / years_obs) * 10
print(incidence_rate)

# %% [markdown]
# # Risk Ratio (RR)

# %%
np.random.seed(1)  # for reproducibility (R's sample() has no fixed seed in original)

vaccine_data = pd.DataFrame(
    {
        "vaccine_state": np.random.permutation(
            np.repeat(["Vaccinated", "Unvaccinated"], 20)
        ),
        "disease_outcome": np.random.permutation(
            np.repeat(["Positive", "Negative"], 20)
        ),
    }
)

# print first 6 rows
print(vaccine_data.head(6))

# build a 2x2 contingency table: rows = exposure, cols = outcome
table = pd.crosstab(vaccine_data["vaccine_state"], vaccine_data["disease_outcome"])
# reorder so "Vaccinated"/"Positive" is the reference cell, matching epitools convention
table = table.reindex(index=["Vaccinated", "Unvaccinated"], columns=["Positive", "Negative"])

t2x2 = Table2x2(table.to_numpy())

# calculating the risk ratio
print("Risk ratio:", t2x2.riskratio, "95% CI:", t2x2.riskratio_confint())

# calculating the odds ratio
print("Odds ratio:", t2x2.oddsratio, "95% CI:", t2x2.oddsratio_confint())

# %% [markdown]
# # Epidemic curve

# %%
# Convert date to proper format and create epidemiological week using floor to Monday
# Epidemiological weeks start on Monday

cholera_data["date"] = pd.to_datetime(cholera_data["date"])
# floor_date(..., unit = "week", week_start = 1) equivalent: back up to the Monday
cholera_data["epi_week_start"] = cholera_data["date"] - pd.to_timedelta(
    cholera_data["date"].dt.weekday, unit="D"
)

epi_curve_data = (
    cholera_data.groupby("epi_week_start", as_index=False)
    .agg(
        total_cases=("cases", "sum"),
        total_deaths=("deaths", "sum"),
        min_date=("date", "min"),
        max_date=("date", "max"),
    )
    .sort_values("epi_week_start")
)

# Define the scaling factor for the dual axes, sized to the actual data range
# Primary axis: cases; secondary axis: deaths
cases_max = int(np.ceil(epi_curve_data["total_cases"].max() / 500) * 500)
deaths_max = int(np.ceil(epi_curve_data["total_deaths"].max() / 20) * 20)
scale_factor = deaths_max / cases_max  # converting deaths scale to cases scale

fig, ax1 = plt.subplots(figsize=(11, 6))

# Column bars for cases (primary axis)
ax1.bar(
    epi_curve_data["epi_week_start"],
    epi_curve_data["total_cases"],
    width=5,
    color="#FFA500",
    edgecolor="#FF8C00",
    alpha=0.8,
    label="Cases",
)
ax1.set_ylim(0, cases_max)
ax1.set_yticks(range(0, cases_max + 1, cases_max // 5))
ax1.set_ylabel("Cases", fontsize=10, color="black")
ax1.set_xlabel("Epidemiological Week", fontsize=10)

# Line plot for deaths (needs scaling to fit primary axis, then shown on secondary axis)
ax1.plot(
    epi_curve_data["epi_week_start"],
    epi_curve_data["total_deaths"] / scale_factor,
    color="#FF4500",
    linewidth=1.2,
    label="Deaths",
)

# Secondary y-axis (deaths)
ax2 = ax1.twinx()
ax2.set_ylim(0, deaths_max)
ax2.set_yticks(range(0, deaths_max + 1, deaths_max // 5))
ax2.set_ylabel("Deaths", fontsize=10, color="black")

# X-axis date formatting (by month)
ax1.xaxis.set_major_locator(mdates.MonthLocator())
ax1.xaxis.set_major_formatter(mdates.DateFormatter("%Y-%m-%d"))
plt.setp(ax1.get_xticklabels(), rotation=45, ha="right", fontsize=8)

# Gridlines and title
ax1.grid(axis="y", color="gray", alpha=0.3)
ax1.set_axisbelow(True)
start_label = epi_curve_data["epi_week_start"].min().strftime("%B %Y")
end_label = epi_curve_data["epi_week_start"].max().strftime("%B %Y")
plt.title(
    f"Weekly Epi curve of cholera cases in Malawi, {start_label} to {end_label}",
    fontsize=12,
    fontweight="bold",
)

fig.tight_layout()
plt.savefig("cholera_epi_curve.png", dpi=300, bbox_inches="tight")
plt.show()
