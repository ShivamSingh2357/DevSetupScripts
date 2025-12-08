#!/bin/bash

################################################################################
# Party Service - Automated Setup Script (Mac/Linux)
# This script automates the complete setup process for new developers
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
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

################################################################################
# 0. INSTALL HOMEBREW (macOS) or APT PACKAGES (Linux)
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
# 1. CHECK AND INSTALL PREREQUISITES
################################################################################

check_and_install_prerequisites() {
    print_header "Checking and Installing Prerequisites"

    # Install Homebrew first (macOS)
    install_homebrew

    # Check and install Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -ge 17 ]; then
            print_success "Java $JAVA_VERSION already installed (skipping)"
        else
            print_warning "Java $JAVA_VERSION found, but Java 17+ is required"
            install_java
        fi
    else
        print_warning "Java is not installed"
        install_java
    fi

    # Check and install Maven
    if command -v mvn &> /dev/null; then
        MVN_VERSION=$(mvn -version | head -n 1 | awk '{print $3}')
        print_success "Maven $MVN_VERSION already installed (skipping)"
    else
        print_warning "Maven is not installed"
        install_maven
    fi

    # Check and install PostgreSQL
    if command -v psql &> /dev/null; then
        PSQL_VERSION=$(psql --version | awk '{print $3}')
        print_success "PostgreSQL $PSQL_VERSION already installed (skipping)"
    else
        print_warning "PostgreSQL is not installed"
        install_postgresql
    fi

    # Check and install Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git $GIT_VERSION already installed (skipping)"
    else
        print_warning "Git is not installed"
        install_git
    fi

    print_success "All prerequisites are met!"
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
    java -version
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
    mvn -version
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
    git --version
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
# 2. GITHUB AUTHENTICATION AND REPOSITORY CLONE
################################################################################

github_auth_and_clone() {
    print_header "GitHub Authentication and Repository Setup"

    REPO_URL="https://github.com/dfh-swt-banking/sales-and-onboarding.git"
    WORK_DIR="$HOME/workspace"
    PROJECT_PATH="$WORK_DIR/sales-and-onboarding/BackendServices/party-service"

    # First, check if repository already exists locally
    if [ -d "$PROJECT_PATH/.git" ]; then
        print_success "Repository already exists at: $PROJECT_PATH"
        cd "$PROJECT_PATH"

        # Ask if user wants to update
        read -p "Do you want to pull latest changes? (y/n): " update_repo
        if [[ $update_repo =~ ^[Yy]$ ]]; then
            print_info "Pulling latest changes..."
            if git pull origin main 2>/dev/null; then
                print_success "Repository updated successfully"
            else
                print_warning "Could not update repository (might be offline or no changes)"
            fi
        else
            print_info "Using existing repository"
        fi
        return 0
    fi

    # Repository doesn't exist - need to authenticate and clone
    print_warning "Repository not found locally. Authentication and cloning required."
    echo ""

    # Step 1: Install GitHub CLI if needed
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI (gh) is already installed"
    else
        print_warning "GitHub CLI (gh) is not installed"
        install_github_cli
    fi

    # Step 2: ALWAYS authenticate before cloning (even if previously authenticated)
    print_info "Authenticating with GitHub..."
    print_info "You will be prompted to login via browser or token"
    echo ""

    gh auth login

    # Verify authentication
    if gh auth status &> /dev/null; then
        print_success "GitHub authentication successful!"
    else
        print_error "GitHub authentication failed"
        print_error "Please run 'gh auth login' manually and try again"
        exit 1
    fi

    # Step 3: Ask for workspace directory
    read -p "Enter workspace directory (press Enter for default: $WORK_DIR): " custom_dir
    if [ ! -z "$custom_dir" ]; then
        WORK_DIR="$custom_dir"
        PROJECT_PATH="$WORK_DIR/sales-and-onboarding/BackendServices/party-service"
    fi

    # Step 4: Clone repository
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    print_info "Cloning repository from $REPO_URL"
    if git clone "$REPO_URL"; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        print_error "Please check your GitHub access and try again"
        exit 1
    fi

    # Verify project path
    if [ -d "$PROJECT_PATH" ]; then
        cd "$PROJECT_PATH"
        print_success "Repository ready at: $PROJECT_PATH"
    else
        print_error "Project path not found: $PROJECT_PATH"
        exit 1
    fi
}

################################################################################
# 4. DATABASE SETUP
################################################################################

setup_database() {
    print_header "Setting Up Local Database"

    print_info "Configuring local PostgreSQL database"

    DB_NAME="party_service_db"
    DB_USER="party_user"
    DB_PASSWORD="party_pass_2024"
    DB_HOST="localhost"
    DB_PORT="5432"

    read -p "Database name (press Enter for '$DB_NAME'): " input_db_name
    DB_NAME=${input_db_name:-$DB_NAME}

    read -p "Database user (press Enter for '$DB_USER'): " input_db_user
    DB_USER=${input_db_user:-$DB_USER}

    read -sp "Database password (press Enter for '$DB_PASSWORD'): " input_db_password
    echo
    DB_PASSWORD=${input_db_password:-$DB_PASSWORD}

    # Try to create database using psql
    if command -v psql &> /dev/null; then
        # Check if database already exists
        if PGPASSWORD=postgres psql -U postgres -h localhost -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw $DB_NAME; then
            print_success "Database '$DB_NAME' already exists (skipping creation)"
        else
            print_info "Creating database '$DB_NAME'..."
            PGPASSWORD=postgres psql -U postgres -h localhost -c "CREATE DATABASE $DB_NAME;" 2>/dev/null
            print_success "Database created"
        fi

        # Check if user already exists
        if PGPASSWORD=postgres psql -U postgres -h localhost -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" 2>/dev/null | grep -q 1; then
            print_success "User '$DB_USER' already exists (skipping creation)"
        else
            print_info "Creating user '$DB_USER'..."
            PGPASSWORD=postgres psql -U postgres -h localhost -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null
            print_success "User created"
        fi

        # Grant privileges (safe to run multiple times)
        print_info "Granting privileges..."
        PGPASSWORD=postgres psql -U postgres -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null
        PGPASSWORD=postgres psql -U postgres -h localhost -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;" 2>/dev/null

        print_success "Database setup completed"
    else
        print_warning "Please create the database manually:"
        echo "  Database: $DB_NAME"
        echo "  User: $DB_USER"
        echo "  Password: $DB_PASSWORD"
    fi

    DB_URL="jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
}

################################################################################
# 5. CONFIGURE APPLICATION
################################################################################

configure_application() {
    print_header "Configuring Application"

    APP_CONFIG="$PROJECT_PATH/src/main/resources/application.yml"

    if [ ! -f "$APP_CONFIG" ]; then
        print_error "application.yml not found!"
        exit 1
    fi

    # Backup original file if not already backed up
    if [ ! -f "$APP_CONFIG.backup" ]; then
        cp "$APP_CONFIG" "$APP_CONFIG.backup"
        print_info "Backup created: application.yml.backup"
    else
        print_success "Backup already exists (skipping)"
    fi

    # Update database configuration in YAML
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|url:.*|url: $DB_URL|g" "$APP_CONFIG"
        sed -i '' "s|username:.*|username: $DB_USER|g" "$APP_CONFIG"
        sed -i '' "s|password:.*|password: $DB_PASSWORD|g" "$APP_CONFIG"
    else
        sed -i "s|url:.*|url: $DB_URL|g" "$APP_CONFIG"
        sed -i "s|username:.*|username: $DB_USER|g" "$APP_CONFIG"
        sed -i "s|password:.*|password: $DB_PASSWORD|g" "$APP_CONFIG"
    fi

    # Ask for server port
    read -p "Server port (press Enter for default 8081): " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-8081}

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|port:.*|port: $SERVER_PORT|g" "$APP_CONFIG"
    else
        sed -i "s|port:.*|port: $SERVER_PORT|g" "$APP_CONFIG"
    fi

    print_success "Application configured successfully"
    print_info "Database URL: $DB_URL"
    print_info "Server will run on port: $SERVER_PORT"
}

################################################################################
# 6. BUILD PROJECT
################################################################################

build_project() {
    print_header "Building Project"

    cd "$PROJECT_PATH"

    # Check if project was already built
    if [ -f "target/party-service-0.0.1-SNAPSHOT.jar" ] || [ -f "target/*.jar" ]; then
        print_info "Previous build found. Rebuilding..."
    else
        print_info "Running first build (this may take 2-5 minutes)..."
    fi

    print_info "Running Maven clean install..."

    if mvn clean install -DskipTests; then
        print_success "Project built successfully!"
    else
        print_error "Build failed! Check the errors above."
        print_info "You can try running manually: cd $PROJECT_PATH && mvn clean install"
        exit 1
    fi
}

################################################################################
# 7. RUN APPLICATION
################################################################################

run_application() {
    print_header "Starting Application"

    read -p "Do you want to start the application now? (y/n): " start_app

    if [[ $start_app =~ ^[Yy]$ ]]; then
        print_info "Starting Party Service..."
        print_info "Application will be available at: http://localhost:$SERVER_PORT"
        print_info "Swagger UI: http://localhost:$SERVER_PORT/swagger-ui/index.html"
        print_info "Health Check: http://localhost:$SERVER_PORT/actuator/health"
        print_info ""
        print_warning "Press Ctrl+C to stop the application"
        echo ""

        mvn spring-boot:run
    else
        print_info "Skipping application startup"
        print_info ""
        print_info "To start the application later, run:"
        echo "  cd $PROJECT_PATH"
        echo "  mvn spring-boot:run"
    fi
}

################################################################################
# 8. PRINT SUMMARY
################################################################################

print_summary() {
    print_header "Setup Complete! 🎉"

    echo "Project Location: $PROJECT_PATH"
    echo "Database: $DB_URL"
    echo "Server Port: $SERVER_PORT"
    echo ""
    echo "Useful Commands:"
    echo "  Start application:  cd $PROJECT_PATH && mvn spring-boot:run"
    echo "  Build project:      mvn clean install"
    echo "  Run tests:          mvn test"
    echo ""
    echo "Useful URLs (when app is running):"
    echo "  Swagger UI:    http://localhost:$SERVER_PORT/swagger-ui/index.html"
    echo "  Health Check:  http://localhost:$SERVER_PORT/actuator/health"
    echo "  API Base:      http://localhost:$SERVER_PORT/v1/party"
    echo ""
    print_success "You're all set! Happy Coding! 🚀"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║     Party Service - Automated Setup Script            ║"
    echo "║     This will set up everything for you!              ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""

    check_and_install_prerequisites
    github_auth_and_clone
    setup_database
    configure_application
    build_project

    print_summary

    run_application
}

# Run main function
main