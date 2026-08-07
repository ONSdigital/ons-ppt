# Analysis for Action code snippets repository

This repository contains tools and example code snippets in **Python** and **R** to support materials and case studies for the Analysis for Action platform. The content is organised by **themes**, **modules** and **units** to align with the structure of the website.

---

## Repository Structure

```
analysis-for-action/
├── learning_resources/             # Top-level folder containing all learning resource code examples.
│   ├── theme1/                     # A specific theme (e.g., data_analysis, outputs_and_reporting).
│   │   ├── data/                   # Example datasets used for learning resource examples.
│   │   ├── module1/                # A module within a theme (e.g., reproducible_analytical_pipelines, data_visualisation).
│   │   │   ├── unit1/              # A unit within a module (e.g., intro_to_rap, basic_data_visualisation).
│   │   │   │   ├── docs/           # Documentation for the specific unit code examples.
│   │   │   │   ├── python/         # Python code examples for the specific unit.
│   │   │   │   │   └── example1.py
│   │   │   │   └── r/              # R code examples for the specific unit.
│   │   │   │       └── example1.R
│   │   │   └── unit2/
│   │   │       ├── docs/
│   │   │       ├── python/
│   │   │       └── r/
│   │   └── module2/
│   │       └── unit1/
│   │           ├── docs/
│   │           ├── python/
│   │           └── r/
├── tools/                       # Top-level folder containing all tools.
│   ├── theme1/                  # A specific theme (e.g., data_analysis, outputs_and_reporting).
│   │   └── module1/             # A module within a theme (e.g., reproducible_analytical_pipelines, data_visualisation).
│   │       └── tool1/           # A specific tool (e.g. epidemic_curve_modelling_dashboard, digital_dashboards).
│   │           ├── docs/        # Documentation for the specific tool.
│   │           ├── python/      # Python code for the specific tool.
│   │           └── r/           # R code for the specific tool.
├── requirements.txt      # Python dependencies
├── setup.R               # R dependencies setup script
├── .pre-commit-config.yaml
├── .gitignore
├── README.md
└── CHANGELOG
```

---

## Getting Started

### Fork the repository
Forking means creating your own copy of this project on GitHub.
- Go to the [GitHub page](https://github.com/ONSdigital/python_rap_demo) for this repository (if you are not there already) and click the "Fork" button in the top right.
- After forking, go to your new repository (it will be at `https://github.com/<your-username>/analysis-for-action`).
- Click the green "Code" button and copy the URL shown under "Clone".
- Open a terminal (Command Prompt) and run:
   ```cmd
   git clone https://github.com/<your-username>/analysis-for-action.git
   cd analysis-for-action
   ```
- **Tip:** To check you are in the project root, run `dir` and make sure you see files like `README.md` and folders like `src` and `data`.

### Python Setup

1. Ensure you have Python 3.12+ installed
2. (Recommended) Create a virtual environment:
   ```sh
   python -m venv .venv
   ```
3. Activate the virtual environment:
   - Windows (cmd):
     ```sh
     .venv\Scripts\activate
     ```
   - macOS/Linux:
     ```sh
     source .venv/bin/activate
     ```
4. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```

### R Setup

1. Ensure you have R installed.
2. Run the provided `setup.R` script to install required packages:
   ```R
   source("setup.R")
   ```
   This will install all necessary R packages for the project.

---

## How to Use

Learning resources and tools are structured in the same way as the platform content.

`learning_resources/` contains code snippets and examples relating to written content.
`tools/` contains more comprehensive scripts and functions that can be used as standalone tools or adapted for different contexts and use cases.

> Note: Some tools on the platform are located in standalone repositories. Please refer to the platform for the full range of tools.

To use this repository:
- Navigate to the relevant learning resource code or tool of interest.
- Choose the `python/` or `r/` folder depending on your language of interest.
- Run the code snippets as needed for your learning or case study
or
- Use or adapt the tools provided in the `tools/` directory.
