# How to Clone and Use the RAP Resource Explorer

The RAP Resource Explorer is a Streamlit application that allows you to explore
RAP resources.

It is currently in early stages of development, so feedback is welcome, but please limit any feedback to the resource content and navigation of the tool rather than its look or code.

Follow these steps to clone the repository and run the application.

## 1. Clone the Repository

Open a terminal or command prompt and run:

```sh
git clone https://github.com/ONSdigital/ons-ppt.git
```

Checkout the create_rap_resources_search branch:

```sh
cd ons-ppt
git checkout create_rap_resources_search
```

## 2. Set up a python virtual environment (optional but recommended)

On windows:

```sh
python -m venv .venv
.venv\Scripts\activate
```

On macOS/Linux:

```sh
python -m venv .venv
source .venv/bin/activate
```

## 3. Install Python Dependencies

```sh
pip install -r requirements.txt
```

## 4. Run the RAP Resource Explorer
Navigate to the RAP resources directory:

```sh
cd themes/2_data_analysis/2_rap/python/rap_resources
```

Using the bat file:
```sh
RAP_Resource_Explorer.bat
```

Or open the directory in your file explorer and double-click the `RAP_Resource_Explorer.bat` file.

From the terminal:
```sh
streamlit run RAP_Resource_Explorer.py
```

Streamlit uses port 8501 by default. If that port is in use you can find a free port using
```sh
python get_free_port.py
```

Then run streamlit on a specific port (optional):
```sh
streamlit run RAP_Resource_Explorer.py --server.port 8502  # replace 8502 with your free port
```

## 5. Open in your browser
After running the above command, Streamlit will display a local URL (usually http://localhost:8501).
Open this link in your web browser to use the app.

## Troubleshooting
* Make sure you have Python 3.12 or higher installed.
* If you add or update dependencies, re-run pip install -r requirements.txt.
* If you have issues, try updating Streamlit:
pip install --upgrade streamlit
