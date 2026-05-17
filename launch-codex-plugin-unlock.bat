@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "CDP_PORT=%CDP_PORT%"
if not defined CDP_PORT set "CDP_PORT=9229"

set "SCRIPT_JS=%SCRIPT_DIR%plugin_unlock.js"
set "SCRIPT_PY=%SCRIPT_DIR%inject_plugin_unlock.py"
set "VENV_DIR=%SCRIPT_DIR%.venv"
set "CODEX_APP="
set "PYTHON_CMD="
set "PYTHON_DISPLAY="

if not exist "%SCRIPT_JS%" (
  echo [launcher] required file missing: %SCRIPT_JS%
  exit /b 1
)
if not exist "%SCRIPT_PY%" (
  echo [launcher] required file missing: %SCRIPT_PY%
  exit /b 1
)

call :find_codex_app
if errorlevel 1 (
  echo [launcher] Codex app not found.
  echo [launcher] Set CODEX_APP_PATH and retry, e.g.:
  echo [launcher]   set CODEX_APP_PATH=C:\Path\To\Codex.exe
  exit /b 1
)

echo [launcher] using Codex app: %CODEX_APP%

call :cdp_ready
if errorlevel 1 (
  call :is_codex_running
  if not errorlevel 1 (
    echo [launcher] Codex is running without CDP %CDP_PORT%; quitting for restart ...
    powershell -NoProfile -Command "$p = Get-Process -Name Codex -ErrorAction SilentlyContinue; if ($p) { $p.CloseMainWindow() | Out-Null }" >nul 2>&1

    set "WAIT_COUNT=0"
    :wait_codex_exit
    call :is_codex_running
    if errorlevel 1 goto :after_quit
    set /a WAIT_COUNT+=1
    if !WAIT_COUNT! geq 25 (
      echo [launcher] graceful quit timed out; forcing Codex shutdown ...
      taskkill /IM Codex.exe /T /F >nul 2>&1
    )
    timeout /t 1 /nobreak >nul
    goto :wait_codex_exit
    :after_quit
  )
)

call :cdp_ready
if errorlevel 1 (
  echo [launcher] launching Codex with CDP port %CDP_PORT% ...
  start "" "%CODEX_APP%" --remote-debugging-port=%CDP_PORT% --remote-allow-origins=http://127.0.0.1:%CDP_PORT%
) else (
  echo [launcher] CDP %CDP_PORT% already available; reusing current Codex process.
)

call :choose_python
if errorlevel 1 (
  echo [launcher] python3 not found.
  exit /b 1
)

call :ensure_websocket_dependency
if errorlevel 1 (
  echo [launcher] failed to prepare websocket-client.
  exit /b 1
)

echo [launcher] starting injector watcher with %PYTHON_DISPLAY% ...
set "HTTP_PROXY="
set "HTTPS_PROXY="
set "ALL_PROXY="
set "http_proxy="
set "https_proxy="
set "all_proxy="
set "NO_PROXY=127.0.0.1,localhost"
set "no_proxy=127.0.0.1,localhost"

%PYTHON_CMD% "%SCRIPT_PY%" --port "%CDP_PORT%" --script "%SCRIPT_JS%" --wait-timeout 45 --poll-interval 1
exit /b %errorlevel%

:find_codex_app
if defined CODEX_APP_PATH (
  if exist "%CODEX_APP_PATH%" (
    set "CODEX_APP=%CODEX_APP_PATH%"
    exit /b 0
  )
)

for /f "delims=" %%I in ('where Codex.exe 2^>nul') do (
  if exist "%%~fI" (
    set "CODEX_APP=%%~fI"
    exit /b 0
  )
)

for %%P in (
  "%LOCALAPPDATA%\Programs\Codex\Codex.exe"
  "%LOCALAPPDATA%\Programs\codex\Codex.exe"
  "%ProgramFiles%\Codex\Codex.exe"
  "%ProgramFiles(x86)%\Codex\Codex.exe"
  "%LOCALAPPDATA%\Microsoft\WindowsApps\Codex.exe"
) do (
  if exist "%%~fP" (
    set "CODEX_APP=%%~fP"
    exit /b 0
  )
)

exit /b 1

:is_codex_running
tasklist /FI "IMAGENAME eq Codex.exe" /NH | findstr /I /C:"Codex.exe" >nul
exit /b %errorlevel%

:cdp_ready
curl.exe --silent --show-error --fail --max-time 1 --noproxy * "http://127.0.0.1:%CDP_PORT%/json/list" >nul 2>&1
if not errorlevel 1 exit /b 0

powershell -NoProfile -Command "$ProgressPreference = 'SilentlyContinue'; try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%CDP_PORT%/json/list' -TimeoutSec 1; if ($r.StatusCode -ge 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
exit /b %errorlevel%

:choose_python
if exist "%VENV_DIR%\Scripts\python.exe" (
  set "PYTHON_CMD=\"%VENV_DIR%\Scripts\python.exe\""
  set "PYTHON_DISPLAY=%VENV_DIR%\Scripts\python.exe"
  exit /b 0
)

where py >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=py -3"
  set "PYTHON_DISPLAY=py -3"
  exit /b 0
)

where python3 >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=python3"
  set "PYTHON_DISPLAY=python3"
  exit /b 0
)

where python >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=python"
  set "PYTHON_DISPLAY=python"
  exit /b 0
)

exit /b 1

:ensure_websocket_dependency
%PYTHON_CMD% -c "import websocket" >nul 2>&1
if not errorlevel 1 exit /b 0

echo [launcher] creating lightweight .venv and installing websocket-client ...
%PYTHON_CMD% -m venv "%VENV_DIR%"
if errorlevel 1 exit /b 1

set "PYTHON_CMD=\"%VENV_DIR%\Scripts\python.exe\""
set "PYTHON_DISPLAY=%VENV_DIR%\Scripts\python.exe"

%PYTHON_CMD% -m pip install --quiet --upgrade pip
if errorlevel 1 exit /b 1

%PYTHON_CMD% -m pip install --quiet websocket-client
exit /b %errorlevel%
