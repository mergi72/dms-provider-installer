# dms-provider-installer

[![Status](https://img.shields.io/badge/Status-Alpha-orange)](https://github.com/mergi72/dms-provider-installer)
[![Version](https://img.shields.io/badge/Version-v0.1.0--alpha-blue)](https://github.com/mergi72/dms-provider-installer)

Current development branch: `develop`  
Stable release branch: `main`

Standalone installer project for deploying dms-provider-bridge as a Windows Service and installing the Total Commander WFX plugin.

Installs:
- DMS Provider Bridge
- Windows Service (NSSM)
- Total Commander WFX plugin (`TcWfxPlugin.wfx64`)
- Plugin config (`config.json`)

Supported:
- Windows 10/11
- Total Commander 64-bit

Related projects:
- dms-provider-bridge
- tc-wfx-plugin

Disclaimer:
- This installer currently supports the Alfresco provider.
- eDoCat-specific provider support is still under development.

Goals:
- Keep the bridge repository clean (application/API only).
- Keep the tc-wfx-plugin repository clean (plugin code only).
- Provide one place for deployment steps (service install, health check, uninstall).

## What This Project Does

- Installs prebuilt bridge executable.
- Installs WFX plugin into `%ProgramFiles%\DMS Provider\TcWfxPlugin.wfx64`.
- Installs plugin config into `%ProgramFiles%\DMS Provider\config.json`.
- Installs/updates Windows Service via NSSM.
- Supports uninstall.
- Verifies bridge health endpoint after service start.
- If Total Commander config is found, registers plugin automatically in `wincmd.ini` under `[FileSystemPlugins64]`.
- Creates `wincmd.ini` backup before modification.
- Provides manual plugin path when Total Commander config is not found.
- Provides a wrapper flow: bridge service install -> health check -> plugin install/registration.
- Prints runtime summary after health check (URL/service/install paths).

## Prerequisites

- PowerShell running as Administrator.
- NSSM binary available locally (for example `tools/nssm/nssm.exe`).
- Prebuilt `dms-provider-bridge.exe` available (for example from bridge repo `dist/`).
- Built WFX plugin and config available from `tc-wfx-plugin` repo.

## Quick Commands

Build single installer EXE (Inno Setup):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-inno-installer.ps1 \
  -BridgeRepoPath C:\dev\dms-provider-bridge \
  -TcPluginRepoPath C:\dev\tc-wfx-plugin
```

Build script does:

- prepares payload (bridge exe + WFX + config)
- copies `nssm.exe` into payload (from `-NssmExePath` or common local paths)
- compiles [installer.iss](installer.iss) into one installer EXE

Installer output:

- `artifacts\installer\DmsProviderInstaller-v0.2.0-alpha.exe`

Prepare payload from bridge build output:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-payload.ps1 \
  -BridgeRepoPath C:\dev\dms-provider-bridge \
  -TcPluginRepoPath C:\dev\tc-wfx-plugin
```

This copies all required files into payload:

- `payload\dms-provider-bridge.exe`
- `payload\TcWfxPlugin.wfx64`
- `payload\config.json`

Recommended wrapper (interactive flow):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeExePath C:\dev\dms-provider-bridge\dist\dms-provider-bridge.exe \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Wrapper behavior:

- Installs bridge as Windows Service (via `install.ps1`).
- Verifies `http://127.0.0.1:8765/health`.
- Installs plugin bundle into `%ProgramFiles%\DMS Provider`.
- Tries to register WFX plugin automatically in Total Commander config.
- Creates backup of `wincmd.ini` before editing.
- If Total Commander config is not found, prints plugin path for manual registration.

Default payload behavior:

- If `-BridgeExePath` is not provided, installer looks for `payload/dms-provider-bridge.exe` in this repository.
- If `-WfxPluginPath` is not provided, installer looks for `payload/TcWfxPlugin.wfx64`.
- If `-PluginConfigPath` is not provided, installer looks for `payload/config.json`.

Important:

- Current installer phase installs bridge + service + WFX plugin + config.
- Automatic TC registration can be disabled with `-DisableTcRegistration`.

Silent mode (no prompts, installs plugin automatically when TC is detected):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeExePath C:\dev\dms-provider-bridge\dist\dms-provider-bridge.exe \
  -NssmExePath C:\tools\nssm\win64\nssm.exe \
  -Silent
```

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 \
  -BridgeExePath C:\dev\dms-provider-bridge\dist\dms-provider-bridge.exe \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Optional install arguments:

```powershell
-HealthTimeoutSeconds 30
-HealthUrl http://127.0.0.1:8765/health
-WinCmdIniPath C:\Users\<user>\AppData\Roaming\GHISLER\wincmd.ini
-DisableTcRegistration
```

Uninstall:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Manual compile (if needed):

```powershell
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer.iss
```

## Troubleshooting

- Service does not start:
  - check service state and NSSM configuration
  - check installer runtime logs under `%ProgramFiles%\DMS Provider\logs`
- Health check fails (`http://127.0.0.1:8765/health`):
  - verify port `8765` is not blocked or used by another process
  - verify service is running (`DmsProviderBridge`)
- Plugin not visible in Total Commander:
  - verify `%ProgramFiles%\DMS Provider\TcWfxPlugin.wfx64` exists
  - verify installer output for detected `wincmd.ini` path and backup creation
  - if auto-registration was skipped, add plugin manually in Total Commander (WFX -> Add)
