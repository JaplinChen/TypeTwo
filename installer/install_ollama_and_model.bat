@echo off
setlocal

set "DEFAULT_MODEL=qwen3:14b"
set "MODEL=%~1"
if "%MODEL%"=="" (
  set "MODELS=qwen3:14b translategemma:4b translategemma:12b"
) else (
  set "MODELS=%MODEL%"
)

echo.
if "%MODEL%"=="" (
  echo [TypeTwo] Preparing to install Ollama and download default models: %MODELS%
) else (
  echo [TypeTwo] Preparing to install Ollama and download model: %MODEL%
)
echo.

:: [1/4] Find or install Ollama
set "OLLAMA_EXE="
for /f "delims=" %%i in ('where.exe ollama 2^>nul') do (
  set "OLLAMA_EXE=%%i"
  goto :found_ollama
)
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
  set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
  goto :found_ollama
)

echo Installing Ollama...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://ollama.com/install.ps1 | iex"
if errorlevel 1 (
  echo [Error] Ollama installation failed.
  exit /b 1
)
for /f "delims=" %%i in ('where.exe ollama 2^>nul') do (
  set "OLLAMA_EXE=%%i"
  goto :found_ollama
)
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
  set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
)

:found_ollama
if "%OLLAMA_EXE%"=="" (
  echo [Error] ollama.exe not found after installation.
  exit /b 1
)
echo [1/4] Found Ollama: %OLLAMA_EXE%

:: [2/4] Ensure service is running
set "API_READY=0"
set "SERVE_LOG=%TEMP%\ollama_serve.log"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 (
  set "API_READY=1"
  echo [2/4] Ollama service already running.
) else (
  echo [2/4] Starting Ollama service...
  if exist "%SERVE_LOG%" del "%SERVE_LOG%" >nul 2>&1
  start "" /B cmd /c ""%OLLAMA_EXE%" serve >"%SERVE_LOG%" 2>&1"
)

:: [3/4] Wait for API (skip if already confirmed up)
if "%API_READY%"=="0" (
  echo [3/4] Waiting for Ollama API...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ok = $false; for ($i = 0; $i -lt 60; $i++) { try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 ^| Out-Null; $ok = $true; break } catch { Start-Sleep -Seconds 2 } }; if (-not $ok) { exit 1 }"
  if errorlevel 1 (
    echo [Error] Timed out waiting for Ollama API.
    echo         Check firewall rules for port 11434, or run "ollama serve" manually.
    echo.
    echo Last lines from Ollama log:
    powershell -NoProfile -Command "Get-Content '%SERVE_LOG%' -Tail 10 -ErrorAction SilentlyContinue"
    exit /b 1
  )
)

:: [4/4] Pull models
echo [4/4] Pulling model(s): %MODELS%
for %%M in (%MODELS%) do (
  "%OLLAMA_EXE%" show "%%M" >nul 2>&1
  if not errorlevel 1 (
    echo   - %%M already downloaded, skipping.
  ) else (
    echo   - Pulling %%M ...
    "%OLLAMA_EXE%" pull "%%M"
    if errorlevel 1 (
      echo [Error] Failed to pull %%M
      exit /b 1
    )
  )
)

echo.
if "%MODEL%"=="" (
  echo [Done] Default models downloaded: %MODELS%
) else (
  echo [Done] Model %MODEL% downloaded.
)
echo.
echo To use in TypeTwo:
echo   Provider = Ollama
echo   Endpoint = http://127.0.0.1:11434/api/chat
if "%MODEL%"=="" (
  echo   Model    = %DEFAULT_MODEL%
) else (
  echo   Model    = %MODEL%
)
echo.
pause
