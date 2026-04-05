@echo off
setlocal enabledelayedexpansion

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "CYAN=%ESC%[0;36m"
set "GREEN=%ESC%[0;32m"
set "YELLOW=%ESC%[1;33m"
set "RED=%ESC%[0;31m"
set "BOLD=%ESC%[1m"
set "NC=%ESC%[0m"

set "LOCK_FILE=.server.lock"
set "PID_FILE=.server.pid"

goto :main

:info    & echo %CYAN%[INFO]%NC%  %~1 & goto :eof
:success & echo %GREEN%[OK]%NC%    %~1 & goto :eof
:warn    & echo %YELLOW%[WARN]%NC%  %~1 & goto :eof
:error   & echo %RED%[ERROR]%NC% %~1 & goto :eof

:main

if not exist "player.config" (
    call :error "player.config not found! Create it before running this."
    pause & exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("player.config") do (
    set "%%A=%%B"
)

set "CMD=%~1"
if /i "%CMD%"=="start"  goto :cmd_start
if /i "%CMD%"=="stop"   goto :cmd_stop
if /i "%CMD%"=="status" goto :cmd_status

echo Usage: %CYAN%server.bat [start^|stop^|status]%NC%
echo.
echo   start   Pull latest world, claim lock, start server
echo   stop    Stop server, push world data, release lock
echo   status  Check who is currently hosting
exit /b 1

:cmd_start

call :info "Pulling latest world data from GitHub..."
git pull origin "%GITHUB_BRANCH%"
if errorlevel 1 ( call :error "Git pull failed." & pause & exit /b 1 )

call :lock_get "host" LOCK_HOST
if not "%LOCK_HOST%"=="" (
    call :lock_get "ip"    LOCK_IP
    call :lock_get "since" LOCK_SINCE
    echo.
    echo %RED%Server is already being hosted!%NC%
    echo   Host  : %BOLD%%LOCK_HOST%%NC%
    echo   IP    : %BOLD%%LOCK_IP%:%SERVER_PORT%%NC%
    echo   Since : %BOLD%%LOCK_SINCE%%NC%
    echo.
    call :error "Stop the server on %LOCK_HOST%'s machine first."
    pause & exit /b 1
)

call :info "Fetching NetBird IP..."
set "NB_IP="
for /f "tokens=*" %%L in ('netbird status 2^>nul ^| findstr /i "IP:"') do (
    for /f "tokens=2" %%I in ("%%L") do set "NB_IP=%%I"
)
if "%NB_IP%"=="" (
    call :error "NetBird IP not found. Run: netbird up --setup-key %NETBIRD_SETUP_KEY%"
    pause & exit /b 1
)
call :success "Using NetBird IP: %NB_IP%"

call :info "Claiming server lock..."
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-ddTHH:mm:ssZ\" -AsUTC"') do set "TIMESTAMP=%%T"

(
    echo {
    echo   "host": "%PLAYER_NAME%",
    echo   "since": "%TIMESTAMP%",
    echo   "ip": "%NB_IP%"
    echo }
) > "%LOCK_FILE%"

git add "%LOCK_FILE%"
git commit -m "LOCK: %PLAYER_NAME% started the server"
git push origin "%GITHUB_BRANCH%"
if errorlevel 1 ( call :error "Could not push lock file." & pause & exit /b 1 )
call :success "Lock claimed and pushed."

echo.
echo %BOLD%%GREEN%Starting Minecraft %MC_VERSION% server...%NC%
echo Connect via NetBird: %CYAN%%NB_IP%:%SERVER_PORT%%NC%
echo Type "stop" in the Minecraft console to stop the server.
echo.

start /b "Minecraft Server" java -Xms%MC_RAM_MIN% -Xmx%MC_RAM_MAX% -jar server.jar nogui
:: Get PID of the java process we just launched
for /f "tokens=2" %%P in ('tasklist /fi "imagename eq java.exe" /fo list ^| findstr /i "PID:"') do (
    set "MC_PID=%%P"
    goto :pid_found
)
:pid_found
echo %MC_PID% > "%PID_FILE%"

:wait_loop
tasklist /fi "PID eq %MC_PID%" 2>nul | findstr /i "java.exe" >nul
if not errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto :wait_loop
)

call :cmd_stop_cleanup
goto :eof

:cmd_stop

if not exist "%PID_FILE%" (
    call :warn "No PID file found. Is the server running?"
    exit /b 0
)

set /p MC_PID=<"%PID_FILE%"
tasklist /fi "PID eq %MC_PID%" 2>nul | findstr /i "java.exe" >nul
if not errorlevel 1 (
    call :info "Stopping server (PID %MC_PID%)..."
    taskkill /PID %MC_PID% /F >nul 2>&1
    timeout /t 3 /nobreak >nul
    call :success "Server stopped."
) else (
    call :warn "Process not found. It may have already stopped."
)

call :cmd_stop_cleanup
goto :eof

:cmd_stop_cleanup

echo.
call :info "Server stopped. Waiting for world to flush..."
timeout /t 3 /nobreak >nul

call :info "Pushing world data to GitHub..."

if exist "%PID_FILE%" del /f "%PID_FILE%"
echo {} > "%LOCK_FILE%"

git add -A
git commit -m "SAVE: %PLAYER_NAME% ended the session"
if errorlevel 1 ( call :warn "Nothing to commit." ) 

git push origin "%GITHUB_BRANCH%"
if errorlevel 1 (
    call :warn "Push failed. Run: git push manually."
) else (
    call :success "World data pushed."
    call :success "Lock released. Anyone can now start the server."
)
goto :eof

:cmd_status

git pull origin "%GITHUB_BRANCH%" -q
if errorlevel 1 ( call :warn "Could not sync status from GitHub." )

call :lock_get "host" LOCK_HOST

echo.
if "%LOCK_HOST%"=="" (
    echo %GREEN%%BOLD%Server is FREE%NC% — no one is hosting right now.
    echo Run %CYAN%server.bat start%NC% to start hosting.
) else (
    call :lock_get "ip"    LOCK_IP
    call :lock_get "since" LOCK_SINCE
    echo %YELLOW%%BOLD%Server is ACTIVE%NC%
    echo   Host  : %BOLD%%LOCK_HOST%%NC%
    echo   IP    : %BOLD%%LOCK_IP%:%SERVER_PORT%%NC%
    echo   Since : %BOLD%%LOCK_SINCE%%NC%
    echo.
    echo Connect via NetBird: %CYAN%%LOCK_IP%:%SERVER_PORT%%NC%
)
echo.
goto :eof

:lock_get
set "%~2="
if not exist "%LOCK_FILE%" goto :eof
for /f "usebackq delims=" %%V in (
    `python3 -c "import json,sys; d=json.load(open('.server.lock')); print(d.get('%~1',''))" 2^>nul`
) do set "%~2=%%V"
goto :eof