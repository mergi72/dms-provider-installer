# Changelog

All notable changes to this project will be documented in this file.

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
