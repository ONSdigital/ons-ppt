# **[unit name]**, **[chapter name]** - Instructions for running code snippets
This document provides instructions on how to run the code snippets provided for the **[unit name]**, **[chapter name]** learning resource. The code examples are available in both Python and R formats.

## Files and locations
The code snippets for this unit can be found in the `python` and `r` folders within this unit's directory. Both folders contain the same set of example files, but in different programming languages. Choose the appropriate folder based on your preferred programming language.

## Contents
> **Note for developers**: Where there are many examples, consider creating a file per chapter or topic, for example, the "Intro to RAP" unit could be split into;   `01_rap_vs_traditional_analytical_worflows`
`02_how_rap_overcomes_challenges`
In this case, use the below as a template for contents.

- 01_example: [add a brief description of what this file contains]
[Python](learning_resources/_example_theme/_example_module/_example_unit/python/01_example.ipynb), [R](learning_resources/_example_theme/_example_module/_example_unit/r/01_example.Rmd)
- 02_example: [add a brief description of what this file contains]
[Python](learning_resources/_example_theme/_example_module/_example_unit/python/02_example.ipynb), [R](learning_resources/_example_theme/_example_module/_example_unit/r/02_example.Rmd)

## Running Python Code Snippets
To run the Python code snippets, follow these steps:
1. Ensure you have followed the setup instructions in the [README.md](../../../README.md) file to configure your Python environment.
2. Navigate to the `learning_resources/_example_theme/_example_module/_example_unit/python/` directory.
3. Open the `example.ipynb` notebook located in this folder using Jupyter Notebook or JupyterLab.
4. Run the notebook cells sequentially to execute the code snippets.
5. Refer to the troubleshooting section below if you encounter any issues.

## Running R Code Snippets
To run the R code snippets, follow these steps:
1. Ensure you have followed the setup instructions in the [README.md](../../../README.md) file to configure your R environment.
2. Navigate to the `learning_resources/_example_theme/_example_module/_example_unit/r/` directory.
3. Open the `example.Rmd` file located in this folder using RStudio.
4. Either:
- Run the code chunks sequentially, or,
- Knit the R Markdown document to execute the code snippets and generate the output.
5. Refer to the troubleshooting section below if you encounter any issues.

## Troubleshooting
If you encounter any issues running the code snippets, consider the following troubleshooting steps:
- Ensure you have followed the setup instructions in the [README.md](../../../README.md) file including `pip install -r requirements.txt`.
- Run code from top to bottom to ensure all dependencies are met.
- Restart the notebook kernel and clear all outputs (at the top of the notebook, select "Kernel" > "Restart & Clear Outputs").
- For more detailed troubleshooting guidance, refer to the [troubleshooting document]([PLACEHOLDER])
