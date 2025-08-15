#### Script to accompany 'How to make a bar chart in R' section of Basic Data Visualisation

## Set up

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


## Importing data using the readr package and read_csv function

vulnerable <- read_csv("C:/Users/bestj/OneDrive - Office for National Statistics/Documents/Pandemic Preparedness Toolkit/Basic data vis/R/vulnerable.csv")



### SIMPLE BAR CHARTS: FREQUENCY CHARTS
# Also known as frequency charts, these are charts with just one dependent variable based on the count
# or instances of each category.


## Make the base chart
# Make a simple bar chart with one variable, looking at count of countries by continent
# The data is filtered to 1997 first

filter(vulnerable, year == 1997) %>%
  ggplot() +
  geom_bar(mapping = aes(x = continent)) +
  
# The code below removes the padding between the bars and the axis at the start of each bar, 
# but keeps a small gap at the end  
  
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05)))
  

## Flip the chart to be horizontal
# Flip the chart using coord_flip()
# This is added as a layer

filter(vulnerable, year == 1997) %>%
  ggplot() +
  geom_bar(mapping = aes(x = continent)
           ) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  coord_flip() # This flips the chart


## Add text
# Add a title, subtitle, source information, and footnote

filter(vulnerable, year == 1997) %>%
  ggplot() +
  geom_bar(mapping = aes(x = continent)
  ) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    caption = paste(
      "Source: Pandemic Preparedness Toolkit",
      "Note: Counts are based on boundaries in 1997.",
      sep = "\n"
    )
  )


## Add labels
# Add labels to the bars, then remove the x-axis label while renaming the label on the y-axis

filter(vulnerable, year == 1997) %>%
  ggplot() +
  geom_bar(mapping = aes(x = continent)) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  
  )

# Alternatively, have the labels appear at the start of each bar

# Prepare the df

labels_inside <- vulnerable %>%
  filter(year == 1997) %>%
  count(continent)

# Recreate the chart, with labels inside the bars

ggplot(labels_inside, aes(x = continent, y = n)) +
  geom_col() +
  geom_text(
    aes(y = 0.5, label = n),  # label at start of bar
    hjust = 0,
    color = "white",
    size = 3
  ) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))
  ) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  )


## Modify layout and appearance

# Modify axis breaks and change gridline and background colours

filter(vulnerable, year == 1997) %>%
  ggplot() +
  geom_bar(mapping = aes(x = continent)) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))
  ) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )
    

# Rank categories in descending order (highest first)
# For a frequency chart, this needs to be done manually

# Prepare the data

ranked_categories <- vulnerable %>%
  filter(year == 1997) %>%
  group_by(continent) %>%
  mutate(level_continent = factor(continent,
                                  levels = c("Oceania", "Americas", "Asia", "Europe", "Africa")))

# Recreate the chart

ggplot(ranked_categories) +
  geom_bar(mapping = aes(x = level_continent)) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  scale_y_continuous(breaks = pretty(c(0, 60), n = 10)) + 
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )


# Change the width of your bars

ggplot(ranked_categories) +
  geom_bar(mapping = aes(x = level_continent), width = 0.6) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )
    
# Change the colour of bars

# Change all bars to dark blue

ggplot(ranked_categories) +
  geom_bar(mapping = aes(x = level_continent), fill = "#003d59", width = 0.6) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )
    
# Change the bar for Africa to a dark blue, and all the other bars to a light grey

ggplot(ranked_categories) +
  geom_bar(
    mapping = aes(x = level_continent, fill = level_continent == "Africa"),
    width = 0.6
  ) +
  scale_fill_manual(
    values = c("TRUE" = "#003d59", "FALSE" = "lightgrey"),
    guide = "none") + # hides the legend
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )

## Export your frequency chart

# Define the chart as an object

vuln_countries = 
  ggplot(ranked_categories) +
  geom_bar(mapping = aes(x = level_continent), fill = "#003d59", width = 0.6) +
  scale_y_continuous(
    breaks = pretty(c(0, 60), n = 10),
    expand = expansion(mult = c(0, 0.05))) +
  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..), 
            hjust = -0.4, color = "black", size = 3) +
  coord_flip() +
  labs(
    title = "Figure 1: Africa has the most countries by continent",
    subtitle = "Number of countries by continent",
    x = "",
    y = "Number of countries"
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "grey85", size = 0.5),
    panel.grid.major.y = element_blank()
  )

# Export

ggsave(
  filename = "vuln_countries_freq.svg",
  plot = vuln_countries,
  path = "D:/Temp",
  width = 7,
  height = 5,
  dpi = 300
)
