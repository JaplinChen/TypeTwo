@echo off
setlocal
cd /d %~dp0\..\src

if not exist .venv (
  py -m venv .venv
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements-build.txt

pyinstaller --noconfirm --onefile --name settings_ui ^
  --hidden-import=requests ^
  settings_ui.py

echo.
echo Build complete: src\dist\settings_ui.exe
if "%1"=="" pause
