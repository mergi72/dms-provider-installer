# dms-provider-installer

Samostatny instalacni projekt pro nasazeni dms-provider-bridge jako Windows Service a instalaci TC WFX pluginu.

Cile:
- Udrzet bridge repo ciste (jen aplikace/API).
- Udrzet tc-wfx-plugin repo ciste (jen plugin kod).
- Mit jedno misto pro deployment kroky (venv, service, config, plugin copy, uninstall).

## Co tento projekt dela

- Pripravi bridge runtime z release ZIPu nebo z lokalniho checkoutu.
- Vytvori Python virtual environment.
- Nainstaluje Python dependencies.
- Vytvori user local konfiguraci.
- Nainstaluje/aktualizuje Windows Service pres NSSM.
- Zkopiruje WFX plugin do Total Commander cesty.
- Umozni uninstall.

## Predpoklady

- PowerShell spusteny jako Administrator.
- Python 3.11+ na stroji.
- NSSM binarka dostupna lokalne (napr. tools/nssm/nssm.exe).

## Rychle prikazy

Install:

powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 \
  -BridgeSourceRepoPath C:\Users\merhautr\python_projects\dms-provider-bridge \
  -WfxPluginBinaryPath C:\Users\merhautr\python_projects\tc-wfx-plugin\artifacts\TcWfxPlugin-win-x64\TcWfxPlugin.dll \
  -NssmExePath C:\tools\nssm\win64\nssm.exe

Uninstall:

powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 \
  -NssmExePath C:\tools\nssm\win64\nssm.exe
