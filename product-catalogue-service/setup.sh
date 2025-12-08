#!/bin/bash

################################################################################
# Product Catalogue - Automated Setup Script
# This script automates the complete setup process for new developers
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/dfh-swt-banking/sales-and-onboarding.git"
PROJECT_DIR="sales-and-onboarding/BackendServices/product-catalogue-service"
DB_NAME="product_catalog"
DB_USER="product_catalogue"
DB_HOST="localhost"
DB_PORT="5432"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_warning "$1 is not installed"
        return 1
    fi
}

prompt_input() {
    local prompt_message="$1"
    local default_value="$2"
    local user_input
    
    if [ -n "$default_value" ]; then
        read -p "$(echo -e ${YELLOW}$prompt_message [${default_value}]: ${NC})" user_input
        echo "${user_input:-$default_value}"
    else
        read -p "$(echo -e ${YELLOW}$prompt_message: ${NC})" user_input
        echo "$user_input"
    fi
}

prompt_yes_no() {
    local prompt_message="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${YELLOW}$prompt_message [y/n]: ${NC})" response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

################################################################################
# Step 0: Install Homebrew and Package Managers
################################################################################

install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            print_success "Homebrew already installed"
        else
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == 'arm64' ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            print_success "Homebrew installed successfully"
        fi
    fi
}

################################################################################
# Step 1: Check and Install Prerequisites
################################################################################

check_prerequisites() {
    print_header "Step 1: Checking and Installing Prerequisites"
    
    # Install Homebrew first (macOS)
    install_homebrew
    
    # Check Java
    if command -v java &> /dev/null; then
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        print_success "Java $java_version already installed (skipping)"
    else
        install_java
    fi
    
    # Check Maven
    if command -v mvn &> /dev/null; then
        mvn_version=$(mvn -version | grep "Apache Maven" | awk '{print $3}')
        print_success "Maven $mvn_version already installed (skipping)"
    else
        install_maven
    fi
    
    # Check PostgreSQL
    if command -v psql &> /dev/null; then
        pg_version=$(psql --version | awk '{print $3}')
        print_success "PostgreSQL $pg_version already installed (skipping)"
    else
        install_postgresql
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        git_version=$(git --version | awk '{print $3}')
        print_success "Git $git_version already installed (skipping)"
    else
        install_git
    fi
    
    print_success "All prerequisites are installed!"
}

install_java() {
    print_info "Installing Java JDK 17..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        brew install openjdk@17
        
        # Link Java for macOS
        sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
        
        # Add to PATH
        echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux with apt
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk
        elif command -v yum &> /dev/null; then
            sudo yum install -y java-17-openjdk-devel
        fi
    fi
    
    print_success "Java installed successfully"
}

install_maven() {
    print_info "Installing Maven..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        brew install maven
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux with apt
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y maven
        elif command -v yum &> /dev/null; then
            sudo yum install -y maven
        fi
    fi
    
    print_success "Maven installed successfully"
}

install_postgresql() {
    print_info "Installing PostgreSQL..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        brew install postgresql@15
        
        # Start PostgreSQL service
        brew services start postgresql@15
        
        # Add to PATH
        echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
        export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux with apt
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        elif command -v yum &> /dev/null; then
            sudo yum install -y postgresql-server postgresql-contrib
            sudo postgresql-setup initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        fi
    fi
    
    print_success "PostgreSQL installed successfully"
    sleep 3  # Wait for PostgreSQL to start
}

install_git() {
    print_info "Installing Git..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        brew install git
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux with apt
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        fi
    fi
    
    print_success "Git installed successfully"
}

install_github_cli() {
    print_info "Installing GitHub CLI (gh)..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        brew install gh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux with apt
        if command -v apt-get &> /dev/null; then
            type -p curl >/dev/null || sudo apt-get install curl -y
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install gh -y
        elif command -v yum &> /dev/null; then
            sudo yum install -y gh
        fi
    fi
    
    print_success "GitHub CLI installed successfully"
    gh --version
}

################################################################################
# Step 2: GitHub Authentication
################################################################################

github_authentication() {
    print_header "Step 2: GitHub Authentication"
    
    # Check if gh is installed
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI (gh) already installed (skipping)"
    else
        print_warning "GitHub CLI (gh) is not installed"
        install_github_cli
    fi
    
    # Check if already authenticated
    if gh auth status &> /dev/null; then
        print_success "Already authenticated with GitHub (skipping)"
        gh auth status 2>&1 | head -3
    else
        print_info "Please authenticate with GitHub..."
        print_info "You will be prompted to login via browser or token"
        echo ""
        
        gh auth login
        
        if gh auth status &> /dev/null; then
            print_success "GitHub authentication successful!"
        else
            print_error "GitHub authentication failed"
            print_error "Please run 'gh auth login' manually and try again"
            exit 1
        fi
    fi
}

################################################################################
# Step 3: Clone Repository
################################################################################

clone_repository() {
    print_header "Step 3: Cloning Repository"
    
    if [ -d "sales-and-onboarding" ]; then
        print_success "Repository already exists (skipping clone)"
        if prompt_yes_no "Do you want to pull latest changes?"; then
            cd sales-and-onboarding
            print_info "Updating to latest version..."
            if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
                print_success "Repository updated successfully"
            else
                print_warning "Could not update repository (might be offline or no changes)"
            fi
            cd ..
        else
            print_info "Skipping repository update"
        fi
    else
        print_info "Cloning repository from $REPO_URL"
        if git clone $REPO_URL; then
            print_success "Repository cloned successfully"
        else
            print_error "Failed to clone repository"
            exit 1
        fi
    fi
}

################################################################################
# Step 4: Database Setup
################################################################################

setup_database() {
    print_header "Step 4: Setting Up Local Database"
    
    # Get database credentials for local setup
    print_info "Configuring local PostgreSQL database"
    DB_USER=$(prompt_input "PostgreSQL username" "$DB_USER")
    read -sp "$(echo -e ${YELLOW}PostgreSQL password [${DB_USER}]: ${NC})" DB_PASSWORD
    echo ""
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD="$DB_USER"
    fi
    DB_HOST="localhost"
    DB_PORT="5432"
    DB_NAME=$(prompt_input "Database name" "$DB_NAME")
    
    # Check if PostgreSQL is running
    print_info "Checking PostgreSQL connection..."
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; then
        print_success "PostgreSQL connection successful"
    else
        print_error "Cannot connect to PostgreSQL. Please check your credentials and ensure PostgreSQL is running"
        
        # Try to start PostgreSQL
        if prompt_yes_no "Would you like to try starting PostgreSQL?"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                if command -v brew &> /dev/null; then
                    brew services start postgresql@15 || brew services start postgresql
                    sleep 3
                fi
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                # Linux
                sudo systemctl start postgresql
                sleep 3
            fi
            
            if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; then
                print_success "PostgreSQL started successfully"
            else
                print_error "Still cannot connect to PostgreSQL. Please start it manually and run this script again"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    # Check if database exists
    print_info "Checking if database '$DB_NAME' exists..."
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_success "Database '$DB_NAME' already exists"
        if prompt_yes_no "Do you want to drop and recreate it? (ALL DATA WILL BE LOST)"; then
            print_info "Dropping database..."
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
            print_success "Database dropped"
            
            # Create database
            print_info "Creating database '$DB_NAME'..."
            if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"; then
                print_success "Database created successfully"
            else
                print_error "Failed to create database"
                exit 1
            fi
        else
            print_success "Using existing database (skipping creation)"
            # Skip table creation if database exists and user chose not to recreate
            return
        fi
    else
        # Create database
        print_info "Creating database '$DB_NAME'..."
        if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"; then
            print_success "Database created successfully"
        else
            print_error "Failed to create database"
            exit 1
        fi
    fi
    
    # Create tables
    print_info "Creating database tables..."
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
-- Create product table
CREATE TABLE IF NOT EXISTS product (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100),
    description TEXT,
    full_description TEXT,
    category VARCHAR(100),
    type VARCHAR(100),
    image_url VARCHAR(2048),
    info_url VARCHAR(2048),
    icon_class VARCHAR(255),
    sort_order INTEGER,
    popular BOOLEAN DEFAULT FALSE,
    disabled BOOLEAN DEFAULT FALSE,
    revolving BOOLEAN DEFAULT FALSE,
    secured BOOLEAN DEFAULT FALSE,
    internal BOOLEAN DEFAULT FALSE,
    external BOOLEAN DEFAULT FALSE,
    is_employee BOOLEAN DEFAULT FALSE,
    allow_joint_applicant BOOLEAN DEFAULT FALSE,
    allow_beneficiary BOOLEAN DEFAULT FALSE,
    enable_automatic_repayment BOOLEAN DEFAULT FALSE,
    enable_settlement_instruction BOOLEAN DEFAULT FALSE,
    is_cloning_supported BOOLEAN DEFAULT FALSE,
    is_ladder_supported BOOLEAN DEFAULT FALSE,
    is_interest_only_repayment_supported BOOLEAN DEFAULT FALSE,
    is_balloon_repayment_supported BOOLEAN DEFAULT FALSE,
    card_text_color_type VARCHAR(50),
    business_loan_processing_method VARCHAR(100),
    term_unit VARCHAR(50),
    maximum_quantity INTEGER,
    reference_id VARCHAR(255),
    external_id VARCHAR(255),
    start_date DATE,
    end_date DATE,
    created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create product_feature table
CREATE TABLE IF NOT EXISTS product_feature (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    name VARCHAR(255),
    description TEXT,
    code VARCHAR(100),
    value TEXT,
    value_name VARCHAR(1000),
    sort_order INTEGER,
    created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
);

-- Create product_term table
CREATE TABLE IF NOT EXISTS product_term (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    min_term INTEGER,
    sort_order INTEGER,
    created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
);
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Database tables created successfully"
    else
        print_error "Failed to create database tables"
        exit 1
    fi
    
    # Verify tables
    table_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")
    print_success "Created $table_count tables in database"
}

################################################################################
# Step 5: Configure Application
################################################################################

configure_application() {
    print_header "Step 5: Configuring Application"
    
    cd $PROJECT_DIR
    
    local config_file="src/main/resources/application.yml"
    
    if [ ! -f "$config_file" ]; then
        print_error "application.yml file not found"
        exit 1
    fi
    
    print_info "Updating database configuration..."
    
    # Backup original file if not already backed up
    if [ ! -f "${config_file}.backup" ]; then
        cp $config_file ${config_file}.backup
        print_info "Backup created: ${config_file}.backup"
    else
        print_success "Backup already exists (skipping)"
    fi
    
    # Update database configuration
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|url:.*|url: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}|g" $config_file
        sed -i '' "s|username:.*|username: ${DB_USER}|g" $config_file
        sed -i '' "s|password:.*|password: ${DB_PASSWORD}|g" $config_file
        sed -i '' "s|use-mock-data:.*|use-mock-data: false|g" $config_file
    else
        sed -i "s|url:.*|url: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}|g" $config_file
        sed -i "s|username:.*|username: ${DB_USER}|g" $config_file
        sed -i "s|password:.*|password: ${DB_PASSWORD}|g" $config_file
        sed -i "s|use-mock-data:.*|use-mock-data: false|g" $config_file
    fi
    
    print_success "Application configured successfully"
    
    print_info "Configuration:"
    echo "  Database URL: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
    echo "  Database User: ${DB_USER}"
    echo "  Mock Data: false"
}

################################################################################
# Step 6: Build Project
################################################################################

build_project() {
    print_header "Step 6: Building Project"
    
    # Check if project was already built
    if [ -f "target/product-catalogue-service-0.0.1-SNAPSHOT.jar" ] || [ -d "target" ]; then
        print_info "Previous build found. Rebuilding..."
    else
        print_info "Running first build (this may take a few minutes)..."
    fi
    
    print_info "Running Maven build..."
    
    if ./mvnw clean install -DskipTests; then
        print_success "Project built successfully"
    else
        print_error "Build failed"
        print_info "Trying to build without tests..."
        if ./mvnw clean package -DskipTests; then
            print_success "Project built successfully (without tests)"
        else
            print_error "Build failed. Please check the error messages above"
            print_info "You can try running manually: cd $PROJECT_DIR && ./mvnw clean install"
            exit 1
        fi
    fi
}

################################################################################
# Step 7: Load Sample Data (Optional)
################################################################################

load_sample_data() {
    print_header "Step 7: Load Sample Data (Optional)"
    
    if prompt_yes_no "Would you like to load sample product data?"; then
        print_info "Starting application temporarily to load data..."
        
        # Start application in background
        ./mvnw spring-boot:run > /tmp/product-catalogue.log 2>&1 &
        APP_PID=$!
        
        print_info "Waiting for application to start (30 seconds)..."
        sleep 30
        
        # Check if app is running
        if curl -s http://localhost:8082/actuator/health > /dev/null; then
            print_success "Application started"
            
            # Load data
            print_info "Loading sample data..."
            if curl -X POST http://localhost:8082/v1/data-loader/products -H "Content-Type: application/json"; then
                print_success "Sample data loaded successfully"
            else
                print_warning "Could not load sample data automatically"
                print_info "You can load it manually later using: curl -X POST http://localhost:8082/v1/data-loader/products"
            fi
            
            # Stop application
            print_info "Stopping temporary application..."
            kill $APP_PID 2>/dev/null || true
            sleep 3
        else
            print_warning "Application did not start in time"
            kill $APP_PID 2>/dev/null || true
        fi
    else
        print_info "Skipping sample data load"
        print_info "You can load sample data later by:"
        print_info "1. Start the application: ./mvnw spring-boot:run"
        print_info "2. Call the endpoint: curl -X POST http://localhost:8082/v1/data-loader/products"
    fi
}

################################################################################
# Step 8: Run Application
################################################################################

run_application() {
    print_header "Step 8: Run Application"
    
    if prompt_yes_no "Would you like to start the application now?"; then
        print_success "Starting Product Catalogue API..."
        echo ""
        print_info "Application will be available at:"
        print_info "  • API Base URL: http://localhost:8082"
        print_info "  • Swagger UI: http://localhost:8082/swagger-ui.html"
        print_info "  • Health Check: http://localhost:8082/actuator/health"
        print_info "  • API Endpoint: http://localhost:8082/v1/products"
        echo ""
        print_info "Press Ctrl+C to stop the application"
        echo ""
        sleep 3
        
        ./mvnw spring-boot:run
    else
        print_info "Setup complete! You can start the application later with:"
        print_info "  cd $PROJECT_DIR"
        print_info "  ./mvnw spring-boot:run"
    fi
}

################################################################################
# Print Summary
################################################################################

print_summary() {
    print_header "Setup Summary"
    
    cat << EOF
${GREEN}✓ Setup completed successfully!${NC}

${BLUE}Next Steps:${NC}

1. ${YELLOW}Start the Application:${NC}
   cd $PROJECT_DIR
   ./mvnw spring-boot:run

2. ${YELLOW}Access the Application:${NC}
   • Swagger UI: http://localhost:8082/swagger-ui.html
   • Health Check: http://localhost:8082/actuator/health
   • Get Products: http://localhost:8082/v1/products

3. ${YELLOW}Test the API:${NC}
   curl http://localhost:8082/v1/products

4. ${YELLOW}Load Sample Data (if not loaded):${NC}
   curl -X POST http://localhost:8082/v1/data-loader/products

${BLUE}Project Location:${NC}
   $(pwd)/$PROJECT_DIR

${BLUE}Database Details:${NC}
   • Host: $DB_HOST:$DB_PORT
   • Database: $DB_NAME
   • Username: $DB_USER

${BLUE}Configuration File:${NC}
   $PROJECT_DIR/src/main/resources/application.yml

${GREEN}Happy Coding! 🚀${NC}
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║       Product Catalogue API - Automated Setup Script         ║
║                                                               ║
║   This script will set up everything you need to run the     ║
║   Product Catalogue API on your local machine.               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    
    echo ""
    print_warning "This script will:"
    echo "  1. Check and install prerequisites (Java, Maven, PostgreSQL, Git, GitHub CLI)"
    echo "  2. Authenticate with GitHub"
    echo "  3. Clone the repository"
    echo "  4. Set up PostgreSQL database"
    echo "  5. Configure the application"
    echo "  6. Build the project"
    echo "  7. (Optional) Load sample data"
    echo "  8. (Optional) Run the application"
    echo ""
    
    if ! prompt_yes_no "Do you want to continue?"; then
        print_info "Setup cancelled"
        exit 0
    fi
    
    # Execute setup steps
    check_prerequisites
    github_authentication
    clone_repository
    setup_database
    configure_application
    build_project
    load_sample_data
    
    # Return to original directory
    cd - > /dev/null
    
    print_summary
    
    echo ""
    run_application
}

# Run main function
main
