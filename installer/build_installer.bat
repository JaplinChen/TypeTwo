@echo off
setlocal
cd /d %~dp0

set INNO_COMPILER=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%INNO_COMPILER%" (
  echo Inno Setup compiler not found:
  echo %INNO_COMPILER%
  echo Please install Inno Setup 6 first.
  pause
  exit /b 1
)

"%INNO_COMPILER%" typetwo.iss

echo.
echo Installer build complete: installer\output\setup_typetwo.exe
if "%1"=="" pause
