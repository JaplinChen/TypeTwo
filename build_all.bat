@echo off
setlocal
cd /d %~dp0

echo ===== Step 1: Build Flutter =====
cd typetwo_flutter
call flutter build windows
if errorlevel 1 (echo [FAIL] Flutter build failed & exit /b 1)
cd ..

echo ===== Step 2: Stage Flutter output to package\ =====
set RELEASE=typetwo_flutter\build\windows\x64\runner\Release
set DEFAULT_CFG=typetwo_flutter\assets\translator_config.json
set INSTALL_SCRIPT=installer\install_ollama_and_model.bat
if not exist package mkdir package
del /Q package\typetwo.log >nul 2>nul
copy /Y %RELEASE%\typetwo.exe package\TypeTwo.exe
if exist package\data rmdir /S /Q package\data
del /Q package\*.dll >nul 2>nul
xcopy /Y /E /I %RELEASE%\data package\data\
for %%f in (%RELEASE%\*.dll) do copy /Y "%%f" package\
if not exist package\translator_config.json copy /Y %DEFAULT_CFG% package\translator_config.json
copy /Y %INSTALL_SCRIPT% package\install_ollama_and_model.bat

echo ===== Step 3: Build Installer =====
set INNO_COMPILER=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%INNO_COMPILER%" (
  echo [SKIP] Inno Setup not found, skipping installer build.
) else (
  "%INNO_COMPILER%" installer\typetwo.iss
  if errorlevel 1 (echo [FAIL] Installer build failed & exit /b 1)
)

echo.
echo All done.
echo EXE staged in package\TypeTwo.exe
echo Installer in installer\output\
if "%1"=="" pause
