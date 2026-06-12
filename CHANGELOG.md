# Changelog

All notable changes to this project will be documented in this file.

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

