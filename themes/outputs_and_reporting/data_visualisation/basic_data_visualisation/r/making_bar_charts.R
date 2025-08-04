## Script to accompany 'How to make a bar chart in R' section of Basic Data Visualisation

# Set up

install.packages(c(
  "readr", # for read_csv()
  "dplyr", # for data manipulation
  "janitor", # for clean_names()
  "ggplot2", # for visualising data
  "tidyr", # for tidying data
  "scales", # for automatically determining labels for axes and legends
  "patchwork", # for combining plots
))


library(readr)
library(dplyr)
library(janitor)
library(ggplot2)
library(tidyr)
library(scales)
library(patchwork) 

# Importing data using the readr package and read_csv function

vulnerable <- read_csv("C:/Users/bestj/OneDrive - Office for National Statistics/Documents/Pandemic Preparedness Toolkit/Basic data vis/R/vulnerable.csv")

# SIMPLE BAR CHARTS

# Make a simple bar chart with one variable, looking at count of countries by continent

filter(vulnerable, year == 1997) %>%
  
  ggplot() +
  
  geom_bar(mapping = aes(x = continent)
           
  )



