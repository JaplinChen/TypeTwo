@echo off
setlocal
cd /d %~dp0\..\src

set "VENV_PYTHON=%CD%\.venv\Scripts\python.exe"

if not exist "%VENV_PYTHON%" (
  python -m venv .venv
  if errorlevel 1 (
    echo [FAIL] Failed to create Python virtual environment.
    exit /b 1
  )
)

"%VENV_PYTHON%" -m pip install --upgrade pip
if errorlevel 1 (
  echo [FAIL] Failed to upgrade pip.
  exit /b 1
)

"%VENV_PYTHON%" -m pip install -r requirements-build.txt
if errorlevel 1 (
  echo [FAIL] Failed to install Python build dependencies.
  exit /b 1
)

"%VENV_PYTHON%" -m PyInstaller --noconfirm --onefile --name TypeTwo --noconsole ^
  --hidden-import=keyboard ^
  --hidden-import=keyboard._winkeyboard ^
  --hidden-import=win32clipboard ^
  --hidden-import=win32con ^
  --hidden-import=flask ^
  --hidden-import=flask.json ^
  --hidden-import=werkzeug ^
  --hidden-import=werkzeug.serving ^
  --hidden-import=jinja2 ^
  --hidden-import=click ^
  --hidden-import=itsdangerous ^
  typetwo_client.py
if errorlevel 1 (
  echo [FAIL] PyInstaller build failed.
  exit /b 1
)

echo.
echo Build complete: src\dist\TypeTwo.exe
if "%1"=="" pause
