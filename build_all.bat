@echo off
setlocal
cd /d %~dp0

echo ===== Step 1: Build Flutter UI =====
cd typetwo_flutter
call flutter build windows
if errorlevel 1 (echo [FAIL] Flutter build failed & exit /b 1)
cd ..

echo ===== Step 2: Stage Flutter output to package\ =====
set RELEASE=typetwo_flutter\build\windows\x64\runner\Release
set DEFAULT_CFG=typetwo_flutter\assets\translator_config.json
set TRAY_ICON=src\tray_icon.ico
set UI_LOCALE=%RELEASE%\ui_locale.txt
set INSTALL_SCRIPT=installer\install_ollama_and_model.bat
if not exist package mkdir package
del /Q package\typetwo.log >nul 2>nul
copy /Y %RELEASE%\typetwo.exe package\TypeTwoUI.exe
if exist package\data rmdir /S /Q package\data
del /Q package\*.dll >nul 2>nul
xcopy /Y /E /I %RELEASE%\data package\data\
for %%f in (%RELEASE%\*.dll) do copy /Y "%%f" package\
copy /Y %DEFAULT_CFG% package\translator_config.json
copy /Y %TRAY_ICON% package\tray_icon.ico
if exist %UI_LOCALE% (
  copy /Y %UI_LOCALE% package\ui_locale.txt
) else (
  del /Q package\ui_locale.txt >nul 2>nul
)
copy /Y %INSTALL_SCRIPT% package\install_ollama_and_model.bat

echo ===== Step 3: Build Python EXE =====
call release\build_client_exe.bat skip
if errorlevel 1 (echo [FAIL] Python build failed & exit /b 1)
if exist package\_internal rmdir /S /Q package\_internal
del /Q package\TypeTwo.exe >nul 2>nul
xcopy /Y /E /I src\dist\TypeTwo\* package\ >nul

echo ===== Step 4: Build Installer =====
set INNO_COMPILER=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%INNO_COMPILER%" (
  echo [SKIP] Inno Setup not found, skipping installer build.
) else (
  "%INNO_COMPILER%" installer\typetwo.iss
  if errorlevel 1 (echo [FAIL] Installer build failed & exit /b 1)
)

echo.
echo All done.
echo EXEs staged in package\
echo Installer in installer\output\
if "%1"=="" pause
