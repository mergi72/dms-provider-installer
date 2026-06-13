# dms-provider-installer

[![Status](https://img.shields.io/badge/Status-Alpha-orange)](https://github.com/mergi72/dms-provider-installer)
[![Version](https://img.shields.io/badge/Version-v0.3.12--alpha-blue)](https://github.com/mergi72/dms-provider-installer)

Current development branch: `develop`  
Stable release branch: `main`

Orchestrator installer for the DMS Provider desktop stack.

It bundles and runs the dedicated installers in this order:

- Credential Broker
- Total Commander WFX plugin
- DMS Provider Bridge

The orchestrator runs in the current user context. The credential broker installer owns broker deployment, per-user scheduled task setup, and broker config. The bridge installer owns its own elevation/admin flow, bridge executable deployment, service/task setup, NSSM usage, health checks, and machine/user config locations. This project owns only orchestration and Total Commander WFX installation/registration.

## What This Project Does

- Bundles `DmsProviderBridgeSetup.exe`.
- Bundles `CredentialBrokerSetup.exe`.
- Installs `TcWfxPlugin.wfx64` into the orchestrator user install root under `tc-wfx`.
- Installs WFX `config.json` next to the plugin and under `tc-wfx\config`.
- Installs WFX localization from `localize.json` under `tc-wfx\config`.
- Runs broker setup first and bridge setup last.
- Optionally verifies bridge and broker health endpoints.
- Registers the WFX plugin in Total Commander `wincmd.ini` under `[FileSystemPlugins64]`.
- Creates a `wincmd.ini` backup before modification.

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
- picks the latest `CredentialBrokerSetup-*.exe` from the broker repo unless `-BrokerSetupRelativePath` is provided;
- copies the WFX plugin, runtime config, and localization file from `tc-wfx-plugin`;
- compiles [installer.iss](installer.iss) with Inno Setup.

Output:

- `artifacts\installer\DmsProviderInstaller-v0.3.12-alpha.exe`

Prepare payload only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-payload.ps1 `
  -BridgeRepoPath ..\dms-provider-bridge `
  -CredentialBrokerRepoPath ..\credential-broker `
  -TcPluginRepoPath ..\tc-wfx-plugin
```

Payload layout:

- `payload\installers\DmsProviderBridgeSetup.exe`
- `payload\installers\CredentialBrokerSetup.exe`
- `payload\tc-wfx\TcWfxPlugin.wfx64`
- `payload\tc-wfx\config.json`
- `payload\tc-wfx\localize.json`

## Manual Install

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-wrapper.ps1
```

Useful options:

```powershell
-BridgeSetupPath C:\path\DmsProviderBridgeSetup-v0.4.22.exe
-BrokerSetupPath C:\path\CredentialBrokerSetup-v0.2.12.exe
-WfxPluginPath C:\path\TcWfxPlugin.wfx64
-PluginConfigPath C:\path\config.json
-PluginLocalizePath C:\path\localize.json
-WinCmdIniPath C:\Users\<user>\AppData\Roaming\GHISLER\wincmd.ini
-SkipBridge
-SkipBroker
-SkipHealthCheck
-DisableTcRegistration
-PauseOnError
-PauseOnBrokerStep
```

Default health endpoints:

- Bridge: `http://127.0.0.1:8765/health`
- Credential Broker: `http://127.0.0.1:8776/health`

## Uninstall

The orchestrator uninstall removes only its WFX files. Bridge and Credential Broker are uninstalled through their own entries in Windows Apps & Features.

Manual WFX cleanup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

