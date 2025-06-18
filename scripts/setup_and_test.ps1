# PowerShell script for setting up and testing the ITF Group Loan Risk Analysis project on Windows
# Installs dependencies, configures MySQL, and runs tests

# Stop on any error
$ErrorActionPreference = "Stop"

# Log function
function Log-Message {
    param ($Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# Check if command exists
function Test-CommandExists {
    param ($Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

# Install system dependencies
function Install-SystemDeps {
    Log-Message "Installing system dependencies for Windows..."

    # Check and install Python
    if (-not (Test-CommandExists python)) {
        Log-Message "Installing Python..."
        winget install --id Python.Python.3.11 --source winget
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    } else {
        Log-Message "Python already installed"
    }

    # Check and install MySQL
    if (-not (Test-CommandExists mysql)) {
        Log-Message "Installing MySQL..."
        winget install --id Oracle.MySQL --source winget
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    } else {
        Log-Message "MySQL already installed"
    }

    # Check and install virtualenv
    if (-not (Test-CommandExists virtualenv)) {
        Log-Message "Installing virtualenv..."
        pip install virtualenv
    } else {
        Log-Message "virtualenv already installed"
    }

    Log-Message "System dependencies installed"
}

# Install Python dependencies
function Install-PythonDeps {
    Log-Message "Installing Python dependencies..."
    pip install -r requirements.txt
    Log-Message "Python dependencies installed"
}

# Configure MySQL
function Configure-MySQL {
    Log-Message "Configuring MySQL database..."
    $MYSQL_USER = "itf_user"
    $MYSQL_PASS = "itf_password"
    $MYSQL_DB = "itf_dwh"

    # Create MySQL user and database
    try {
        mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';"
        mysql -u root -e "GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';"
        mysql -u root -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
        mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < sql/dwh_schema.sql
        Log-Message "MySQL configured successfully"
    } catch {
        Log-Message "Failed to configure MySQL. Ensure root access or update credentials."
        exit 1
    }

    # Update database credentials in scripts
    Log-Message "Updating database credentials in Python scripts..."
    $scriptContent = Get-Content src/loan_risk_analysis.py -Raw
    $newContent = $scriptContent -replace "mysql\+mysqlconnector://username:password@localhost:3306/itf_dwh", "mysql+mysqlconnector://$MYSQL_USER:$MYSQL_PASS@localhost:3306/$MYSQL_DB"
    Set-Content -Path src/loan_risk_analysis.py -Value $newContent
}

# Create sample data
function Create-SampleData {
    Log-Message "Checking for sample data..."
    if (-not (Test-Path "data/loan_data.csv")) {
        Log-Message "Creating sample loan_data.csv..."
        New-Item -ItemType Directory -Path data -Force | Out-Null
        @"
loan_id,income,credit_score,loan_amount,default_status
1,50000,700,10000,No
2,30000,600,15000,Yes
3,45000,650,12000,No
"@ | Set-Content -Path data/loan_data.csv
    }
}

# Run ETL and dashboard
function Run-ETLAndDashboard {
    Log-Message "Running ETL process..."
    try {
        python src/loan_risk_analysis.py
        Log-Message "ETL process completed"
    } catch {
        Log-Message "ETL process failed"
        exit 1
    }

    Log-Message "Starting Dash dashboard in background..."
    $process = Start-Process python -ArgumentList "src/dashboard.py" -RedirectStandardOutput dashboard.log -RedirectStandardError dashboard_err.log -PassThru -NoNewWindow
    Start-Sleep -Seconds 5

    # Check if dashboard is running
    try {
        $response = Invoke-WebRequest -Uri http://127.0.0.1:8050 -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Log-Message "Dash dashboard is running"
        } else {
            Log-Message "Dash dashboard failed to start"
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            exit 1
        }
    } catch {
        Log-Message "Dash dashboard failed to start"
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        exit 1
    }
    $script:DASH_PID = $process.Id
}

# Run unit tests
function Run-Tests {
    Log-Message "Running unit tests..."
    try {
        pytest tests/test_loan_risk_analysis.py -v
        Log-Message "All unit tests passed"
    } catch {
        Log-Message "Unit tests failed"
        Stop-Process -Id $script:DASH_PID -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# Main execution
Log-Message "Starting setup and test process for Windows"

# Set up virtual environment
Log-Message "Setting up virtual environment..."
if (-not (Test-Path venv)) {
    virtualenv venv
}
. .\venv\Scripts\Activate.ps1

# Install dependencies
Install-SystemDeps
Install-PythonDeps

# Configure MySQL and data
Configure-MySQL
Create-SampleData

# Run ETL, dashboard, and tests
Run-ETLAndDashboard
Run-Tests

# Cleanup
Log-Message "Cleaning up..."
Stop-Process -Id $script:DASH_PID -Force -ErrorAction SilentlyContinue
Log-Message "Setup and testing completed successfully!"
Log-Message "To view the dashboard, run: python src/dashboard.py"
Log-Message "To view outputs, check: outputs/loan_summary.csv, outputs/loan_dashboard.png"

# Deactivate virtual environment
deactivate