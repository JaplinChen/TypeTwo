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
if not exist package mkdir package
copy /Y %RELEASE%\typetwo.exe package\TypeTwoUI.exe
if exist package\data rmdir /S /Q package\data
xcopy /Y /E /I %RELEASE%\data package\data\
for %%f in (%RELEASE%\*.dll) do copy /Y "%%f" package\

echo ===== Step 3: Build Python EXE =====
call release\build_client_exe.bat skip
if errorlevel 1 (echo [FAIL] Python build failed & exit /b 1)
copy /Y src\dist\TypeTwo.exe package\

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
