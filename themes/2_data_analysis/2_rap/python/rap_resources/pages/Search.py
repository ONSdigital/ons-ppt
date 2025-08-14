import pandas as pd
import streamlit as st
import yaml
from rapidfuzz import fuzz

with open("data/rap_resources.yaml", "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

df = pd.DataFrame(data)

st.title("RAP Resource Explorer")
st.write(
    "Filter and explore tools, templates, and packages for building "
    "Reproducible Analytical Pipelines (RAP)."
)

# Search box and filters in main area
search_query = st.text_input("Search by name or purpose:")

col1, col2 = st.columns(2)
with col1:
    languages = st.multiselect(
        "Filter by Language:",
        sorted({lang for langs in df["language"] for lang in langs}),
    )
with col2:
    purposes = st.multiselect(
        "Filter by Purpose:",
        sorted({purpose for purposes in df["purpose"] for purpose in purposes}),  # noqa
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
