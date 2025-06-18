# ITF Group Consumer Loan Risk Analysis

## Overview
This project is a Business Intelligence solution designed for ITF Group, a non-bank financial institution offering consumer loans. It provides an end-to-end pipeline for processing loan data, calculating risk scores, storing data in a MySQL data warehouse, and generating actionable insights through static and interactive dashboards. The solution demonstrates expertise in ETL processes, MySQL, statistical analysis, and data visualization, aligning with ITF Group's mission to be a modern and smart company.

**Note**: I utilized AI tools to optimize and accelerate the development process. All solutions were carefully reviewed, customized, and tested by me to ensure they meet ITF Group's requirements and maintain high quality standards.

## Features
- **ETL Pipeline**: Extracts loan data from CSV, transforms it (cleaning, risk scoring), and loads it into a MySQL data warehouse.
- **Risk Scoring Model**: Computes risk scores using a weighted statistical formula based on credit score, loan amount, income, and default history.
- **MySQL Data Warehouse**: Optimized schema with indexes and views for efficient querying and reporting.
- **Static Dashboard**: Visualizations (risk distribution, loan amount vs risk, credit score vs risk) generated with matplotlib.
- **Interactive Dashboard**: Web-based dashboard using Dash with Plotly for real-time data exploration and filtering.
- **Excel Compatibility**: Summary statistics exported to CSV for business users.
- **Automated Setup**: Universal setup scripts for Linux (Ubuntu, CentOS), macOS, and Windows, with unit tests for quality assurance.

## Requirements
- Operating System: Ubuntu/Debian, CentOS/RHEL, macOS, or Windows 10/11
- Python 3.8+
- MySQL 8.0+ (or MariaDB for CentOS)
- Input CSV file with columns: `loan_id`, `income`, `credit_score`, `loan_amount`, `default_status`

## Installation
1. Extract the project ZIP file:
   ```bash
   unzip itf-loan-risk-analysis.zip
   cd itf-loan-risk-analysis
   ```
2. Run the setup script:
   - **Linux/macOS**:
     ```bash
     chmod +x scripts/setup_and_test.sh
     ./scripts/setup_and_test.sh
     ```
   - **Windows**:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
     .\scripts\setup_and_test.ps1
     ```
   This will:
   - Install dependencies (Python, MySQL, libraries).
   - Configure MySQL with the provided schema.
   - Generate sample data if none exists.
   - Run ETL, dashboard, and unit tests.

## Usage
1. **Run ETL and Static Dashboard**:
   ```bash
   python src/loan_risk_analysis.py
   ```
   - Outputs: `outputs/loan_summary.csv` (Excel-compatible), `outputs/loan_dashboard.png` (visualizations).
   - Data is loaded into MySQL `loans` table.
2. **Run Interactive Dashboard**:
   ```bash
   python src/dashboard.py
   ```
   - Access the dashboard at `http://127.0.0.1:8050`.
3. **Run Tests**:
   ```bash
   pytest tests/test_loan_risk_analysis.py -v
   ```

## Project Structure
- `src/`:
  - `loan_risk_analysis.py`: ETL pipeline, risk scoring, and static dashboard.
  - `dashboard.py`: Interactive web dashboard using Dash.
- `tests/`:
  - `test_loan_risk_analysis.py`: Unit tests for ETL and dashboard.
- `sql/`:
  - `dwh_schema.sql`: MySQL schema and views for the data warehouse.
- `docs/`:
  - `README.md`: Project documentation.
  - `application_letter.tex`: LaTeX source for application letter.
  - `application_letter.pdf`: Compiled application letter.
- `data/`:
  - `loan_data.csv`: Sample input data.
- `outputs/`:
  - `loan_summary.csv`: Summary statistics.
  - `loan_dashboard.png`: Static visualizations.
- `scripts/`:
  - `setup_and_test.sh`: Setup script for Linux/macOS.
  - `setup_and_test.ps1`: Setup script for Windows.
- `requirements.txt`: Python dependencies.
- `.gitignore`: Git ignore file for temporary files.

## Future Enhancements
- **Machine Learning**: Implement logistic regression for predictive risk modeling using scikit-learn.
- **Partitioning**: Add table partitioning in MySQL for scalability.
- **CI/CD**: Integrate GitHub Actions for automated testing and deployment.
- **NoSQL**: Explore MongoDB for unstructured data storage.

## Notes
- The project includes a sample `loan_data.csv`. Replace it with actual data as needed.
- MySQL root access is required for initial setup. Update credentials in `scripts/setup_and_test.*` if necessary.
- The project is hosted on GitHub: [github.com/St11fler/ITF-Loan-Risk-Analysis](https://github.com/St11fler/ITF-Loan-Risk-Analysis).

## Contact
For questions or feedback, please contact STIVAN F. at brixeat@gmail.com.

---

*This project is a proof of concept for ITF Group's Business Intelligence Developer role, showcasing technical expertise, analytical thinking, and a commitment to quality.*
