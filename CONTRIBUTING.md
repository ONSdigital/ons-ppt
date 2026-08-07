# Contributing

## Contents
- [What to Contribute](#what-to-contribute)
- [Contribution Process](#contribution-process)
  - [1. Cloning the Repository](#1-cloning-the-repository)
  - [2. Set-up](#2-set-up)
  - [3. Adding your code and data](#3-adding-your-code-and-data)
  - [4. Pull Requests](#4-pull-requests)
- [Coding standards](#coding-standards)
- [Raising Issues](#raising-issues)
- [Questions](#questions)

## What to Contribute
This repository should include code and data that directly relates to written content or tools on the Analysis for Action platform, including:
- runnable code snippets in Python and R,
- example datasets,
- small tools that are included within a unit,
- documentation to support understanding and use of the code snippets and tools.

This repository should **not** include:
- sensitive data,
- large tools or applications (these should be in their own repositories),
- written unit content that is or will be hosted on the Analysis for Action platform,
- code from written unit content that is not runnable i.e. only used as an example.

## Contribution Process

### 1. **Cloning the Repository**
To begin contributing, clone the repository directly:

```cmd
git clone https://github.com/ONSdigital/analysis-for-action.git
cd analysis-for-action
```

### 2. **Set-up**
Follow the setup instructions in the [README.md](README.md) to configure your development environment.

This repository also uses `pre-commit` to manage git hooks. This ensures our code is consistent and secure. To set it up:
1. install python dependencies following instructions in the [README.md](README.md)
2. run the below in your terminal:
   ```sh
   pre-commit install
   ```

### 3. **Adding your code and data**

#### Branching
Create a new branch for your changes, include the unit name and description of the code where possible e.g. `intro_to_rap_code_snippets`, `outputs_and_reporting_contrast_checker`.

#### Where to add your code

##### Learning resources
- Add code and documentation to the correct folder, following the [repository structure](README.md#repository-structure).
- Python code should be added to the `python/` folder as an `.ipynb` notebook file.
- R code should be to the `R/` folder as an `.Rmd` R markdown file.
- Documentation should be added to the `docs/` folder as a `.md` markdown file.
- You may need to create the folders yourself if they do not already exist.

Templates for each can be found the below:
 - Python notebook template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\python\\example.ipynb](learning_resources\\_example_theme\\_example_module\\_example_unit\\python\\example.ipynb)
 - R markdown template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\R\\example.Rmd](learning_resources\\_example_theme\\_example_module\\_example_unit\\R\\example.Rmd)
 - Instructions template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\docs\\example.md](learning_resources\\_example_theme\\_example_module\\_example_unit\\docs\\example.md)

- .py and .R script files can be used when learning resources refer to existing tools that are not appropriate for the `tools/` folder, but these should be avoided where possible in favour of notebooks and R markdown files.

##### Tools
- Add tools to the correct folder, following the [repository structure](README.md#repository-structure).
- Create a folder for the tool within the relevant theme and module.
- Add Python tool files and folders to the `python/` folder.
- Add R tool files and folders to the `R/` folder.
- If a tool has only been built in one language, the code can go directly into the module folder, for example `tools/theme1/module1/tool1/main.py`.
- Additional documentation should be added to the `docs/` folder as a `.md` markdown file.
- You may need to create the folders yourself if they do not already exist.

- Code files and structure will vary for each tool, but example structures can be found in the [tools/_example_theme/](tools/_example_theme/) directory.
- Instructions can also be found in the [developer instructions](tools/_example_theme/_example_module/_example_tool/docs/developer_instructions.md).

These examples are intended to provide an example of a simple structure as well as best practice code and documentation for tools within the platform. They are not intended as a one size fits all solution, and you should adapt the structure as necessary to suit the needs of your specific tool.


#### Where to add data
Add data for learning resource code to the `learning_resources/data/` folder.

> **Ensure no sensitive code or data is included before committing and pushing changes.**

#### Where to add dependencies
Add any dependencies to the relevant files:
- For Python, update `requirements.txt`.
- For R, add the package names to the `setup.R` script if new packages are required.

Ensure your code has been peer reviewed and meets the project's [coding standards](#coding-standards).

### Linting and styling
#### Python
This repository uses pre commits for Python linting and styling. Install the pre commits by following the instructions in the [Set Up](#2-set-up) section of the contributing guidance. These checks will then run whenever you commit code.

#### R
R code quality can be checked using the `lintr` and `styler` packages. It is recommended to run these checks before committing your code to ensure it meets the project's coding standards.

To do this, you can use the following commands in R:
1. Install the packages (if not already installed):
```R
# Install lintr and styler if you haven't already
install.packages("lintr")
install.packages("styler")
```
2. Run `lintr` to check for linting issues:
```R
lintr::lint_dir("path/to/your/code")  # Replace with the path to your R code
```
3. Use `styler` to format your code:
```R
styler::style_dir("path/to/your/code")  # Replace with the path to your R code
```

### 4. **Pull Requests**
#### Creating Pull Requests
- Push your branch to the remote repository.
- Navigate to the repository on GitHub and create a new Pull Request.
- When you create a Pull Request (PR), always select the `dev` branch as the target for merging your changes.
- **Do not select `main` as the target branch.**
- Fill in details and submit the pull request.
- Use clear, consistent Pull Request (PR) names to make collaboration easier. Follow this format:

```
<theme>.<module>.<unit>. <unit_name> <short_description_or_product_name>
```
Example - `2.2.1. Intro to RAP Code snippets`
- Clearly describe your changes and reference any relevant issues.
- The code must be reviewed by at least one tester and a member of the UK Analysis for Action team before it is merged.

#### Reviewing Pull Requests
- Navigate to the Pull Request on GitHub. If a link is not provided the Pull Request can be found under the "Pull Requests" tab of the repository.
- Read the description of the changes made.
- Click on the "Files changed" tab to see the code changes and click "Review changes" to add your comments.
- Where possible add comments to specific lines of code by hovering over the line and clicking the blue plus icon that appears.
- For general comments that are not tied to a specific line of code, add them in the review box on the top right.
- Follow the testing recommendations template for more information on what to consider when reviewing tools and code.
- Ensure code follows the project's [coding standards](#coding-standards).
- Add a summary of your review comments in the review box on the top right.
- Select "Approve" if the code is good to merge, or "Request changes" if there are issues that need to be addressed.

## Coding standards
All contributions should adhere to the following standards:

### Coding practice
- Code follows the [tidyverse](https://style.tidyverse.org/) style (for R) or the [PEP8](https://www.python.org/dev/peps/pep-0008/) style (for Python).
- Function, variable, and dataframe names are clear and logical.
- Code logic is clear and avoids unnecessary complexity.
- Hardcoded values (like file paths or constants) have been removed so that the user can easily customise these themselves.
- Repetition in the code is minimalised. For example, by moving reusable code into functions or classes.

### Code documentation

- A README file is submitted alongside your code explaining its purpose and how it can be used by the user. This may not be appropriate for all scripts, but it should be included for code designed to be adapted and used by the user for their own purposes.
- Comments are used to describe what the code is doing.
- Comments are up to date, so they do not confuse the user.
- Code is not commented out to adjust which lines of code run.
- All functions and classes are documented to describe what they do, what inputs they take and what they return.
- R functions are documented using [roxygen2](https://roxygen2.r-lib.org/) comments. Python functions are documented using [docstrings](https://docs.python.org/3/tutorial/controlflow.html#defining-functions).

### Data management

- Any sensitive input data are omitted or replaced with fictional (i.e. ‘dummy’) data. There is no way to identify individuals from the data.
- All input data referred to in the code are submitted alongside the Unit content, so that the Tester can access and download the files.
- All input data referred to in the code is documented in your copy of the PPT Data Register, including where they come from, whether they are real or fictional data, assurance of their quality, and their importance to the Unit.

### Testing

- The programmer has tested the code from start to finish using one or more realistic end-to-end tests. In other words, the code does what it is supposed to.
- A peer reviewer (i.e. not the original programmer) has tested the code from start to finish using one or more realistic end-to-end tests. In other words, they have verified that the code does what it is supposed to.
- Core functionality has been unit tested, where appropriate (this may not be necessary for shorter code). See testthat for R and pytest for Python.
- Where appropriate, the code has been designed so that users can adapt it for their own purposes, including using their own input data instead of the example data provided. This may not be appropriate for all scripts, for example, source code for a tool. However, it is important to consider for code intended for users to make use of in their own work.

### Dependency management

- Required libraries and packages are documented, including their versions.
- Where appropriate, configuration files are included.
- Where appropriate, code runs independently of the operating system (for example there is suitable management of file paths for different operating systems).
- The code handles memory and processing efficiently, avoiding unnecessary data duplication and excessive memory usage.

## Raising Issues
If you encounter any problems or have suggestions for improvements, raise an issue in the repository. Provide as much detail as possible to help us understand and address the issue effectively.

You are also welcome to google message or email.

## Questions
If you have questions, please contact the project maintainers directly at [analysisforaction@ons.gov.uk](analysisforaction@ons.gov.uk) or in the google workspace.
