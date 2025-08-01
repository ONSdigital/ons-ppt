import pandas as pd
import streamlit as st
from rapidfuzz import fuzz

# Expanded dataset with more RAP tools and resources
data = [
    {
        "name": "govcookiecutter",
        "language": ["Python", "R"],
        "purpose": ["Project template", "Quality assurance"],
        "description": """
        A cookiecutter template for creating government projects with a
        focus on Quality assurance.
        """,
        "install": "cookiecutter gh:best-practice-and-impact/govcookiecutter",
        "link": "https://github.com/best-practice-and-impact/govcookiecutter",
    },
    {
        "name": "testthat",
        "language": ["R"],
        "purpose": ["Testing", "Quality assurance"],
        "description": """
        A testing framework for R that makes it easy to write and run tests.
        """,
        "install": "install.packages('testthat')",
        "link": "https://cran.r-project.org/web/packages/testthat/index.html",
    },
    {
        "name": "pytest",
        "language": ["Python"],
        "purpose": ["Testing", "Quality assurance"],
        "description": """
        A framework that makes building simple and scalable test cases easy.
        """,
        "install": "pip install pytest",
        "link": "https://docs.pytest.org/",
    },
    {
        "name": "cookiecutter-data-science",
        "language": ["Python"],
        "purpose": ["Project template"],
        "description": """
        A logical, reasonably standardized, but flexible project structure for
        doing and sharing data science work.
        """,
        "install": "cookiecutter https://github.com/drivendata/cookiecutter-data-science",  # noqa: E501
        "link": "https://github.com/drivendata/cookiecutter-data-science",
    },
    {
        "name": "gptables",
        "language": ["Python"],
        "purpose": ["Publication tables"],
        "description": """
        A package for generating publication-ready tables from Python data
        frames.
        """,
        "install": "pip install gptables",
        "link": "https://github.com/best-practice-and-impact/gptables",
    },
    {
        "name": "aftables",
        "language": ["R"],
        "purpose": ["Publication tables"],
        "description": """
        A package for generating publication-ready tables from R data frames.
        """,
        "install": "devtools::install_github('best-practice-and-impact/aftables')",  # noqa: E501
        "link": "https://github.com/best-practice-and-impact/aftables",
    },
    {
        "name": "rapid.spreadsheets",
        "language": ["R"],
        "purpose": ["Publication tables"],
        "description": (
            "A package for generating publication-ready tables from R data frames."  # noqa: E501
        ),
        "install": "devtools::install_github('best-practice-and-impact/rapid.spreadsheets')",  # noqa: E501
        "link": "https://github.com/best-practice-and-impact/rapid.spreadsheets",  # noqa: E501
    },
    {
        "name": "cookiecutter-reproducible-research",
        "language": ["Python"],
        "purpose": ["Project template"],
        "description": (
            "A cookiecutter template for creating reproducible research projects."  # noqa: E501
        ),
        "install": "cookiecutter https://github.com/alan-turing-institute/cookiecutter-reproducible-research",  # noqa: E501
        "link": "https://github.com/alan-turing-institute/cookiecutter-reproducible-research",  # noqa: E501
    },
    {
        "name": "venv",
        "language": ["Python"],
        "purpose": ["Environment management"],
        "description": """
        A standard library module for creating lightweight virtual environments
        in Python; allows you to manage dependencies for different projects.
        """,
        "install": "python -m venv venv",
        "link": "https://docs.python.org/3/library/venv.html",
    },
    {
        "name": "pyenv",
        "language": ["Python"],
        "purpose": ["Environment management"],
        "description": """
        A tool to manage multiple Python versions; allows you to switch
        between different Python versions easily.
        """,
        "install": "See installation guide",
        "link": "https://github.com/pyenv/pyenv",
    },
    {
        "name": "virtualenv",
        "language": ["Python"],
        "purpose": ["Environment management"],
        "description": """
        A tool to create isolated Python environments; allows for different
        dependencies in different projects.
        """,
        "install": "pip install virtualenv",
        "link": "https://virtualenv.pypa.io/",
    },
    {
        "name": "renv",
        "language": ["R"],
        "purpose": ["Environment management"],
        "description": """
        A package for managing R project environments; captures the state of
        your R packages and their versions.
        """,
        "install": "install.packages('renv')",
        "link": "https://rstudio.github.io/renv/",
    },
    {
        "name": "devtools",
        "language": ["R"],
        "purpose": ["Package development"],
        "description": """
        A set of tools to make Package development easier; includes functions
        for testing, building, and installing packages.
        """,
        "install": "install.packages('devtools')",
        "link": "https://devtools.r-lib.org/",
    },
    {
        "name": "roxygen2",
        "language": ["R"],
        "purpose": ["Documentation"],
        "description": """
        A package for documenting R code; generates documentation from
        comments in the source code.
        """,
        "install": "install.packages('roxygen2')",
        "link": "https://roxygen2.r-lib.org/",
    },
    {
        "name": "Sphinx",
        "language": ["Python"],
        "purpose": ["Documentation"],
        "description": """
        A Documentation for Python projects; supports reStructuredText and
        Markdown.
        """,
        "install": "pip install sphinx",
        "link": "https://www.sphinx-doc.org/",
    },
    {
        "name": "MkDocs",
        "language": ["Python"],
        "purpose": ["Documentation"],
        "description": "A static site generator that's geared towards project "
        "documentation; uses Markdown for writing content.",
        "install": "pip install mkdocs",
        "link": "https://www.mkdocs.org/",
    },
    {
        "name": "Quarto",
        "language": ["Any"],
        "purpose": ["Publishing"],
        "description": """
        A publishing system for scientific and technical documents; supports R
        Markdown, Jupyter Notebooks, and more.
        """,
        "install": "See installation guide",
        "link": "https://quarto.org/",
    },
    {
        "name": "Docker",
        "language": ["Any"],
        "purpose": ["Containerisation"],
        "description": """
        Platform for developing, shipping, and running applications in
        containers; ensures consistent environments across different systems.
        """,
        "install": "See installation guide",
        "link": "https://www.docker.com/",
    },
    {
        "name": "logging",
        "language": ["Python"],
        "purpose": ["Logging"],
        "description": """
        Standard library module for logging in Python; provides a flexible
        framework for emitting log messages from Python programs.
        """,
        "install": "Standard library",
        "link": "https://docs.python.org/3/library/logging.html",
    },
    {
        "name": "pre-commit",
        "language": ["Python"],
        "purpose": ["Code Quality"],
        "description": """
        Framework for managing and maintaining multi-language pre-commit hooks;
        helps enforce code quality and style before commits.
        """,
        "install": "pip install pre-commit",
        "link": "https://pre-commit.com/",
    },
    {
        "name": "detect-secrets",
        "language": ["Python"],
        "purpose": ["Code Quality"],
        "description": """
        Scans code for sensitive information like API keys and passwords;
        integrates with pre-commit.
        """,
        "install": "pip install detect-secrets",
        "link": "https://github.com/Yelp/detect-secrets",
    },
    {
        "name": "flake8",
        "language": ["Python"],
        "purpose": ["Code Quality"],
        "description": """
        Checks Python code for style and syntax issues; integrates with various
        editors.
        """,
        "install": "pip install flake8",
        "link": "https://flake8.pycqa.org/",
    },
    {
        "name": "black",
        "language": ["Python"],
        "purpose": ["Code Quality"],
        "description": """
        Formats Python code to a consistent style; integrates with various
        editors.
        """,
        "install": "pip install black",
        "link": "https://black.readthedocs.io/",
    },
    {
        "name": "isort",
        "language": ["Python"],
        "purpose": ["Code Quality"],
        "description": """
        Sorts imports in Python files according to PEP 8 style guide;
        integrates with various editors.
        """,
        "install": "pip install isort",
        "link": "https://pycqa.github.io/isort/",
    },
    {
        "name": "lintr",
        "language": ["R"],
        "purpose": ["Code Quality"],
        "description": """
        Checks R code for style and syntax issues; integrates with RStudio and
        other editors.
        """,
        "install": "install.packages('lintr')",
        "link": "https://lintr.r-lib.org/",
    },
    {
        "name": "styler",
        "language": ["R"],
        "purpose": ["Code Quality"],
        "description": """
        Formats R code to a consistent style; integrates with RStudio and other
        editors.
        """,
        "install": "install.packages('styler')",
        "link": "https://styler.r-lib.org/",
    },
    {
        "name": "poetry",
        "language": ["Python"],
        "purpose": ["Dependency Management"],
        "description": """
        A tool for dependency management and packaging in Python; simplifies
        the management of project dependencies and virtual environments.
        """,
        "install": "pip install poetry",
        "link": "https://python-poetry.org/",
    },
    {
        "name": "pip",
        "language": ["Python"],
        "purpose": ["Dependency Management"],
        "description": """
        Installs and manages Python packages from the Python Package index
        (PyPI); essential for adding libraries to a RAP.
        """,
        "install": "pip install <package_name>",
        "link": "https://pip.pypa.io/",
    },
]

df = pd.DataFrame(data)

st.title("RAP Resource Explorer")
st.write(
    "Filter and explore tools, templates, and packages for building "
    "Reproducible Analytical Pipelines (RAP)."
)

# Search box
search_query = st.text_input("Search by name or purpose:")

# Filters below the search bar (in main area)
col1, col2 = st.columns(2)
with col1:
    languages = st.multiselect(
        "Filter by Language:",
        sorted({lang for langs in df["language"] for lang in langs}),
    )
with col2:
    purposes = st.multiselect(
        "Filter by Purpose:",
        sorted({purpose for purposes in df["purpose"] for purpose in purposes}),  # noqa: E501
    )

filtered = df.copy()

# Apply search filter
if search_query:
    words = search_query.lower().split()

    def fuzzy_in_haystack(word, haystack_words, threshold=70):
        # Return True if any word in haystack_words is similar to the search
        # word
        return any(fuzz.ratio(word, hay) >= threshold for hay in haystack_words)  # noqa: E501

    def row_matches(row):
        haystack = (
            row["name"].lower()
            + " "
            + " ".join(row["language"]).lower()
            + " "
            + " ".join(row["purpose"]).lower()
            + " "
            + row["description"].lower()
        )
        haystack_words = haystack.split()
        # Match if all search words are similar to something in the haystack
        return all(fuzzy_in_haystack(word, haystack_words) for word in words)

    filtered = filtered[filtered.apply(row_matches, axis=1)]

# Apply filters
if languages:
    filtered = filtered[
        filtered["language"].apply(
            lambda x: any(language in x for language in languages)
        )  # noqa: E501
    ]
if purposes:
    filtered = filtered[
        filtered["purpose"].apply(lambda x: any(purpose in x for purpose in purposes))  # noqa: E501
    ]

# Display
for _, row in filtered.iterrows():
    st.markdown(f"### [{row['name']}]({row['link']})")
    st.write(f"**Languages:** {', '.join(row['language'])}")
    st.write(f"**Purpose:** {', '.join(row['purpose'])}")
    st.write(f"**Description:** {row['description']}")
    st.code(row["install"], language="bash")
    if row.get("documentation"):
        st.markdown(f"[Documentation]({row['documentation']})")
    st.markdown("---")
