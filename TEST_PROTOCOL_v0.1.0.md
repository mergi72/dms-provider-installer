# Test Protocol v0.1.0

## Scope

This protocol validates first public testing build for:
- bridge runtime service
- WFX plugin deployment package
- installer flow

Feature freeze rule for this phase:
- no new features
- only bug fixes with reproducible steps

## Test Environment

Required:
- Windows machine (clean profile preferred)
- PowerShell as Administrator
- Total Commander installed
- NSSM available (for example `C:\tools\nssm\win64\nssm.exe`)

Inputs:
- dms-provider-installer package
- bridge source or bridge release ZIP
- tc-wfx-plugin binary (`TcWfxPlugin.wfx64` or `TcWfxPlugin.dll`)

## Execution Steps

### 1. Fresh Install

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\dev\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Expected:
- service created and started
- health check passed
- runtime summary printed
- Total Commander detection message shown
- optional plugin copy prompt shown

### 2. Silent Install

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1 \
  -BridgeSourceRepoPath C:\dev\dms-provider-bridge \
  -NssmExePath C:\tools\nssm\win64\nssm.exe \
  -Silent
```

Expected:
- no interactive prompts
- service installed and healthy
- if TC detected, plugin files copied automatically

### 3. Service Verification

Check:
- service name: `DmsProviderBridge`
- endpoint: `http://127.0.0.1:8765/health`

Run:

```powershell
Invoke-RestMethod -Method Get -Uri http://127.0.0.1:8765/health | ConvertTo-Json -Depth 5
```

Expected:
- response status is ok

### 4. Config Persistence (Upgrade/Reinstall)

1. Edit `config/user.local.json` under install root.
2. Run install again.
3. Verify custom values are preserved.

Expected:
- `user.local.json` survives reinstall

### 5. Plugin Files Layout

Verify path:
- `%LOCALAPPDATA%\DMSProvider\TCPlugin`

Expected layout:
- `TcWfxPlugin.wfx64`
- `config\config.json`
- `logs\`

### 6. Manual Plugin Registration in Total Commander

In Total Commander:
- Configuration -> Options -> Plugins -> File system plugins (WFX)
- add prepared plugin file from deploy path

Expected:
- plugin loads without immediate error

### 7. Functional WFX Smoke

Minimum operation set:
- list
- stat
- upload
- download
- delete
- directory create/delete

Expected:
- operations complete without crash
- no service restart needed during normal use

Note:
- explicitly observe download progress behavior and report mismatch

### 8. Uninstall

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
```

Expected:
- service removed
- runtime files removed (unless keep flags are used)

## Pass/Fail Criteria

Pass:
- install, health, plugin prep, core WFX ops, uninstall all pass

Fail:
- any blocker in install/uninstall/health/service start/plugin load

## Bug Report Template

Use this format:

- Title:
- Build/commit:
- Environment:
- Steps to reproduce:
- Expected result:
- Actual result:
- Logs/attachments:
- Severity: critical/high/medium/low

## Triage Guidance

- critical: install impossible, service down, data loss risk
- high: major operation blocked (upload/download/list)
- medium: partial failure or unstable behavior
- low: cosmetic, docs, minor UX issues
