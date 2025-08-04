## Script to accompany 'How to make a demonstration table in R' section of Basic Data Visualisation

# Set up

install.packages(c(
  "readr", # for read_csv()
  "dplyr", # for data manipulation
  "tidyr", # for pivot_wider() and drop_na()
  "janitor", # for clean_names()
  "gt" # for creating and styling tables
))


library(readr)
library(dplyr)
library(tidyr)
library(janitor)
library(gt)

# Importing data using the readr package and read_csv function

vulnerable <- read_csv("C:/Users/bestj/OneDrive - Office for National Statistics/Documents/Pandemic Preparedness Toolkit/Basic data vis/R/vulnerable.csv")


# Prepare the data to make it suitable for a table

vuln_for_select_countries_3y <- vulnerable %>%
  
  filter(year %in% c(1997, 2002, 2007)) %>%
  
  select(country, continent, year, vulnerable_pop) %>%
  
  # Reshaping the data
  
  tidyr::pivot_wider(names_from = year, values_from = vulnerable_pop) %>%
  
  tidyr::drop_na() %>%
  
  group_by(continent) %>%
  
  # Selecting the top 2 values
  
  dplyr::top_n(n = 2)


# Cleaning the column names

vuln_for_select_countries_3y <- janitor::clean_names(vuln_for_select_countries_3y)

# To Display the data

vuln_for_select_countries_3y


# Creating a gt table

vuln_for_select_countries_3y %>%
  
  gt()


# Specifying the rowname and groupname

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent")


# Add a title and subtitle
# Use tab_header and specify the title and subtitle arguments

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  tab_header(title = "Table 1: Vulnerable populations increase in size over time",
             
             subtitle = "Size of vulnerable population in select countries in 1997, 2002, and 2007")


# Add a title and subtitle

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  tab_header(title = gt::md("**Table 1: Vulnerable populations increase in size over time**"),
             
             subtitle = gt::md("*Size of vulnerable population in select countries in 1997, 2002, and 2007*")

             )


# Add a source

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  tab_header(title = gt::md("**Table 1: Vulnerable populations increase in size over time**"),
             
             subtitle = gt::md("*Size of vulnerable population in select countries in 1997, 2002, and 2007*")
             
  ) %>%
  
  # Add a source note
  
  tab_source_note(source_note = "Source: Pandemic Preparedness Toolkit")


# Add a footnote
# Use locations to specify where it should appear

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  tab_header(title = gt::md("**Table 1: Vulnerable populations increase in size over time**"),
             
             subtitle = gt::md("*Size of vulnerable population in select countries in 1997, 2002, and 2007*")
             
  ) %>%
  
  tab_source_note(source_note = gt::md("Source: Pandemic Preparedness Toolkit")
                  
  ) %>%
  
  # Add a footnote
  
  tab_footnote(footnote = "Data from 1997 is incomplete",
               
               locations = cells_column_labels(columns = ("x1997")
                                               
               )
  )


# Label your columns

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  tab_header(title = gt::md("**Table 1: Vulnerable populations increase in size over time**"),
             
             subtitle = gt::md("*Size of vulnerable population in select countries in 1997, 2002, and 2007*")
             
  ) %>%
  
  # Add a spanner
  
  tab_spanner(label = gt::md("**Years**"), columns = everything()
              
  ) %>%
  
  # Add a stub head
  
  tab_stubhead(label = gt::md("**Continent**")
               
  )


# Right align a column’s text

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  # Right align column text
  
  cols_align(align = "right",
             
             columns = vars(x1997, x2002, x2007)
             
  )


# Format numbers to include commas

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  fmt_number(columns = everything(),
             
             use_seps = TRUE,
             
             decimals = 0)

# Add a suffix

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
# Format numbers
  
  fmt_number(columns = everything(),
             
             decimals = 2,
             
             suffixing = TRUE)


# Rearrange columns

vuln_for_select_countries_3y_rearrange <-vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  cols_move(columns = vars(x2002, x1997),
            
            after = vars(x2007)
            
  )


# Manually rearrange the order of rows

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  row_group_order(groups = c("Africa",
                             
                             "Asia",
                             
                             "Americas",
                             
                             "Europe",
                             
                             "Oceania")
                  
  )


# Re-prepare the data, arranging rows in ranked order, then recreate the table

vuln_for_select_countries_3y_ranked <- vulnerable %>%
  
  filter(year %in% c(1997, 2002, 2007)) %>%
  
  select(country, continent, year, vulnerable_pop) %>%
  
  tidyr::pivot_wider(names_from = year, values_from = vulnerable_pop) %>%
  
  tidyr::drop_na() %>%
  
  group_by(continent) %>%
  
  dplyr::top_n(n = 2)
  
vuln_for_select_countries_3y_ranked <- janitor::clean_names(vuln_for_select_countries_3y_ranked)

# Here the code sorts by continent name, then size of vulnerable population for each continent as of 2007 (largest to smallest)

vuln_for_select_countries_3y_ranked <- vuln_for_select_countries_3y_ranked %>%
  
  arrange(continent, desc(x2007))

# Recreate the table

vuln_for_select_countries_3y_ranked %>%
  
  gt()

vuln_for_select_countries_3y_ranked %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent")


# Add summary rows

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  summary_rows(groups = everything(),
               
               columns = everything(),
               
               fns = list(my_total = "sum",
                          
                          my_mean = "mean")
               
  )


# Add grand summary rows

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  grand_summary_rows(columns = everything(),
                     
                     fns = list(my_min = "min",
                                
                                my_max = "max",
                                
                                my_avg = "mean"))


# Re-prepare the data to include a summary column

vuln_for_select_countries_3y_avg <- vulnerable %>%
  
  filter(year %in% c(1997, 2002, 2007)) %>%
  
  select(country, continent, year, vulnerable_pop) %>%
  
  tidyr::pivot_wider(names_from = year, values_from = vulnerable_pop) %>%
  
  tidyr::drop_na() %>%
  
  group_by(continent) %>%
  
  dplyr::top_n(n = 2)

vuln_for_select_countries_3y_avg <- janitor::clean_names(vuln_for_select_countries_3y_avg)

# Add a column for mean average
# Make sure columns are numeric first (otherwise it won't be possible to calculate an average)

vuln_for_select_countries_3y_avg <- vuln_for_select_countries_3y_avg %>%
  
  mutate(
    
    x1997 = as.numeric(gsub(",", "", x1997)),
    
    x2002 = as.numeric(gsub(",", "", x2002)),
    
    x2007 = as.numeric(gsub(",", "", x2007))
    
  ) %>%
  
  mutate(average_vulnerable = rowMeans(across(c(x1997, x2002, x2007)), na.rm = TRUE))

# Recreate the table

vuln_for_select_countries_3y_avg %>%
  
  gt()

vuln_for_select_countries_3y_avg %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent")         


# Change cell width

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country",
     
     groupname_col = "continent") %>%
  
  cols_width(vars(x2007) ~ px(120),
             
             vars(x2002) ~ px(100),
             
             TRUE ~ px(70)
             
  )


# Highlight the cell with the largest vulnerable population in 1997 by making the cell gold and the text bold

vuln_for_select_countries_3y %>%
  
  gt(
    
    rowname_col = "country",
    
    groupname_col = "continent"
    
  ) %>%
  
  tab_style(
    
    style = list(
      
      cell_fill(color = "#E2BC22"),
      
      cell_text(weight = "bold")
    ),
    
    
    locations = cells_body(
      
      columns = vars(x1997),
      
      rows = x1997 == max(x1997, na.rm = TRUE) # Changes the colour of the cell with the highest value
      
    )
  )


# Highlight the row for Brazil

vuln_for_select_countries_3y %>%
  
  gt(rowname_col = "country", groupname_col = "continent") %>%
  
  # Highlight all data cells in the Brazil row
  
  tab_style(
    
    style = list(
      
      cell_fill(color = "#E2BC22"),
      
      cell_text(weight = "bold")
      
    ),
    
    locations = cells_body(
      
      rows = country == "Brazil"
      
    )
    
  ) %>%
  
  
  # Highlight the row label (country name) for Brazil
  
  tab_style(
    
    style = list(
      
      cell_fill(color = "#E2BC22"),
      
      cell_text(weight = "bold")
      
    ),
    
    locations = cells_stub(
      
      rows = country == "Brazil"
      
    )
    
  )


# Save the table as HTML

vuln_for_select_countries_3y %>%
  
  gt(
    
    rowname_col = "country",
    
    groupname_col = "continent"
    
  ) %>%
  
  gtsave(filename = "test_r.html", path = "D:/Temp/")

