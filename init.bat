@echo off
setlocal enabledelayedexpansion

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "CYAN=%ESC%[0;36m"
set "GREEN=%ESC%[0;32m"
set "YELLOW=%ESC%[1;33m"
set "RED=%ESC%[0;31m"
set "BOLD=%ESC%[1m"
set "NC=%ESC%[0m"

goto :main

:info    & echo %CYAN%[INFO]%NC%  %~1 & goto :eof
:success & echo %GREEN%[OK]%NC%    %~1 & goto :eof
:warn    & echo %YELLOW%[WARN]%NC%  %~1 & goto :eof
:error   & echo %RED%[ERROR]%NC% %~1 & exit /b 1

:main

if not exist "player.config" (
    call :error "player.config not found! Create it before running this."
    pause & exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("player.config") do (
    set "%%A=%%B"
)

call :info "Checking dependencies..."

where git >nul 2>&1
if errorlevel 1 ( call :error "git is not installed. Get it from git-scm.com" & pause & exit /b 1 )

where java >nul 2>&1
if errorlevel 1 ( call :error "Java is not installed. Get Java 21 from adoptium.net" & pause & exit /b 1 )

where curl >nul 2>&1
if errorlevel 1 ( call :error "curl is not installed. Update Windows or install curl." & pause & exit /b 1 )

call :success "All dependencies found."

call :info "Checking Java version..."
for /f "tokens=3 delims= " %%V in ('java -version 2^>^&1 ^| findstr /i "version"') do (
    set "JAVA_VER_RAW=%%V"
)
set "JAVA_VER_RAW=%JAVA_VER_RAW:"=%"
for /f "tokens=1 delims=." %%M in ("%JAVA_VER_RAW%") do set "JAVA_MAJOR=%%M"

if %JAVA_MAJOR% LSS 21 (
    call :error "Java 21+ required. You have Java %JAVA_MAJOR%. Get it from adoptium.net"
    pause & exit /b 1
)
call :success "Java %JAVA_MAJOR% found."

call :info "Checking NetBird..."
where netbird >nul 2>&1
if errorlevel 1 (
    call :error "NetBird is not installed. Download from netbird.io/download"
    pause & exit /b 1
)

netbird status >nul 2>&1
if errorlevel 1 (
    call :warn "NetBird not connected. Connecting now..."
    netbird up --setup-key "%NETBIRD_SETUP_KEY%"
    if errorlevel 1 (
        call :error "Failed to connect to NetBird."
        pause & exit /b 1
    )
    timeout /t 3 /nobreak >nul
)

set "NB_IP="
for /f "tokens=*" %%L in ('netbird status 2^>nul ^| findstr /i "IP:"') do (
    for /f "tokens=2" %%I in ("%%L") do set "NB_IP=%%I"
)

if "%NB_IP%"=="" (
    call :error "NetBird connected but no IP found. Check app.netbird.io"
    pause & exit /b 1
)
call :success "NetBird active. Your IP: %NB_IP%"

if exist "server.jar" (
    call :warn "server.jar already exists, skipping download."
) else (
    call :info "Downloading server.jar for Minecraft %MC_VERSION%..."
    curl -L -# -o server.jar "%SERVER_JAR_URL%"
    if errorlevel 1 (
        call :error "Download failed."
        pause & exit /b 1
    )
    call :success "server.jar downloaded."
)

call :info "Verifying required files..."
for %%F in (eula.txt server.properties ops.json .server.lock) do (
    if not exist "%%F" (
        call :error "%%F is missing from the repo!"
        pause & exit /b 1
    )
)
call :success "All required files present."

echo.
echo %BOLD%%GREEN%Setup complete!%NC%
echo Run %CYAN%server.bat start%NC% to start the server.
echo.
pause