; Inno Setup script for TypeTwo
#define MyAppName "TypeTwo"
#define MyAppVersion "1.0.16"
#define MyAppPublisher "TypeTwo"
#define MyAppExeName "TypeTwo.exe"

[Setup]
AppId={{A9917C0D-8F76-4D91-8A56-E36D7A2E61F1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\TypeTwo
DefaultGroupName=TypeTwo
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=setup_typetwo
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UsedUserAreasWarning=no
CloseApplications=no
RestartApplications=no

[Languages]
Name: "traditionalchinese"; MessagesFile: "ChineseTraditional.isl"

[Files]
Source: "..\package\TypeTwo.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\package\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\package\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\package\install_ollama_and_model.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\TypeTwo\TypeTwo"; Filename: "{app}\TypeTwo.exe"
Name: "{autodesktop}\TypeTwo"; Filename: "{app}\TypeTwo.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "建立桌面捷徑"; GroupDescription: "其他選項:"
Name: "startup"; Description: "開機自動啟動"; GroupDescription: "其他選項:"

[Run]
Filename: "{app}\TypeTwo.exe"; Description: "啟動 TypeTwo"; Flags: postinstall nowait skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "TypeTwo"; ValueData: """{app}\TypeTwo.exe"""; Flags: uninsdeletevalue; Tasks: startup

[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM TypeTwo.exe /F', '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := '';
end;
