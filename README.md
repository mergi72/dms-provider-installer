# dms-provider-installer

[![CI](https://github.com/mergi72/dms-provider-installer/actions/workflows/ci.yml/badge.svg)](https://github.com/mergi72/dms-provider-installer/actions/workflows/ci.yml)
[![Status](https://img.shields.io/badge/Status-1.0-brightgreen)](https://github.com/mergi72/dms-provider-installer)
[![Installer](https://img.shields.io/badge/Installer-v1.0.0-blueviolet)](https://github.com/mergi72/dms-provider-installer/releases/tag/v1.0.0)

Current development branch: `develop`  
Stable release branch: `main`

Orchestrator installer for the DMS Provider desktop stack.

It bundles and runs the dedicated installers in this order:

- Credential Broker
- Total Commander WFX plugin
- DMS Provider Bridge

The orchestrator runs in the current user context. The credential broker installer owns broker deployment, per-user scheduled task setup, startup, health wait, and broker config. The bridge installer owns its own elevation/admin flow, bridge executable deployment, service/task setup, NSSM usage, health checks, and machine/user config locations. This project owns only orchestration and Total Commander WFX installation/registration.

## What This Project Does

- Bundles `DmsProviderBridgeSetup.exe` (the public bridge bootstrapper).
- Bundles the Credential Broker runtime payload directly and runs its `install-broker.ps1` script.
- Installs `TcWfxPlugin.wfx64` into the orchestrator user install root under `tc-wfx`.
- Installs WFX `config.json` next to the plugin and under `tc-wfx\config`.
- Installs WFX localization from `localize.json` under `tc-wfx\config`.
- Runs the install flow in this order: Credential Broker script, Total Commander WFX install/registration, DMS Provider Bridge setup.
- Optionally verifies the bridge health endpoint.
- Registers the WFX plugin in Total Commander `wincmd.ini` under `[FileSystemPlugins64]`.
- Creates a `wincmd.ini` backup before modification.

## Install Flow

1. Credential Broker files are copied to `%LOCALAPPDATA%\Credential Broker` by Inno Setup.
2. The orchestrator runs `%LOCALAPPDATA%\Credential Broker\install-broker.ps1` and waits for that script to finish.
3. The orchestrator installs `TcWfxPlugin.wfx64`, `config.json`, and `localize.json` under its own `tc-wfx` directory.
4. The orchestrator registers the WFX plugin in Total Commander `wincmd.ini` when the file can be found.
5. The orchestrator starts the bundled `DmsProviderBridgeSetup.exe` and waits for that setup to finish.
6. The orchestrator optionally checks bridge health at `http://127.0.0.1:8765/health`.

The orchestrator does not create bridge config directories, does not set bridge config environment variables directly, and does not install the bridge service by itself.
## What This Project Does Not Own

- Bridge config files.
- `DMS_PROVIDER_MACHINE_CONFIG_DIR`.
- `DMS_PROVIDER_USER_CONFIG_DIR`.
- NSSM service setup.
- Credential Broker config files.
- Credential Broker scheduled task setup.

Those are intentionally handled by the dedicated component installers.

## Build

Build the orchestrator installer:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-inno-installer.ps1 `
  -BridgeRepoPath ..\dms-provider-bridge `
  -CredentialBrokerRepoPath ..\credential-broker `
  -TcPluginRepoPath ..\tc-wfx-plugin
```

The build script:

- picks the latest `DmsProviderBridgeSetup-*.exe` from the bridge repo unless `-BridgeSetupRelativePath` is provided;
- copies the prepared Credential Broker runtime payload from `credential-broker`;
- copies the WFX plugin, runtime config, and localization file from `tc-wfx-plugin`;
- compiles [installer.iss](installer.iss) with Inno Setup.

Output:

- `artifacts\installer\DmsProviderInstaller-v1.0.0.exe`

Prepare payload only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-payload.ps1 `
  -BridgeRepoPath ..\dms-provider-bridge `
  -CredentialBrokerRepoPath ..\credential-broker `
  -TcPluginRepoPath ..\tc-wfx-plugin
```

Payload layout:

- `payload\installers\DmsProviderBridgeSetup.exe`
- `payload\credential-broker\credential-broker.exe`
- `payload\credential-broker\install-broker.ps1`
- `payload\credential-broker\config\broker.json`
- `payload\tc-wfx\TcWfxPlugin.wfx64`
- `payload\tc-wfx\config.json`
- `payload\tc-wfx\localize.json`

## Manual Install

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1
```

Useful options:

```powershell
-BridgeSetupPath C:\path\DmsProviderBridgeSetup-v1.0.0.exe
-BrokerInstallRoot C:\Users\<user>\AppData\Local\Credential Broker
-WfxPluginPath C:\path\TcWfxPlugin.wfx64
-PluginConfigPath C:\path\config.json
-PluginLocalizePath C:\path\localize.json
-WinCmdIniPath C:\Users\<user>\AppData\Roaming\GHISLER\wincmd.ini
-SkipBridge
-SkipBroker
-SkipHealthCheck
-DisableTcRegistration
-PauseOnError
```

Default health endpoint:

- Bridge: `http://127.0.0.1:8765/health`

## Uninstall

The orchestrator uninstall removes only its WFX files. Bridge and Credential Broker are uninstalled through their own entries in Windows Apps & Features.

Manual WFX cleanup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```
