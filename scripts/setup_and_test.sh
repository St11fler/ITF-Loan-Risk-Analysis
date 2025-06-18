#!/bin/bash

# Universal setup script for ITF Group Loan Risk Analysis project
# Supports Ubuntu/Debian, CentOS/RHEL, and macOS
# Installs dependencies, configures MySQL, and runs tests

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo "Ubuntu"
        elif [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
            echo "CentOS"
        else
            echo "Unsupported"
        fi
    else
        echo "Unsupported"
    fi
}

# Install system dependencies based on OS
install_system_deps() {
    local os=$1
    log "Installing system dependencies for $os..."

    case $os in
        Ubuntu)
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip mysql-server
            if ! command_exists virtualenv; then
                pip3 install virtualenv
            fi
            ;;
        CentOS)
            sudo dnf install -y epel-release || sudo yum install -y epel-release
            sudo dnf install -y python3 python3-pip mariadb-server mariadb || sudo yum install -y python3 python3-pip mariadb-server mariadb
            sudo systemctl start mariadb
            sudo systemctl enable mariadb
            if ! command_exists virtualenv; then
                pip3 install virtualenv
            fi
            ;;
        macOS)
            if ! command_exists brew; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install python3 mysql
            brew services start mysql
            if ! command_exists virtualenv; then
                pip3 install virtualenv
            fi
            ;;
        *)
            log "${RED}Unsupported OS${NC}"
            exit 1
            ;;
    esac
    log "${GREEN}System dependencies installed${NC}"
}

# Install Python dependencies
install_python_deps() {
    log "Installing Python dependencies..."
    pip install -r requirements.txt
    log "${GREEN}Python dependencies installed${NC}"
}

# Configure MySQL
configure_mysql() {
    log "Configuring MySQL database..."
    MYSQL_USER="itf_user"
    MYSQL_PASS="itf_password"
    MYSQL_DB="itf_dwh"

    # Create MySQL user and database
    mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';" || {
        log "${RED}Failed to create MySQL user. Ensure root access or update credentials.${NC}"
        exit 1
    }
    mysql -u root -e "GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';" || {
        log "${RED}Failed to grant MySQL privileges${NC}"
        exit 1
    }
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;" || {
        log "${RED}Failed to create MySQL database${NC}"
        exit 1
    }
    mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < sql/dwh_schema.sql || {
        log "${RED}Failed to run dwh_schema.sql${NC}"
        exit 1
    }
    log "${GREEN}MySQL configured successfully${NC}"

    # Update database credentials in scripts
    log "Updating database credentials in Python scripts..."
    sed -i.bak "s|mysql+mysqlconnector://username:password@localhost:3306/itf_dwh|mysql+mysqlconnector://$MYSQL_USER:$MYSQL_PASS@localhost:3306/$MYSQL_DB|g" src/loan_risk_analysis.py
    rm -f src/loan_risk_analysis.py.bak
}

# Create sample data
create_sample_data() {
    log "Checking for sample data..."
    if [ ! -f "data/loan_data.csv" ]; then
        log "Creating sample loan_data.csv..."
        mkdir -p data
        echo "loan_id,income,credit_score,loan_amount,default_status" > data/loan_data.csv
        echo "1,50000,700,10000,No" >> data/loan_data.csv
        echo "2,30000,600,15000,Yes" >> data/loan_data.csv
        echo "3,45000,650,12000,No" >> data/loan_data.csv
    fi
}

# Run ETL and dashboard
run_etl_and_dashboard() {
    log "Running ETL process..."
    python src/loan_risk_analysis.py || {
        log "${RED}ETL process failed${NC}"
        exit 1
    }
    log "${GREEN}ETL process completed${NC}"

    log "Starting Dash dashboard in background..."
    python src/dashboard.py > dashboard.log 2>&1 &
    DASH_PID=$!
    sleep 5  # Wait for server to start

    # Check if dashboard is running
    if curl -s http://127.0.0.1:8050 >/dev/null; then
        log "${GREEN}Dash dashboard is running${NC}"
    else
        log "${RED}Dash dashboard failed to start${NC}"
        kill $DASH_PID 2>/dev/null
        exit 1
    fi
    DASH_PID=$DASH_PID
}

# Run unit tests
run_tests() {
    log "Running unit tests..."
    pytest tests/test_loan_risk_analysis.py -v || {
        log "${RED}Unit tests failed${NC}"
        kill $DASH_PID 2>/dev/null
        exit 1
    }
    log "${GREEN}All unit tests passed${NC}"
}

# Main execution
OS=$(detect_os)
log "Detected operating system: $OS"

# Set up virtual environment
log "Setting up virtual environment..."
if [ ! -d "venv" ]; then
    virtualenv venv
fi
source venv/bin/activate

# Install dependencies
install_system_deps "$OS"
install_python_deps

# Configure MySQL and data
configure_mysql
create_sample_data

# Run ETL, dashboard, and tests
run_etl_and_dashboard
run_tests

# Cleanup
log "Cleaning up..."
kill $DASH_PID 2>/dev/null
log "${GREEN}Setup and testing completed successfully!${NC}"
log "To view the dashboard, run: python src/dashboard.py"
log "To view outputs, check: outputs/loan_summary.csv, outputs/loan_dashboard.png"

# Deactivate virtual environment
deactivate