# DMS Provider Installer Test Protocol

This protocol covers the orchestrator installer model introduced in `v0.3.0-alpha`.

## Build Smoke

From `dms-provider-installer`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-inno-installer.ps1 -SkipCompile
```

Expected result:

- `payload\installers\DmsProviderBridgeSetup.exe` exists.
- `payload\broker\credential-broker.exe` exists.
- `payload\broker\install-broker.ps1` exists.
- `payload\tc-wfx\TcWfxPlugin.wfx64` exists.
- `payload\tc-wfx\config.json` exists.
- `payload\tc-wfx\localize.json` exists.
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

- Credential Broker setup runs first in the current user context.
- WFX plugin is installed under the orchestrator user install root `tc-wfx` directory.
- DMS Provider Bridge setup runs last and owns its own admin/elevation flow.
- WFX `config.json` is present next to the plugin and under `tc-wfx\config`.
- WFX `localize.json` is present under `tc-wfx\config`.
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
