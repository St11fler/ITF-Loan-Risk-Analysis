# Unit tests for loan_risk_analysis.py using pytest
import pytest
import pandas as pd
import os
from src.loan_risk_analysis import extract_data, transform_data, generate_dashboard

# Sample test data
SAMPLE_CSV = "data/test_loan_data.csv"
SAMPLE_DATA = {
    "loan_id": [1, 2, 3],
    "income": [50000, 30000, 45000],
    "credit_score": [700, 600, 650],
    "loan_amount": [10000, 15000, 12000],
    "default_status": ["No", "Yes", "No"]
}

# Setup fixture for test data
@pytest.fixture(scope="module")
def setup_test_data():
    os.makedirs("data", exist_ok=True)
    df = pd.DataFrame(SAMPLE_DATA)
    df.to_csv(SAMPLE_CSV, index=False)
    yield
    if os.path.exists(SAMPLE_CSV):
        os.remove(SAMPLE_CSV)

# Test extract_data function
def test_extract_data(setup_test_data):
    df = extract_data(SAMPLE_CSV)
    assert df is not None, "Failed to extract data"
    assert len(df) == 3, "Incorrect number of rows"
    assert set(df.columns) == set(SAMPLE_DATA.keys()), "Incorrect columns"

# Test transform_data function
def test_transform_data(setup_test_data):
    df = extract_data(SAMPLE_CSV)
    transformed_df = transform_data(df)
    assert transformed_df is not None, "Failed to transform data"
    assert "risk_score" in transformed_df.columns, "Risk score column missing"
    assert all(transformed_df["risk_score"].between(0, 100)), "Risk scores out of range"
    assert transformed_df["default_history"].sum() == 1, "Incorrect default history"

# Test generate_dashboard function
def test_generate_dashboard(setup_test_data):
    df = extract_data(SAMPLE_CSV)
    transformed_df = transform_data(df)
    generate_dashboard(transformed_df)
    assert os.path.exists("outputs/loan_summary.csv"), "Summary CSV not created"
    assert os.path.exists("outputs/loan_dashboard.png"), "Dashboard image not created"

# Test invalid CSV
def test_extract_invalid_csv():
    df = extract_data("non_existent.csv")
    assert df is None, "Should return None for invalid CSV"