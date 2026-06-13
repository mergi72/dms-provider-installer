# Changelog

All notable changes to this project will be documented in this file.

## [v0.3.8-alpha] - 2026-06-13

### Changed

- Refreshed Credential Broker payload to v0.2.11.
- Orchestrator now starts the `CredentialBroker` scheduled task after the broker setup returns, then runs its own broker health check.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.7-alpha] - 2026-06-13

### Changed

- Refreshed DMS Provider Bridge payload to v0.4.22.
- Refreshed Credential Broker payload to v0.2.10.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.6-alpha] - 2026-06-13

### Changed

- Changed orchestrator install flow to user context first: Credential Broker, WFX plugin install/registration, then DMS Provider Bridge setup last.
- Removed the orchestrator-level administrator requirement so the bridge setup owns its own elevation/admin flow.
- Changed the default orchestrator install root to the current user's local app data programs directory.
- Made WFX file copy idempotent when the payload file is already in the target location.
- Updated the install wrapper to pass `PluginLocalizePath`.

## [v0.3.5-alpha] - 2026-06-13

### Changed

- Refreshed WFX plugin payload for tc-wfx-plugin v0.2.7.
- Kept DMS Provider Bridge payload on v0.4.21.
- Kept Credential Broker payload on v0.2.9.

## [v0.3.4-alpha] - 2026-06-13

### Changed

- Refreshed orchestrator payload for DMS Provider Bridge v0.4.21.
- Refreshed WFX plugin payload for tc-wfx-plugin v0.2.6.
- Kept Credential Broker payload on v0.2.9.
- Added WFX `localize.json` to the orchestrator payload and install copy step.

## [v0.3.3-alpha] - 2026-06-13

### Changed

- Refreshed orchestrator payload for DMS Provider Bridge v0.4.19.
- Kept Credential Broker payload on v0.2.9.
- Updated manual install documentation to reference the current bridge setup version.

## [v0.3.2-alpha] - 2026-06-12

### Changed

- Refreshed orchestrator payload for DMS Provider Bridge v0.4.18.
- Kept Credential Broker payload on v0.2.9.
- Updated manual install documentation to reference the current bridge setup version.

## [v0.3.1-alpha] - 2026-06-12

### Changed

- Refreshed orchestrator payload for DMS Provider Bridge v0.4.17.
- Kept Credential Broker payload on v0.2.9.
- Updated manual install documentation to reference the current bridge setup version.

## [v0.3.0-alpha] - 2026-06-12

### Changed

- Converted installer project into an orchestrator for dedicated component installers.
- Bridge deployment is now delegated to `DmsProviderBridgeSetup.exe`.
- Credential Broker deployment is now delegated to `CredentialBrokerSetup.exe`.
- WFX plugin installation and Total Commander registration remain owned by this project.
- Payload layout now uses `payload/installers/` for child setup EXEs and `payload/tc-wfx/` for the plugin bundle.

### Removed

- Direct bridge executable deployment.
- Direct NSSM service setup.
- Direct bridge config bundling and copying.
- `DMS_PROVIDER_CONFIG_DIR` setup from this installer.

## [v0.2.2-alpha] - 2026-06-06

### Added

- Installer payload is now split into `bridge/` and `tc-wfx/` directories.
- Bridge provider configuration files are bundled into installer payload (`bridge/config/*.json`).
- Bridge configuration copy step during install into `%ProgramFiles%\DMS Provider\config`.

### Changed

- Inno Setup file sources and install parameters updated to use separated payload directories.
- Installer documentation updated for new payload structure and default path fallbacks.

### Fixed

- Build orchestrator now validates `prepare-payload.ps1` success correctly.
- Build orchestrator no longer fails when `nssm.exe` source and destination paths are identical.

