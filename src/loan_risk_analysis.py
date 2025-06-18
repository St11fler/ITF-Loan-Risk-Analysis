# Import required libraries for ETL, analysis, and visualization
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
import warnings
warnings.filterwarnings('ignore')

# --- ETL Process ---

# Extract: Load loan data from CSV
def extract_data(file_path):
    # Expected CSV columns: loan_id, income, credit_score, loan_amount, default_status
    try:
        df = pd.read_csv(file_path)
        if not all(col in df.columns for col in ['loan_id', 'income', 'credit_score', 'loan_amount', 'default_status']):
            raise ValueError("Missing required columns in CSV")
        print("Data extracted successfully from CSV")
        return df
    except Exception as e:
        print(f"Error during extraction: {e}")
        return None

# Transform: Clean data and compute risk score
def transform_data(df):
    if df is None:
        return None
    try:
        # Handle missing values
        df['income'] = df['income'].fillna(df['income'].median())
        df['credit_score'] = df['credit_score'].fillna(df['credit_score'].mean())
        df['loan_amount'] = df['loan_amount'].fillna(df['loan_amount'].median())
        df['default_status'] = df['default_status'].fillna('No')
        
        # Calculate risk score using weighted statistical model
        # Formula: Risk = 0.4*(1 - credit_score/850) + 0.3*(loan_amount/income) + 0.3*default_history
        df['default_history'] = df['default_status'].apply(lambda x: 1 if x == 'Yes' else 0)
        df['risk_score'] = (
            0.4 * (1 - df['credit_score'] / 850) +
            0.3 * (df['loan_amount'] / (df['income'] + 1e-6)) +  # Avoid division by zero
            0.3 * df['default_history']
        )
        
        # Normalize risk score to 0-100
        df['risk_score'] = 100 * (df['risk_score'] - df['risk_score'].min()) / (df['risk_score'].max() - df['risk_score'].min() + 1e-6)
        
        print("Data transformed successfully")
        return df
    except Exception as e:
        print(f"Error during transformation: {e}")
        return None

# Load: Store data in MySQL data warehouse
def load_data(df, db_connection_string):
    if df is None:
        return
    try:
        engine = create_engine(db_connection_string)
        df.to_sql('loans', con=engine, if_exists='replace', index=False)
        print("Data loaded successfully to MySQL")
    except Exception as e:
        print(f"Error during loading: {e}")

# --- Reporting and Visualization ---

# Generate summary statistics and dashboard visualizations
def generate_dashboard(df):
    if df is None:
        return
    try:
        # Summary statistics for Excel
        summary = df[['risk_score', 'loan_amount', 'credit_score', 'income']].describe()
        summary.to_csv('outputs/loan_summary.csv')
        print("Summary statistics saved to outputs/loan_summary.csv for Excel")

        # Dashboard: Create three visualizations
        plt.figure(figsize=(15, 5))

        # 1. Risk Score Distribution
        plt.subplot(1, 3, 1)
        plt.hist(df['risk_score'], bins=20, color='skyblue', edgecolor='black')
        plt.title('Risk Score Distribution')
        plt.xlabel('Risk Score')
        plt.ylabel('Frequency')

        # 2. Loan Amount vs Risk Score
        plt.subplot(1, 3, 2)
        plt.scatter(df['loan_amount'], df['risk_score'], alpha=0.5, color='coral')
        plt.title('Loan Amount vs Risk Score')
        plt.xlabel('Loan Amount')
        plt.ylabel('Risk Score')

        # 3. Credit Score vs Risk Score
        plt.subplot(1, 3, 3)
        plt.scatter(df['credit_score'], df['risk_score'], alpha=0.5, color='green')
        plt.title('Credit Score vs Risk Score')
        plt.xlabel('Credit Score')
        plt.ylabel('Risk Score')

        plt.tight_layout()
        plt.savefig('outputs/loan_dashboard.png')
        plt.close()
        print("Dashboard visualizations saved to outputs/loan_dashboard.png")
    except Exception as e:
        print(f"Error during dashboard generation: {e}")

# --- Main Execution ---

if __name__ == "__main__":
    # File path for loan data
    file_path = 'data/loan_data.csv'
    
    # MySQL connection
    db_connection = 'mysql+mysqlconnector://username:password@localhost:3306/itf_dwh'
    
    # Execute ETL pipeline
    raw_data = extract_data(file_path)
    transformed_data = transform_data(raw_data)
    load_data(transformed_data, db_connection)
    
    # Generate dashboard
    generate_dashboard(transformed_data)