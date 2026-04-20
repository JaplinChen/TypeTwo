@echo off
setlocal
cd /d %~dp0

echo ===== Step 1: Build EXEs =====
call release\make_release.bat skip
if errorlevel 1 exit /b 1

echo ===== Step 2: Build Installer =====
call installer\build_installer.bat skip
if errorlevel 1 exit /b 1

echo.
echo All done.
echo EXEs staged in package\
echo Installer in installer\output\
pause
