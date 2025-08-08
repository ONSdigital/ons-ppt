# 2.2.2 RAP Principles


## Introduction

### Skill requirements
To complete this training, users are expected to have a pre-existing knowledge of R or Python.

### Homepage
This unit follows on from the ‘Introduction to RAP’ Unit, which provides users with a theoretical understanding of RAPs. The purpose of the unit is to provide users with useful code packages and real-world code examples to aid their understanding of how to implement Reproducible Analytical Pipelines (RAP). By the end of this unit, users will be able to:

* Have knowledge of useful code packages in R and Python for developing RAPs.
* Understand why and how RAP was implemented in the real-world examples provided.
* Have knowledge on how to begin creating their own RAP for data analysis.

This material is aimed at analysts, data scientists and data engineers. It is also useful for individuals wanting to develop their code.


## Resources
A list of resources for Reproducible Analytical Pipelines (RAP) can be found in the RAP Resource Explorer.


## Case Studies
This section will lead the user through real life examples of where RAP has been implemented. Each example will include commentary and explanations alongside key elements, to explain the RAP code, discuss best practice and show differences between RAP and non-RAP code.

### Birth Characteristics

### Introduction (what the code is, why made)
The Office for National Statistics (ONS) publishes annual birth statistics for England and Wales, including breakdowns by parent age, registration type, and fertility rates. Historically, these outputs were generated using R for data processing, followed by manual table creation in Excel, a workflow that was time-consuming, error-prone, and difficult to maintain.

To address these inefficiencies, the Birth Characteristics pipeline was developed. Its goal was to replace the legacy workflow with a more streamlined, automated process using a Reproducible Analytical Pipeline (RAP) approach. This transition introduced modular code, parameterisation, and automation, significantly reducing manual effort and improving quality assurance.

You can explore the outputs from this pipeline here:
* [GitHub repo](https://gitlab-app-l-01/hapi/child_health/birth-characteristics/-/tree/main/birth.char?ref_type=heads) Think this is private...
* [Output tables](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/birthcharacteristicsinenglandandwales)

Although the pipeline has since evolved further and is no longer actively used, this case study focuses on the initial RAP conversion. These changes offer a good insight into the process of modifying legacy code into a RAP. As we progress through the unit, we will compare the original version of the code with its RAP implementation, highlighting the improvements, benefits, and any difficulties encountered during the transition, starting with the project’s structure.

> **Note:** While the updated code is much better organised, easier to reuse, and more reliable, it doesn’t include every feature you’d expect in a fully RAP-compliant pipeline. As you explore this example, consider what other improvements would help make it more robust, scalable, or easier to maintain in a collaborative setting.

> A best practice example for RAP in R and Python can be found in the Weekly Deaths **[LINK]** and Covid Infection Survey (CIS) Households **[LINK]** examples respectively. More information on best practice for RAP can be found in Quality Assurance for RAP **[LINK]**.

### Structure of the project
#### Original
In this chapter we will compare the structure of the original code to the new RAP implementation.

Here is how the original code was organised:

```
root/
├── Birth_char_code/           # 24 R scripts for QA of output tables
│   ├── Table1_check.R
│   ├── Table2_check.R
│   ├── ...
├── Parents_char_code/         # 6 R scripts for parent characteristic tables
│   ├── Par_char_table1.R
│   ├── Par_char_table2.R
│   ├── ...
├── CODE_for_2022.R            # Main script for importing, cleaning, processing, and outputting tables
├── R code for dealing with multi-birth parities.R
└── R code for imputing missing number of previous children.R
```

> **Reflection**: Before reading further, take a moment to review the structure of the original codebase. Ask yourself:
> * Where would you look to find information about the project and how to run the code?
> * How easy would it be to locate and update a specific part of the code? (e.g. could you easily find where to update the code for calculating fertility rates?)
> * How well does the structure support collaboration – could multiple analysts work on different parts at the same time easily?

The original pipeline relied heavily on a single script `CODE_for_2022.R` located in the root folder. This script handled most of the workflow, including data import, cleaning, processing, and table generation. Two additional scripts in the root directory were used to manage specific cases, such as multi-birth parities and missing data on previous children.

Alongside these, the project included two folders; `Birth_char_code`, which contained 24 scripts used for quality assurance of the output tables, and `Parents_char_code`, which held 6 scripts for generating additional tables based on parental characteristics.

>**Optional Task**: Sketch a revised folder and file structure that you think would make the codebase easier to navigate, maintain, and extend.


#### RAP
Now, have a look at the structure of the RAP implementation:

```
root/
├── birth.char/
│   ├── R/
│   │   ├── backseries.R
│   │   ├── counts_and_rates.R
│   │   ├── create_tables.R
│   │   ├── data_flags.R
│   │   ├── data_imports.R
│   │   ├── estimate_father_age.R
│   │   ├── factor_levels.R
│   │   ├── format_tables.R
│   │   ├── geographies_ew.R
│   │   ├── mean_age_mother.R
│   │   ├── prep_data.R
│   │   ├── summarise_births_char.R
│   │   ├── total_fertitility_rate.R
│   │   ├── user_guide.R
│   │   ├── utils.R
│   │   ├── sysdata.rda
│   ├── man/         # Documentation for all functions
│   ├── tests/       # Unit test scripts
├── .gitignore       # Files and folders for git to ignore
├── README.md        # Project documentation
├── config.R         # Template config file for parameters
├── config_2016.R
├── ...              # Annual config files from 2016 to 2022
├── config_2022.R
├── main.R
└── uk_lookup2019.csv # Area code lookup
```
> **Reflection**: Look at these questions again in the context of the RAP implementation:
> * Where would you look to find information about the project and how to run the code?
> * How easy would it be to locate and update a specific part of the code? (e.g. could you easily find where to update the code for calculating fertility rates?)
> * How well does the structure support collaboration – could multiple analysts work on different parts at the same time easily?
>
>Did you find it easier or harder to answer these questions for the RAP implementation?

At the root level, the project contains a `main.R` script to run the entire pipeline, configuration files for each year for users to enter and adjust parameters and a `README` with documentation for users and stakeholders, such as a project description and how to run the pipeline.

The `birth.char` directory contains an R folder with individual scripts for each analytical step, such as data import, formatting tables, and calculating rates. Supporting folders include `man` for function documentation and `tests` for unit tests.

#### Comparison
Here is a table outlining the differences between the two structures.
| Characteristic      | Old code                                                                                                                                      | RAP implementation                                                                                                                      |
|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| **Workflow**        | Most logic is contained in one large script, making the overall flow difficult to follow. It’s unclear from the structure what each script does. | Each analytical step is separated into its own script with a descriptive name, making the pipeline easier to understand and maintain.    |
| **Interaction**     | Analysts must update parameters in multiple scripts and run each script separately, allowing more room for error.                              | Config files allow users to update parameters in one place, which are then passed to scripts and functions.                              |
| **Documentation**   | The location of documentation isn’t clear. It’s possible that it is held elsewhere, or within code comments.                                  | The `README.md` and `man` folder are within the folder structure and provide clear guidance and documentation for users and developers.  |
| **Quality Assurance** | Quality Assurance (QA) scripts in the “Birth_char” folder are run one by one after the tables have been created.                             | Unit tests in the `tests` folder are used to test all functionality in the pipeline. They can be automated to run after committing changes or merging branches. |
| **Collaboration**   | Multiple analysts working on different scripts risk overwriting changes or duplicating effort.                                                 | Holding different functionality in separate scripts enables multiple analysts to work in parallel without conflict.                      |

Overall the RAP implementation introduces a more structured and maintainable approach compared to the old code. While the original workflow relied on a single, complex script, RAP separates each analytical step into modular scripts with descriptive names, improving readability and maintainability. Interaction is streamlined through the use of a central configuration file, replacing the need to manually update parameters across multiple scripts. Documentation is also more accessible, with clear guidance provided in dedicated files like README.md and the man folder. Quality assurance is enhanced through automated unit tests, replacing the manual execution of QA scripts. Finally, the modular design of RAP supports better collaboration, allowing multiple analysts to work in parallel without risk of conflict or duplication.

### Running the code

As you can see, the old code used to produce this statistical publication included 24 R scripts, which all needed to be run individually by the analyst to produce the data tables required. These scripts range from 66 to 659 lines of code per script.

These scripts required the analyst to update variables relating to the year of interest **in each script** before running the code.

```r
# Update data year
datyr <- 21
datayrfull <- 2021
```

The data outputted from these scripts would then need to be manually copied into the publication tables, which increased the number of manual steps and likelihood for errors to occur.

>**Exercise**
How you could avoid the need to update these variables in each script?
* README
*You could include a config file with the parameters that need changing for each run and pass those parameters to functions*
