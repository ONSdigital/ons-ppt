import streamlit as st

st.title("Welcome to the RAP Resource Explorer")
st.markdown(
    """
## How to use this tool

This tool helps you explore and filter resources for building Reproducible
Analytical Pipelines (RAP).

### Instructions:
- Use the sidebar to navigate to the 'Search' page.
- Filter by language, purpose, or search by name.
- Click on any resource to view more details and installation instructions.

### Search Functionality:
- **Search by Language**: Filter resources based on programming languages
like Python, R, or SQL.
- **Search by Purpose**: Find resources tailored for specific tasks such
as data cleaning, visualization, or machine learning.
- **Search by Name**: Quickly locate a resource by its name.
- **Resource Details**: Click on a resource to see detailed information and
installation instructions.

### Purpose category descriptions:
- `Code Quality`: Tools for ensuring code quality and maintainability,
including linters, formatters and secrets handling.
- `Dependency management`: Tools for managing dependencies and environments,
including package and environment managers.
- `Documentation`: Tools for generating and managing documentation,
including docstrings, html documentation and loggers.
- `Package development`: Tools for developing and packaging packages,
including package managers and build tools.
- `Project templates`: RAP adherent project templates to kickstart your
project.
- `Quality assurance`: Tools for ensuring the quality of your code and
data, including unit testing frameworks and data validation tools.
"""
)
