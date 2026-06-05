# dms-provider-installer

Standalone installer project for deploying dms-provider-bridge as a Windows Service and installing the Total Commander WFX plugin.

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

## Prerequisites

- PowerShell running as Administrator.
- Python 3.11+ installed on the machine.
- NSSM binary available locally (for example `tools/nssm/nssm.exe`).

## Quick Commands

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 \
  -BridgeSourceRepoPath C:\Users\merhautr\python_projects\dms-provider-bridge \
  -WfxPluginBinaryPath C:\Users\merhautr\python_projects\tc-wfx-plugin\artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Uninstall:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```
