#define MyAppName "NetchX"
#define MyAppVersion "1.9.7"
#define MyAppPublisher "NanoKillX Software"
#define MyAppExeName "Netch.exe"
#define SourcePayload "..\\payload"
#define AssetRoot "..\\assets"

[Setup]
AppId={{2EAB3702-0B77-4DBF-9E43-3B0C44D1A3E1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppComments=Modern optimized proxy client for Windows.
DefaultDirName={pf}\NetchX
DefaultGroupName={#MyAppName}
DisableDirPage=no
OutputDir=..\\
OutputBaseFilename=NetchX-Setup
SetupIconFile={#AssetRoot}\NetchX.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesInstallIn64BitMode=x64
Compression=lzma
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#SourcePayload}\\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch NetchX"; Flags: nowait postinstall skipifsilent
