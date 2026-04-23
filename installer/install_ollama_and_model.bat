@echo off
setlocal

set "DEFAULT_MODEL=translategemma:4b"
set "MODEL=%~1"
if "%MODEL%"=="" set "MODEL=%DEFAULT_MODEL%"

echo.
echo [TypeTwo] Preparing to install Ollama and download model: %MODEL%
echo.

set "OLLAMA_EXE="
for /f "delims=" %%i in ('where.exe ollama 2^>nul') do (
  set "OLLAMA_EXE=%%i"
  goto :found_ollama
)

if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
  set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
  goto :found_ollama
)

echo [1/4] Ollama was not found. Starting installation...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://ollama.com/install.ps1 | iex"
if errorlevel 1 (
  echo [Error] Ollama installation failed.
  exit /b 1
)

if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
  set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
) else (
  for /f "delims=" %%i in ('where.exe ollama 2^>nul') do (
    set "OLLAMA_EXE=%%i"
    goto :found_ollama
  )
)

:found_ollama
if "%OLLAMA_EXE%"=="" (
  echo [Error] Installation finished, but ollama.exe could not be found.
  echo Please verify that Ollama was installed successfully.
  exit /b 1
)

echo [2/4] Using Ollama executable: %OLLAMA_EXE%

tasklist /FI "IMAGENAME eq ollama app.exe" | find /I "ollama app.exe" >nul
if errorlevel 1 (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
    echo [3/4] Starting Ollama background service...
    start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
  )
)

echo [3/4] Waiting for the Ollama API to become available...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ok = $false; for ($i = 0; $i -lt 30; $i++) { try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 ^| Out-Null; $ok = $true; break } catch { Start-Sleep -Seconds 2 } }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
  echo [Error] Timed out while waiting for the Ollama API.
  echo Please make sure Ollama is running correctly.
  exit /b 1
)

echo [4/4] Pulling model %MODEL% ...
"%OLLAMA_EXE%" pull "%MODEL%"
if errorlevel 1 (
  echo [Error] Failed to pull model: %MODEL%
  exit /b 1
)

echo.
echo [Done] Ollama is ready, and model %MODEL% has been downloaded.
echo You can now select the following in TypeTwoUI:
echo   Provider = Ollama
echo   Endpoint = http://127.0.0.1:11434/api/chat
echo   Model    = %MODEL%
echo.
pause
