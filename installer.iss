[Setup]
AppId={{4B5D3C16-2A06-4A1A-AE22-08FBA70FE11D}
AppName=DMS Provider Installer
AppVersion=0.5.0-beta
AppPublisher=mergi72
DefaultDirName={localappdata}\Programs\DMS Provider
DefaultGroupName=DMS Provider
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=artifacts\installer
OutputBaseFilename=DmsProviderInstaller-v0.5.0-beta
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "payload\installers\DmsProviderBridgeSetup.exe"; DestDir: "{app}\installers"; Flags: ignoreversion
Source: "payload\credential-broker\credential-broker.exe"; DestDir: "{localappdata}\Credential Broker"; Flags: ignoreversion
Source: "payload\credential-broker\install-broker.ps1"; DestDir: "{localappdata}\Credential Broker"; Flags: ignoreversion
Source: "payload\credential-broker\uninstall-broker.ps1"; DestDir: "{localappdata}\Credential Broker"; Flags: ignoreversion
Source: "payload\credential-broker\stop-credential-broker.ps1"; DestDir: "{localappdata}\Credential Broker"; Flags: ignoreversion
Source: "payload\credential-broker\config\broker.json"; DestDir: "{localappdata}\Credential Broker\config"; Flags: ignoreversion
Source: "payload\tc-wfx\TcWfxPlugin.wfx64"; DestDir: "{app}\tc-wfx"; Flags: ignoreversion
Source: "payload\tc-wfx\config.json"; DestDir: "{app}\tc-wfx"; Flags: ignoreversion
Source: "payload\tc-wfx\localize.json"; DestDir: "{app}\tc-wfx"; Flags: ignoreversion skipifsourcedoesntexist
Source: "scripts\install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "scripts\uninstall.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\installers"
Name: "{localappdata}\Credential Broker\config"
Name: "{localappdata}\Credential Broker\logs"
Name: "{app}\tc-wfx"
Name: "{app}\tc-wfx\config"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install.ps1"" -InstallRoot ""{app}"" -BridgeSetupPath ""{app}\installers\DmsProviderBridgeSetup.exe"" -BrokerInstallRoot ""{localappdata}\Credential Broker"" -WfxPluginPath ""{app}\tc-wfx\TcWfxPlugin.wfx64"" -PluginConfigPath ""{app}\tc-wfx\config.json"" -PluginLocalizePath ""{app}\tc-wfx\localize.json"" -PauseOnError"; Flags: waituntilterminated

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall.ps1"" -InstallRoot ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "DMSProviderOrchestratorUninstall"

