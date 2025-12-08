@echo off
REM ############################################################################
REM Party Service - Automated Setup Script (Windows)
REM This script automates the complete setup process for new developers
REM ############################################################################

setlocal enabledelayedexpansion

REM Set colors (requires Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo.
echo ========================================================
echo      Party Service - Automated Setup Script
echo      This will set up everything for you!
echo ========================================================
echo.

REM ############################################################################
REM 0. CHECK AND INSTALL CHOCOLATEY
REM ############################################################################

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

REM ############################################################################
REM 1. CHECK AND INSTALL PREREQUISITES
REM ############################################################################

echo.
echo ================================
echo Checking and Installing Prerequisites
echo ================================
echo.

REM Check Java
where java >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set JAVA_VERSION=%%g
        set JAVA_VERSION=!JAVA_VERSION:"=!
        echo [92m[OK] Java found: !JAVA_VERSION![0m
    )
) else (
    echo [93m[WARNING] Java is not installed[0m
    call :INSTALL_JAVA
)

REM Check Maven
where mvn >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%g in ('mvn -version ^| findstr /i "Apache Maven"') do (
        echo [92m[OK] Maven found: %%g[0m
    )
) else (
    echo [93m[WARNING] Maven is not installed[0m
    call :INSTALL_MAVEN
)

REM Check Git
where git >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%g in ('git --version') do (
        echo [92m[OK] Git found: %%g[0m
    )
) else (
    echo [93m[WARNING] Git is not installed[0m
    call :INSTALL_GIT
)

REM Check PostgreSQL
where psql >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m[OK] PostgreSQL client found[0m
) else (
    echo [93m[WARNING] PostgreSQL client not found in PATH[0m
    call :INSTALL_POSTGRESQL
)

echo.
echo [92mAll prerequisites are installed or will be installed![0m
goto GITHUB_AUTH

REM ############################################################################
REM INSTALLATION FUNCTIONS
REM ############################################################################

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

REM ############################################################################
REM 2. GITHUB AUTHENTICATION
REM ############################################################################

:GITHUB_AUTH
echo.
echo ================================
echo GitHub Authentication
echo ================================
echo.

REM Check if gh is installed
where gh >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m[OK] GitHub CLI ^(gh^) is already installed[0m
) else (
    echo [93m[WARNING] GitHub CLI ^(gh^) is not installed[0m
    call :INSTALL_GITHUB_CLI
)

REM Check if already authenticated
gh auth status >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m[OK] Already authenticated with GitHub ^(skipping^)[0m
    for /f "tokens=*" %%i in ('gh auth status 2^>^&1 ^| findstr /C:"Logged in"') do echo %%i
) else (
    echo [94m[INFO] Please authenticate with GitHub...[0m
    echo [94m[INFO] You will be prompted to login via browser or token[0m
    echo.
    
    gh auth login
    
    gh auth status >nul 2>&1
    if %errorlevel% equ 0 (
        echo [92m[OK] GitHub authentication successful![0m
    ) else (
        echo [91m[ERROR] GitHub authentication failed[0m
        echo [91m[ERROR] Please run 'gh auth login' manually and try again[0m
        pause
        exit /b 1
    )
)

REM ############################################################################
REM 3. CLONE REPOSITORY
REM ############################################################################

:CLONE_REPO
echo.
echo ================================
echo Cloning Repository
echo ================================
echo.

set "REPO_URL=https://github.com/dfh-swt-banking/sales-and-onboarding.git"
set "WORK_DIR=%USERPROFILE%\workspace"
set "PROJECT_PATH=%WORK_DIR%\sales-and-onboarding\BackendServices\party-service"

set /p "CUSTOM_DIR=Enter workspace directory (press Enter for default: %WORK_DIR%): "
if not "%CUSTOM_DIR%"=="" (
    set "WORK_DIR=%CUSTOM_DIR%"
    set "PROJECT_PATH=%WORK_DIR%\sales-and-onboarding\BackendServices\party-service"
)

REM Create workspace directory
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
cd /d "%WORK_DIR%"

REM Clone or update repository
if exist "sales-and-onboarding" (
    echo [92m[OK] Repository already exists ^(skipping clone^)[0m
    cd sales-and-onboarding
    echo [94m[INFO] Updating to latest version...[0m
    git pull origin main 2>nul
    if %errorlevel% equ 0 (
        echo [92m[OK] Repository updated successfully[0m
    ) else (
        echo [93m[WARNING] Could not update repository ^(might be offline or no changes^)[0m
    )
) else (
    echo [94m[INFO] Cloning repository from %REPO_URL%[0m
    git clone "%REPO_URL%"
    if %errorlevel% equ 0 (
        echo [92m[OK] Repository cloned successfully[0m
    ) else (
        echo [91m[ERROR] Failed to clone repository[0m
        pause
        exit /b 1
    )
)

cd /d "%PROJECT_PATH%"
echo [92mRepository ready at: %PROJECT_PATH%[0m

REM ############################################################################
REM 4. DATABASE SETUP
REM ############################################################################

echo.
echo ================================
echo Setting Up Local Database
echo ================================
echo.

echo [94m[INFO] Configuring local PostgreSQL database[0m
echo.

set "DB_NAME=party_service_db"
set "DB_USER=party_user"
set "DB_PASSWORD=party_pass_2024"
set "DB_HOST=localhost"
set "DB_PORT=5432"

set /p "INPUT_DB_NAME=Database name (press Enter for '%DB_NAME%'): "
if not "%INPUT_DB_NAME%"=="" set "DB_NAME=%INPUT_DB_NAME%"

set /p "INPUT_DB_USER=Database user (press Enter for '%DB_USER%'): "
if not "%INPUT_DB_USER%"=="" set "DB_USER=%INPUT_DB_USER%"

set /p "INPUT_DB_PASSWORD=Database password (press Enter for '%DB_PASSWORD%'): "
if not "%INPUT_DB_PASSWORD%"=="" set "DB_PASSWORD=%INPUT_DB_PASSWORD%"

set "DB_URL=jdbc:postgresql://%DB_HOST%:%DB_PORT%/%DB_NAME%"

REM Try to create database
where psql >nul 2>&1
if %errorlevel% equ 0 (
    set "PGPASSWORD=postgres"
    
    REM Check if database exists
    psql -U postgres -h localhost -lqt 2>nul | findstr /C:"%DB_NAME%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [92m[OK] Database '%DB_NAME%' already exists ^(skipping creation^)[0m
    ) else (
        echo [94m[INFO] Creating database '%DB_NAME%'...[0m
        psql -U postgres -h localhost -c "CREATE DATABASE %DB_NAME%;" 2>nul
        echo [92m[OK] Database created[0m
    )
    
    REM Check if user exists
    psql -U postgres -h localhost -t -c "SELECT 1 FROM pg_roles WHERE rolname='%DB_USER%'" 2>nul | findstr "1" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [92m[OK] User '%DB_USER%' already exists ^(skipping creation^)[0m
    ) else (
        echo [94m[INFO] Creating user '%DB_USER%'...[0m
        psql -U postgres -h localhost -c "CREATE USER %DB_USER% WITH PASSWORD '%DB_PASSWORD%';" 2>nul
        echo [92m[OK] User created[0m
    )
    
    REM Grant privileges ^(safe to run multiple times^)
    echo [94m[INFO] Granting privileges...[0m
    psql -U postgres -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %DB_USER%;" 2>nul
    psql -U postgres -h localhost -c "ALTER DATABASE %DB_NAME% OWNER TO %DB_USER%;" 2>nul
    echo [92m[OK] Database setup completed[0m
) else (
    echo [93mNote: You may need to create the database manually using PostgreSQL tools[0m
    echo   Database: %DB_NAME%
    echo   User: %DB_USER%
    echo   Password: %DB_PASSWORD%
)

REM ############################################################################
REM 5. CONFIGURE APPLICATION
REM ############################################################################
echo.
echo ================================
echo Configuring Application
echo ================================
echo.

set "APP_CONFIG=%PROJECT_PATH%\src\main\resources\application.yml"

if not exist "%APP_CONFIG%" (
    echo [91mapplication.yml not found![0m
    pause
    exit /b 1
)

REM Backup original file if not already backed up
if not exist "%APP_CONFIG%.backup" (
    copy "%APP_CONFIG%" "%APP_CONFIG%.backup" >nul
    echo [94m[INFO] Backup created: application.yml.backup[0m
) else (
    echo [92m[OK] Backup already exists ^(skipping^)[0m
)

REM Update database configuration using PowerShell
powershell -Command "(Get-Content '%APP_CONFIG%') -replace 'url:.*', 'url: %DB_URL%' | Set-Content '%APP_CONFIG%'"
powershell -Command "(Get-Content '%APP_CONFIG%') -replace 'username:.*', 'username: %DB_USER%' | Set-Content '%APP_CONFIG%'"
powershell -Command "(Get-Content '%APP_CONFIG%') -replace 'password:.*', 'password: %DB_PASSWORD%' | Set-Content '%APP_CONFIG%'"

REM Ask for server port
set /p "SERVER_PORT=Server port (press Enter for default 8081): "
if "%SERVER_PORT%"=="" set "SERVER_PORT=8081"
powershell -Command "(Get-Content '%APP_CONFIG%') -replace 'port:.*', 'port: %SERVER_PORT%' | Set-Content '%APP_CONFIG%'"

echo [92mApplication configured successfully[0m
echo Database URL: %DB_URL%
echo Server will run on port: %SERVER_PORT%

REM ############################################################################
REM 6. BUILD PROJECT
REM ############################################################################

echo.
echo ================================
echo Building Project
echo ================================
echo.

cd /d "%PROJECT_PATH%"

REM Check if project was already built
if exist "target\*.jar" (
    echo [94m[INFO] Previous build found. Rebuilding...[0m
) else (
    echo [94m[INFO] Running first build ^(this may take 2-5 minutes^)...[0m
)

echo [94m[INFO] Running Maven clean install...[0m
echo.

call mvn clean install -DskipTests
if %errorlevel% neq 0 (
    echo [91m[ERROR] Build failed! Check the errors above.[0m
    echo [94m[INFO] You can try running manually: cd %PROJECT_PATH% ^&^& mvn clean install[0m
    pause
    exit /b 1
)

echo [92mProject built successfully![0m

REM ############################################################################
REM 7. PRINT SUMMARY
REM ############################################################################

echo.
echo ================================
echo Setup Complete! 🎉
echo ================================
echo.

echo Project Location: %PROJECT_PATH%
echo Database: %DB_URL%
echo Server Port: %SERVER_PORT%
echo.
echo Useful Commands:
echo   Start application:  mvn spring-boot:run
echo   Build project:      mvn clean install
echo   Run tests:          mvn test
echo.
echo Useful URLs (when app is running):
echo   Swagger UI:    http://localhost:%SERVER_PORT%/swagger-ui/index.html
echo   Health Check:  http://localhost:%SERVER_PORT%/actuator/health
echo   API Base:      http://localhost:%SERVER_PORT%/v1/party
echo.
echo [92mYou're all set! Happy Coding! 🚀[0m
echo.

REM ############################################################################
REM 8. RUN APPLICATION
REM ############################################################################

set /p "START_APP=Do you want to start the application now? (y/n): "
if /i "%START_APP%"=="y" (
    echo.
    echo Starting Party Service...
    echo Application will be available at: http://localhost:%SERVER_PORT%
    echo Swagger UI: http://localhost:%SERVER_PORT%/swagger-ui/index.html
    echo Health Check: http://localhost:%SERVER_PORT%/actuator/health
    echo.
    echo [93mPress Ctrl+C to stop the application[0m
    echo.
    
    call mvn spring-boot:run
) else (
    echo.
    echo Skipping application startup
    echo.
    echo To start the application later, run:
    echo   cd %PROJECT_PATH%
    echo   mvn spring-boot:run
    echo.
)

pause
