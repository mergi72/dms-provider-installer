Payload staging directory for the DMS Provider orchestrator installer.

Generated layout:

- installers/DmsProviderBridgeSetup.exe
- credential-broker/credential-broker.exe
- credential-broker/install-broker.ps1
- credential-broker/config/broker.json
- tc-wfx/TcWfxPlugin.wfx64
- tc-wfx/config.json
- tc-wfx/localize.json

Use scripts/prepare-payload.ps1 to refresh this directory from sibling repos.
