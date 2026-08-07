# Developer Instrcutions for adding tools
## Overview
This document provides instructions for developers on how to add new tools to the Analysis for Action repository.

## Repository Structure
The repository is structured to organise tools by themes and modules. Each tool has its own directory containing documentation and code in both Python and R.

```
analysis-for-action/
└── tools/                      # Top-level folder containing all tools.
    └── theme1/                 # A specific theme (e.g., data_analysis, outputs_and_reporting).
        └── module1/            # A module within a theme (e.g., reproducible_analytical_pipelines, data_visualisation).
            └── tool1/          # A specific tool (e.g. epidemic_curve_modelling_dashboard, digital_dashboards).
                ├── docs/       # Documentation for the specific tool.
                ├── python/     # Python code for the specific tool.
                └── R/          # R code for the specific tool.
```

## Adding a New Tool
To add a new tool to the repository, follow these steps:
1. **Create the Tool Directory**:
- Navigate to the appropriate theme and module directories within the `tools` folder.
- Create a new directory for your tool if it does not already exist, named appropriately (e.g., `epidemic_curve_modelling_dashboard`).
2. **Add tool code**:
- This example directory contains examples of how to structure the code for both Python and R implementations of the tool.
- Open the `python/` and `R/` folders to see an example tool structure.

- 2a. **Python Implementation**:
    - Inside the tool directory, create a `python` folder.
    - Add your Python code files to this folder.
    - For **Python**, the minimum structure can include:
        - main.py: The main script to run the tool.
        - requirements.txt: A list of Python dependencies.
        - README.md: Documentation specific to the tool.
        - tests/: A directory containing unit tests for the tool.
    - Also consider adding:
        - src/: A directory containing the main source code for the tool.
- 2b. **R Implementation**:
    - Inside the tool directory, create an `R` folder.
    - Add your R code files to this folder.
    - For **R**, the minimum structure can include:
        - main.R: The main script to run the tool.
        - README.md: Documentation specific to the tool.
        - tests/: A directory containing unit tests for the tool.
        - R/: A directory containing the main source code for the tool.
    - For package development, consider adding:
        - DESCRIPTION: Metadata about the R package. This can replace the setup.R file.
        - NAMESPACE: To manage the functions and datasets exported by the package.
        - man/: A directory containing documentation files for the package functions. These manuals should be created automatically using [Roxygen2](https://roxygen2.r-lib.org/).
3. **Extra documentation**:
- Add a `docs` folder within the tool directory.
- Include any additional documentation files related to the tool in this folder, such as:
    - Usage examples
    - Data dictionaries
    - Design documents

## README templates
- The Python and R folders contain README.md templates that you can adapt for your specific tool.
- Either use these examples as a template to fill with your own content or use them as a reference to create your own README.md file.

## Coding standards
- Follow coding standards as outlined in the [coding standards](../../CONTRIBUTING.md#coding-standards) section of the repository.
- Pre commit hooks are set up to help maintain code quality. Install pre commits by following the instructions in the [Set Up](../../CONTRIBUTING.md#2-set-up) section of the contributing guidance.
- It is also recommended to use lintr and styler for R code quality checks.
