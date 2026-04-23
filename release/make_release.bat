@echo off
setlocal
cd /d %~dp0

call build_client_exe.bat skip
if errorlevel 1 (echo [FAIL] Client build failed & exit /b 1)

set FLUTTER_RELEASE=..\typetwo_flutter\build\windows\x64\runner\Release

if not exist ..\src\dist\TypeTwo.exe (echo [FAIL] TypeTwo.exe missing & exit /b 1)
if not exist %FLUTTER_RELEASE%\typetwo.exe (echo [FAIL] Flutter typetwo.exe missing - run: flutter build windows & exit /b 1)

if not exist ..\package mkdir ..\package
copy /Y ..\src\dist\TypeTwo.exe ..\package\
copy /Y %FLUTTER_RELEASE%\typetwo.exe ..\package\TypeTwoUI.exe
xcopy /Y /E /I %FLUTTER_RELEASE%\data ..\package\data\
for %%f in (%FLUTTER_RELEASE%\*.dll) do copy /Y "%%f" ..\package\
copy /Y ..\src\translator_config.json ..\package\

echo.
echo Release staging ready in package\
if "%1"=="" pause
