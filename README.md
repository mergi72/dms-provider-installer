# dms-provider-installer

[![Status](https://img.shields.io/badge/Status-Alpha-orange)](https://github.com/mergi72/dms-provider-installer)
[![Version](https://img.shields.io/badge/Version-v0.1.0--alpha-blue)](https://github.com/mergi72/dms-provider-installer)

Current development branch: `develop`  
Stable release branch: `main`

Standalone installer project for deploying dms-provider-bridge as a Windows Service and installing the Total Commander WFX plugin.

Installs:
- DMS Provider Bridge
- Windows Service (NSSM)

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
- Installs/updates Windows Service via NSSM.
- Supports uninstall.
- Verifies bridge health endpoint after service start.
- Provides a wrapper flow: bridge service install -> health check.
- Prints runtime summary after health check (URL/service/install paths).

## Prerequisites

- PowerShell running as Administrator.
- NSSM binary available locally (for example `tools/nssm/nssm.exe`).
- Prebuilt `dms-provider-bridge.exe` available (for example from bridge repo `dist/`).

## Quick Commands

Prepare payload from bridge build output:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-payload.ps1 \
  -BridgeRepoPath C:\dev\dms-provider-bridge
```

This copies `dist\dms-provider-bridge.exe` from bridge repo into this repo as `payload\dms-provider-bridge.exe`.

Recommended wrapper (interactive flow):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeExePath C:\dev\dms-provider-bridge\dist\dms-provider-bridge.exe \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Wrapper behavior:

- Installs bridge as Windows Service (via `install.ps1`).
- Verifies `http://127.0.0.1:8765/health`.

Default payload behavior:

- If `-BridgeExePath` is not provided, installer looks for `payload/dms-provider-bridge.exe` in this repository.

Important:

- `install.ps1` and `install-wrapper.ps1` in current phase install bridge service only.
- WFX plugin deployment and Total Commander registration are planned for later phases.

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
```

Uninstall:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

## Troubleshooting

- Service does not start:
  - check service state and NSSM configuration
  - check installer runtime logs under `%ProgramFiles%\DMS Provider\logs`
- Health check fails (`http://127.0.0.1:8765/health`):
  - verify port `8765` is not blocked or used by another process
  - verify service is running (`DmsProviderBridge`)
