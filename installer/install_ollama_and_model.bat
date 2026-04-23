@echo off
setlocal

set "DEFAULT_MODEL=translategemma:4b"
set "MODEL=%~1"
if "%MODEL%"=="" set "MODEL=%DEFAULT_MODEL%"

echo.
echo [TypeTwo] 準備安裝 Ollama 並下載模型：%MODEL%
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

echo [1/4] 目前未找到 Ollama，開始安裝...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://ollama.com/install.ps1 | iex"
if errorlevel 1 (
  echo [錯誤] Ollama 安裝失敗。
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
  echo [錯誤] 已完成安裝流程，但仍找不到 ollama.exe。
  echo 請先確認 Ollama 是否已成功安裝。
  exit /b 1
)

echo [2/4] 使用 Ollama：%OLLAMA_EXE%

tasklist /FI "IMAGENAME eq ollama app.exe" | find /I "ollama app.exe" >nul
if errorlevel 1 (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
    echo [3/4] 啟動 Ollama 背景服務...
    start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
  )
)

echo [3/4] 等待 Ollama API 啟動...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ok = $false; for ($i = 0; $i -lt 30; $i++) { try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags -TimeoutSec 2 ^| Out-Null; $ok = $true; break } catch { Start-Sleep -Seconds 2 } }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
  echo [錯誤] 等待 Ollama API 啟動逾時，請確認 Ollama 是否正常執行。
  exit /b 1
)

echo [4/4] 下載模型 %MODEL% ...
"%OLLAMA_EXE%" pull "%MODEL%"
if errorlevel 1 (
  echo [錯誤] 模型下載失敗：%MODEL%
  exit /b 1
)

echo.
echo [完成] Ollama 已可使用，模型 %MODEL% 已下載完成。
echo 你現在可以在 TypeTwoUI 中選擇：
echo   Provider = Ollama
echo   Endpoint = http://127.0.0.1:11434/api/chat
echo   Model    = %MODEL%
echo.
pause
