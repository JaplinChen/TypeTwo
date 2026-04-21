; Inno Setup script for TypeTwo
#define MyAppName "TypeTwo"
#define MyAppVersion "1.0.1"
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

[Languages]
Name: "traditionalchinese"; MessagesFile: "ChineseTraditional.isl"

[Files]
; Python bridge (hotkey + translation engine)
Source: "..\package\TypeTwo.exe"; DestDir: "{app}"; Flags: ignoreversion
; Flutter UI
Source: "..\package\TypeTwoUI.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\package\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\package\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Default config (only if not already present, to preserve user settings)
Source: "..\package\translator_config.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist

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
