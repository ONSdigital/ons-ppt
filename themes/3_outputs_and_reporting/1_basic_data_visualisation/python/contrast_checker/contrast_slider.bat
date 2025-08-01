@echo off
REM Activate the virtual environment in the repo root
call "%~dp0..\..\..\..\..\venv\Scripts\activate"

REM Get a free port and store it in a variable
for /f "delims=" %%p in ('python "%~dp0get_free_port.py"') do set PORT=%%p

echo Port found: %PORT%

REM Run Streamlit on that port, using the local contrast_checker.py
streamlit run "%~dp0contrast_checker.py" --server.port %PORT%
