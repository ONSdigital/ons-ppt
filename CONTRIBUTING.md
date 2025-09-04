# Contributing
Thank you for your interest in contributing to this project.

**Please note:** We are not accepting public contributions at this stage. This guidance is intended only for delivery partners and approved collaborators.

## Contribution Process

### 1. **Forking and Cloning the Repository**
   To begin contributing, you need your own copy of the repository:

   - **Fork the Repository:**
     1. Go to the GitHub page of this repository.
     2. Click the **Fork** button at the top right. This creates a copy under your GitHub account.
   - **Clone Your Fork Locally:**
     1. On your forked repository page, click the **Code** button and copy the URL.
     2. Open your terminal and run:
        ```cmd
        git clone <your-fork-url>
        cd <repo-folder>
        ```
   - **Set Upstream Remote (optional, for syncing with original repo):**
     ```cmd
     git remote add upstream https://github.com/ONSdigital/ons-ppt.git
     ```

### 2. **Making Changes**

- Create a new branch for your changes:
    ```cmd
    git checkout -b feature/your-branch-name
    ```
- Open the project.
- Edit files, add features, or fix bugs as needed.
- Stage and commit your changes:
    ```cmd
    git add .
    git commit -m "Describe your changes"
    ```
- Push your branch to your forked repository:
    ```cmd
    git push origin feature/your-branch-name
    ```

### 3. **Pull Requests**
- Go to your fork on GitHub.
- Click **Compare & pull request**.
- Fill in details and submit the pull request to the original repository.
- Clearly describe your changes and reference any relevant issues.

## **Branch Naming Convention**
   Use clear, consistent branch names to make collaboration easier. Follow this format:

   ```
   <type>/<theme>.<module>.<unit>.<unit_name>_<short_description_or_product_name>
   ```

   **Examples:**
   - `feat/2.2.1.intro_to_rap_code_snippets` (new feature)
   - `bug/1.1.1.households_fix_nulls` (bug fix)
   - `chore/3.1.1.data_vis_update_docs` (documentation or maintenance)

   **Branch type prefixes:**
   - `feat` or `feature`: new user-facing feature
   - `bug` or `bugfix`: fix for a user-facing bug
   - `refactor`: code improvements (e.g. renaming, restructuring)
   - `test`: adding or improving tests
   - `chore`: maintenance tasks (e.g. updating docs, configs)

   **Tips:**
   - Use short, descriptive names after the prefix and numbers.
   - Separate words with underscores for readability.
   - Match the theme/module/unit numbers to the folder structure if possible.

## Questions
If you have questions, please contact the project maintainers directly at [PPT@ons.gov.uk](PPT@ons.gov.uk).
