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



## Case Studies
This section will lead the user through real life examples of where RAP has been implemented. Each example will include commentary and explanations alongside key elements, to explain the RAP code, discuss best practice and show differences between RAP and non-RAP code.

### Birth Characteristics

### Intro (what the code is, why made)
The Birth characteristics and Birth by parents' characteristics pipeline was developed by the Office for National Statistics (ONS) to produce user-friendly publication tables. These tables present data on different types of births in England and Wales, broken down by various demographic factors. You can find the code here

---

*Do we want this*
*[Birth Characteristics](https://gitlab-app-l-01/hapi/child_health/birth-characteristics/-/tree/main?ref_type=heads).*

---

Although the pipeline is no longer actively used, it provides a good example of how legacy code can be modified into a Reproducible Analytical Pipeline (RAP). In this section, we will compare the original version of the code with its RAP implementation, highlighting the improvements, benefits, and any difficulties encountered during the transition.

A best practice example for RAP in R and Python can be found in the Weekly Deaths and Covid Infection Survey (CIS) Households examples. More information on best practice for RAP can be found in Quality Assurance for RAP.

### Structure of the project
#### Original
The original codebase consisted of 24 R scripts

#### RAP

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
Consider how you could avoid the need to update these variables in each script...
*You could include a config file with the parameters that need changing for each run and pass those parameters to functions*
