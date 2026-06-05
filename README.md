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
- Validates Python version before install (default minimum 3.11).
- Verifies bridge health endpoint after service start.
- Preserves existing `config/user.local.json` during reinstall.
- Provides a wrapper flow: bridge service install -> health check -> Total Commander detection -> optional WFX file deployment.

## Prerequisites

- PowerShell running as Administrator.
- Python 3.11+ installed on the machine.
- NSSM binary available locally (for example `tools/nssm/nssm.exe`).

## Quick Commands

Recommended wrapper (interactive flow):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\Users\merhautr\python_projects\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Wrapper behavior:

- Installs bridge as Windows Service (via `install.ps1`).
- Verifies `http://127.0.0.1:8765/health`.
- Detects Total Commander in common install paths.
- Asks whether WFX files should be prepared.
- If confirmed, copies plugin + config to `%LOCALAPPDATA%\DMSProvider\TCPlugin`.
- Does not modify `wincmd.ini` automatically.

After WFX file preparation, wrapper prints manual registration guidance:

- Total Commander -> Configuration -> Options -> Plugins -> File system plugins (WFX).

Silent mode (no prompts, installs plugin automatically when TC is detected):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\Users\merhautr\python_projects\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe \
  -Silent
```

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 \
  -BridgeSourceRepoPath C:\Users\merhautr\python_projects\dms-provider-bridge \
  -WfxPluginBinaryPath C:\Users\merhautr\python_projects\tc-wfx-plugin\artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Optional install hardening arguments:

```powershell
-MinPythonMajor 3 -MinPythonMinor 11
-HealthTimeoutSeconds 30
-HealthUrl http://127.0.0.1:8765/health
```

Uninstall:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```
