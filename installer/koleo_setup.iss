[Setup]
AppName=Koleo Browser
AppVersion=1.0.0
AppPublisher=Koleo
DefaultDirName={autopf}\Koleo Browser
DefaultGroupName=Koleo Browser
OutputDir=..\build\installer
OutputBaseFilename=KoleoBrowserSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительно:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Koleo Browser"; Filename: "{app}\koleo_browser.exe"
Name: "{autodesktop}\Koleo Browser"; Filename: "{app}\koleo_browser.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\koleo_browser.exe"; Description: "Запустить Koleo Browser"; Flags: nowait postinstall skipifsilent
