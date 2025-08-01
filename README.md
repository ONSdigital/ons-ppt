# ONS PPT Code Snippets Repository

This repository contains example code snippets in **Python** and **R** to support learning materials and case studies for the Pandemic Preparedness Toolkit. The content is organized by **themes**, **modules** and **units** to align with the structure of the learning resources.

---

## 📁 Repository Structure

```
ons-ppt/
├── themes/
│   ├── module1/
│   │   ├── unit1/
│   │   │   ├── python/
│   │   │   │   └── example1.py
│   │   │   └── r/
│   │   │       └── example1.R
│   │   └── unit2/
│   │       ├── python/
│   │       └── r/
│   └── module2/
│       └── unit1/
│           ├── python/
│           └── r/
├── requirements.txt      # Python dependencies
├── renv.lock             # R dependencies (generated by renv)
├── .pre-commit-config.yaml
├── .gitignore
├── README.md
└── CHANGELOG
```

- **themes/**: Top-level folder containing all themes.
- **moduleX/unitY/python/**: Python code examples for a specific unit.
- **moduleX/unitY/r/**: R code examples for a specific unit.

---

## 🚀 Getting Started

### Python Setup

1. Ensure you have Python 3.12+ installed.
2. (Recommended) Create a virtual environment:
   ```sh
   python -m venv venv
   ```
3. Activate the virtual environment:
   - Windows:
     ```sh
     venv\Scripts\activate
     ```
   - macOS/Linux:
     ```sh
     source venv/bin/activate
     ```
4. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```

### R Setup

1. Ensure you have R installed.
2. Install the [`renv`](https://rstudio.github.io/renv/) package if not already:
   ```R
   install.packages("renv")
   ```
3. Restore the R environment:
   ```R
   renv::restore()
   ```

---

## 🧑‍💻 How to Use

- Navigate to the relevant unit and module.
- Choose the `python/` or `r/` folder depending on your language of interest.
- Run the code snippets as needed for your learning or case study.

---

## 🛡️ Contributing

1. Please do **not** push directly to the `main` branch.  
2. Submit changes via a pull request.
3. Ensure all pre-commit checks pass before submitting.
