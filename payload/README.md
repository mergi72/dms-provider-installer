Payload staging directory for the DMS Provider orchestrator installer.

Generated layout:

- installers/DmsProviderBridgeSetup.exe
- broker/credential-broker.exe
- broker/install-broker.ps1
- broker/config/broker.json
- tc-wfx/TcWfxPlugin.wfx64
- tc-wfx/config.json
- tc-wfx/localize.json

Use scripts/prepare-payload.ps1 to refresh this directory from sibling repos.
