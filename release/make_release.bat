@echo off
setlocal
cd /d %~dp0

call ..\build_all.bat skip
if errorlevel 1 (echo [FAIL] build_all.bat failed & exit /b 1)

echo.
echo Release staging ready in ..\package\
if "%1"=="" pause
