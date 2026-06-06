[Setup]
AppId={{4B5D3C16-2A06-4A1A-AE22-08FBA70FE11D}
AppName=DMS Provider Installer
AppVersion=0.2.2-alpha
AppPublisher=mergi72
DefaultDirName={autopf}\DMS Provider
DefaultGroupName=DMS Provider
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=artifacts\installer
OutputBaseFilename=DmsProviderInstaller-v0.2.2-alpha
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "payload\bridge\dms-provider-bridge.exe"; DestDir: "{app}\bridge"; Flags: ignoreversion
Source: "payload\bridge\config\*.json"; DestDir: "{app}\bridge\config"; Flags: ignoreversion
Source: "payload\tc-wfx\TcWfxPlugin.wfx64"; DestDir: "{app}\tc-wfx"; Flags: ignoreversion
Source: "payload\tc-wfx\config.json"; DestDir: "{app}\tc-wfx"; Flags: ignoreversion
Source: "payload\nssm.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "scripts\install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "scripts\uninstall.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install.ps1"" -BridgeExePath ""{app}\bridge\dms-provider-bridge.exe"" -WfxPluginPath ""{app}\tc-wfx\TcWfxPlugin.wfx64"" -PluginConfigPath ""{app}\tc-wfx\config.json"" -BridgeConfigDirPath ""{app}\bridge\config"" -NssmExePath ""{app}\nssm.exe"""; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall.ps1"" -NssmExePath ""{app}\nssm.exe"" -KeepBridgeFiles"; Flags: runhidden waituntilterminated; RunOnceId: "DMSProviderUninstallCleanup"
