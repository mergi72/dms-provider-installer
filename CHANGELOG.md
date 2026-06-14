# Changelog

All notable changes to this project will be documented in this file.

## [v0.5.0-beta] - 2026-06-14

- Beta release candidate for external Total Commander testing.
- Bundles DMS Provider Bridge v0.5.0-beta.
- Bundles Credential Broker v0.5.0-beta user-level installer payload.
- Bundles tc-wfx-plugin v0.5.0-beta.

## [v0.3.13-alpha] - 2026-06-14

### Changed

- Removed the nested `CredentialBrokerSetup.exe` child installer from the orchestrator package.
- Installs the Credential Broker runtime directly into `%LOCALAPPDATA%\Credential Broker`, matching the standalone broker installer layout.
- Runs `%LOCALAPPDATA%\Credential Broker\install-broker.ps1` with the same install root.
- Keeps broker startup, health wait, and per-user scheduled task registration in the broker install script without another Inno setup layer.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.12-alpha] - 2026-06-13

### Changed

- Refreshed Credential Broker payload to v0.2.12.
- Prints Credential Broker installer/stdout/stderr log tails when broker health check fails.
- Starts Credential Broker through its local launcher after WFX installation instead of depending on scheduled task lookup.
- Refreshes the v0.2.12 broker payload with ScheduledTasks-compatible `Interactive` logon type.
- Refreshes the v0.2.12 broker payload with ScheduledTasks-compatible `Limited` run level.
- Refreshes the v0.2.12 broker payload to avoid version-specific `New-ScheduledTaskSettingsSet` parameters.
- Refreshes the v0.2.12 broker payload to use `schtasks.exe` instead of PowerShell ScheduledTasks cmdlets.
- Refreshes the v0.2.12 broker payload so missing-task cleanup does not block task creation.
- Refreshes the v0.2.12 broker payload to avoid `/TR` path quoting issues by using an encoded launcher command.
- Refreshes the v0.2.12 broker payload to use the short PowerShell `-File` launcher command again.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.11-alpha] - 2026-06-13

### Changed

- Starts Credential Broker only after the Total Commander WFX plugin has been installed and registered.
- Keeps broker setup first and DMS Provider Bridge setup last.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept Credential Broker payload on v0.2.11.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.10-alpha] - 2026-06-13

### Changed

- Waits briefly for the Credential Broker scheduled task to become visible after broker setup.
- Falls back to starting the broker launcher directly when the scheduled task is not visible after setup.
- Keeps the main installer diagnostic pauses from v0.3.9-alpha.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept Credential Broker payload on v0.2.11.
- Kept tc-wfx-plugin payload on v0.2.7.

## [v0.3.9-alpha] - 2026-06-13

### Changed

- Added installer diagnostics switches for pausing the main orchestration window after broker setup/start and after errors.
- Enabled the diagnostic pauses in the packaged Inno installer so broker initialization errors remain visible on a clean machine.
- Kept DMS Provider Bridge payload on v0.4.22.
- Kept Credential Broker payload on v0.2.11.
- Kept tc-wfx-plugin payload on v0.2.7.

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

