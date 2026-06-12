# DMS Provider Installer Test Protocol

This protocol covers the orchestrator installer model introduced in `v0.3.0-alpha`.

## Build Smoke

From `dms-provider-installer`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-inno-installer.ps1 -SkipCompile
```

Expected result:

- `payload\installers\DmsProviderBridgeSetup.exe` exists.
- `payload\installers\CredentialBrokerSetup.exe` exists.
- `payload\tc-wfx\TcWfxPlugin.wfx64` exists.
- `payload\tc-wfx\config.json` exists.
- No bridge config files are copied into the orchestrator payload.

Full compile:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-inno-installer.ps1
```

Expected result:

- `artifacts\installer\DmsProviderInstaller-v0.3.0-alpha.exe`

## Install Smoke

Run the generated installer.

Expected flow:

- DMS Provider Bridge setup runs.
- Credential Broker setup runs.
- WFX plugin is installed to `%ProgramFiles%\DMS Provider\tc-wfx`.
- WFX `config.json` is present next to the plugin and under `tc-wfx\config`.
- Total Commander registration is updated when `wincmd.ini` is detected.
- A `wincmd.ini.*.bak` backup is created before modification.

Expected health:

- Bridge: `http://127.0.0.1:8765/health`
- Credential Broker: `http://127.0.0.1:8776/health`

## Ownership Checks

The orchestrator must not install or mutate:

- bridge service configuration directly;
- bridge machine/user config files directly;
- bridge config environment variables directly;
- Credential Broker config files directly;
- Credential Broker scheduled task directly.

Those responsibilities belong to the dedicated component installers.
