@echo off
REM ################################################################################
REM Product Catalogue - Automated Setup Script (Windows)
REM This script automates the complete setup process for new developers
REM ################################################################################

setlocal EnableDelayedExpansion

REM Configuration
set REPO_URL=https://github.com/dfh-swt-banking/sales-and-onboarding.git
set PROJECT_DIR=sales-and-onboarding\BackendServices\product-catalogue-service
set DB_NAME=product_catalog
set DB_USER=product_catalogue
set DB_HOST=localhost
set DB_PORT=5432

echo.
echo ===============================================================
echo       Product Catalogue API - Automated Setup Script
echo ===============================================================
echo.
echo This script will set up everything you need to run the
echo Product Catalogue API on your local machine.
echo.
echo This script will:
echo   1. Check and install prerequisites (Java, Maven, PostgreSQL, Git, GitHub CLI)
echo   2. Authenticate with GitHub and clone repository
echo   3. Set up PostgreSQL database
echo   4. Configure the application
echo   5. Build the project
echo   6. (Optional) Load sample data
echo   7. (Optional) Run the application
echo.

set /p continue="Do you want to continue? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup cancelled.
    exit /b 0
)

REM ################################################################################
REM Step 0: Check and Install Chocolatey
REM ################################################################################

:CHECK_CHOCO
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo [93m[WARNING] Chocolatey package manager not found[0m
    echo.
    set /p "INSTALL_CHOCO=Do you want to install Chocolatey to auto-install missing dependencies? (y/n): "
    if /i "!INSTALL_CHOCO!"=="y" (
        echo [94m[INFO] Installing Chocolatey...[0m
        powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
        echo [92m[OK] Chocolatey installed. Please restart this script in a new command prompt.[0m
        pause
        exit /b 0
    ) else (
        echo [93m[WARNING] Without Chocolatey, you'll need to manually install missing dependencies[0m
    )
)

REM ################################################################################
REM Step 1: Check and Install Prerequisites
REM ################################################################################

echo.
echo ========================================
echo Step 1: Checking and Installing Prerequisites
echo ========================================
echo.

set ALL_INSTALLED=1

REM Check Java
where java >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Java is installed
    java -version 2>&1 | findstr "version"
) else (
    echo [WARNING] Java is not installed
    call :INSTALL_JAVA
)

REM Check Maven
where mvn >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Maven is installed
    mvn -version 2>&1 | findstr "Apache Maven"
) else (
    echo [WARNING] Maven is not installed
    call :INSTALL_MAVEN
)

REM Check PostgreSQL
where psql >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] PostgreSQL is installed
    psql --version
) else (
    echo [WARNING] PostgreSQL is not installed
    call :INSTALL_POSTGRESQL
)

REM Check Git
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git is installed
    git --version
) else (
    echo [WARNING] Git is not installed
    call :INSTALL_GIT
)

echo.
echo [OK] All prerequisites are installed!
goto :GITHUB_AUTH

REM ################################################################################
REM Installation Functions
REM ################################################################################

:INSTALL_JAVA
echo [94m[INFO] Installing Java JDK 17...[0m
where choco >nul 2>&1
if %errorlevel% equ 0 (
    choco install openjdk17 -y
    refreshenv
    echo [92m[OK] Java installed successfully[0m
) else (
    echo [91m[ERROR] Please install Java 17 manually from: https://adoptium.net/[0m
    echo After installation, restart this script.
    pause
    exit /b 1
)
goto :eof

:INSTALL_MAVEN
echo [94m[INFO] Installing Maven...[0m
where choco >nul 2>&1
if %errorlevel% equ 0 (
    choco install maven -y
    refreshenv
    echo [92m[OK] Maven installed successfully[0m
) else (
    echo [91m[ERROR] Please install Maven manually from: https://maven.apache.org/download.cgi[0m
    echo After installation, restart this script.
    pause
    exit /b 1
)
goto :eof

:INSTALL_GIT
echo [94m[INFO] Installing Git...[0m
where choco >nul 2>&1
if %errorlevel% equ 0 (
    choco install git -y
    refreshenv
    echo [92m[OK] Git installed successfully[0m
) else (
    echo [91m[ERROR] Please install Git manually from: https://git-scm.com/downloads[0m
    echo After installation, restart this script.
    pause
    exit /b 1
)
goto :eof

:INSTALL_GITHUB_CLI
echo [94m[INFO] Installing GitHub CLI (gh)...[0m
where choco >nul 2>&1
if %errorlevel% equ 0 (
    choco install gh -y
    refreshenv
    echo [92m[OK] GitHub CLI installed successfully[0m
) else (
    echo [91m[ERROR] Please install GitHub CLI manually from: https://cli.github.com/[0m
    echo After installation, restart this script.
    pause
    exit /b 1
)
goto :eof

:INSTALL_POSTGRESQL
echo [94m[INFO] Installing PostgreSQL...[0m
where choco >nul 2>&1
if %errorlevel% equ 0 (
    choco install postgresql15 -y --params '/Password:postgres'
    refreshenv
    echo [92m[OK] PostgreSQL installed successfully[0m
    echo [94m[INFO] Starting PostgreSQL service...[0m
    net start postgresql-x64-15
) else (
    echo [93m[WARNING] Please install PostgreSQL manually from: https://www.postgresql.org/download/[0m
    echo You can continue setup and use a remote database instead.
)
goto :eof

REM ################################################################################
REM Step 2: GitHub Authentication and Repository Clone
REM ################################################################################

:GITHUB_AUTH_AND_CLONE
echo.
echo ========================================
echo Step 2: GitHub Authentication and Repository Setup
echo ========================================
echo.

REM First, check if repository already exists locally
if exist "%PROJECT_DIR%\.git" (
    echo [92m[OK] Repository already exists at: %CD%\%PROJECT_DIR%[0m

    set /p "UPDATE_REPO=Do you want to pull latest changes? ^(y/n^): "
    if /i "!UPDATE_REPO!"=="y" (
        cd %PROJECT_DIR%
        echo [94m[INFO] Pulling latest changes...[0m
        git pull origin main 2>nul
        if %errorlevel% equ 0 (
            echo [92m[OK] Repository updated successfully[0m
        ) else (
            echo [93m[WARNING] Could not update repository ^(might be offline or no changes^)[0m
        )
        cd ..
    ) else (
        echo [94m[INFO] Using existing repository[0m
    )
    goto :DATABASE_SETUP
)

REM Repository doesn't exist - need to authenticate and clone
echo [93m[WARNING] Repository not found locally. Authentication and cloning required.[0m
echo.

REM Step 1: Install GitHub CLI if needed
where gh >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m[OK] GitHub CLI ^(gh^) is already installed[0m
) else (
    echo [93m[WARNING] GitHub CLI ^(gh^) is not installed[0m
    call :INSTALL_GITHUB_CLI
)

REM Step 2: ALWAYS authenticate before cloning
echo [94m[INFO] Authenticating with GitHub...[0m
echo [94m[INFO] You will be prompted to login via browser or token[0m
echo.

gh auth login

REM Verify authentication
gh auth status >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m[OK] GitHub authentication successful![0m
) else (
    echo [91m[ERROR] GitHub authentication failed[0m
    echo [91m[ERROR] Please run 'gh auth login' manually and try again[0m
    pause
    exit /b 1
)

REM Step 3: Clone repository
echo [94m[INFO] Cloning repository from %REPO_URL%[0m
git clone %REPO_URL%
if %errorlevel% equ 0 (
    echo [92m[OK] Repository cloned successfully[0m
) else (
    echo [91m[ERROR] Failed to clone repository[0m
    echo [91m[ERROR] Please check your GitHub access and try again[0m
    pause
    exit /b 1
)

:DATABASE_SETUP

REM ################################################################################
REM Step 3: Database Setup
REM ################################################################################

echo.
echo ========================================
echo Step 3: Setting Up Local Database
echo ========================================
echo.

echo [94m[INFO] Configuring local PostgreSQL database[0m
echo.

set DB_HOST=localhost
set DB_PORT=5432

set /p DB_USER="PostgreSQL username [%DB_USER%]: "
if "%DB_USER%"=="" set DB_USER=product_catalogue

set /p DB_PASSWORD="PostgreSQL password [%DB_USER%]: "
if "%DB_PASSWORD%"=="" set DB_PASSWORD=product_catalogue

set /p DB_NAME="Database name [%DB_NAME%]: "
if "%DB_NAME%"=="" set DB_NAME=product_catalog

REM Check if PostgreSQL is running
echo [INFO] Checking PostgreSQL connection...
set PGPASSWORD=%DB_PASSWORD%
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "\q" >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] PostgreSQL connection successful
) else (
    echo [ERROR] Cannot connect to PostgreSQL
    echo Please check your credentials and ensure PostgreSQL is running
    echo You can start PostgreSQL from Windows Services
    pause
    exit /b 1
)

REM Check if database exists
echo [INFO] Checking if database '%DB_NAME%' exists...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -lqt | findstr /C:"%DB_NAME%" >nul 2>nul
if %errorlevel% equ 0 (
    echo [WARNING] Database '%DB_NAME%' already exists
    set /p drop="Do you want to drop and recreate it? ALL DATA WILL BE LOST (Y/N): "
    if /i "!drop!"=="Y" (
        echo [INFO] Dropping database...
        psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "DROP DATABASE IF EXISTS %DB_NAME%;"
        echo [OK] Database dropped
    ) else (
        echo [INFO] Using existing database
        goto :configure
    )
)

REM Create database
echo [INFO] Creating database '%DB_NAME%'...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "CREATE DATABASE %DB_NAME%;"
if %errorlevel% equ 0 (
    echo [OK] Database created successfully
) else (
    echo [ERROR] Failed to create database
    pause
    exit /b 1
)

REM Create tables
echo [INFO] Creating database tables...

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "CREATE TABLE IF NOT EXISTS product (id BIGSERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL, code VARCHAR(100), description TEXT, full_description TEXT, category VARCHAR(100), type VARCHAR(100), image_url VARCHAR(2048), info_url VARCHAR(2048), icon_class VARCHAR(255), sort_order INTEGER, popular BOOLEAN DEFAULT FALSE, disabled BOOLEAN DEFAULT FALSE, revolving BOOLEAN DEFAULT FALSE, secured BOOLEAN DEFAULT FALSE, internal BOOLEAN DEFAULT FALSE, external BOOLEAN DEFAULT FALSE, is_employee BOOLEAN DEFAULT FALSE, allow_joint_applicant BOOLEAN DEFAULT FALSE, allow_beneficiary BOOLEAN DEFAULT FALSE, enable_automatic_repayment BOOLEAN DEFAULT FALSE, enable_settlement_instruction BOOLEAN DEFAULT FALSE, is_cloning_supported BOOLEAN DEFAULT FALSE, is_ladder_supported BOOLEAN DEFAULT FALSE, is_interest_only_repayment_supported BOOLEAN DEFAULT FALSE, is_balloon_repayment_supported BOOLEAN DEFAULT FALSE, card_text_color_type VARCHAR(50), business_loan_processing_method VARCHAR(100), term_unit VARCHAR(50), maximum_quantity INTEGER, reference_id VARCHAR(255), external_id VARCHAR(255), start_date DATE, end_date DATE, created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "CREATE TABLE IF NOT EXISTS product_feature (id BIGSERIAL PRIMARY KEY, product_id BIGINT NOT NULL, name VARCHAR(255), description TEXT, code VARCHAR(100), value TEXT, value_name VARCHAR(1000), sort_order INTEGER, created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE);"

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "CREATE TABLE IF NOT EXISTS product_term (id BIGSERIAL PRIMARY KEY, product_id BIGINT NOT NULL, min_term INTEGER, sort_order INTEGER, created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE);"

if %errorlevel% equ 0 (
    echo [OK] Database tables created successfully
) else (
    echo [ERROR] Failed to create database tables
    pause
    exit /b 1
)

:configure

REM ################################################################################
REM Step 4: Configure Application
REM ################################################################################

echo.
echo ========================================
echo Step 4: Configuring Application
echo ========================================
echo.

cd %PROJECT_DIR%

set CONFIG_FILE=src\main\resources\application.yml

if not exist "%CONFIG_FILE%" (
    echo [ERROR] application.yml file not found
    pause
    exit /b 1
)

echo [INFO] Updating database configuration...

REM Backup original file
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul
echo [INFO] Backup created: %CONFIG_FILE%.backup

REM Update database configuration using PowerShell
powershell -Command "(gc '%CONFIG_FILE%') -replace 'url:.*', 'url: jdbc:postgresql://%DB_HOST%:%DB_PORT%/%DB_NAME%' | Out-File -encoding ASCII '%CONFIG_FILE%'"
powershell -Command "(gc '%CONFIG_FILE%') -replace 'username:.*', 'username: %DB_USER%' | Out-File -encoding ASCII '%CONFIG_FILE%'"
powershell -Command "(gc '%CONFIG_FILE%') -replace 'password:.*', 'password: %DB_PASSWORD%' | Out-File -encoding ASCII '%CONFIG_FILE%'"
powershell -Command "(gc '%CONFIG_FILE%') -replace 'use-mock-data:.*', 'use-mock-data: false' | Out-File -encoding ASCII '%CONFIG_FILE%'"

echo [OK] Application configured successfully
echo.
echo Configuration:
echo   Database URL: jdbc:postgresql://%DB_HOST%:%DB_PORT%/%DB_NAME%
echo   Database User: %DB_USER%
echo   Mock Data: false

REM ################################################################################
REM Step 5: Build Project
REM ################################################################################

echo.
echo ========================================
echo Step 5: Building Project
echo ========================================
echo.

echo [INFO] Running Maven build (this may take a few minutes)...

call mvnw.cmd clean install -DskipTests
if %errorlevel% equ 0 (
    echo [OK] Project built successfully
) else (
    echo [ERROR] Build failed. Trying without tests...
    call mvnw.cmd clean package -DskipTests
    if %errorlevel% equ 0 (
        echo [OK] Project built successfully (without tests)
    ) else (
        echo [ERROR] Build failed. Please check the error messages above
        pause
        exit /b 1
    )
)

REM ################################################################################
REM Step 6: Summary
REM ################################################################################

echo.
echo ========================================
echo Setup Summary
echo ========================================
echo.
echo [OK] Setup completed successfully!
echo.
echo Next Steps:
echo.
echo 1. Start the Application:
echo    cd %PROJECT_DIR%
echo    mvnw.cmd spring-boot:run
echo.
echo 2. Access the Application:
echo    - Swagger UI: http://localhost:8082/swagger-ui.html
echo    - Health Check: http://localhost:8082/actuator/health
echo    - Get Products: http://localhost:8082/v1/products
echo.
echo 3. Test the API:
echo    curl http://localhost:8082/v1/products
echo.
echo Database Details:
echo    - Host: %DB_HOST%:%DB_PORT%
echo    - Database: %DB_NAME%
echo    - Username: %DB_USER%
echo.
echo Happy Coding!
echo.

set /p run="Would you like to start the application now? (Y/N): "
if /i "%run%"=="Y" (
    echo.
    echo Starting Product Catalogue API...
    echo.
    echo Application will be available at:
    echo   - API Base URL: http://localhost:8082
    echo   - Swagger UI: http://localhost:8082/swagger-ui.html
    echo   - Health Check: http://localhost:8082/actuator/health
    echo.
    echo Press Ctrl+C to stop the application
    echo.
    call mvnw.cmd spring-boot:run
) else (
    echo Setup complete! You can start the application later with:
    echo   cd %PROJECT_DIR%
    echo   mvnw.cmd spring-boot:run
)

pause