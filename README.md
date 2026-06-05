# dms-provider-installer

[![Status](https://img.shields.io/badge/Status-Alpha-orange)](https://github.com/mergi72/dms-provider-installer)
[![Version](https://img.shields.io/badge/Version-v0.1.0--alpha-blue)](https://github.com/mergi72/dms-provider-installer)

Current development branch: `develop`  
Stable release branch: `main`

Standalone installer project for deploying dms-provider-bridge as a Windows Service and installing the Total Commander WFX plugin.

Installs:
- DMS Provider Bridge
- Windows Service (NSSM)
- Total Commander WFX Plugin (optional)

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
- Provide one place for deployment steps (venv, service, config, plugin copy, uninstall).

## What This Project Does

- Prepares bridge runtime from a release ZIP or local checkout.
- Creates a Python virtual environment.
- Installs Python dependencies.
- Creates user-local configuration.
- Installs/updates Windows Service via NSSM.
- Copies the WFX plugin to Total Commander path.
- Supports uninstall.
- Validates Python version before install (default minimum 3.11).
- Verifies bridge health endpoint after service start.
- Preserves existing `config/user.local.json` during reinstall.
- Provides a wrapper flow: bridge service install -> health check -> Total Commander detection -> optional WFX file deployment.
- Uses a version-agnostic virtual environment directory (`.venv`) by default.
- Prints runtime summary after health check (URL/service/install paths).

## Prerequisites

- PowerShell running as Administrator.
- Python 3.11+ installed on the machine.
- NSSM binary available locally (for example `tools/nssm/nssm.exe`).

## Quick Commands

Recommended wrapper (interactive flow):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\dev\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Wrapper behavior:

- Installs bridge as Windows Service (via `install.ps1`).
- Verifies `http://127.0.0.1:8765/health`.
- Detects Total Commander in common install paths, with registry fallback (`HKCU/HKLM\Software\Ghisler\Total Commander`).
- Asks whether WFX files should be prepared.
- If confirmed, copies plugin + config to `%LOCALAPPDATA%\DMSProvider\TCPlugin`.
- Does not modify `wincmd.ini` automatically.

Important:

- `install.ps1` installs bridge service only.
- WFX plugin deployment is handled only by `install-wrapper.ps1`.

Prepared plugin layout:

- `%LOCALAPPDATA%\DMSProvider\TCPlugin\TcWfxPlugin.wfx64`
- `%LOCALAPPDATA%\DMSProvider\TCPlugin\config\config.json`
- `%LOCALAPPDATA%\DMSProvider\TCPlugin\logs\`

After WFX file preparation, wrapper prints manual registration guidance:

- Total Commander -> Configuration -> Options -> Plugins -> File system plugins (WFX).

Silent mode (no prompts, installs plugin automatically when TC is detected):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\dev\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe \
  -Silent
```

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 \
  -BridgeSourceRepoPath C:\dev\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Optional install hardening arguments:

```powershell
-MinPythonMajor 3 -MinPythonMinor 11
-HealthTimeoutSeconds 30
-HealthUrl http://127.0.0.1:8765/health
-VenvDirectoryName .venv
```

Uninstall:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

## Troubleshooting

- Service does not start:
  - check service state and NSSM configuration
  - check installer runtime logs under `%ProgramData%\DmsProviderBridge\logs`
- Health check fails (`http://127.0.0.1:8765/health`):
  - verify port `8765` is not blocked or used by another process
  - verify service is running (`DmsProviderBridge`)
- Total Commander plugin cannot reach bridge:
  - open `http://127.0.0.1:8765/health` manually
  - verify deployed plugin files exist in `%LOCALAPPDATA%\DMSProvider\TCPlugin`
